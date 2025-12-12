package com.example.stremini_chatbot

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
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
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

class ChatOverlayService : Service(), View.OnTouchListener {

    companion object {
        const val ACTION_SEND_MESSAGE = "com.example.stremini_chatbot.SEND_MESSAGE"
        const val EXTRA_MESSAGE = "message"
        val NEON_BLUE: Int = android.graphics.Color.parseColor("#00D9FF")
        val WHITE: Int = android.graphics.Color.parseColor("#FFFFFF")
        private const val TAG = "ChatOverlayService"
    }

    private lateinit var windowManager: WindowManager
    private var overlayContainer: FrameLayout? = null
    private var containerParams: WindowManager.LayoutParams? = null

    // Floating Chatbot Window
    private var floatingChatView: View? = null
    private var floatingChatParams: WindowManager.LayoutParams? = null
    private var isChatbotVisible = false

    private var bubbleIcon: ImageView? = null
    private val menuItems = mutableListOf<ImageView>()
    private var isMenuExpanded = false
    private var isAnimating = false

    // Track active features
    private val activeFeatures = mutableSetOf<Int>()
    private var isScannerActive = false
    private var isKeyboardActive = false

    // Drag Logic Variables
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false
    private var hasMoved = false

    // Configuration - Match reference image sizes
    private val bubbleSizeDp = 60f  // Main bubble
    private val menuIconSizeDp = 50f  // Menu icons
    private val radiusDp = 90f  // Distance from center

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
                    Log.d(TAG, "Scan complete received")
                }
                "com.example.stremini_chatbot.KEYBOARD_STATE_CHANGED" -> {
                    val isActive = intent.getBooleanExtra("isActive", false)
                    isKeyboardActive = isActive
                    updateMenuItemsColor()
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
        Log.d(TAG, "Service onCreate")
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForegroundService()
        setupOverlay()

        val filter = IntentFilter().apply {
            addAction(ACTION_SEND_MESSAGE)
            addAction(ScreenReaderService.ACTION_SCAN_COMPLETE)
            addAction("com.example.stremini_chatbot.KEYBOARD_STATE_CHANGED")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(controlReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(controlReceiver, filter)
        }
    }

    private fun setupOverlay() {
        try {
            // Create a container to hold both bubble and menu items
            overlayContainer = FrameLayout(this)
            
            // Inflate bubble
            val bubbleView = LayoutInflater.from(this).inflate(R.layout.chat_bubble_layout, null)
            bubbleIcon = bubbleView.findViewById(R.id.bubble_icon)

            // Get menu item views
            val btnRefresh = bubbleView.findViewById<ImageView>(R.id.btn_refresh)
            val btnSettings = bubbleView.findViewById<ImageView>(R.id.btn_settings)
            val btnAi = bubbleView.findViewById<ImageView>(R.id.btn_ai)
            val btnScanner = bubbleView.findViewById<ImageView>(R.id.btn_scanner)
            val btnKeyboard = bubbleView.findViewById<ImageView>(R.id.btn_keyboard)

            // Add to list
            menuItems.clear()
            btnRefresh?.let { menuItems.add(it) }
            btnSettings?.let { menuItems.add(it) }
            btnAi?.let { menuItems.add(it) }
            btnScanner?.let { menuItems.add(it) }
            btnKeyboard?.let { menuItems.add(it) }

            // Add bubble to container
            overlayContainer?.addView(bubbleView)

            val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            // Create large container to hold expanded menu
            val containerSize = dpToPx(250f)  // Large enough for menu
            containerParams = WindowManager.LayoutParams(
                containerSize,
                containerSize,
                typeParam,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            )
            containerParams?.gravity = Gravity.TOP or Gravity.START
            containerParams?.x = lastCollapsedX
            containerParams?.y = lastCollapsedY

            bubbleIcon?.setOnTouchListener(this)

            // Set click listeners
            if (menuItems.size >= 5) {
                menuItems[0].setOnClickListener { 
                    if (!isAnimating) { 
                        collapseMenu()
                        postDelayed({ handleRefresh() }, 250)
                    } 
                }
                menuItems[1].setOnClickListener { 
                    if (!isAnimating) { 
                        collapseMenu()
                        postDelayed({ handleSettings() }, 250)
                    } 
                }
                menuItems[2].setOnClickListener { 
                    if (!isAnimating) { 
                        collapseMenu()
                        postDelayed({ handleAIChat() }, 250)
                    } 
                }
                menuItems[3].setOnClickListener { 
                    if (!isAnimating) { 
                        collapseMenu()
                        postDelayed({ handleScanner() }, 250)
                    } 
                }
                menuItems[4].setOnClickListener { 
                    if (!isAnimating) { 
                        collapseMenu()
                        postDelayed({ handleKeyboard() }, 250)
                    } 
                }
            }

            // Configure rendering
            overlayContainer?.setLayerType(View.LAYER_TYPE_HARDWARE, null)
            bubbleIcon?.apply {
                setLayerType(View.LAYER_TYPE_HARDWARE, null)
                scaleType = ImageView.ScaleType.FIT_CENTER
            }
            
            // Initially hide and position menu items at center
            menuItems.forEach { item ->
                item.setLayerType(View.LAYER_TYPE_HARDWARE, null)
                item.scaleType = ImageView.ScaleType.FIT_CENTER
                item.visibility = View.INVISIBLE  // Use INVISIBLE not GONE
                item.alpha = 0f
                // Position at center initially
                item.translationX = 0f
                item.translationY = 0f
            }

            updateMenuItemsColor()
            
            overlayContainer?.let { container ->
                containerParams?.let { params ->
                    windowManager.addView(container, params)
                    Log.d(TAG, "Overlay container added with ${menuItems.size} menu items")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in setupOverlay", e)
        }
    }

    private fun postDelayed(action: () -> Unit, delayMillis: Long) {
        overlayContainer?.postDelayed(action, delayMillis)
    }

    private fun handleAIChat() {
        val chatIconId = menuItems.getOrNull(2)?.id ?: return
        toggleFeature(chatIconId)

        if (isFeatureActive(chatIconId)) {
            showFloatingChatbot()
        } else {
            hideFloatingChatbot()
        }
    }

    private fun showFloatingChatbot() {
        if (isChatbotVisible) return

        try {
            floatingChatView = LayoutInflater.from(this).inflate(R.layout.floating_chatbot_layout, null)

            val typeParam = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
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

            floatingChatView?.let { view ->
                floatingChatParams?.let { params ->
                    windowManager.addView(view, params)
                }
            }
            isChatbotVisible = true

            addMessageToChatbot("Hello! I'm Stremini AI. How can I help you?", isUser = false)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing chatbot", e)
        }
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
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        if (chatIsDragging && floatingChatParams != null) {
                            val deltaX = (event.rawX - chatInitialTouchX).toInt()
                            val deltaY = (event.rawY - chatInitialTouchY).toInt()

                            floatingChatParams?.x = chatInitialX - deltaX
                            floatingChatParams?.y = chatInitialY - deltaY

                            floatingChatView?.let { v ->
                                floatingChatParams?.let { p ->
                                    windowManager.updateViewLayout(v, p)
                                }
                            }
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        chatIsDragging = false
                        true
                    }
                    else -> false
                }
            }

            view.findViewById<ImageView>(R.id.btn_close_chat)?.setOnClickListener {
                hideFloatingChatbot()
                menuItems.getOrNull(2)?.id?.let { toggleFeature(it) }
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
                Toast.makeText(this, "Voice input coming soon", Toast.LENGTH_SHORT).show()
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

        try {
            floatingChatView?.let { view ->
                windowManager.removeView(view)
                floatingChatView = null
                floatingChatParams = null
                isChatbotVisible = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding chatbot", e)
        }
    }

    private fun handleScanner() {
        if (!ScreenReaderService.isRunning(this)) {
            Toast.makeText(
                this,
                "Please enable 'Stremini Screen Scanner' in Accessibility Settings",
                Toast.LENGTH_LONG
            ).show()

            val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return
        }

        val scannerIconId = menuItems.getOrNull(3)?.id ?: return
        toggleFeature(scannerIconId)
        isScannerActive = !isScannerActive

        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = if (isScannerActive) {
            ScreenReaderService.ACTION_START_SCAN
        } else {
            ScreenReaderService.ACTION_STOP_SCAN
        }
        startService(intent)
        
        Toast.makeText(
            this, 
            if (isScannerActive) "Scanner ON" else "Scanner OFF", 
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun handleKeyboard() {
        val keyboardIconId = menuItems.getOrNull(4)?.id ?: return
        toggleFeature(keyboardIconId)

        if (isFeatureActive(keyboardIconId)) {
            // Keyboard activated - show electric neon blue
            showKeyboardActivation()
        } else {
            // Keyboard deactivated
            isKeyboardActive = false
            Toast.makeText(this, "AI Keyboard deactivated", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showKeyboardActivation() {
        // Check if keyboard is enabled
        if (!isKeyboardEnabled()) {
            // Prompt user to enable keyboard
            val intent = Intent(android.provider.Settings.ACTION_INPUT_METHOD_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            
            Toast.makeText(
                this,
                "Please enable 'Stremini AI Keyboard' in the list",
                Toast.LENGTH_LONG
            ).show()
            return
        }

        // Check if keyboard is selected
        if (!isKeyboardSelected()) {
            // Show keyboard picker
            showKeyboardPicker()
        } else {
            isKeyboardActive = true
            Toast.makeText(this, "Stremini AI Keyboard is active", Toast.LENGTH_SHORT).show()
        }
    }

    private fun isKeyboardEnabled(): Boolean {
        val imeManager = getSystemService(INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
        val enabledInputMethods = imeManager.enabledInputMethodList
        val packageName = packageName
        
        return enabledInputMethods.any { it.packageName == packageName }
    }

    private fun isKeyboardSelected(): Boolean {
        val currentInputMethod = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.DEFAULT_INPUT_METHOD
        )
        
        return currentInputMethod?.contains(packageName) == true
    }

    private fun showKeyboardPicker() {
        try {
            val imeManager = getSystemService(INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
            imeManager.showInputMethodPicker()
            
            Toast.makeText(
                this,
                "Select 'Stremini AI Keyboard' from the list",
                Toast.LENGTH_LONG
            ).show()
        } catch (e: Exception) {
            Log.e(TAG, "Error showing keyboard picker", e)
        }
    }

    private fun handleSettings() {
        // Open keyboard settings activity
        val intent = Intent(this, KeyboardSettingsActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun handleRefresh() {
        activeFeatures.clear()
        isScannerActive = false
        isKeyboardActive = false
        updateMenuItemsColor()

        hideFloatingChatbot()

        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = ScreenReaderService.ACTION_STOP_SCAN
        startService(intent)
        
        Toast.makeText(this, "All features cleared", Toast.LENGTH_SHORT).show()
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
        val scannerIconId = menuItems.getOrNull(3)?.id
        val keyboardIconId = menuItems.getOrNull(4)?.id
        
        menuItems.forEach { item ->
            if (activeFeatures.contains(item.id) ||
                (item.id == scannerIconId && isScannerActive) ||
                (item.id == keyboardIconId && isKeyboardActive)) {
                item.setColorFilter(NEON_BLUE)
            } else {
                item.setColorFilter(WHITE)
            }
        }
    }

    override fun onTouch(v: View, event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                containerParams?.let { p ->
                    initialX = p.x
                    initialY = p.y
                }
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                isDragging = false
                hasMoved = false
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = (event.rawX - initialTouchX).toInt()
                val dy = (event.rawY - initialTouchY).toInt()

                if (abs(dx) > 15 || abs(dy) > 15) {
                    hasMoved = true
                    if (!isMenuExpanded && !isAnimating) {
                        isDragging = true
                        containerParams?.x = initialX + dx
                        containerParams?.y = initialY + dy
                        overlayContainer?.let { container ->
                            containerParams?.let { p ->
                                windowManager.updateViewLayout(container, p)
                            }
                        }
                    } else if (isMenuExpanded && !isAnimating) {
                        collapseMenu()
                    }
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                if (!hasMoved && !isDragging && !isAnimating) {
                    toggleMenu()
                } else if (isDragging && !isAnimating) {
                    containerParams?.let { p ->
                        lastCollapsedX = p.x
                        lastCollapsedY = p.y
                    }
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
        if (isAnimating) return
        Log.d(TAG, "Toggle menu - expanded: $isMenuExpanded")
        if (isMenuExpanded) collapseMenu() else expandMenu()
    }

    private fun expandMenu() {
        if (isAnimating) return
        isAnimating = true
        isMenuExpanded = true
        Log.d(TAG, "Expanding menu with ${menuItems.size} items")

        val radiusPx = dpToPx(radiusDp)
        val containerSize = dpToPx(250f)
        val centerOffset = containerSize / 2

        val screenWidth = resources.displayMetrics.widthPixels
        val currentX = containerParams?.x ?: 0
        val bubbleCenterX = currentX + centerOffset
        val isOnRightSide = bubbleCenterX > (screenWidth / 2)

        // Calculate angles for menu placement
        val startAngle = if (isOnRightSide) 90.0 else -90.0
        val endAngle = if (isOnRightSide) 270.0 else 90.0
        val angleRange = endAngle - startAngle
        val step = angleRange / (menuItems.size - 1)

        val animatorSet = AnimatorSet()
        val animators = mutableListOf<Animator>()

        for ((index, item) in menuItems.withIndex()) {
            item.visibility = View.VISIBLE
            item.alpha = 0f
            item.scaleX = 0.3f
            item.scaleY = 0.3f

            val angle = startAngle + (index * step)
            val rad = Math.toRadians(angle)

            val targetX = (radiusPx * cos(rad)).toFloat()
            val targetY = (radiusPx * -sin(rad)).toFloat()

            Log.d(TAG, "Item $index - angle: $angle, targetX: $targetX, targetY: $targetY")

            val animX = ObjectAnimator.ofFloat(item, "translationX", 0f, targetX)
            val animY = ObjectAnimator.ofFloat(item, "translationY", 0f, targetY)
            val animAlpha = ObjectAnimator.ofFloat(item, "alpha", 0f, 1f)
            val animScaleX = ObjectAnimator.ofFloat(item, "scaleX", 0.3f, 1f)
            val animScaleY = ObjectAnimator.ofFloat(item, "scaleY", 0.3f, 1f)

            animators.addAll(listOf(animX, animY, animAlpha, animScaleX, animScaleY))
        }

        animatorSet.playTogether(animators as Collection<Animator>)
        animatorSet.duration = 300
        animatorSet.interpolator = OvershootInterpolator(1.5f)
        animatorSet.start()

        overlayContainer?.postDelayed({
            isAnimating = false
            Log.d(TAG, "Menu expansion complete")
        }, 300)

        updateMenuItemsColor()
    }

    private fun collapseMenu() {
        if (isAnimating) return
        isAnimating = true
        isMenuExpanded = false
        Log.d(TAG, "Collapsing menu")

        val animatorSet = AnimatorSet()
        val animators = mutableListOf<Animator>()

        for (item in menuItems) {
            val animX = ObjectAnimator.ofFloat(item, "translationX", item.translationX, 0f)
            val animY = ObjectAnimator.ofFloat(item, "translationY", item.translationY, 0f)
            val animAlpha = ObjectAnimator.ofFloat(item, "alpha", item.alpha, 0f)
            val animScaleX = ObjectAnimator.ofFloat(item, "scaleX", item.scaleX, 0.3f)
            val animScaleY = ObjectAnimator.ofFloat(item, "scaleY", item.scaleY, 0.3f)

            animators.addAll(listOf(animX, animY, animAlpha, animScaleX, animScaleY))
        }

        animatorSet.playTogether(animators as Collection<Animator>)
        animatorSet.duration = 200
        animatorSet.interpolator = AccelerateDecelerateInterpolator()
        animatorSet.start()

        overlayContainer?.postDelayed({
            menuItems.forEach { it.visibility = View.INVISIBLE }
            isAnimating = false
            Log.d(TAG, "Menu collapse complete")
        }, 200)
    }

    private fun snapToEdge() {
        val screenWidth = resources.displayMetrics.widthPixels
        val containerSize = dpToPx(250f)
        val currentX = containerParams?.x ?: 0
        val currentCenterX = currentX + (containerSize / 2)
        val middle = screenWidth / 2

        val targetX = if (currentCenterX > middle) {
            screenWidth - containerSize
        } else {
            0
        }

        ValueAnimator.ofInt(currentX, targetX).apply {
            duration = 250
            interpolator = DecelerateInterpolator()
            addUpdateListener { animator ->
                containerParams?.x = animator.animatedValue as Int
                lastCollapsedX = containerParams?.x ?: 0
                overlayContainer?.let { container ->
                    containerParams?.let { p ->
                        windowManager.updateViewLayout(container, p)
                    }
                }
            }
            start()
        }
    }

    private fun startForegroundService() {
        val channelId = "chat_head_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, 
                "Stremini Overlay", 
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Stremini AI")
            .setContentText("Floating bubble active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
        startForeground(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        
        try {
            unregisterReceiver(controlReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        
        hideFloatingChatbot()

        val intent = Intent(this, ScreenReaderService::class.java)
        intent.action = ScreenReaderService.ACTION_STOP_SCAN
        startService(intent)

        try {
            overlayContainer?.let { container ->
                if (container.windowToken != null) {
                    windowManager.removeView(container)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay container", e)
        }
    }
}
