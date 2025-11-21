
package com.example.stremniapp.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.provider.Settings
import com.example.stremniapp.services.ScreenCaptureService
import com.example.stremniapp.services.StreminiAccessibilityService
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import android.util.Base64

class ScreenCaptureChannel(
    private val activity: Activity,
    channel: MethodChannel
) : MethodChannel.MethodCallHandler {
    
    companion object {
        const val REQUEST_SCREEN_CAPTURE = 1001
        const val REQUEST_ACCESSIBILITY = 1002
    }
    
    private var pendingResult: MethodChannel.Result? = null
    private val context: Context = activity.applicationContext
    
    init {
        channel.setMethodCallHandler(this)
        ScreenCaptureService.methodChannel = channel
        StreminiAccessibilityService.methodChannel = channel
    }
    
    override fun onMethodCall(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestScreenCapturePermission" -> {
                requestScreenCapturePermission(result)
            }
            
            "captureScreen" -> {
                captureScreen(result)
            }
            
            "captureScreenText" -> {
                captureScreenText(result)
            }
            
            "checkAccessibilityPermission" -> {
                result.success(isAccessibilityServiceEnabled())
            }
            
            "requestAccessibilityPermission" -> {
                requestAccessibilityPermission(result)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun requestScreenCapturePermission(result: MethodChannel.Result) {
        pendingResult = result
        val projectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val captureIntent = projectionManager.createScreenCaptureIntent()
        activity.startActivityForResult(captureIntent, REQUEST_SCREEN_CAPTURE)
    }
    
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Start screen capture service
                val intent = Intent(context, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                }
                context.startForegroundService(intent)
                
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
    
    private fun captureScreen(result: MethodChannel.Result) {
        try {
            val service = context as? ScreenCaptureService
            
            ScreenCaptureService.captureCallback = { text, bitmap ->
                val imageBase64 = bitmap?.let { bitmapToBase64(it) }
                
                result.success(mapOf(
                    "text" to text,
                    "image" to imageBase64,
                    "success" to true
                ))
            }
            
            // Trigger capture
            // This would need to be called on the service instance
            result.success(mapOf("success" to true, "message" to "Capture initiated"))
            
        } catch (e: Exception) {
            result.error("CAPTURE_ERROR", e.message, null)
        }
    }
    
    private fun captureScreenText(result: MethodChannel.Result) {
        val service = StreminiAccessibilityService.instance
        
        if (service == null) {
            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
            return
        }
        
        try {
            val text = service.captureScreenText()
            result.success(mapOf(
                "text" to text,
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("CAPTURE_ERROR", e.message, null)
        }
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return service?.contains("${context.packageName}/${StreminiAccessibilityService::class.java.name}") == true
    }
    
    private fun requestAccessibilityPermission(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }
    
    private fun bitmapToBase64(bitmap: Bitmap): String {
        val byteArrayOutputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
        val byteArray = byteArrayOutputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}
