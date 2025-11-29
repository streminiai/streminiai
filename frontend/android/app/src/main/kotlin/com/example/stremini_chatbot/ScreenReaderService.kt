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
        val nodeInfo: String // Description of what this is (button, text, link, etc)
    )

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
                delay(800) // Brief animation
                
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.e(TAG, "❌ Cannot access screen - rootInActiveWindow is null")
                    showError("Cannot access screen content. Please ensure accessibility permission is granted.")
                    return@launch
                }
                
                Log.d(TAG, "✅ Got root node, extracting content with positions...")
                
                // Extract content with position data
                val contentList = mutableListOf<ContentWithPosition>()
                extractContentWithPositions(rootNode, contentList)
                rootNode.recycle()
                
                Log.d(TAG, "📋 Extracted ${contentList.size} content items")
                
                if (contentList.isEmpty()) {
                    showInfo("Screen appears empty - no analyzable content found")
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
            
            if (!text.isNullOrBlank() && text.length > 3) { // Filter out very short text
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                
                // Only add if bounds are valid and visible on screen
                if (bounds.width() > 0 && bounds.height() > 0) {
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
                put("content", content.take(5000)) // Limit to 5000 chars
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
            Log.d(TAG, "📥 Response body: ${responseBody.take(300)}...")

            if (!response.isSuccessful) {
                Log.e(TAG, "❌ API Error: ${response.code}")
                
                return@withContext ScanResult(
                    isSafe = true,
                    riskLevel = "safe",
                    tags = listOf("Analysis Error"),
                    analysis = "Unable to connect to security service. Status code: ${response.code}"
                )
            }

            // Parse JSON response
            val json = JSONObject(responseBody)

            val isSafe = json.optBoolean("isSafe", true)
            val riskLevel = json.optString("riskLevel", "safe")
            val analysis = json.optString("analysis", "Content analyzed")
            
            val tagsArray = json.optJSONArray("tags") ?: JSONArray()
            val tags = mutableListOf<String>()
            for (i in 0 until tagsArray.length()) {
                tags.add(tagsArray.getString(i))
            }

            if (tags.isEmpty()) {
                tags.add(if (isSafe) "Safe" else "Review Recommended")
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
    // DISPLAY TAGS NEAR CONTENT
    // ========================================
    private fun displayTagsNearContent(
        contentList: List<ContentWithPosition>,
        result: ScanResult
    ) {
        Log.d(TAG, "📍 Displaying tags near content...")
        
        // Create tags container
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
            
            // Smart tagging: only tag the most relevant items
            val taggedBounds = mutableSetOf<Rect>() // Prevent duplicate tags on same location
            val maxTags = 5 // Limit number of tags to avoid clutter
            var tagCount = 0
            
            // Prioritize dangerous patterns first
            val dangerPatterns = listOf("scam", "phishing", "verify account", "click here", "urgent")
            val warningPatterns = listOf("limited time", "act now", "prize", "winner", "free")
            val infoPatterns = listOf("password", "confirm", "payment")
            
            // Process content in priority order
            contentList.forEach { content ->
                if (tagCount >= maxTags) return@forEach
                
                val lowerText = content.text.lowercase()
                
                // Skip if already tagged nearby (within 100px)
                if (taggedBounds.any { existingBounds ->
                    Math.abs(existingBounds.top - content.bounds.top) < 100 &&
                    Math.abs(existingBounds.left - content.bounds.left) < 100
                }) {
                    return@forEach
                }
                
                // Determine tag based on content
                val tagInfo = when {
                    dangerPatterns.any { lowerText.contains(it) } -> {
                        TagInfo("⚠️ SCAM ALERT", android.graphics.Color.parseColor("#F44336"))
                    }
                    warningPatterns.any { lowerText.contains(it) } -> {
                        TagInfo("⏰ Urgent Tactic", android.graphics.Color.parseColor("#FF9800"))
                    }
                    infoPatterns.any { lowerText.contains(it) } -> {
                        TagInfo("🔐 Verify Source", android.graphics.Color.parseColor("#2196F3"))
                    }
                    lowerText.contains("emotional") || result.tags.contains("Emotional Manipulation") -> {
                        TagInfo("💭 Emotional", android.graphics.Color.parseColor("#9C27B0"))
                    }
                    !result.isSafe && result.riskLevel == "danger" -> {
                        TagInfo("⚠️ Suspicious", android.graphics.Color.parseColor("#F44336"))
                    }
                    !result.isSafe && result.riskLevel == "warning" -> {
                        TagInfo("⚠️ Check This", android.graphics.Color.parseColor("#FF9800"))
                    }
                    else -> null
                }
                
                tagInfo?.let { (text, color) ->
                    createTag(content.bounds, text, color, content.text)
                    taggedBounds.add(content.bounds)
                    tagCount++
                }
            }
            
            // If analysis found threats but no specific tags placed, show general warning
            if (tagCount == 0 && !result.isSafe) {
                // Place warning at top of screen
                val topBounds = Rect(100, 200, 500, 300)
                createTag(
                    topBounds, 
                    "⚠️ SUSPICIOUS CONTENT", 
                    android.graphics.Color.parseColor("#F44336"),
                    result.analysis
                )
                tagCount++
            }
            
            // Add overall safety indicator at bottom if scan was successful
            if (tagCount > 0) {
                val screenHeight = resources.displayMetrics.heightPixels
                val bottomBounds = Rect(100, screenHeight - 200, 500, screenHeight - 100)
                val statusColor = when (result.riskLevel) {
                    "danger" -> android.graphics.Color.parseColor("#F44336")
                    "warning" -> android.graphics.Color.parseColor("#FF9800")
                    else -> android.graphics.Color.parseColor("#4CAF50")
                }
                createTag(
                    bottomBounds,
                    "🛡️ Scan: ${result.tags.size} issues found",
                    statusColor,
                    "Risk Level: ${result.riskLevel.uppercase()}"
                )
            }
            
            Log.d(TAG, "✅ $tagCount tags displayed")
            
            // Auto-hide after 30 seconds
            serviceScope.launch {
                delay(30000)
                if (tagsVisible) {
                    clearTags()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to display tags", e)
        }
    }
    
    data class TagInfo(val text: String, val color: Int)

    private fun createTag(bounds: Rect, text: String, color: Int, fullText: String) {
        // Create custom tag view
        val tagView = TextView(this).apply {
            this.text = text
            textSize = 12f
            setTextColor(android.graphics.Color.WHITE)
            setPadding(20, 8, 20, 8)
            
            // Rounded corners background
            background = createRoundedBackground(color)
            
            elevation = 8f
            alpha = 0.95f
            
            // Make text bold
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        // Calculate optimal position
        // Place tag to the right of content or above if no space
        val screenWidth = resources.displayMetrics.widthPixels
        val tagWidth = 200 // Estimated tag width
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            // Try to place on the right side of the content
            if (bounds.right + tagWidth < screenWidth - 40) {
                // Place to the right
                leftMargin = bounds.right + 16
                topMargin = bounds.top.coerceAtLeast(80)
            } else {
                // Place above or to the left
                leftMargin = (bounds.left - tagWidth).coerceAtLeast(20)
                topMargin = (bounds.top - 50).coerceAtLeast(80)
            }
            
            // Add some margin from edges
            leftMargin = leftMargin.coerceIn(20, screenWidth - tagWidth - 20)
            rightMargin = 20
        }

        // Make clickable to show details
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
            cornerRadius = 20f
            
            // Add stroke/border for better visibility
            setStroke(2, android.graphics.Color.WHITE)
        }
    }

    private fun showDetailedAnalysis(tagText: String, fullText: String) {
        android.widget.Toast.makeText(
            this,
            "$tagText\nContent: ${fullText.take(100)}...",
            android.widget.Toast.LENGTH_LONG
        ).show()
    }

    // ========================================
    // SCANNING ANIMATION
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
    // INFO/ERROR HANDLING
    // ========================================
    private fun showInfo(message: String) {
        Log.i(TAG, "Info: $message")
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
        Log.e(TAG, "Error: $message")
        
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
}
