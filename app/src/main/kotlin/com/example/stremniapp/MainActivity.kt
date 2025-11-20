package com.example.stremniapp

import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.stremniapp/permissions"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Request runtime permissions on app start
        requestRuntimePermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup method channel for Flutter to request permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestRuntimePermissions()
                    result.success(true)
                }
                "checkPermissions" -> {
                    val hasPermissions = checkAllPermissions()
                    result.success(hasPermissions)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestRuntimePermissions() {
        val permissionsToRequest = mutableListOf<String>()

        // Internet - always granted (manifest permission)
        // No need to request at runtime

        // Camera permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
            != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.CAMERA)
        }

        // Storage permissions based on Android version
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ - Use READ_MEDIA_IMAGES
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        } else {
            // Below Android 13 - Use READ_EXTERNAL_STORAGE
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            
            // Write permission for older Android versions
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) 
                    != PackageManager.PERMISSION_GRANTED) {
                    permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                }
            }
        }

        // Request all needed permissions
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun checkAllPermissions(): Boolean {
        // Check Camera
        val hasCamera = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == 
            PackageManager.PERMISSION_GRANTED

        // Check Storage
        val hasStorage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) == 
                PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == 
                PackageManager.PERMISSION_GRANTED
        }

        return hasCamera && hasStorage
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            if (!allGranted) {
                // Show a message if permissions are denied
                println("⚠️ Some permissions were denied")
            } else {
                println("✅ All permissions granted")
            }
        }
    }
}
