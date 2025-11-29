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
import android.widget.LinearLayout
import android.widget.TextView
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

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
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()
    
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Overlay views
    private var scanningOverlay: View? = null
    private var tagsContainer: FrameLayout? = null
    private var isScanning = false
    private var tagsVisible = false

    // Store detected content with positions
    data class ContentWithPosition(
        val text: String,
        val bounds: Rect,
        val nodeInfo: String
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "✅ Screen Reader Service Connected - Works over ALL apps")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Monitor for window changes to ensure we can scan any app
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            Log.d(TAG, "Window changed: ${event.packageName}")
        }
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
        Log.d(TAG, "🔍 Starting screen scan - scanning ANY active app...")
        isScanning = true
        showScanningAnimation()
        
        serviceScope.launch {
            try {
                delay(1000) // Brief animation
                
                // Get the CURRENT active window - works for ANY app
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.e(TAG, "❌ Cannot access screen - rootInActiveWindow is null")
                    showError("Cannot access screen content. Please ensure accessibility permission is granted and try reopening the app you want to scan.")
                    return@launch
                }
                
                val packageName = rootNode.packageName?.toString() ?: "unknown"
                Log.d(TAG, "✅ Scanning app: $packageName")
                
                // Extract content with position data
                val contentList = mutableListOf<ContentWithPosition>()
                extractContentWithPositions(rootNode, contentList)
                rootNode.recycle()
                
                Log.d(TAG, "📋 Extracted ${contentList.size} content items from $packageName")
                
                if (contentList.isEmpty()) {
                    showInfo("Screen appears empty - no analyzable content found. Try scrolling or interacting with the app.")
                    return@launch
                }
                
                // Combine all text for analysis
                val fullText = contentList.joinToString("\n") { it.text }
                Log.d(TAG, "Text preview: ${fullText.take(200)}...")
                
                // Send to backend for analysis
                Log.d(TAG, "🌐 Sending to backend for analysis...")
                val result = analyzeScreenContent(fullText)
                
                Log.d(TAG, "✅ Analysis complete: isSafe=${result.isSafe}, tags=${result.tags.size}")
                
                // Hide scanning animation
                hideScanningAnimation()
                
                // Show tags positioned near relevant content
                displayTagsNearContent(contentList, result)
                
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
    // EXTRACT CONTENT WITH POSITIONS
    // ========================================
    private fun extractContentWithPositions(
        node: AccessibilityNodeInfo,
        contentList: MutableList<ContentWithPosition>
    ) {
        try {
            // Get text from current node
            val text = node.text?.toString() ?: node.contentDescription?.toString()
            
            if (!text.isNullOrBlank() && text.length > 3) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                
                // Only add if bounds are valid and visible on screen
                if (bounds.width() > 0 && bounds.height() > 0 && bounds.top >= 0) {
                    val nodeInfo = buildString {
                        append(node.className?.toString()?.substringAfterLast('.') ?: "Unknown")
                        if (node.isClickable) append(" [Clickable]")
                        if (node.isCheckable) append(" [Checkable]")
                    }
                    
                    contentList.add(ContentWithPosition(text, bounds, nodeInfo))
                }
            }
            
            // Traverse children
            for (i in 0 until node.childCount) {
                try {
                    node.getChild(i)?.let { 
                        extractContentWithPositions(it, contentList)
                        it.recycle()
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Error traversing child node: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error extracting content: ${e.message}")
        }
    }

    // ========================================
    // ANALYZE USING BACKEND API
    // ========================================
    data class ScanResult(
        val isSafe: Boolean,
        val riskLevel: String,
        val tags: List<String>,
        val analysis: String
    )

    private suspend fun analyzeScreenContent(content: String): ScanResult = withContext(Dispatchers.IO) {
        Log.d(TAG, "🔄 Building API request...")
        
        try {
            val requestJson = JSONObject().apply {
                put("content", content.take(5000))
            }

            val requestBody = requestJson.toString()
                .toRequestBody("application/json".toMediaType())

            Log.d(TAG, "📤 Sending request to /security/scan-content...")

            val request = Request.Builder()
                .url("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/scan-content")
                .post(requestBody)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            val response = client.newCall(request).execute()

            val responseBody = response.body?.string() 
                ?: throw IOException("Empty response from server")

            Log.d(TAG, "📥 Response code: ${response.code}")

            if (!response.isSuccessful) {
                Log.e(TAG, "❌ API Error: ${response.code}")
                
                return@withContext ScanResult(
                    isSafe = true,
                    riskLevel = "safe",
                    tags = listOf("Analysis Error"),
                    analysis = "Unable to connect to security service."
                )
            }

            val json = JSONObject(responseBody)

            val isSafe = json.optBoolean("isSafe", true)
            val riskLevel = json.optString("riskLevel", "safe")
            val analysis = json.optString("analysis", "Content analyzed")
            
            val tagsArray = json.optJSONArray("tags") ?: JSONArray()
            val tags = mutableListOf<String>()
            for (i in 0 until tagsArray.length()) {
                tags.add(tagsArray.getString(i))
            }

            if (tags.isEmpty() && !isSafe) {
                tags.add("Review Recommended")
            }

            Log.d(TAG, "✅ Parsed result: isSafe=$isSafe, riskLevel=$riskLevel, tags=${tags.size}")

            return@withContext ScanResult(
                isSafe = isSafe,
                riskLevel = riskLevel,
                tags = tags,
                analysis = analysis
            )
            
        } catch (e: IOException) {
            Log.e(TAG, "❌ Network error", e)
            return@withContext ScanResult(
                isSafe = true,
                riskLevel = "safe",
                tags = listOf("Network Error"),
                analysis = "Could not reach security server."
            )
        } catch (e: Exception) {
            Log.e(TAG, "❌ Analysis error", e)
            return@withContext ScanResult(
                isSafe = true,
                riskLevel = "safe",
                tags = listOf("Error"),
                analysis = "Analysis failed: ${e.message}"
            )
        }
    }

    // ========================================
    // DISPLAY TAGS NEAR CONTENT - IMPROVED VISIBILITY
    // ========================================
    private fun displayTagsNearContent(
        contentList: List<ContentWithPosition>,
        result: ScanResult
    ) {
        Log.d(TAG, "📍 Displaying tags near content...")
        
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
            
            // ONLY tag if risk level is warning or danger
            if (result.riskLevel == "safe") {
                Log.d(TAG, "Content is safe - no tags needed")
                
                showSafeIndicator()
                return
            }
            
            val taggedBounds = mutableSetOf<Rect>()
            val maxTags = 8
            var tagCount = 0
            
            // Critical patterns for tagging
            val criticalPatterns = listOf(
                "verify your account", "suspended", "confirm password",
                "click here to login", "won a prize", "claim your reward",
                "urgent action required", "verify identity", "payment failed",
                "account will be closed", "verify now", "limited time"
            )
            
            val dangerPatterns = listOf("scam", "phishing", "fraud", "steal")
            val warningPatterns = listOf("suspicious", "unusual", "verify")
            
            // Process content and place tags
            contentList.forEach { content ->
                if (tagCount >= maxTags) return@forEach
                
                val lowerText = content.text.lowercase()
                
                // Skip if already tagged nearby
                if (taggedBounds.any { existingBounds ->
                    Math.abs(existingBounds.top - content.bounds.top) < 120 &&
                    Math.abs(existingBounds.left - content.bounds.left) < 120
                }) {
                    return@forEach
                }
                
                // Determine tag based on content
                val tagInfo = when {
                    criticalPatterns.any { lowerText.contains(it) } -> {
                        TagInfo("🚨 PHISHING", android.graphics.Color.parseColor("#D32F2F"))
                    }
                    dangerPatterns.any { lowerText.contains(it) } && result.riskLevel == "danger" -> {
                        TagInfo("⚠️ SCAM", android.graphics.Color.parseColor("#F44336"))
                    }
                    warningPatterns.any { lowerText.contains(it) } && result.riskLevel == "warning" -> {
                        TagInfo("⚠️ Verify", android.graphics.Color.parseColor("#FF9800"))
                    }
                    result.tags.any { it.contains("Emotional", ignoreCase = true) } && lowerText.length > 50 -> {
                        TagInfo("💭 Manipulation", android.graphics.Color.parseColor("#9C27B0"))
                    }
                    else -> null
                }
                
                tagInfo?.let { (text, color) ->
                    createTag(content.bounds, text, color, content.text)
                    taggedBounds.add(content.bounds)
                    tagCount++
                }
            }
            
            // If no specific tags but content is dangerous, show general warning
            if (tagCount == 0 && result.riskLevel == "danger") {
                val topBounds = Rect(40, 250, 600, 350)
                createTag(
                    topBounds, 
                    "🚨 THREAT DETECTED", 
                    android.graphics.Color.parseColor("#D32F2F"),
                    result.analysis
                )
                tagCount++
            }
            
            // Add status indicator at bottom
            if (tagCount > 0) {
                showStatusIndicator(result, tagCount)
            }
            
            Log.d(TAG, "✅ $tagCount tags displayed")
            
            // Auto-hide based on severity
            serviceScope.launch {
                val hideDelay = when (result.riskLevel) {
                    "danger" -> 60000L
                    "warning" -> 30000L
                    else -> 5000L
                }
                delay(hideDelay)
                if (tagsVisible) {
                    clearTags()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to display tags", e)
        }
    }

    private fun showSafeIndicator() {
        val safeView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(32, 16, 32, 16)
            setBackgroundColor(android.graphics.Color.parseColor("#4CAF50"))
            elevation = 12f
        }
        
        val iconText = TextView(this).apply {
            text = "✓"
            textSize = 24f
            setTextColor(android.graphics.Color.WHITE)
            setPadding(0, 0, 16, 0)
        }
        
        val messageText = TextView(this).apply {
            text = "Screen is Safe"
            textSize = 16f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        safeView.addView(iconText)
        safeView.addView(messageText)
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.TOP
            topMargin = 100
        }
        
        tagsContainer?.addView(safeView, layoutParams)
        
        serviceScope.launch {
            delay(3000)
            if (tagsVisible) {
                clearTags()
            }
        }
    }

    private fun showStatusIndicator(result: ScanResult, tagCount: Int) {
        val statusView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(32, 16, 32, 16)
            val bgColor = when (result.riskLevel) {
                "danger" -> android.graphics.Color.parseColor("#D32F2F")
                "warning" -> android.graphics.Color.parseColor("#F57C00")
                else -> android.graphics.Color.parseColor("#388E3C")
            }
            setBackgroundColor(bgColor)
            elevation = 12f
        }
        
        val statusText = TextView(this).apply {
            text = when (result.riskLevel) {
                "danger" -> "🛡️ $tagCount THREATS FOUND"
                "warning" -> "🛡️ $tagCount Warnings"
                else -> "🛡️ Safe"
            }
            textSize = 14f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        statusView.addView(statusText)
        
        val screenHeight = resources.displayMetrics.heightPixels
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
            bottomMargin = 100
        }
        
        tagsContainer?.addView(statusView, layoutParams)
    }

    private fun createTag(bounds: Rect, text: String, color: Int, fullText: String) {
        val tagView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(24, 12, 24, 12)
            
            // Rounded background
            background = createRoundedBackground(color)
            elevation = 10f
            alpha = 0.95f
        }
        
        val textView = TextView(this).apply {
            this.text = text
            textSize = 13f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        tagView.addView(textView)
        
        // Smart positioning
        val screenWidth = resources.displayMetrics.widthPixels
        val tagWidth = 300
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            // Position tag near the content
            leftMargin = when {
                bounds.right + tagWidth < screenWidth - 40 -> bounds.right + 20
                bounds.left - tagWidth > 40 -> bounds.left - tagWidth - 20
                else -> 40
            }
            
            topMargin = (bounds.top - 60).coerceIn(80, resources.displayMetrics.heightPixels - 200)
        }

        tagView.setOnClickListener {
            showDetailedAnalysis(text, fullText)
        }

        try {
            tagsContainer?.addView(tagView, layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding tag", e)
        }
    }
    
    private fun createRoundedBackground(color: Int): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            setColor(color)
            cornerRadius = 24f
            setStroke(3, android.graphics.Color.WHITE)
        }
    }

    private fun showDetailedAnalysis(tagText: String, fullText: String) {
        android.widget.Toast.makeText(
            this,
            "$tagText\nContent: ${fullText.take(100)}...",
            android.widget.Toast.LENGTH_LONG
        ).show()
    }

    data class TagInfo(val text: String, val color: Int)

    // ========================================
    // SCANNING ANIMATION
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

        try {
            windowManager.addView(scanningOverlay, params)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add scanning overlay", e)
        }
    }

    private fun hideScanningAnimation() {
        scanningOverlay?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing scanning overlay", e)
            }
        }
        scanningOverlay = null
    }

    private fun showInfo(message: String) {
        hideScanningAnimation()
        
        serviceScope.launch(Dispatchers.Main) {
            android.widget.Toast.makeText(
                this@ScreenReaderService,
                message,
                android.widget.Toast.LENGTH_LONG
            ).show()
        }
        
        isScanning = false
    }

    private fun showError(message: String) {
        val intent = Intent(ACTION_SCAN_COMPLETE)
        intent.putExtra("error", message)
        sendBroadcast(intent)
        
        hideScanningAnimation()
        isScanning = false
        
        serviceScope.launch(Dispatchers.Main) {
            android.widget.Toast.makeText(
                this@ScreenReaderService,
                message,
                android.widget.Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun clearTags() {
        Log.d(TAG, "Clearing tags...")
        tagsContainer?.let { container ->
            try {
                windowManager.removeView(container)
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing tags", e)
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
}
