package com.example.stremini_chatbot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.EditText
import android.widget.TextView
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.core.app.NotificationCompat
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.abs

class ChatOverlayService : Service(), View.OnTouchListener {

    companion object {
        const val ACTION_OPEN_FLOATING_CHAT = "com.example.stremini_chatbot.OPEN_FLOATING_CHAT"
        const val ACTION_CLOSE_FLOATING_CHAT = "com.example.stremini_chatbot.CLOSE_FLOATING_CHAT"
        const val ACTION_OPEN_SCANNER = "com.example.stremini_chatbot.OPEN_SCANNER"
        const val ACTION_CLOSE_SCANNER = "com.example.stremini_chatbot.CLOSE_SCANNER"
        const val ACTION_SEND_MESSAGE = "com.example.stremini_chatbot.SEND_MESSAGE"
        const val EXTRA_MESSAGE = "message"
    }

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private lateinit var params: WindowManager.LayoutParams

    // Floating Chatbot Window
    private var floatingChatView: View? = null
    private var floatingChatParams: WindowManager.LayoutParams? = null
    private var isChatbotVisible = false

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

    // Broadcast receiver for floating chat and scanner controls
    private val controlReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_OPEN_FLOATING_CHAT -> {
                    showFloatingChatbot()
                }
                ACTION_CLOSE_FLOATING_CHAT -> {
                    hideFloatingChatbot()
                }
                ACTION_SEND_MESSAGE -> {
                    val message = intent.getStringExtra(EXTRA_MESSAGE)
                    if (message != null) {
                        addMessageToChatbot(message, isUser = false)
                    }
                }
                ACTION_OPEN_SCANNER -> {
                    // Notify Flutter to show scanner
                }
                ACTION_CLOSE_SCANNER -> {
                    // Notify Flutter to hide scanner
                }
            }
        }
    }

    private fun dpToPx(dp: Float): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForegroundService()
        setupOverlay()
        
        // Register broadcast receiver
        val filter = IntentFilter().apply {
            addAction(ACTION_OPEN_FLOATING_CHAT)
            addAction(ACTION_CLOSE_FLOATING_CHAT)
            addAction(ACTION_OPEN_SCANNER)
            addAction(ACTION_CLOSE_SCANNER)
            addAction(ACTION_SEND_MESSAGE)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(controlReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(controlReceiver, filter)
        }
    }

    private fun setupOverlay() {
        overlayView = LayoutInflater.from(this).inflate(R.layout.chat_bubble_layout, null)
        bubbleIcon = overlayView.findViewById(R.id.bubble_icon)
        
        // Get references to menu items (including new scanner button)
        menuItems = listOf(
            overlayView.findViewById(R.id.btn_refresh),
            overlayView.findViewById(R.id.btn_settings),
            overlayView.findViewById(R.id.btn_ai),
            overlayView.findViewById(R.id.btn_scanner),
            overlayView.findViewById(R.id.btn_keyboard)
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
        menuItems[3].setOnClickListener { handleScanner() }      // Scanner
        menuItems[4].setOnClickListener { handleVoiceCommand() } // Voice
        menuItems[1].setOnClickListener { handleSettings() }     // Settings
        menuItems[0].setOnClickListener { handleRefresh() }      // Refresh

        windowManager.addView(overlayView, params)
    }

    private fun handleAIChat() {
        toggleFeature(menuItems[2].id)
        
        if (isFeatureActive(menuItems[2].id)) {
            showFloatingChatbot()
        } else {
            hideFloatingChatbot()
        }
    }

    private fun showFloatingChatbot() {
        if (isChatbotVisible) return

        // Create floating chatbot layout
        floatingChatView = LayoutInflater.from(this).inflate(R.layout.floating_chatbot_layout, null)
        
        val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        }

        floatingChatParams = WindowManager.LayoutParams(
            dpToPx(320f),
            dpToPx(480f),
            typeParam,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        )
        
        floatingChatParams?.gravity = Gravity.BOTTOM or Gravity.END
        floatingChatParams?.x = dpToPx(20f)
        floatingChatParams?.y = dpToPx(100f)

        setupFloatingChatListeners()
        
        windowManager.addView(floatingChatView, floatingChatParams)
        isChatbotVisible = true

        // Add welcome message
        addMessageToChatbot("Hello! I'm Stremini AI. How can I help you?", isUser = false)
    }

    private fun setupFloatingChatListeners() {
        floatingChatView?.let { view ->
            // Close button
            view.findViewById<ImageView>(R.id.btn_close_chat)?.setOnClickListener {
                hideFloatingChatbot()
            }

            // Send button
            view.findViewById<ImageView>(R.id.btn_send_message)?.setOnClickListener {
                val input = view.findViewById<EditText>(R.id.et_chat_input)
                val message = input?.text?.toString()?.trim()
                
                if (!message.isNullOrEmpty()) {
                    addMessageToChatbot(message, isUser = true)
                    input.text?.clear()
                    
                    // Send message to Flutter for API call
                    val intent = Intent("com.example.stremini_chatbot.FLUTTER_MESSAGE")
                    intent.putExtra("message", message)
                    sendBroadcast(intent)
                }
            }

            // Voice button
            view.findViewById<ImageView>(R.id.btn_voice_input)?.setOnClickListener {
                // TODO: Implement voice input
            }

            // Minimize button
            view.findViewById<ImageView>(R.id.btn_minimize_chat)?.setOnClickListener {
                hideFloatingChatbot()
            }
        }
    }

    private fun addMessageToChatbot(message: String, isUser: Boolean) {
        floatingChatView?.let { view ->
            val messagesContainer = view.findViewById<LinearLayout>(R.id.messages_container)
            
            // Create message view
            val messageView = LayoutInflater.from(this).inflate(
                if (isUser) R.layout.message_bubble_user else R.layout.message_bubble_bot,
                messagesContainer,
                false
            )
            
            messageView.findViewById<TextView>(R.id.tv_message)?.text = message
            messagesContainer?.addView(messageView)
            
            // Scroll to bottom
            view.findViewById<ScrollView>(R.id.scroll_messages)?.post {
                view.findViewById<ScrollView>(R.id.scroll_messages)?.fullScroll(View.FOCUS_DOWN)
            }
        }
    }

    private fun hideFloatingChatbot() {
        if (!isChatbotVisible) return
        
        floatingChatView?.let { view ->
            windowManager.removeView(view)
            floatingChatView = null
            floatingChatParams = null
            isChatbotVisible = false
        }
    }

    private fun handleScanner() {
        toggleFeature(menuItems[3].id)
        
        if (isFeatureActive(menuItems[3].id)) {
            val intent = Intent(ACTION_OPEN_SCANNER)
            sendBroadcast(intent)
        } else {
            val intent = Intent(ACTION_CLOSE_SCANNER)
            sendBroadcast(intent)
        }
    }

    private fun handleVoiceCommand() {
        // TODO: Implement voice command
    }

    private fun handleSettings() {
        openMainApp()
    }

    private fun handleRefresh() {
        activeFeatures.clear()
        updateMenuItemsColor()
        hideFloatingChatbot()
        
        val chatIntent = Intent(ACTION_CLOSE_FLOATING_CHAT)
        sendBroadcast(chatIntent)
        
        val scannerIntent = Intent(ACTION_CLOSE_SCANNER)
        sendBroadcast(scannerIntent)
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
                item.setColorFilter(android.graphics.Color.parseColor("#00D9FF"))
            } else {
                when(item.id) {
                    R.id.btn_ai -> item.setColorFilter(android.graphics.Color.parseColor("#23A6E2"))
                    R.id.btn_scanner -> item.setColorFilter(android.graphics.Color.parseColor("#E040FB"))
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
        unregisterReceiver(controlReceiver)
        hideFloatingChatbot()
        if (::overlayView.isInitialized) windowManager.removeView(overlayView)
    }
}
