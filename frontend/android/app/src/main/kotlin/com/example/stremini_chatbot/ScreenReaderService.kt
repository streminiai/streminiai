package com.example.stremini_chatbot

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class ScreenReaderService : AccessibilityService() {

    companion object {
        const val ACTION_START_SCAN = "com.example.stremini_chatbot.START_SCAN"
        const val ACTION_SCAN_COMPLETE = "com.example.stremini_chatbot.SCAN_COMPLETE"
        const val EXTRA_SCANNED_TEXT = "scanned_text"
        
        private var instance: ScreenReaderService? = null
        
        fun isRunning(): Boolean = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle events for our use case
    }

    override fun onInterrupt() {
        // Called when service is interrupted
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    fun scanScreen() {
        val rootNode = rootInActiveWindow ?: return
        
        val scannedText = StringBuilder()
        extractTextFromNode(rootNode, scannedText)
        
        rootNode.recycle()
        
        // Send result back to Flutter
        val intent = Intent(ACTION_SCAN_COMPLETE)
        intent.putExtra(EXTRA_SCANNED_TEXT, scannedText.toString())
        sendBroadcast(intent)
    }

    private fun extractTextFromNode(node: AccessibilityNodeInfo, builder: StringBuilder) {
        // Extract text from current node
        node.text?.let {
            if (it.isNotEmpty()) {
                builder.append(it.toString()).append("\n")
            }
        }
        
        // Extract content description
        node.contentDescription?.let {
            if (it.isNotEmpty()) {
                builder.append(it.toString()).append("\n")
            }
        }
        
        // Recursively extract from children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            child?.let {
                extractTextFromNode(it, builder)
                it.recycle()
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_START_SCAN) {
            scanScreen()
        }
        return START_NOT_STICKY
    }
}
