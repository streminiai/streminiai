package com.stremini.ai

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class ScreenReaderService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Handle accessibility events
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Screen content changed - can be used for real-time scanning
            }
        }
    }

    override fun onInterrupt() {
        // Handle interruption
    }

    fun getScreenContent(): String {
        val rootNode = rootInActiveWindow ?: return ""
        return extractTextFromNode(rootNode)
    }

    private fun extractTextFromNode(node: AccessibilityNodeInfo): String {
        val builder = StringBuilder()
        
        if (node.text != null) {
            builder.append(node.text.toString()).append(" ")
        }
        
        if (node.contentDescription != null) {
            builder.append(node.contentDescription.toString()).append(" ")
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                builder.append(extractTextFromNode(child))
                child.recycle()
            }
        }
        
        return builder.toString()
    }

    companion object {
        private var instance: ScreenReaderService? = null
        
        fun getInstance(): ScreenReaderService? = instance
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}
