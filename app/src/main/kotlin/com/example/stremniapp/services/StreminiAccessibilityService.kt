package com.example.stremniapp.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel

class StreminiAccessibilityService : AccessibilityService() {
    
    companion object {
        var instance: StreminiAccessibilityService? = null
        var methodChannel: MethodChannel? = null
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        
        serviceInfo = info
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // This is called when screen content changes
        // We don't need to do anything here automatically
    }
    
    override fun onInterrupt() {
        // Handle interruption
    }
    
    fun captureScreenText(): String {
        val rootNode = rootInActiveWindow ?: return "No content accessible"
        val textBuilder = StringBuilder()
        
        extractText(rootNode, textBuilder)
        rootNode.recycle()
        
        return textBuilder.toString()
    }
    
    private fun extractText(node: AccessibilityNodeInfo, builder: StringBuilder) {
        // Get text from current node
        node.text?.let {
            if (it.isNotEmpty()) {
                builder.append(it).append("\n")
            }
        }
        
        node.contentDescription?.let {
            if (it.isNotEmpty()) {
                builder.append(it).append("\n")
            }
        }
        
        // Recursively get text from child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            childNode?.let {
                extractText(it, builder)
                it.recycle()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}
