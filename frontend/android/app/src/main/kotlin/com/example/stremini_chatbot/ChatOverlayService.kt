package com.example.stremini_chatbot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.abs

// Replace 'com.example.stremini_chatbot' with your actual package name

class ChatOverlayService : Service(), View.OnTouchListener {

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private lateinit var params: WindowManager.LayoutParams

    private lateinit var bubbleIcon: ImageView
    private lateinit var menuItems: List<ImageView> 
    private var isMenuExpanded = false

    // Drag Logic Variables
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false

    // Configuration
    private val bubbleSizeDp = 78f // Matches your Flutter GlowCircleButton size
    private val menuItemSizeDp = 55f // Matches your Flutter radial button size
    private val radiusDp = 110f // Matches your Flutter radius

    // Position storage
    private var lastCollapsedX = 0
    private var lastCollapsedY = 200

    private fun dpToPx(dp: Float): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForegroundService()
        setupOverlay()
    }

    private fun setupOverlay() {
        overlayView = LayoutInflater.from(this).inflate(R.layout.chat_bubble_layout, null)
        bubbleIcon = overlayView.findViewById(R.id.bubble_icon)
        
        // Ensure menu items are in the same order as in Flutter (Top to Bottom visually)
        menuItems = listOf(
            overlayView.findViewById(R.id.btn_message),
            overlayView.findViewById(R.id.btn_settings),
            overlayView.findViewById(R.id.btn_ai),
            overlayView.findViewById(R.id.btn_keyboard),
            overlayView.findViewById(R.id.btn_security)
        )

        val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        }

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            typeParam,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = lastCollapsedX
        params.y = lastCollapsedY

        bubbleIcon.setOnTouchListener(this)
        
        menuItems.forEach { view ->
            view.setOnClickListener {
                openMainApp() // Tapping any menu item returns to app
            }
        }

        windowManager.addView(overlayView, params)
    }

    override fun onTouch(v: View, event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params.x
                initialY = params.y
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
                    if (isMenuExpanded) collapseMenu() 
                }
                
                if (!isMenuExpanded) {
                    params.x = initialX + dx
                    params.y = initialY + dy
                    lastCollapsedX = params.x
                    lastCollapsedY = params.y
                    windowManager.updateViewLayout(overlayView, params)
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                if (!isDragging) {
                    toggleMenu() 
                } else {
                    snapToEdge()
                }
                return true
            }
        }
        return false
    }

    private fun toggleMenu() {
        if (isMenuExpanded) collapseMenu() else expandMenu()
    }

    private fun expandMenu() {
        isMenuExpanded = true
        
        val radiusPx = dpToPx(radiusDp).toFloat()
        val bubbleSizePx = dpToPx(bubbleSizeDp).toFloat()
        val menuItemSizePx = dpToPx(menuItemSizeDp).toFloat()

        // 1. Resize Window to allow expansion
        val expandedWindowSizePx = (radiusPx * 2) + bubbleSizePx + menuItemSizePx
        val offsetPx = (expandedWindowSizePx / 2) - (bubbleSizePx / 2)

        val currentX = params.x
        val currentY = params.y

        params.width = expandedWindowSizePx.toInt()
        params.height = expandedWindowSizePx.toInt()
        
        // Center the new large window over the bubble
        params.x = currentX - offsetPx.toInt()
        params.y = currentY - offsetPx.toInt()
        
        windowManager.updateViewLayout(overlayView, params)

        // 2. Determine Side and Angles (Dynamic Direction Logic)
        val screenWidth = resources.displayMetrics.widthPixels
        val bubbleCenterX = lastCollapsedX + (bubbleSizePx / 2)
        val isOnRightSide = bubbleCenterX > (screenWidth / 2)

        var startAngle = 0.0
        var endAngle = 0.0

        if (isOnRightSide) {
            // Icon on Right -> Explode Left (90 to 270)
            startAngle = 90.0
            endAngle = 270.0
        } else {
            // Icon on Left -> Explode Right (90 to -90)
            startAngle = 90.0
            endAngle = -90.0
        }

        val step = (endAngle - startAngle) / (menuItems.size - 1)

        // 3. Animate Items
        for ((index, view) in menuItems.withIndex()) {
            view.visibility = View.VISIBLE
            view.alpha = 0f
            
            val angle = startAngle + (index * step)
            val rad = Math.toRadians(angle)
            
            // Android Y is Down, so -sin(rad) moves Up
            val targetX = (radiusPx * cos(rad)).toFloat()
            val targetY = (radiusPx * -sin(rad)).toFloat()

            view.animate()
                .translationX(targetX)
                .translationY(targetY)
                .alpha(1f)
                .setDuration(300)
                .start()
        }
    }

    private fun collapseMenu() {
        isMenuExpanded = false

        for (view in menuItems) {
            view.animate()
                .translationX(0f)
                .translationY(0f)
                .alpha(0f)
                .setDuration(300)
                .withEndAction { view.visibility = View.GONE }
                .start()
        }
        
        // Restore window size and position after collapse animation
        overlayView.postDelayed({
            params.width = WindowManager.LayoutParams.WRAP_CONTENT
            params.height = WindowManager.LayoutParams.WRAP_CONTENT
            
            params.x = lastCollapsedX
            params.y = lastCollapsedY
            
            if (::overlayView.isInitialized) {
                windowManager.updateViewLayout(overlayView, params)
            }
        }, 300)
    }

    private fun snapToEdge() {
        val bubbleSizePx = dpToPx(bubbleSizeDp).toFloat()
        val screenWidth = resources.displayMetrics.widthPixels
        
        val currentCenterX = params.x + (bubbleSizePx / 2) 
        val middle = screenWidth / 2
        
        // Snap Logic
        val targetX = if (currentCenterX > middle) {
            screenWidth - bubbleSizePx.toInt() 
        } else {
            0
        }
        
        params.x = targetX
        lastCollapsedX = targetX 
        windowManager.updateViewLayout(overlayView, params)
    }

    private fun openMainApp() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
        stopSelf()
    }

    private fun startForegroundService() {
        val channelId = "chat_head_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Chat Overlay", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Stremini Chat")
            .setContentText("Active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
        startForeground(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::overlayView.isInitialized) windowManager.removeView(overlayView)
    }
}