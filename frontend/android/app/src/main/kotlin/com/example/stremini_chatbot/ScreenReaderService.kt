package com.example.stremini_chatbot

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Rect
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class ScreenReaderService : AccessibilityService() {

    companion object {
        const val ACTION_START_SCAN = "com.example.stremini_chatbot.START_SCAN"
        const val ACTION_STOP_SCAN = "com.example.stremini_chatbot.STOP_SCAN"
        const val ACTION_SCAN_COMPLETE = "com.example.stremini_chatbot.SCAN_COMPLETE"
        const val EXTRA_SCANNED_TEXT = "scanned_text"
        
        private const val TAG = "ScreenReaderService"
        private var instance: ScreenReaderService? = null
        
        fun isRunning(context: android.content.Context? = null): Boolean {
            return instance != null
        }
    }

    private lateinit var windowManager: WindowManager
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
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
        Log.d(TAG, "✅ Screen Reader Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for manual scanning
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        serviceScope.cancel()
        clearAllOverlays()
        Log.d(TAG, "Service destroyed")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_SCAN -> {
                Log.d(TAG, "START_SCAN received")
                if (!isScanning && !tagsVisible) {
                    startScreenScan()
                } else if (tagsVisible) {
                    Log.d(TAG, "Tags already visible - clearing them")
                    clearTags()
                } else {
                    Log.d(TAG, "Already scanning")
                }
            }
            ACTION_STOP_SCAN -> {
                Log.d(TAG, "STOP_SCAN received")
                clearAllOverlays()
            }
        }
        return START_NOT_STICKY
    }

    private fun startScreenScan() {
        Log.d(TAG, "🔍 Starting screen scan...")
        isScanning = true
        showScanningAnimation()
        
        serviceScope.launch {
            try {
                delay(1500) // Scanning animation duration
                
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.e(TAG, "❌ Cannot access screen - rootInActiveWindow is null")
                    showError("Cannot access screen content. Please ensure accessibility permission is granted.")
                    return@launch
                }
                
                Log.d(TAG, "✅ Got root node, extracting elements...")
                
                // Extract screen elements
                val elements = extractScreenElements(rootNode)
                rootNode.recycle()
                
                Log.d(TAG, "📋 Extracted ${elements.size} elements")
                
                if (elements.isEmpty()) {
                    showError("No content found on screen to analyze")
                    return@launch
                }
                
                // Log first few elements for debugging
                elements.take(3).forEach { elem ->
                    Log.d(TAG, "Element: type=${elem.type}, text=${elem.text?.take(50)}")
                }
                
                // Send to backend for analysis
                Log.d(TAG, "🌐 Sending to backend for analysis...")
                val result = analyzeScreenElements(elements)
                
                Log.d(TAG, "✅ Analysis complete: ${result.elements.size} tagged elements")
                
                // Hide scanning animation
                hideScanningAnimation()
                
                // Show tags on screen
                displayTags(result)
                
                isScanning = false
                tagsVisible = true
                
                // Broadcast completion
                val completeIntent = Intent(ACTION_SCAN_COMPLETE)
                completeIntent.putExtra(EXTRA_SCANNED_TEXT, "Scan complete: ${result.elements.size} elements tagged")
                sendBroadcast(completeIntent)
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Scan failed", e)
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
        Log.d(TAG, "Total elements found: ${elements.size}")
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
        if (bounds.width() < 20 || bounds.height() < 20) {
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { 
                    traverseNode(it, elements, depth + 1)
                    it.recycle()
                }
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
        if (!text.isNullOrBlank() && text.length >= 3) {
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
            node.getChild(i)?.let { 
                traverseNode(it, elements, depth + 1)
                it.recycle()
            }
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
        Log.d(TAG, "🔄 Building API request...")
        
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

        Log.d(TAG, "📤 Sending request to backend...")
        Log.d(TAG, "Request body preview: ${requestJson.toString().take(200)}...")

        val request = Request.Builder()
            .url("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/analyze-screen")
            .post(requestBody)
            .build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            val errorBody = response.body?.string()
            Log.e(TAG, "❌ API Error: ${response.code}, Body: $errorBody")
            throw IOException("API Error: ${response.code}")
        }

        val responseBody = response.body?.string() 
            ?: throw IOException("Empty response")

        Log.d(TAG, "📥 Response received: ${responseBody.take(200)}...")

        val json = JSONObject(responseBody)

        if (!json.optBoolean("success", false)) {
            val error = json.optString("error", "Unknown error")
            Log.e(TAG, "❌ Analysis failed: $error")
            throw IOException("Analysis failed: $error")
        }

        // Parse elements
        val analyzedElements = mutableListOf<ElementAnalysis>()
        val elementsArray = json.getJSONArray("elements")

        Log.d(TAG, "Parsing ${elementsArray.length()} analyzed elements...")

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

        Log.d(TAG, "✅ Successfully parsed ${analyzedElements.size} elements")

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

        Log.d(TAG, "Showing scanning animation...")

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

        try {
            windowManager.addView(scanningOverlay, params)
            Log.d(TAG, "✅ Scanning overlay added")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to add scanning overlay", e)
        }
    }

    private fun hideScanningAnimation() {
        scanningOverlay?.let { view ->
            try {
                windowManager.removeView(view)
                Log.d(TAG, "Scanning overlay removed")
            } catch (e: Exception) {
                Log.e(TAG, "Error removing scanning overlay", e)
            }
        }
        scanningOverlay = null
    }

    // ========================================
    // DISPLAY TAGS ON SCREEN
    // ========================================
    private fun displayTags(result: AnalysisResult) {
        Log.d(TAG, "📍 Displaying ${result.elements.size} tags...")
        
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

        try {
            windowManager.addView(tagsContainer, params)
            
            // Add tags for risky elements or all elements
            var tagCount = 0
            result.elements.forEach { element ->
                // Show all tags, not just risky ones
                createTagView(element)
                tagCount++
            }
            
            Log.d(TAG, "✅ Displayed $tagCount tags")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to display tags", e)
        }
    }

    private fun createTagView(element: ElementAnalysis) {
        val tagView = android.widget.TextView(this).apply {
            text = element.tag
            textSize = 11f
            setPadding(12, 6, 12, 6)
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
                cornerRadius = 14f
                setStroke(2, android.graphics.Color.parseColor("#FFFFFF"))
            }
            
            elevation = 10f
            alpha = 0.95f
            
            // Add icon based on tag
            when (element.tag) {
                "Scam" -> setCompoundDrawablesWithIntrinsicBounds(android.R.drawable.ic_dialog_alert, 0, 0, 0)
                "Safe" -> setCompoundDrawablesWithIntrinsicBounds(android.R.drawable.checkbox_on_background, 0, 0, 0)
                "Urgent" -> setCompoundDrawablesWithIntrinsicBounds(android.R.drawable.ic_dialog_info, 0, 0, 0)
            }
            compoundDrawablePadding = 4
        }

        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            // Position tag near the element (top-right corner)
            // Ensure it doesn't go off screen
            val maxX = resources.displayMetrics.widthPixels - 120
            val maxY = resources.displayMetrics.heightPixels - 40
            
            leftMargin = minOf(element.bounds.right - 100, maxX).coerceAtLeast(10)
            topMargin = minOf(element.bounds.top - 5, maxY).coerceAtLeast(10)
        }

        try {
            tagsContainer?.addView(tagView, layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding tag view", e)
        }
    }

    // ========================================
    // CLEAR TAGS
    // ========================================
    private fun clearTags() {
        Log.d(TAG, "Clearing tags...")
        tagsContainer?.let { container ->
            try {
                windowManager.removeView(container)
                Log.d(TAG, "✅ Tags cleared")
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing tags", e)
            }
        }
        tagsContainer = null
        tagsVisible = false
    }

    private fun clearAllOverlays() {
        Log.d(TAG, "Clearing all overlays...")
        hideScanningAnimation()
        clearTags()
        isScanning = false
        tagsVisible = false
    }

    // ========================================
    // ERROR HANDLING
    // ========================================
    private fun showError(message: String) {
        Log.e(TAG, "Error: $message")
        
        // Send error to MainActivity
        val intent = Intent(ACTION_SCAN_COMPLETE)
        intent.putExtra("error", message)
        sendBroadcast(intent)
        
        hideScanningAnimation()
        isScanning = false
        
        // Show toast on main thread
        serviceScope.launch(Dispatchers.Main) {
            android.widget.Toast.makeText(
                this@ScreenReaderService,
                message,
                android.widget.Toast.LENGTH_LONG
            ).show()
        }
    }
}
