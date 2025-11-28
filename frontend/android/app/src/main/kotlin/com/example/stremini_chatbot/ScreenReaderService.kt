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
                
                Log.d(TAG, "✅ Got root node, extracting text...")
                
                // Extract ALL text from screen
                val screenText = extractAllText(rootNode)
                rootNode.recycle()
                
                Log.d(TAG, "📋 Extracted ${screenText.length} characters of text")
                
                if (screenText.isEmpty()) {
                    showError("No text found on screen to analyze")
                    return@launch
                }
                
                Log.d(TAG, "Text preview: ${screenText.take(200)}...")
                
                // Send to simplified backend endpoint
                Log.d(TAG, "🌐 Sending to backend for analysis...")
                val result = analyzeScreenContent(screenText)
                
                Log.d(TAG, "✅ Analysis complete")
                
                // Hide scanning animation
                hideScanningAnimation()
                
                // Show results as tags
                displayResultTags(result)
                
                isScanning = false
                tagsVisible = true
                
                // Broadcast completion
                val completeIntent = Intent(ACTION_SCAN_COMPLETE)
                completeIntent.putExtra(EXTRA_SCANNED_TEXT, "Scan complete")
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
    // EXTRACT ALL TEXT FROM SCREEN
    // ========================================
    private fun extractAllText(rootNode: AccessibilityNodeInfo): String {
        val textBuilder = StringBuilder()
        traverseForText(rootNode, textBuilder)
        return textBuilder.toString().trim()
    }

    private fun traverseForText(node: AccessibilityNodeInfo, textBuilder: StringBuilder) {
        // Get text from current node
        val text = node.text?.toString() ?: node.contentDescription?.toString()
        if (!text.isNullOrBlank()) {
            textBuilder.append(text).append(" ")
        }
        
        // Traverse children
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { 
                traverseForText(it, textBuilder)
                it.recycle()
            }
        }
    }

    // ========================================
    // ANALYZE USING SIMPLER ENDPOINT
    // ========================================
    data class ScanResult(
        val isSafe: Boolean,
        val riskLevel: String,
        val tags: List<String>,
        val analysis: String
    )

    private suspend fun analyzeScreenContent(content: String): ScanResult = withContext(Dispatchers.IO) {
        Log.d(TAG, "🔄 Building API request...")
        
        val requestJson = JSONObject().apply {
            put("content", content)
        }

        val requestBody = requestJson.toString()
            .toRequestBody("application/json".toMediaType())

        Log.d(TAG, "📤 Sending request to /security/scan-content...")

        val request = Request.Builder()
            .url("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/scan-content")
            .post(requestBody)
            .build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            val errorBody = response.body?.string()
            Log.e(TAG, "❌ API Error: ${response.code}, Body: $errorBody")
            
            // Return a mock/fallback result for now
            return@withContext ScanResult(
                isSafe = false,
                riskLevel = "warning",
                tags = listOf("Unable to analyze", "API Error ${response.code}"),
                analysis = "Could not connect to security service. Error: ${response.code}"
            )
        }

        val responseBody = response.body?.string() 
            ?: throw IOException("Empty response")

        Log.d(TAG, "📥 Response received: ${responseBody.take(200)}...")

        val json = JSONObject(responseBody)

        // Parse response
        val isSafe = json.optBoolean("isSafe", true)
        val riskLevel = json.optString("riskLevel", "safe")
        val analysis = json.optString("analysis", "Content analyzed")
        
        val tagsArray = json.optJSONArray("tags") ?: JSONArray()
        val tags = mutableListOf<String>()
        for (i in 0 until tagsArray.length()) {
            tags.add(tagsArray.getString(i))
        }

        Log.d(TAG, "✅ Parsed result: isSafe=$isSafe, tags=${tags.size}")

        ScanResult(
            isSafe = isSafe,
            riskLevel = riskLevel,
            tags = tags,
            analysis = analysis
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
    // DISPLAY RESULT TAGS ON SCREEN
    // ========================================
    private fun displayResultTags(result: ScanResult) {
        Log.d(TAG, "📍 Displaying scan results...")
        
        // Create container for summary
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
            
            // Create a summary card at the top
            createSummaryCard(result)
            
            Log.d(TAG, "✅ Results displayed")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to display results", e)
        }
    }

    private fun createSummaryCard(result: ScanResult) {
        val summaryView = LayoutInflater.from(this)
            .inflate(android.R.layout.simple_list_item_2, null)
        
        val text1 = summaryView.findViewById<android.widget.TextView>(android.R.id.text1)
        val text2 = summaryView.findViewById<android.widget.TextView>(android.R.id.text2)
        
        text1.apply {
            text = if (result.isSafe) "✅ Safe" else "⚠️ Threats Detected"
            textSize = 20f
            setTextColor(if (result.isSafe) 
                android.graphics.Color.parseColor("#4CAF50") 
            else 
                android.graphics.Color.parseColor("#FF5722"))
        }
        
        text2.apply {
            text = result.tags.joinToString(", ")
            textSize = 14f
            setTextColor(android.graphics.Color.WHITE)
        }
        
        summaryView.apply {
            setPadding(40, 40, 40, 40)
            setBackgroundColor(android.graphics.Color.parseColor("#DD000000"))
        }
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            topMargin = 100
            leftMargin = 40
            rightMargin = 40
        }

        try {
            tagsContainer?.addView(summaryView, layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding summary card", e)
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
