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

class ChatOverlayService : Service(), View.OnTouchListener {

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private lateinit var params: WindowManager.LayoutParams

    private lateinit var bubbleIcon: ImageView
    private lateinit var menuItems: List<ImageView>
    private var isMenuExpanded = false

    // Track active features
    private val activeFeatures = mutableSetOf<Int>()

    // Drag Logic Variables
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false

    // Configuration
    private val bubbleSizeDp = 78f
    private val menuItemSizeDp = 60f
    private val radiusDp = 110f

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
        
        // Get references to menu items
        menuItems = listOf(
            overlayView.findViewById(R.id.btn_refresh),
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
        
        // Set click listeners for menu items
        menuItems[2].setOnClickListener { handleAIChat() }       // AI Chat
        menuItems[4].setOnClickListener { handleScreenScanner() } // Scanner
        menuItems[3].setOnClickListener { handleVoiceCommand() }  // Voice
        menuItems[1].setOnClickListener { handleSettings() }      // Settings
        menuItems[0].setOnClickListener { handleRefresh() }       // Refresh

        windowManager.addView(overlayView, params)
    }

    private fun handleAIChat() {
        toggleFeature(menuItems[2].id)
        
        if (isFeatureActive(menuItems[2].id)) {
            // Open floating mini chatbot
            val intent = Intent("com.example.stremini_chatbot.OPEN_FLOATING_CHAT")
            sendBroadcast(intent)
        } else {
            // Close floating chatbot
            val intent = Intent("com.example.stremini_chatbot.CLOSE_FLOATING_CHAT")
            sendBroadcast(intent)
        }
    }

    private fun handleScreenScanner() {
        toggleFeature(menuItems[4].id)
        
        if (isFeatureActive(menuItems[4].id)) {
            // Start scanning
            val intent = Intent(this, ScreenScannerService::class.java)
            intent.action = ScreenScannerService.ACTION_START_SCAN
            startService(intent)
        } else {
            // Stop scanning
            val intent = Intent(this, ScreenScannerService::class.java)
            intent.action = ScreenScannerService.ACTION_STOP_SCAN
            startService(intent)
        }
    }

    private fun handleVoiceCommand() {
        // TODO: Implement voice command
    }

    private fun handleSettings() {
        openMainApp()
    }

    private fun handleRefresh() {
        // Deactivate all features
        activeFeatures.clear()
        updateMenuItemsColor()
    }

    private fun toggleFeature(featureId: Int) {
        if (activeFeatures.contains(featureId)) {
            activeFeatures.remove(featureId)
        } else {
            activeFeatures.add(featureId)
        }
        updateMenuItemsColor()
    }

    private fun isFeatureActive(featureId: Int): Boolean {
        return activeFeatures.contains(featureId)
    }

    private fun updateMenuItemsColor() {
        menuItems.forEach { item ->
            if (activeFeatures.contains(item.id)) {
                // Feature is active - make it blue
                item.setColorFilter(android.graphics.Color.parseColor("#00D9FF"))
            } else {
                // Feature is inactive - default color
                when(item.id) {
                    R.id.btn_ai -> item.setColorFilter(android.graphics.Color.parseColor("#23A6E2"))
                    R.id.btn_security -> item.setColorFilter(android.graphics.Color.parseColor("#AA75F4"))
                    R.id.btn_keyboard -> item.setColorFilter(android.graphics.Color.parseColor("#0066FF"))
                    else -> item.setColorFilter(android.graphics.Color.parseColor("#23A6E2"))
                }
            }
        }
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

        val expandedWindowSizePx = (radiusPx * 2) + bubbleSizePx + menuItemSizePx
        val offsetPx = (expandedWindowSizePx / 2) - (bubbleSizePx / 2)

        val currentX = params.x
        val currentY = params.y

        params.width = expandedWindowSizePx.toInt()
        params.height = expandedWindowSizePx.toInt()
        
        params.x = currentX - offsetPx.toInt()
        params.y = currentY - offsetPx.toInt()
        
        windowManager.updateViewLayout(overlayView, params)

        val screenWidth = resources.displayMetrics.widthPixels
        val bubbleCenterX = lastCollapsedX + (bubbleSizePx / 2)
        val isOnRightSide = bubbleCenterX > (screenWidth / 2)
        
        val startAngle = if (isOnRightSide) 90.0 else 90.0
        val endAngle = if (isOnRightSide) 270.0 else -90.0

        val step = (endAngle - startAngle) / (menuItems.size - 1)

        for ((index, view) in menuItems.withIndex()) {
            view.visibility = View.VISIBLE
            view.alpha = 0f
            
            val angle = startAngle + (index * step)
            val rad = Math.toRadians(angle)
            
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
