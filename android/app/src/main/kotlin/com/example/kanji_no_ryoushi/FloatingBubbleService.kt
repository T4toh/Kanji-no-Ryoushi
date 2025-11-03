package com.example.kanji_no_ryoushi

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.*
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * Servicio que muestra un ícono flotante persistente (bubble) sobre otras apps
 * Similar a los "chat heads" de Facebook Messenger
 */
class FloatingBubbleService : Service() {
    
    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    
    private var isDragging = false
    private val DRAG_THRESHOLD = 10 // pixels
    
    companion object {
        const val NOTIFICATION_ID = 1002
        const val CHANNEL_ID = "floating_bubble_channel"
        const val ACTION_START_BUBBLE = "com.example.kanji_no_ryoushi.START_BUBBLE"
        const val ACTION_STOP_BUBBLE = "com.example.kanji_no_ryoushi.STOP_BUBBLE"
        
        var isRunning = false
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_BUBBLE -> {
                if (!isRunning) {
                    startForeground(NOTIFICATION_ID, createNotification())
                    showBubble()
                    isRunning = true
                }
            }
            ACTION_STOP_BUBBLE -> {
                stopBubble()
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Overlay Flotante",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Botón flotante de captura siempre visible"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(this, FloatingBubbleService::class.java).apply {
            action = ACTION_STOP_BUBBLE
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Captura Rápida Activa")
            .setContentText("Toca el ícono flotante para capturar")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Cerrar",
                stopPendingIntent
            )
            .build()
    }
    
    private fun showBubble() {
        // Configurar parámetros del bubble
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }
        
        // Crear vista del bubble (ícono circular)
        bubbleView = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_camera)
            setBackgroundResource(android.R.drawable.btn_default)
            setPadding(20, 20, 20, 20)
            alpha = 0.8f
            
            // Configurar listeners para drag y click
            setOnTouchListener(object : View.OnTouchListener {
                private var lastAction = MotionEvent.ACTION_UP
                
                override fun onTouch(v: View, event: MotionEvent): Boolean {
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = layoutParams.x
                            initialY = layoutParams.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            lastAction = MotionEvent.ACTION_DOWN
                            isDragging = false
                            alpha = 1.0f
                            return true
                        }
                        
                        MotionEvent.ACTION_MOVE -> {
                            val deltaX = event.rawX - initialTouchX
                            val deltaY = event.rawY - initialTouchY
                            
                            // Determinar si es drag o click
                            if (!isDragging && (abs(deltaX) > DRAG_THRESHOLD || abs(deltaY) > DRAG_THRESHOLD)) {
                                isDragging = true
                            }
                            
                            if (isDragging) {
                                layoutParams.x = initialX + deltaX.toInt()
                                layoutParams.y = initialY + deltaY.toInt()
                                windowManager?.updateViewLayout(bubbleView, layoutParams)
                            }
                            
                            lastAction = MotionEvent.ACTION_MOVE
                            return true
                        }
                        
                        MotionEvent.ACTION_UP -> {
                            alpha = 0.8f
                            
                            // Si no fue drag, es un click
                            if (!isDragging) {
                                onBubbleClicked()
                            } else {
                                // Snap to edge después de drag
                                snapToEdge(layoutParams)
                            }
                            
                            lastAction = MotionEvent.ACTION_UP
                            return true
                        }
                    }
                    return false
                }
            })
        }
        
        try {
            windowManager?.addView(bubbleView, layoutParams)
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }
    
    private fun snapToEdge(params: WindowManager.LayoutParams) {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        
        // Mover al borde más cercano (izquierda o derecha)
        params.x = if (params.x < screenWidth / 2) {
            20 // Margen izquierdo
        } else {
            screenWidth - bubbleView?.width!! - 20 // Margen derecho
        }
        
        windowManager?.updateViewLayout(bubbleView, params)
    }
    
    private fun onBubbleClicked() {
        // Iniciar captura de pantalla
        val captureIntent = Intent(this, MainActivity::class.java).apply {
            action = "com.example.kanji_no_ryoushi.TRIGGER_SCREEN_CAPTURE"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(captureIntent)
    }
    
    private fun stopBubble() {
        try {
            bubbleView?.let {
                windowManager?.removeView(it)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        bubbleView = null
        isRunning = false
        stopForeground(true)
        stopSelf()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopBubble()
    }
}
