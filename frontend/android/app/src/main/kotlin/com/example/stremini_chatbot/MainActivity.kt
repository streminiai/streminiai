package com.example.stremini_chatbot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
    private val channelName = "stremini.chat.overlay"
    private val eventChannelName = "stremini.chat.overlay/events"
    
    private var eventSink: EventChannel.EventSink? = null

    private val eventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ScreenScannerService.ACTION_SCAN_COMPLETE -> {
                    val scannedText = intent.getStringExtra(ScreenScannerService.EXTRA_SCANNED_TEXT)
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
                "com.example.stremini_chatbot.FLUTTER_MESSAGE" -> {
                    val message = intent.getStringExtra("message")
                    if (message != null) {
                        sendMessageToAPI(message)
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
                    val has = ScreenScannerService.isRunning()
                    result.success(has)
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "startScreenScan" -> {
                    if (ScreenScannerService.isRunning()) {
                        startScreenScan()
                        result.success(true)
                    } else {
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

    private fun startScreenScan() {
        val intent = Intent(this, ScreenScannerService::class.java)
        intent.action = ScreenScannerService.ACTION_START_SCAN
        startService(intent)
    }

    private fun sendMessageToAPI(userMessage: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val url = URL("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/chat/message")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 15000
                connection.readTimeout = 15000

                val jsonBody = JSONObject().put("message", userMessage).toString()
                connection.outputStream.use { os ->
                    val input = jsonBody.toByteArray(Charsets.UTF_8)
                    os.write(input, 0, input.size)
                }

                if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    val jsonResponse = JSONObject(response)
                    val reply = jsonResponse.optString("reply", 
                                jsonResponse.optString("response",
                                jsonResponse.optString("message", "No response from AI")))

                    val intent = Intent(ChatOverlayService.ACTION_SEND_MESSAGE)
                    intent.putExtra(ChatOverlayService.EXTRA_MESSAGE, reply)
                    sendBroadcast(intent)
                } else {
                    val intent = Intent(ChatOverlayService.ACTION_SEND_MESSAGE)
                    intent.putExtra(ChatOverlayService.EXTRA_MESSAGE, 
                        "❌ Server error: ${connection.responseCode}")
                    sendBroadcast(intent)
                }

                connection.disconnect()
            } catch (e: Exception) {
                val intent = Intent(ChatOverlayService.ACTION_SEND_MESSAGE)
                intent.putExtra(ChatOverlayService.EXTRA_MESSAGE, 
                    "⚠️ Network error: ${e.message}")
                sendBroadcast(intent)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(ScreenScannerService.ACTION_SCAN_COMPLETE)
            addAction("com.example.stremini_chatbot.FLUTTER_MESSAGE")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(eventReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(eventReceiver, filter)
        }
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
