package com.example.stremini_chatbot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * Minimal floating bubble service with a radial menu.
 * The bubble can be dragged and tapped to toggle the menu.
 */
class ChatOverlayService : Service(), View.OnTouchListener {

    companion object {
        private const val TAG = "ChatOverlayService"
        private const val CHANNEL_ID = "stremini_overlay"
    }

        /* ---------- Window \u0026 Views ---------- */
        private lateinit var windowManager: WindowManager
        private lateinit var overlayView: View
        private lateinit var bubbleIcon: ImageView
        private lateinit var layoutParams: WindowManager.LayoutParams

        /* ---------- Menu ---------- */
        private var menuView: View? = null
        private var menuLayoutParams: WindowManager.LayoutParams? = null
        private var isMenuVisible = false

        /* ---------- Drag state ---------- */
        private var initialX = 0
        private var initialY = 0
        private var initialTouchX = 0f
        private var initialTouchY = 0f
        private var isDragging = false

        override fun onBind(intent: Intent?): IBinder? = null

        override fun onCreate() {
            super.onCreate()
            Log.d(TAG, "Service created")

            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            startForegroundService()
            setupOverlay()
        }

        /* ---------- Overlay setup ---------- */
        private fun setupOverlay() {
            overlayView = LayoutInflater.from(this)
                .inflate(R.layout.chat_bubble_layout, null)

            bubbleIcon = overlayView.findViewById(R.id.bubble_icon)
            bubbleIcon.setOnTouchListener(this)

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE

            layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 200
            }

            windowManager.addView(overlayView, layoutParams)
        }

        /* ---------- Touch handling ---------- */
        override fun onTouch(v: View?, event: MotionEvent?): Boolean {
            if (event == null) return false

            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams.x
                    initialY = layoutParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    return true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()

                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isDragging = true
                        layoutParams.x = initialX + dx
                        layoutParams.y = initialY + dy
                        windowManager.updateViewLayout(overlayView, layoutParams)
                    }
                    return true
                }

                MotionEvent.ACTION_UP -> {
                    if (!isDragging) toggleMenu()
                    return true
                }
            }
            return false
        }

        /* ---------- Menu toggle ---------- */
        private fun toggleMenu() {
            if (isMenuVisible) hideMenu() else showMenu()
        }

        /* ---------- Show radial menu ---------- */
        private fun showMenu() {
            if (menuView != null) return
            menuView = LayoutInflater.from(this).inflate(R.layout.radial_menu_layout, null)

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE

            menuLayoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = layoutParams.x
                y = layoutParams.y
            }

            // Simple radial layout: 5 buttons arranged in a circle
            val radius = 120
            val angles = listOf(0, 72, 144, 216, 288) // degrees
            val buttonIds = listOf(
                R.id.btn_refresh,
                R.id.btn_settings,
                R.id.btn_ai,
                R.id.btn_scanner,
                R.id.btn_keyboard
            )

            buttonIds.forEachIndexed { idx, resId ->
                val btn = menuView!!.findViewById<ImageView>(resId)
                val angleRad = Math.toRadians(angles[idx].toDouble())
                val tx = (radius + radius * Math.cos(angleRad)).toInt()
                val ty = (radius + radius * Math.sin(angleRad)).toInt()
                btn.x = tx.toFloat()
                btn.y = ty.toFloat()
                btn.setOnClickListener {
                    Toast.makeText(this, "Menu item ${idx + 1} clicked", Toast.LENGTH_SHORT).show()
                    hideMenu()
                }
            }

            windowManager.addView(menuView, menuLayoutParams)
            isMenuVisible = true
        }

        /* ---------- Hide radial menu ---------- */
        private fun hideMenu() {
            menuView?.let {
                windowManager.removeView(it)
                menuView = null
                isMenuVisible = false
            }
        }

        /* ---------- Foreground service ---------- */
        private fun startForegroundService() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Stremini Overlay",
                    NotificationManager.IMPORTANCE_LOW
                )
                getSystemService(NotificationManager::class.java)
                    .createNotificationChannel(channel)
            }

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Stremini AI")
                .setContentText("Overlay running")
                .setSmallIcon(R.mipmap.ic_launcher)
                .build()

            startForeground(1, notification)
        }

        override fun onDestroy() {
            super.onDestroy()
            Log.d(TAG, "Service destroyed")

            if (::overlayView.isInitialized) {
                windowManager.removeView(overlayView)
            }
            hideMenu()
        }
    }
