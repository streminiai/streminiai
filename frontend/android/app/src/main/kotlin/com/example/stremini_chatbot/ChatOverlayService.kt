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
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.abs

class ChatOverlayService : Service(), View.OnTouchListener {

    companion object {
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
    private var isScannerActive = false

    // Drag Logic Variables - IMPROVED
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false
    private var hasMoved = false
    private var touchStartTime = 0L

    // Configuration - INCREASED SIZES for better quality
    private val bubbleSizeDp = 70f  // Slightly smaller for smoother performance
    private val menuItemSizeDp = 56f
    private val radiusDp = 110f

    // Position storage
    private var lastCollapsedX = 0
    private var lastCollapsedY = 200

    // HTTP Client
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
        .build()
    
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val controlReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_SEND_MESSAGE -> {
                    val message = intent.getStringExtra(EXTRA_MESSAGE)
                    if (message != null) {
                        addMessageToChatbot(message, isUser = false)
                    }
                }
                ScreenReaderService.ACTION_SCAN_COMPLETE -> {
                    android.util.Log.d("ChatOverlay", "Scan complete received")
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
        
        val filter = IntentFilter().apply {
            addAction(ACTION_SEND_MESSAGE)
            addAction(ScreenReaderService.ACTION_SCAN_COMPLETE)
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
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,  // CRITICAL for smooth rendering
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = lastCollapsedX
        params.y = lastCollapsedY

        bubbleIcon.setOnTouchListener(this)
        
        // Set click listeners
        menuItems[0].setOnClickListener { handleRefresh() }
        menuItems[1].setOnClickListener { handleSettings() }
        menuItems[2].setOnClickListener { handleAIChat() }
        menuItems[3].setOnClickListener { handleScanner() }
        menuItems[4].setOnClickListener { handleVoiceCommand() }

        // IMPORTANT: Force high quality rendering
        bubbleIcon.setLayerType(View.LAYER_TYPE_HARDWARE, null)
        menuItems.forEach { it.setLayerType(View.LAYER_TYPE_HARDWARE, null) }

        updateMenuItemsColor()
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

        floatingChatView = LayoutInflater.from(this).inflate(R.layout.floating_chatbot_layout, null)
        
        val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        }

        // ROUNDED CHATBOT - adjusted dimensions
        floatingChatParams = WindowManager.LayoutParams(
            dpToPx(300f), // Width
            dpToPx(400f), // Height
            typeParam,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,  // CRITICAL
            PixelFormat.TRANSLUCENT
        )
        
        floatingChatParams?.gravity = Gravity.BOTTOM or Gravity.END
        floatingChatParams?.x = dpToPx(20f)
        floatingChatParams?.y = dpToPx(100f)

        // Force hardware acceleration for smooth rendering
        floatingChatView?.setLayerType(View.LAYER_TYPE_HARDWARE, null)

        setupFloatingChatListeners()
        
        windowManager.addView(floatingChatView, floatingChatParams)
        isChatbotVisible = true

        addMessageToChatbot("Hello! I'm Stremini AI. How can I help you?", isUser = false)
    }

    private fun setupFloatingChatListeners() {
        floatingChatView?.let { view ->
            val header = view.findViewById<LinearLayout>(R.id.chat_header)
            var chatInitialX = 0
            var chatInitialY = 0
            var chatInitialTouchX = 0f
            var chatInitialTouchY = 0f
            var chatIsDragging = false

            header?.setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        chatInitialTouchX = event.rawX
                        chatInitialTouchY = event.rawY
                        chatInitialX = floatingChatParams?.x ?: 0
                        chatInitialY = floatingChatParams?.y ?: 0
                        chatIsDragging = true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        if (chatIsDragging && floatingChatParams != null) {
                            val deltaX = (chatInitialTouchX - event.rawX).toInt()
                            val deltaY = (chatInitialTouchY - event.rawY).toInt()
                            
                            floatingChatParams?.x = chatInitialX + deltaX
                            floatingChatParams?.y = chatInitialY + deltaY
                            
                            windowManager.updateViewLayout(floatingChatView!!, floatingChatParams!!)
                        }
                    }
                    MotionEvent.ACTION_UP -> {
                        chatIsDragging = false
                    }
                }
                true
            }
            
            view.findViewById<ImageView>(R.id.btn_close_chat)?.setOnClickListener {
                hideFloatingChatbot()
                toggleFeature(menuItems[2].id)
            }

            view.findViewById<ImageView>(R.id.btn_send_message)?.setOnClickListener {
                val input = view.findViewById<EditText>(R.id.et_chat_input)
                val message = input?.text?.toString()?.trim()
                
                if (!message.isNullOrEmpty()) {
                    addMessageToChatbot(message, isUser = true)
                    input.text?.clear()
                    sendMessageToAPI(message)
                }
            }

            view.findViewById<ImageView>(R.id.btn_voice_input)?.setOnClickListener {
                // TODO: Implement voice input
            }
        }
    }

    private fun sendMessageToAPI(userMessage: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("message", userMessage)
                }

                val requestBody = requestJson.toString()
                    .toRequestBody("application/json".toMediaType())

                val request = Request.Builder()
                    .url("https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/chat/message")
                    .post(requestBody)
                    .build()

                val response = client.newCall(request).execute()

                if (response.isSuccessful) {
                    val responseBody = response.body?.string() ?: ""
                    val json = JSONObject(responseBody)
                    
                    val reply = json.optString("reply", 
                        json.optString("response",
                        json.optString("message", "No response from AI")))

                    withContext(Dispatchers.Main) {
                        addMessageToChatbot(reply, isUser = false)
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        addMessageToChatbot("❌ Server error: ${response.code}", isUser = false)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    addMessageToChatbot("⚠️ Network error: ${e.message}", isUser = false)
                }
            }
        }
    }

    private fun addMessageToChatbot(message: String, isUser: Boolean) {
        floatingChatView?.let { view ->
            val messagesContainer = view.findViewById<LinearLayout>(R.id.messages_container)
            
            val messageView = LayoutInflater.from(this).inflate(
                if (isUser) R.layout.message_bubble_user else R.layout.message_bubble_bot,
                messagesContainer,
                false
            )
            
            messageView.findViewById<TextView>(R.id.tv_message)?.text = message
            messagesContainer?.addView(messageView)
            
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
        if (!ScreenReaderService.isRunning(this)) {
            android.widget.Toast.makeText(
                this,
                "Please enable 'Stremini Screen Scanner' in Accessibility Settings",
                android.widget.Toast.LENGTH_LONG
            ).show()
            
            val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return
        }
        
        toggleFeature(menuItems[3].id)
        isScannerActive = !isScannerActive
        
        if (isScannerActive) {
            val intent = Intent(this, ScreenReaderService::class.java)
            intent.action = ScreenReaderService.ACTION_START_SCAN
            startService(intent)
        } else {
            val intent = Intent(this, ScreenReaderService::class.java)
            intent.action = ScreenReaderService.ACTION_STOP_SCAN
            startService(intent)
        }
    }

    private fun handleVoiceCommand() {
        android.widget.Toast.makeText(this, "Voice command coming soon", android.widget.Toast.LENGTH_SHORT).show()
    }

    private fun handleSettings() {
        openMainApp()
    }

    private fun handleRefresh() {
        activeFeatures.clear()
        isScannerActive = false
        updateMenuItemsColor()
        
        hideFloatingChatbot()
        
        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = ScreenReaderService.ACTION_STOP_SCAN
        startService(intent)
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
        val neonBlue = android.graphics.Color.parseColor("#00D9FF")
        val white = android.graphics.Color.parseColor("#FFFFFF")
        
        menuItems.forEach { item ->
            if (activeFeatures.contains(item.id) || 
                (item.id == menuItems[3].id && isScannerActive)) {
                item.setColorFilter(neonBlue)
            } else {
                item.setColorFilter(white)
            }
        }
    }

    // IMPROVED TOUCH HANDLING - Much smoother
    override fun onTouch(v: View, event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params.x
                initialY = params.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                isDragging = false
                hasMoved = false
                touchStartTime = System.currentTimeMillis()
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = (event.rawX - initialTouchX).toInt()
                val dy = (event.rawY - initialTouchY).toInt()

                // Only consider it moved if distance > 15px (prevents accidental drags)
                if (abs(dx) > 15 || abs(dy) > 15) {
                    hasMoved = true
                    isDragging = true
                    if (isMenuExpanded) collapseMenu()
                }
                
                if (isDragging && !isMenuExpanded) {
                    params.x = initialX + dx
                    params.y = initialY + dy
                    lastCollapsedX = params.x
                    lastCollapsedY = params.y
                    
                    // SMOOTH UPDATE - throttle updates for better performance
                    windowManager.updateViewLayout(overlayView, params)
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                val touchDuration = System.currentTimeMillis() - touchStartTime
                
                // If it's a quick tap (< 200ms) and not moved much, treat as click
                if (!hasMoved && touchDuration < 200) {
                    toggleMenu()
                } else if (isDragging) {
                    snapToEdge()
                }
                isDragging = false
                hasMoved = false
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

            // SMOOTH ANIMATION with proper interpolator
            view.animate()
                .translationX(targetX)
                .translationY(targetY)
                .alpha(1f)
                .setDuration(250)  // Slightly longer for smoothness
                .setInterpolator(android.view.animation.DecelerateInterpolator())
                .start()
        }
        
        updateMenuItemsColor()
    }

    private fun collapseMenu() {
        isMenuExpanded = false

        for (view in menuItems) {
            view.animate()
                .translationX(0f)
                .translationY(0f)
                .alpha(0f)
                .setDuration(200)
                .setInterpolator(android.view.animation.AccelerateInterpolator())
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
        }, 200)
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
        
        // SMOOTH SNAP with animation
        val startX = params.x
        android.animation.ValueAnimator.ofInt(startX, targetX).apply {
            duration = 150
            interpolator = android.view.animation.DecelerateInterpolator()
            addUpdateListener { animator ->
                params.x = animator.animatedValue as Int
                lastCollapsedX = params.x
                windowManager.updateViewLayout(overlayView, params)
            }
            start()
        }
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
            val channel = NotificationChannel(channelId, "Stremini Overlay", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Stremini AI")
            .setContentText("Active - Tap to open")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
        startForeground(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        unregisterReceiver(controlReceiver)
        hideFloatingChatbot()
        
        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = ScreenReaderService.ACTION_STOP_SCAN
        startService(intent)
        
        if (::overlayView.isInitialized) windowManager.removeView(overlayView)
    }
}
