package com.example.stremniapp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import android.view.accessibility.AccessibilityManager
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.stremniapp/screen_capture"
    private val REQUEST_MEDIA_PROJECTION = 1001
    private val REQUEST_OVERLAY_PERMISSION = 1002
    private val REQUEST_ACCESSIBILITY = 1003

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var pendingResult: MethodChannel.Result? = null

    private lateinit var projectionManager: MediaProjectionManager
    private val textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }

    private fun requestScreenCapturePermission(result: MethodChannel.Result) {
        pendingResult = result
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
    }

    private fun captureScreen(result: MethodChannel.Result) {
        if (mediaProjection == null) {
            result.error("NO_PERMISSION", "Screen capture permission not granted", null)
            return
        }

        try {
            val metrics = DisplayMetrics()
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            windowManager.defaultDisplay.getMetrics(metrics)

            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            // Create ImageReader
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

            // Create VirtualDisplay
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null, null
            )

            // Delay to allow screen to be captured
            Handler(Looper.getMainLooper()).postDelayed({
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    val bitmap = imageToBitmap(image, width, height)
                    image.close()

                    // Perform OCR
                    performOCR(bitmap, result)

                    // Cleanup
                    cleanupCapture()
                } else {
                    result.error("CAPTURE_FAILED", "Failed to capture screen", null)
                    cleanupCapture()
                }
            }, 300)

        } catch (e: Exception) {
            Log.e("MainActivity", "Screen capture error", e)
            result.error("CAPTURE_ERROR", e.message, null)
            cleanupCapture()
        }
    }

    private fun captureScreenText(result: MethodChannel.Result) {
        if (mediaProjection == null) {
            result.error("NO_PERMISSION", "Screen capture permission not granted", null)
            return
        }

        try {
            val metrics = DisplayMetrics()
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            windowManager.defaultDisplay.getMetrics(metrics)

            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            // Create ImageReader
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

            // Create VirtualDisplay
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null, null
            )

            // Delay to allow screen to be captured
            Handler(Looper.getMainLooper()).postDelayed({
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    val bitmap = imageToBitmap(image, width, height)
                    image.close()

                    // Perform OCR only (no base64 image)
                    performOCRTextOnly(bitmap, result)

                    // Cleanup
                    cleanupCapture()
                } else {
                    result.error("CAPTURE_FAILED", "Failed to capture screen", null)
                    cleanupCapture()
                }
            }, 300)

        } catch (e: Exception) {
            Log.e("MainActivity", "Screen capture error", e)
            result.error("CAPTURE_ERROR", e.message, null)
            cleanupCapture()
        }
    }

    private fun imageToBitmap(image: Image, width: Int, height: Int): Bitmap {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * width

        val bitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        
        // Crop to actual screen size
        return Bitmap.createBitmap(bitmap, 0, 0, width, height)
    }

    private fun performOCR(bitmap: Bitmap, result: MethodChannel.Result) {
        val inputImage = InputImage.fromBitmap(bitmap, 0)
        
        textRecognizer.process(inputImage)
            .addOnSuccessListener { visionText ->
                val text = visionText.text
                val base64Image = bitmapToBase64(bitmap)
                
                result.success(mapOf(
                    "text" to text,
                    "image" to base64Image,
                    "success" to true
                ))
            }
            .addOnFailureListener { e ->
                Log.e("MainActivity", "OCR failed", e)
                result.error("OCR_FAILED", e.message, null)
            }
    }

    private fun performOCRTextOnly(bitmap: Bitmap, result: MethodChannel.Result) {
        val inputImage = InputImage.fromBitmap(bitmap, 0)
        
        textRecognizer.process(inputImage)
            .addOnSuccessListener { visionText ->
                val text = visionText.text
                
                result.success(mapOf(
                    "text" to text,
                    "success" to true
                ))
            }
            .addOnFailureListener { e ->
                Log.e("MainActivity", "OCR failed", e)
                result.error("OCR_FAILED", e.message, null)
            }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val byteArrayOutputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, byteArrayOutputStream)
        val byteArray = byteArrayOutputStream.toByteArray()
        return android.util.Base64.encodeToString(byteArray, android.util.Base64.DEFAULT)
    }

    private fun cleanupCapture() {
        virtualDisplay?.release()
        imageReader?.close()
        virtualDisplay = null
        imageReader = null
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(packageName) == true
    }

    private fun requestAccessibilityPermission(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivityForResult(intent, REQUEST_ACCESSIBILITY)
        result.success(true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_MEDIA_PROJECTION -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    mediaProjection = projectionManager.getMediaProjection(resultCode, data)
                    pendingResult?.success(true)
                } else {
                    pendingResult?.success(false)
                }
                pendingResult = null
            }
            REQUEST_OVERLAY_PERMISSION -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    pendingResult?.success(Settings.canDrawOverlays(this))
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupCapture()
        mediaProjection?.stop()
        textRecognizer.close()
    }
}
