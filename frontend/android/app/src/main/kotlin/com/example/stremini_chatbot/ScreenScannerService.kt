package com.example.stremini_chatbot

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Rect
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.TextView
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class ScreenScannerService : AccessibilityService() {

    companion object {
        const val ACTION_START_SCAN = "com.example.stremini_chatbot.START_SCAN"
        const val ACTION_STOP_SCAN = "com.example.stremini_chatbot.STOP_SCAN"
        const val ACTION_SCAN_COMPLETE = "com.example.stremini_chatbot.SCAN_COMPLETE"
        const val EXTRA_SCANNED_TEXT = "scanned_text"
        const val EXTRA_ANALYSIS_RESULT = "analysis_result"
        
        private var instance: ScreenScannerService? = null
        
        fun isRunning(): Boolean = instance != null
    }

    private lateinit var windowManager: WindowManager
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
        .build()
    
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Overlay views
    private var scanningOverlay: View? = null
    private var tagsContainer: FrameLayout? = null
    private var isScanning = false
    private var tagsVisible = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for manual scanning
    }

    override fun onInterrupt() {
        // Handle interruption
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        serviceScope.cancel()
        clearAllOverlays()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SCAN -> {
                if (!isScanning && !tagsVisible) {
                    startScreenScan()
                } else if (tagsVisible) {
                    // Toggle off - remove tags
                    clearTags()
                }
            }
            ACTION_STOP_SCAN -> {
                clearAllOverlays()
            }
        }
        return START_NOT_STICKY
    }

    private fun startScreenScan() {
        isScanning = true
        showScanningAnimation()
        
        serviceScope.launch {
            try {
                delay(500) // Brief delay for animation
                
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    showError("Cannot access screen content")
                    return@launch
                }
                
                // Extract screen elements
                val elements = extractScreenElements(rootNode)
                rootNode.recycle()
                
                if (elements.isEmpty()) {
                    showError("No content found on screen")
                    return@launch
                }
                
                // Send to backend for analysis
                val result = analyzeScreenElements(elements)
                
                // Hide scanning animation
                hideScanningAnimation()
                
                // Show tags on screen
                displayTags(result)
                
                isScanning = false
                tagsVisible = true
                
            } catch (e: Exception) {
                hideScanningAnimation()
                showError("Scan failed: ${e.message}")
                isScanning = false
            }
        }
    }

    // ========================================
    // EXTRACT SCREEN ELEMENTS
    // ========================================
    data class ScreenElement(
        val id: String,
        val type: String,
        val text: String?,
        val bounds: Rect,
        val url: String? = null,
        val metadata: Map<String, String>? = null
    )

    private fun extractScreenElements(rootNode: AccessibilityNodeInfo): List<ScreenElement> {
        val elements = mutableListOf<ScreenElement>()
        traverseNode(rootNode, elements, 0)
        return elements.take(50) // Limit to 50 elements
    }

    private fun traverseNode(
        node: AccessibilityNodeInfo,
        elements: MutableList<ScreenElement>,
        depth: Int
    ) {
        if (depth > 15) return
        
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        
        // Skip if bounds are too small
        if (bounds.width() < 10 || bounds.height() < 10) {
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { traverseNode(it, elements, depth + 1) }
            }
            return
        }
        
        val text = node.text?.toString() ?: node.contentDescription?.toString()
        val className = node.className?.toString() ?: ""
        
        // Determine element type
        val type = when {
            className.contains("Button") -> "button"
            className.contains("EditText") -> "input"
            className.contains("TextView") && text != null -> "text"
            node.isClickable && text != null -> "link"
            text != null && text.length > 10 -> "message"
            else -> "unknown"
        }
        
        // Only add elements with meaningful text
        if (!text.isNullOrBlank() && text.length > 3) {
            val metadata = mutableMapOf<String, String>()
            node.packageName?.toString()?.let { metadata["appName"] = it }
            
            var url: String? = null
            if (text.contains("http://") || text.contains("https://")) {
                url = extractUrl(text)
            }
            
            elements.add(
                ScreenElement(
                    id = "elem_${elements.size}_${System.currentTimeMillis()}",
                    type = type,
                    text = text,
                    bounds = bounds,
                    url = url,
                    metadata = metadata.ifEmpty { null }
                )
            )
        }
        
        // Traverse children
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { traverseNode(it, elements, depth + 1) }
        }
    }

    private fun extractUrl(text: String): String? {
        val urlRegex = "(https?://[^\\s]+)".toRegex()
        return urlRegex.find(text)?.value
    }

    // ========================================
    // ANALYZE SCREEN ELEMENTS (API CALL)
    // ========================================
    data class ElementAnalysis(
        val id: String,
        val bounds: Rect,
        val tag: String,
        val tone: String,
        val emotion: String,
        val riskScore: Int,
        val reason: String
    )

    data class AnalysisResult(
        val elements: List<ElementAnalysis>,
        val overallSafety: String,
        val summary: String
    )

    private suspend fun analyzeScreenElements(elements: List<ScreenElement>): AnalysisResult = withContext(Dispatchers.IO) {
        val requestJson = JSONObject().apply {
            put("screenElements", JSONArray().apply {
                elements.forEach { element ->
                    put(JSONObject().apply {
                        put("id", element.id)
                        put("type", element.type)
                        put("text", element.text)
                        put("bounds", JSONObject().apply {
                            put("x", element.bounds.left)
                            put("y", element.bounds.top)
                            put("width", element.bounds.width())
                            put("height", element.bounds.height())
                        })
                        element.url?.let { put("url", it) }
                        element.metadata?.let { put("metadata", JSONObject(it)) }
                    })
                }
            })
            put("sessionId", "session_${System.currentTimeMillis()}")
        }

        val requestBody = requestJson.toString()
            .toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/analyze-screen")
            .post(requestBody)
            .build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            throw IOException("API Error: ${response.code}")
        }

        val responseBody = response.body?.string() 
            ?: throw IOException("Empty response")

        val json = JSONObject(responseBody)

        if (!json.optBoolean("success", false)) {
            throw IOException("Analysis failed: ${json.optString("error")}")
        }

        // Parse elements
        val analyzedElements = mutableListOf<ElementAnalysis>()
        val elementsArray = json.getJSONArray("elements")

        for (i in 0 until elementsArray.length()) {
            val elem = elementsArray.getJSONObject(i)
            val analysis = elem.getJSONObject("analysis")
            val boundsObj = elem.getJSONObject("bounds")

            analyzedElements.add(
                ElementAnalysis(
                    id = elem.getString("id"),
                    bounds = Rect(
                        boundsObj.getInt("x"),
                        boundsObj.getInt("y"),
                        boundsObj.getInt("x") + boundsObj.getInt("width"),
                        boundsObj.getInt("y") + boundsObj.getInt("height")
                    ),
                    tag = analysis.getString("tag"),
                    tone = analysis.getString("tone"),
                    emotion = analysis.getString("emotion"),
                    riskScore = analysis.getInt("riskScore"),
                    reason = analysis.getString("reason")
                )
            )
        }

        val overall = json.getJSONObject("overall")

        AnalysisResult(
            elements = analyzedElements,
            overallSafety = overall.getString("screenSafety"),
            summary = overall.getString("summary")
        )
    }

    // ========================================
    // DISPLAY SCANNING ANIMATION
    // ========================================
    private fun showScanningAnimation() {
        if (scanningOverlay != null) return

        scanningOverlay = LayoutInflater.from(this)
            .inflate(R.layout.scanning_overlay, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        )

        windowManager.addView(scanningOverlay, params)
    }

    private fun hideScanningAnimation() {
        scanningOverlay?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        scanningOverlay = null
    }

    // ========================================
    // DISPLAY TAGS ON SCREEN
    // ========================================
    private fun displayTags(result: AnalysisResult) {
        // Create container for all tags
        tagsContainer = FrameLayout(this)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        )

        windowManager.addView(tagsContainer, params)

        // Add tags for each analyzed element (only risky ones)
        result.elements.forEach { element ->
            if (element.riskScore > 30 || element.tag != "Safe") {
                createTagView(element)
            }
        }
    }

    private fun createTagView(element: ElementAnalysis) {
        val tagView = TextView(this).apply {
            text = element.tag
            textSize = 11f
            setPadding(10, 4, 10, 4)
            setTextColor(android.graphics.Color.WHITE)
            
            // Set background color based on tag
            val bgColor = when (element.tag) {
                "Scam" -> android.graphics.Color.parseColor("#D32F2F")
                "Suspicious" -> android.graphics.Color.parseColor("#FF9800")
                "Phishing" -> android.graphics.Color.parseColor("#E91E63")
                "Emotional" -> android.graphics.Color.parseColor("#9C27B0")
                "Urgent" -> android.graphics.Color.parseColor("#FF5722")
                "Safe" -> android.graphics.Color.parseColor("#4CAF50")
                else -> android.graphics.Color.parseColor("#2196F3")
            }
            
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(bgColor)
                cornerRadius = 12f
            }
            
            elevation = 8f
            alpha = 0.95f
        }

        val tagParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = element.bounds.right - 80
            y = element.bounds.top - 5
        }

        tagsContainer?.addView(tagView, tagParams)
    }

    // ========================================
    // CLEAR TAGS
    // ========================================
    private fun clearTags() {
        tagsContainer?.let { container ->
            try {
                windowManager.removeView(container)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        tagsContainer = null
        tagsVisible = false
    }

    private fun clearAllOverlays() {
        hideScanningAnimation()
        clearTags()
        isScanning = false
        tagsVisible = false
    }

    // ========================================
    // ERROR HANDLING
    // ========================================
    private fun showError(message: String) {
        // Send error to Flutter
        val intent = Intent(ACTION_SCAN_COMPLETE)
        intent.putExtra("error", message)
        sendBroadcast(intent)
        
        hideScanningAnimation()
        isScanning = false
    }
}
