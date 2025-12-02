package com.example.stremini_chatbot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.widget.Toast
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
                    val has = hasOverlayPermission()
                    result.success(has)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermissionSafe()
                    result.success(true)
                }
                "hasAccessibilityPermission" -> {
                    val has = isAccessibilityServiceEnabled()
                    android.util.Log.d("MainActivity", "hasAccessibilityPermission: $has")
                    result.success(has)
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermissionSafe()
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
                    startOverlayServiceSafe()
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
     * Check overlay permission with better error handling
     */
    private fun hasOverlayPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(this)
            } else {
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking overlay permission", e)
            false
        }
    }

    /**
     * Request overlay permission safely
     */
    private fun requestOverlayPermissionSafe() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(this)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    
                    Toast.makeText(
                        this,
                        "Please enable 'Display over other apps' permission",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error requesting overlay permission", e)
            Toast.makeText(
                this,
                "Unable to open settings. Please enable overlay permission manually.",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    /**
     * Check if the accessibility service is actually enabled
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "$packageName/${ScreenReaderService::class.java.canonicalName}"
        
        try {
            // Method 1: Check enabled services
            val settingValue = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            if (settingValue.isNullOrEmpty()) {
                android.util.Log.d("MainActivity", "No accessibility services enabled")
                return false
            }
            
            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(settingValue)
            
            while (colonSplitter.hasNext()) {
                val componentName = colonSplitter.next()
                android.util.Log.d("MainActivity", "Found enabled service: $componentName")
                if (componentName.equals(serviceName, ignoreCase = true)) {
                    android.util.Log.d("MainActivity", "✅ Our service is enabled!")
                    
                    // Method 2: Double-check with accessibility enabled setting
                    val accessibilityEnabled = Settings.Secure.getInt(
                        contentResolver,
                        Settings.Secure.ACCESSIBILITY_ENABLED,
                        0
                    )
                    
                    return accessibilityEnabled == 1
                }
            }
            
            android.util.Log.d("MainActivity", "❌ Our service not found in enabled services")
            return false
            
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking accessibility service", e)
            return false
        }
    }

    /**
     * Request accessibility permission safely with detailed instructions
     */
    private fun requestAccessibilityPermissionSafe() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            
            // Show helpful toast
            Toast.makeText(
                this,
                "Please find and enable 'Stremini Screen Scanner' in the list",
                Toast.LENGTH_LONG
            ).show()
            
            android.util.Log.d("MainActivity", "Opened accessibility settings")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error opening accessibility settings", e)
            Toast.makeText(
                this,
                "Unable to open accessibility settings. Please enable manually in Settings > Accessibility",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    /**
     * Start overlay service safely
     */
    private fun startOverlayServiceSafe() {
        try {
            if (!hasOverlayPermission()) {
                Toast.makeText(
                    this,
                    "Overlay permission required. Please enable it first.",
                    Toast.LENGTH_SHORT
                ).show()
                requestOverlayPermissionSafe()
                return
            }
            
            val intent = Intent(this, ChatOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            
            android.util.Log.d("MainActivity", "Overlay service started")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error starting overlay service", e)
            Toast.makeText(
                this,
                "Failed to start overlay service: ${e.message}",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun startScreenScan() {
        try {
            val intent = Intent(this, ScreenReaderService::class.java)
            intent.action = ScreenReaderService.ACTION_START_SCAN
            startService(intent)
            android.util.Log.d("MainActivity", "Screen scan started")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error starting screen scan", e)
        }
    }

    override fun onResume() {
        super.onResume()
        try {
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
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error in onResume", e)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(eventReceiver)
        } catch (e: Exception) {
            // Receiver not registered
            android.util.Log.d("MainActivity", "Receiver not registered")
        }
    }
}
