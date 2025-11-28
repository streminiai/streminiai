package com.example.stremini_chatbot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "stremini.chat.overlay"
    private val eventChannelName = "stremini.chat.overlay/events"
    
    private var eventSink: EventChannel.EventSink? = null

    private val eventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ScreenReaderService.ACTION_SCAN_COMPLETE -> {
                    val scannedText = intent.getStringExtra(ScreenReaderService.EXTRA_SCANNED_TEXT)
                    val error = intent.getStringExtra("error")
                    
                    if (error != null) {
                        eventSink?.success(mapOf(
                            "action" to "scan_error",
                            "error" to error
                        ))
                    } else {
                        eventSink?.success(mapOf(
                            "action" to "scan_complete",
                            "text" to scannedText
                        ))
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> {
                    val has = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                        Settings.canDrawOverlays(this) else true
                    result.success(has)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "hasAccessibilityPermission" -> {
                    val has = isAccessibilityServiceEnabled()
                    android.util.Log.d("MainActivity", "hasAccessibilityPermission: $has")
                    result.success(has)
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "startScreenScan" -> {
                    if (isAccessibilityServiceEnabled()) {
                        android.util.Log.d("MainActivity", "Starting screen scan from Flutter")
                        startScreenScan()
                        result.success(true)
                    } else {
                        android.util.Log.w("MainActivity", "Accessibility service not enabled")
                        result.error("NO_PERMISSION", "Accessibility service not enabled", null)
                    }
                }
                "startOverlayService" -> {
                    val intent = Intent(this, ChatOverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopOverlayService" -> {
                    val intent = Intent(this, ChatOverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    /**
     * Check if the accessibility service is actually enabled
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "$packageName/${ScreenReaderService::class.java.canonicalName}"
        
        try {
            val settingValue = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            if (settingValue.isNullOrEmpty()) {
                android.util.Log.d("MainActivity", "No accessibility services enabled")
                return false
            }
            
            val enabled = TextUtils.SimpleStringSplitter(':').apply {
                setString(settingValue)
            }
            
            while (enabled.hasNext()) {
                val componentName = enabled.next()
                android.util.Log.d("MainActivity", "Found enabled service: $componentName")
                if (componentName.equals(serviceName, ignoreCase = true)) {
                    android.util.Log.d("MainActivity", "✅ Our service is enabled!")
                    return true
                }
            }
            
            android.util.Log.d("MainActivity", "❌ Our service not found in enabled services")
            return false
            
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking accessibility service", e)
            return false
        }
    }

    private fun startScreenScan() {
        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = ScreenReaderService.ACTION_START_SCAN
        startService(intent)
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(ScreenReaderService.ACTION_SCAN_COMPLETE)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(eventReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(eventReceiver, filter)
        }
        
        // Log current accessibility status
        android.util.Log.d("MainActivity", "onResume - Accessibility enabled: ${isAccessibilityServiceEnabled()}")
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(eventReceiver)
        } catch (e: Exception) {
            // Receiver not registered
        }
    }
}
