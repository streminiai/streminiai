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
 * Fixed: No rotation or glitching when opening/closing menu.
 */
class ChatOverlayService : Service(), View.OnTouchListener {

    companion object {
        private const val TAG = "ChatOverlayService"
        private const val CHANNEL_ID = "stremini_overlay"
        private const val MENU_RADIUS = 120f
        private const val BUTTON_SIZE = 48  // dp
    }

    /* ---------- Window & Views ---------- */
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
                    
                    // If menu is visible, move it with the bubble
                    if (isMenuVisible && menuView != null && menuLayoutParams != null) {
                        updateMenuPosition()
                    }
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
        
        // Clear any animations on the bubble icon - NO position changes
        bubbleIcon.clearAnimation()
        bubbleIcon.rotation = 0f
        bubbleIcon.animate().cancel()
        
        // Ensure bubble view has been laid out
        if (overlayView.width == 0 || overlayView.height == 0) {
            overlayView.post { showMenuInternal() }
        } else {
            showMenuInternal()
        }
    }
    
    private fun showMenuInternal() {
        if (menuView != null) return
        
        menuView = LayoutInflater.from(this).inflate(R.layout.radial_menu_layout, null)

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            WindowManager.LayoutParams.TYPE_PHONE

        // Calculate menu container size
        val menuContainerSize = (MENU_RADIUS * 2.5).toInt()  // Extra space for buttons
        
        menuLayoutParams = WindowManager.LayoutParams(
            menuContainerSize,
            menuContainerSize,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }
        
        // Position menu centered on bubble
        updateMenuPosition()

        // Position buttons in radial layout
        setupRadialButtons()

        windowManager.addView(menuView, menuLayoutParams)
        isMenuVisible = true
    }
    
    private fun updateMenuPosition() {
        if (menuLayoutParams == null || menuView == null) return
        
        val bubbleWidth = overlayView.width
        val bubbleHeight = overlayView.height
        val menuContainerSize = menuLayoutParams!!.width
        
        // Center menu on bubble
        menuLayoutParams!!.x = layoutParams.x - (menuContainerSize / 2) + (bubbleWidth / 2)
        menuLayoutParams!!.y = layoutParams.y - (menuContainerSize / 2) + (bubbleHeight / 2)
        
        windowManager.updateViewLayout(menuView, menuLayoutParams)
    }
    
    private fun setupRadialButtons() {
        if (menuView == null) return
        
        val menuContainerSize = menuLayoutParams!!.width
        val centerX = menuContainerSize / 2f
        val centerY = menuContainerSize / 2f
        
        // 5 buttons arranged in a circle starting from top
        val angles = listOf(-90, -18, 54, 126, 198)  // degrees
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
            
            // Calculate button position
            val btnX = centerX + (MENU_RADIUS * Math.cos(angleRad)).toFloat() - (BUTTON_SIZE / 2)
            val btnY = centerY + (MENU_RADIUS * Math.sin(angleRad)).toFloat() - (BUTTON_SIZE / 2)
            
            btn.x = btnX
            btn.y = btnY
            btn.rotation = 0f
            
            btn.setOnClickListener {
                handleMenuItemClick(idx)
            }
        }
    }
    
    private fun handleMenuItemClick(index: Int) {
        val menuItems = listOf("Refresh", "Settings", "AI", "Scanner", "Keyboard")
        Toast.makeText(this, "${menuItems[index]} clicked", Toast.LENGTH_SHORT).show()
        hideMenu()
    }

    /* ---------- Hide radial menu ---------- */
    private fun hideMenu() {
        menuView?.let {
            windowManager.removeView(it)
            menuView = null
            menuLayoutParams = null
            isMenuVisible = false
        }
        
        // Ensure bubble stays static - NO rotation or movement
        bubbleIcon.clearAnimation()
        bubbleIcon.rotation = 0f
        bubbleIcon.animate().cancel()
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
