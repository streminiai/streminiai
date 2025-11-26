package com.example.stremini_chatbot

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import androidx.core.view.isVisible
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class ScreenScannerService : AccessibilityService() {

    companion object {
        private const val TAG = "ScreenScannerService"
        const val ACTION_START_SCAN = "com.example.stremini_chatbot.START_SCAN"
        const val ACTION_STOP_SCAN = "com.example.stremini_chatbot.STOP_SCAN"
        var isScanning = false
            private set
    }

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var scanningView: View? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var scannedTexts = mutableListOf<ScannedText>()

    data class ScannedText(
        val text: String,
        val bounds: android.graphics.Rect,
        val tag: String? = null,
        val riskLevel: String? = null
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Screen Scanner Service Connected")

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // Configure accessibility service
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We handle events through explicit commands
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SCAN -> startScanning()
            ACTION_STOP_SCAN -> stopScanning()
        }
        return START_STICKY
    }

    private fun startScanning() {
        if (isScanning) return
        
        isScanning = true
        scannedTexts.clear()
        
        showScanningAnimation()
        
        serviceScope.launch {
            try {
                // Read screen content
                val rootNode = rootInActiveWindow
                if (rootNode != null) {
                    extractTextFromNode(rootNode)
                    rootNode.recycle()
                }

                // Send to backend for analysis
                if (scannedTexts.isNotEmpty()) {
                    analyzeScanResults()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error during scanning", e)
                stopScanning()
            }
        }
    }

    private fun extractTextFromNode(node: AccessibilityNodeInfo) {
        // Extract text from this node
        val text = node.text?.toString()
        if (!text.isNullOrBlank() && text.length > 3) {
            val bounds = android.graphics.Rect()
            node.getBoundsInScreen(bounds)
            
            scannedTexts.add(ScannedText(text, bounds))
        }

        // Recursively extract from children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                extractTextFromNode(child)
                child.recycle()
            }
        }
    }

    private suspend fun analyzeScanResults() = withContext(Dispatchers.IO) {
        try {
            // Group texts for batch analysis
            val textsToAnalyze = scannedTexts.map { it.text }
            
            for (scannedText in scannedTexts) {
                try {
                    val result = scanContentWithBackend(scannedText.text)
                    
                    withContext(Dispatchers.Main) {
                        if (!result.isSafe && result.tags.isNotEmpty()) {
                            // Update the scanned text with tags
                            val index = scannedTexts.indexOf(scannedText)
                            if (index >= 0) {
                                scannedTexts[index] = scannedText.copy(
                                    tag = result.tags.firstOrNull(),
                                    riskLevel = result.riskLevel
                                )
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error analyzing text: ${scannedText.text}", e)
                }
            }

            // Display tags on screen
            withContext(Dispatchers.Main) {
                hideScanningAnimation()
                displayTagsOverlay()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in analysis", e)
            withContext(Dispatchers.Main) {
                stopScanning()
            }
        }
    }

    private data class ScanResult(
        val isSafe: Boolean,
        val riskLevel: String,
        val tags: List<String>,
        val analysis: String
    )

    private fun scanContentWithBackend(content: String): ScanResult {
        val url = URL("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/scan-content")
        val connection = url.openConnection() as HttpURLConnection
        
        try {
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.doOutput = true

            val jsonBody = JSONObject()
            jsonBody.put("content", content)

            connection.outputStream.use { os ->
                os.write(jsonBody.toString().toByteArray())
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().readText()
                val jsonResponse = JSONObject(response)
                
                val tagsArray = jsonResponse.optJSONArray("tags") ?: JSONArray()
                val tags = mutableListOf<String>()
                for (i in 0 until tagsArray.length()) {
                    tags.add(tagsArray.getString(i))
                }

                return ScanResult(
                    isSafe = jsonResponse.optBoolean("isSafe", true),
                    riskLevel = jsonResponse.optString("riskLevel", "safe"),
                    tags = tags,
                    analysis = jsonResponse.optString("analysis", "")
                )
            } else {
                throw Exception("HTTP $responseCode")
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun showScanningAnimation() {
        val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            typeParam,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        scanningView = LayoutInflater.from(this).inflate(R.layout.scanning_overlay, null)
        
        try {
            windowManager.addView(scanningView, params)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing scanning animation", e)
        }
    }

    private fun hideScanningAnimation() {
        scanningView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error hiding scanning animation", e)
            }
        }
        scanningView = null
    }

    private fun displayTagsOverlay() {
        if (scannedTexts.isEmpty()) {
            stopScanning()
            return
        }

        val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            typeParam,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        overlayView = LayoutInflater.from(this).inflate(R.layout.tags_overlay, null)
        val container = overlayView?.findViewById<android.widget.FrameLayout>(R.id.tags_container)

        // Add tag views for each scanned text with a tag
        scannedTexts.filter { it.tag != null }.forEach { scannedText ->
            val tagView = createTagView(scannedText)
            
            val tagParams = android.widget.FrameLayout.LayoutParams(
                android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
                android.widget.FrameLayout.LayoutParams.WRAP_CONTENT
            )
            tagParams.leftMargin = scannedText.bounds.right + 10
            tagParams.topMargin = scannedText.bounds.top
            
            container?.addView(tagView, tagParams)
        }

        try {
            windowManager.addView(overlayView, params)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing tags overlay", e)
        }
    }

    private fun createTagView(scannedText: ScannedText): View {
        val tagView = TextView(this).apply {
            text = scannedText.tag
            setTextColor(android.graphics.Color.WHITE)
            textSize = 12f
            setPadding(12, 6, 12, 6)
            
            // Color based on risk level
            val bgColor = when (scannedText.riskLevel) {
                "danger" -> android.graphics.Color.parseColor("#FF3B30")
                "warning" -> android.graphics.Color.parseColor("#FF9500")
                else -> android.graphics.Color.parseColor("#34C759")
            }
            setBackgroundColor(bgColor)
            
            alpha = 0.9f
        }
        return tagView
    }

    private fun stopScanning() {
        isScanning = false
        
        hideScanningAnimation()
        
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay", e)
            }
        }
        overlayView = null
        
        scannedTexts.clear()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        stopScanning()
    }
}
