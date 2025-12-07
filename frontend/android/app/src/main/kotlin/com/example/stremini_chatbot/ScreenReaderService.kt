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

    // Store tag information for click handling
    data class TagInfo(
        val text: String,
        val color: Int,
        val fullText: String,
        val reason: String,
        val threat: String
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "✅ Screen Reader Service Connected - Works over ALL apps")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
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
                if (tagsVisible) {
                    // If tags are visible, hide them (toggle off)
                    Log.d(TAG, "Tags already visible - clearing them")
                    clearTags()
                } else if (!isScanning) {
                    // If not scanning and tags not visible, start new scan
                    startScreenScan()
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
                delay(1500) // Scanning animation
                
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Log.e(TAG, "❌ Cannot access screen - rootInActiveWindow is null")
                    showError("Cannot access screen content. Please ensure accessibility permission is granted.")
                    return@launch
                }
                
                val packageName = rootNode.packageName?.toString() ?: "unknown"
                Log.d(TAG, "✅ Scanning app: $packageName")
                
                val contentList = mutableListOf<ContentWithPosition>()
                extractContentWithPositions(rootNode, contentList)
                rootNode.recycle()
                
                Log.d(TAG, "📋 Extracted ${contentList.size} content items from $packageName")
                
                if (contentList.isEmpty()) {
                    showInfo("Screen appears empty - no analyzable content found.")
                    return@launch
                }
                
                val fullText = contentList.joinToString("\n") { it.text }
                Log.d(TAG, "Text preview: ${fullText.take(200)}...")
                
                Log.d(TAG, "🌐 Sending to backend for analysis...")
                val result = analyzeScreenContent(fullText)
                
                Log.d(TAG, "✅ Analysis complete: isSafe=${result.isSafe}, tags=${result.tags.size}")
                
                hideScanningAnimation()
                displayTagsNearContent(contentList, result)
                
                isScanning = false
                tagsVisible = true
                
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

    private fun extractContentWithPositions(
        node: AccessibilityNodeInfo,
        contentList: MutableList<ContentWithPosition>
    ) {
        try {
            val text = node.text?.toString() ?: node.contentDescription?.toString()
            
            if (!text.isNullOrBlank() && text.length > 3) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                
                if (bounds.width() > 0 && bounds.height() > 0 && bounds.top >= 0) {
                    val nodeInfo = buildString {
                        append(node.className?.toString()?.substringAfterLast('.') ?: "Unknown")
                        if (node.isClickable) append(" [Clickable]")
                        if (node.isCheckable) append(" [Checkable]")
                    }
                    
                    contentList.add(ContentWithPosition(text, bounds, nodeInfo))
                }
            }
            
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

    data class ScanResult(
        val isSafe: Boolean,
        val riskLevel: String,
        val tags: List<String>,
        val analysis: String,
        val flaggedItems: List<FlaggedItem>
    )

    data class FlaggedItem(
        val type: String,
        val content: String,
        val threat: String,
        val severity: String,
        val reason: String
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
                    analysis = "Unable to connect to security service.",
                    flaggedItems = emptyList()
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

            // Parse flaggedItems
            val flaggedItemsArray = json.optJSONArray("flaggedItems") ?: JSONArray()
            val flaggedItems = mutableListOf<FlaggedItem>()
            for (i in 0 until flaggedItemsArray.length()) {
                val item = flaggedItemsArray.getJSONObject(i)
                flaggedItems.add(
                    FlaggedItem(
                        type = item.optString("type", "message"),
                        content = item.optString("content", ""),
                        threat = item.optString("threat", "Unknown"),
                        severity = item.optString("severity", "medium"),
                        reason = item.optString("reason", "Suspicious pattern detected")
                    )
                )
            }

            if (tags.isEmpty() && !isSafe) {
                tags.add("Review Recommended")
            }

            Log.d(TAG, "✅ Parsed result: isSafe=$isSafe, riskLevel=$riskLevel, tags=${tags.size}, flaggedItems=${flaggedItems.size}")

            return@withContext ScanResult(
                isSafe = isSafe,
                riskLevel = riskLevel,
                tags = tags,
                analysis = analysis,
                flaggedItems = flaggedItems
            )
            
        } catch (e: IOException) {
            Log.e(TAG, "❌ Network error", e)
            return@withContext ScanResult(
                isSafe = true,
                riskLevel = "safe",
                tags = listOf("Network Error"),
                analysis = "Could not reach security server.",
                flaggedItems = emptyList()
            )
        } catch (e: Exception) {
            Log.e(TAG, "❌ Analysis error", e)
            return@withContext ScanResult(
                isSafe = true,
                riskLevel = "safe",
                tags = listOf("Error"),
                analysis = "Analysis failed: ${e.message}",
                flaggedItems = emptyList()
            )
        }
    }

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
            
            if (result.riskLevel == "safe") {
                Log.d(TAG, "Content is safe - showing safe indicator")
                showSafeIndicator()
                return
            }
            
            val taggedBounds = mutableSetOf<Rect>()
            val maxTags = 15
            var tagCount = 0
            
            // Analyze patterns
            val criticalPatterns = listOf(
                "verify your account", "suspended", "confirm password",
                "click here to login", "won a prize", "claim your reward",
                "urgent action required", "verify identity", "payment failed",
                "account will be closed", "verify now", "limited time",
                "act now", "expire", "suspicious activity", "click here",
                "confirm now", "update payment"
            )
            
            val dangerPatterns = listOf("scam", "phishing", "fraud", "steal", "hack")
            val warningPatterns = listOf("suspicious", "unusual", "verify", "confirm", "urgent")
            val emotionalPatterns = listOf("love", "miss you", "help me", "please", "emergency", "crisis")
            
            // First, display tags from flaggedItems
            result.flaggedItems.forEach { item ->
                if (tagCount >= maxTags) return@forEach
                
                // Find matching content
                val matchingContent = contentList.find { 
                    it.text.contains(item.content, ignoreCase = true) 
                }
                
                matchingContent?.let { content ->
                    if (taggedBounds.any { existingBounds ->
                        Math.abs(existingBounds.top - content.bounds.top) < 150 &&
                        Math.abs(existingBounds.left - content.bounds.left) < 150
                    }) {
                        return@forEach
                    }
                    
                    val color = when (item.severity) {
                        "high" -> android.graphics.Color.parseColor("#FF1744")
                        "medium" -> android.graphics.Color.parseColor("#FF9800")
                        else -> android.graphics.Color.parseColor("#2196F3")
                    }
                    
                    val tagText = when (item.threat) {
                        "Scam" -> "🚨 SCAM"
                        "Phishing" -> "🚨 PHISHING"
                        "Suspicious Link" -> "🔗 CHECK LINK"
                        else -> "⚠️ ${item.threat}"
                    }
                    
                    createClickableTag(
                        content.bounds,
                        tagText,
                        color,
                        content.text,
                        item.reason,
                        item.threat
                    )
                    taggedBounds.add(content.bounds)
                    tagCount++
                }
            }
            
            // Then analyze content for additional patterns
            contentList.forEach { content ->
                if (tagCount >= maxTags) return@forEach
                
                val lowerText = content.text.lowercase()
                
                // Skip if already tagged nearby
                if (taggedBounds.any { existingBounds ->
                    Math.abs(existingBounds.top - content.bounds.top) < 150 &&
                    Math.abs(existingBounds.left - content.bounds.left) < 150
                }) {
                    return@forEach
                }
                
                val tagInfo = when {
                    criticalPatterns.any { lowerText.contains(it) } -> {
                        TagInfo(
                            "🚨 PHISHING",
                            android.graphics.Color.parseColor("#FF1744"),
                            content.text,
                            "This message uses urgent language and asks for sensitive actions like verifying account or clicking links. This is a common phishing tactic.",
                            "Phishing"
                        )
                    }
                    dangerPatterns.any { lowerText.contains(it) } && result.riskLevel == "danger" -> {
                        TagInfo(
                            "⚠️ SCAM",
                            android.graphics.Color.parseColor("#F44336"),
                            content.text,
                            "This content contains keywords associated with scams. Do not share personal information or send money.",
                            "Scam"
                        )
                    }
                    warningPatterns.any { lowerText.contains(it) } && result.riskLevel == "warning" -> {
                        TagInfo(
                            "⚠️ Verify",
                            android.graphics.Color.parseColor("#FF9800"),
                            content.text,
                            "This message asks you to verify or confirm something. Always verify through official channels, not through links in messages.",
                            "Verification Request"
                        )
                    }
                    emotionalPatterns.any { lowerText.contains(it) } && lowerText.length > 30 -> {
                        TagInfo(
                            "💭 Emotional Tone",
                            android.graphics.Color.parseColor("#9C27B0"),
                            content.text,
                            "This message uses emotional language. Scammers often use emotions to manipulate victims. Stay calm and think carefully.",
                            "Emotional Manipulation"
                        )
                    }
                    lowerText.contains("http") || lowerText.contains("www") || lowerText.contains("bit.ly") -> {
                        TagInfo(
                            "🔗 Check Link",
                            android.graphics.Color.parseColor("#2196F3"),
                            content.text,
                            "This contains a link. Always verify the destination before clicking. Be especially careful with shortened URLs.",
                            "Link Detected"
                        )
                    }
                    else -> null
                }
                
                tagInfo?.let { info ->
                    createClickableTag(
                        content.bounds,
                        info.text,
                        info.color,
                        info.fullText,
                        info.reason,
                        info.threat
                    )
                    taggedBounds.add(content.bounds)
                    tagCount++
                }
            }
            
            if (tagCount == 0 && result.riskLevel == "danger") {
                val topBounds = Rect(60, 300, 700, 400)
                createClickableTag(
                    topBounds,
                    "🚨 THREAT DETECTED",
                    android.graphics.Color.parseColor("#D32F2F"),
                    result.analysis,
                    result.analysis,
                    "General Threat"
                )
                tagCount++
            }
            
            if (tagCount > 0) {
                showStatusIndicator(result, tagCount)
            }
            
            Log.d(TAG, "✅ $tagCount tags displayed")
            
            // Auto-hide based on severity
            serviceScope.launch {
                val hideDelay = when (result.riskLevel) {
                    "danger" -> 90000L  // 90 seconds for danger
                    "warning" -> 45000L // 45 seconds for warning
                    else -> 10000L      // 10 seconds for safe
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

    private fun createClickableTag(
        bounds: Rect,
        text: String,
        color: Int,
        fullText: String,
        reason: String,
        threat: String
    ) {
        val tagView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(32, 16, 32, 16)
            background = createEnhancedRoundedBackground(color)
            elevation = 16f
            alpha = 0.98f
            
            // Make it clickable
            isClickable = true
            isFocusable = true
        }
        
        val textView = TextView(this).apply {
            this.text = text
            textSize = 15f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
            setShadowLayer(4f, 0f, 2f, android.graphics.Color.parseColor("#40000000"))
        }
        
        tagView.addView(textView)
        
        // Smart positioning with better visibility
        val screenWidth = resources.displayMetrics.widthPixels
        val screenHeight = resources.displayMetrics.heightPixels
        val tagWidth = 350
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            leftMargin = when {
                bounds.left + tagWidth < screenWidth - 60 -> bounds.left + 20
                bounds.right - tagWidth > 60 -> bounds.right - tagWidth - 20
                else -> (screenWidth - tagWidth) / 2
            }.coerceIn(40, screenWidth - tagWidth - 40)
            
            topMargin = when {
                bounds.top > 120 -> bounds.top - 80
                bounds.bottom + 100 < screenHeight -> bounds.bottom + 20
                else -> bounds.centerY()
            }.coerceIn(100, screenHeight - 150)
        }

        // Make the tag clickable to show details using Toast instead of Dialog
        tagView.setOnClickListener {
            serviceScope.launch(Dispatchers.Main) {
                android.widget.Toast.makeText(
                    this@ScreenReaderService,
                    "$text\n\n$reason\n\nContent: \"${fullText.take(100)}...\"",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
        }

        try {
            tagsContainer?.addView(tagView, layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding tag", e)
        }
    }
    
    private fun createEnhancedRoundedBackground(color: Int): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            setColor(color)
            cornerRadius = 28f
            setStroke(4, android.graphics.Color.WHITE)
        }
    }

    private fun showSafeIndicator() {
        val safeView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(40, 20, 40, 20)
            setBackgroundColor(android.graphics.Color.parseColor("#4CAF50"))
            elevation = 16f
        }
        
        val iconText = TextView(this).apply {
            text = "✓"
            textSize = 28f
            setTextColor(android.graphics.Color.WHITE)
            setPadding(0, 0, 20, 0)
        }
        
        val messageText = TextView(this).apply {
            text = "Screen is Safe"
            textSize = 18f
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
            topMargin = 150
        }
        
        tagsContainer?.addView(safeView, layoutParams)
        
        serviceScope.launch {
            delay(4000)
            if (tagsVisible) {
                clearTags()
            }
        }
    }

    private fun showStatusIndicator(result: ScanResult, tagCount: Int) {
        val statusView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(40, 20, 40, 20)
            val bgColor = when (result.riskLevel) {
                "danger" -> android.graphics.Color.parseColor("#D32F2F")
                "warning" -> android.graphics.Color.parseColor("#F57C00")
                else -> android.graphics.Color.parseColor("#388E3C")
            }
            setBackgroundColor(bgColor)
            elevation = 16f
        }
        
        val statusText = TextView(this).apply {
            text = when (result.riskLevel) {
                "danger" -> "🛡️ $tagCount THREATS FOUND"
                "warning" -> "🛡️ $tagCount Warnings"
                else -> "🛡️ Safe"
            }
            textSize = 16f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        statusView.addView(statusText)
        
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
            bottomMargin = 120
        }
        
        tagsContainer?.addView(statusView, layoutParams)
    }

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
