package com.example.stremini_chatbot

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat

class ChatOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var bubbleView: View? = null
    private lateinit var layoutParams: WindowManager.LayoutParams

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForegroundWithNotification()
        showBubble()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (bubbleView != null) {
            windowManager.removeView(bubbleView)
            bubbleView = null
        }
    }

    private fun startForegroundWithNotification() {
        val channelId = "stremini_overlay_channel"
        val channelName = "Stremini Overlay"
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_MIN)
            nm.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Stremini Chat")
            .setContentText("Tap to return to chat")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(pendingIntent)
            .build()

        startForeground(1001, notification)
    }

    private fun showBubble() {
        if (bubbleView != null) return

        val size = (60 * resources.displayMetrics.density).toInt()
        val imageView = ImageView(this)

        val bg = GradientDrawable()
        bg.shape = GradientDrawable.OVAL
        bg.setColor(0xFF3F51B5.toInt())
        imageView.background = bg
        imageView.setImageResource(android.R.drawable.ic_dialog_email)
        imageView.setColorFilter(0xFFFFFFFF.toInt())
        imageView.scaleType = ImageView.ScaleType.CENTER

        layoutParams = WindowManager.LayoutParams(
            size,
            size,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        layoutParams.gravity = Gravity.TOP or Gravity.START
        layoutParams.x = resources.displayMetrics.widthPixels - size - 40
        layoutParams.y = (resources.displayMetrics.heightPixels * 0.6).toInt()

        imageView.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private var isClick = false

            override fun onTouch(v: View?, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        isClick = true
                        initialX = layoutParams.x
                        initialY = layoutParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        layoutParams.x = initialX + dx
                        layoutParams.y = initialY + dy
                        windowManager.updateViewLayout(imageView, layoutParams)
                        isClick = false
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (isClick) {
                            // Bring app to front and close overlay
                            val intent = Intent(this@ChatOverlayService, MainActivity::class.java)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            startActivity(intent)
                            stopSelf()
                        }
                        return true
                    }
                }
                return false
            }
        })

        bubbleView = imageView
        try {
            windowManager.addView(imageView, layoutParams)
        } catch (e: Exception) {
            // Likely missing overlay permission
            stopSelf()
        }
    }
}


