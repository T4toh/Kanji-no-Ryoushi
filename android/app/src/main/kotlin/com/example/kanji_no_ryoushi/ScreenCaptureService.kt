package com.example.kanji_no_ryoushi

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.*
import android.widget.Button
import android.widget.FrameLayout
import androidx.core.app.NotificationCompat
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class ScreenCaptureService : Service() {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var selectionView: SelectionOverlayView? = null
    
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    
    private var resultCode: Int = 0
    private var resultData: Intent? = null
    
    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "screen_capture_channel"
        const val ACTION_START_CAPTURE = "com.example.kanji_no_ryoushi.START_CAPTURE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        
        var captureCallback: ((ByteArray?) -> Unit)? = null
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_START_CAPTURE) {
            resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
            resultData = intent.getParcelableExtra(EXTRA_RESULT_DATA)
            
            startForeground(NOTIFICATION_ID, createNotification())
            showOverlay()
        }
        
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Captura de Pantalla",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Servicio de captura de pantalla activo"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Captura de Pantalla Activa")
            .setContentText("Selecciona el área a capturar")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun showOverlay() {
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        
        val container = FrameLayout(this)
        
        // Vista de selección (área transparente con bordes)
        selectionView = SelectionOverlayView(this)
        container.addView(selectionView)
        
        // Botón de captura
        val captureButton = Button(this).apply {
            text = "Capturar"
            setOnClickListener {
                captureScreen()
            }
        }
        val captureParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            bottomMargin = 50
        }
        container.addView(captureButton, captureParams)
        
        // Botón de cancelar
        val cancelButton = Button(this).apply {
            text = "Cancelar"
            setOnClickListener {
                captureCallback?.invoke(null)
                stopOverlay()
            }
        }
        val cancelParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.END
            bottomMargin = 50
            marginEnd = 20
        }
        container.addView(cancelButton, cancelParams)
        
        overlayView = container
        windowManager?.addView(overlayView, layoutParams)
    }
    
    private fun captureScreen() {
        val metrics = DisplayMetrics()
        windowManager?.defaultDisplay?.getRealMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi
        
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        
        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, resultData!!)
        
        // Registrar callback requerido en Android 14+
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                super.onStop()
                cleanup()
            }
        }, Handler(Looper.getMainLooper()))
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )
        
        // Pequeño delay para asegurar que el overlay se oculta antes de capturar
        Handler(Looper.getMainLooper()).postDelayed({
            hideOverlayTemporarily()
            
            Handler(Looper.getMainLooper()).postDelayed({
                processCapture()
            }, 100)
        }, 50)
    }
    
    private fun hideOverlayTemporarily() {
        overlayView?.visibility = View.INVISIBLE
    }
    
    private fun processCapture() {
        try {
            val image = imageReader?.acquireLatestImage()
            if (image != null) {
                val selectionRect = selectionView?.getSelectionRect()
                val bitmap = imageToBitmap(image)
                image.close()
                
                val croppedBitmap = if (selectionRect != null && 
                    selectionRect.width() > 0 && 
                    selectionRect.height() > 0 &&
                    selectionRect.left >= 0 &&
                    selectionRect.top >= 0 &&
                    selectionRect.right <= bitmap.width &&
                    selectionRect.bottom <= bitmap.height
                ) {
                    Bitmap.createBitmap(
                        bitmap,
                        selectionRect.left,
                        selectionRect.top,
                        selectionRect.width(),
                        selectionRect.height()
                    )
                } else {
                    bitmap
                }
                
                val byteArray = bitmapToByteArray(croppedBitmap)
                captureCallback?.invoke(byteArray)
                
                bitmap.recycle()
                if (croppedBitmap != bitmap) {
                    croppedBitmap.recycle()
                }
            } else {
                captureCallback?.invoke(null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            captureCallback?.invoke(null)
        } finally {
            stopOverlay()
        }
    }
    
    private fun imageToBitmap(image: Image): Bitmap {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width
        
        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        
        return if (rowPadding == 0) {
            bitmap
        } else {
            Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
        }
    }
    
    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
    
    private fun stopOverlay() {
        try {
            overlayView?.let {
                windowManager?.removeView(it)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        overlayView = null
        selectionView = null
        
        cleanup()
        stopForeground(true)
        stopSelf()
    }
    
    private fun cleanup() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        
        virtualDisplay = null
        imageReader = null
        mediaProjection = null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        cleanup()
        try {
            overlayView?.let {
                windowManager?.removeView(it)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    // Vista personalizada para selección de área
    inner class SelectionOverlayView(context: Context) : View(context) {
        
        private val paint = Paint().apply {
            color = Color.parseColor("#40FFFFFF")
            style = Paint.Style.FILL
        }
        
        private val borderPaint = Paint().apply {
            color = Color.parseColor("#FF4CAF50")
            style = Paint.Style.STROKE
            strokeWidth = 8f
        }
        
        private val dimPaint = Paint().apply {
            color = Color.parseColor("#AA000000")
            style = Paint.Style.FILL
        }
        
        private var startX = 0f
        private var startY = 0f
        private var endX = 0f
        private var endY = 0f
        private var isDragging = false
        
        init {
            setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        startX = event.x
                        startY = event.y
                        endX = event.x
                        endY = event.y
                        isDragging = true
                        invalidate()
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        if (isDragging) {
                            endX = event.x
                            endY = event.y
                            invalidate()
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        isDragging = false
                        invalidate()
                        true
                    }
                    else -> false
                }
            }
        }
        
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            
            val left = minOf(startX, endX)
            val top = minOf(startY, endY)
            val right = maxOf(startX, endX)
            val bottom = maxOf(startY, endY)
            
            // Dibujar overlay oscuro en toda la pantalla
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dimPaint)
            
            // "Recortar" el área seleccionada (dibujarla clara)
            canvas.drawRect(left, top, right, bottom, paint)
            
            // Dibujar borde del área seleccionada
            if (right - left > 10 && bottom - top > 10) {
                canvas.drawRect(left, top, right, bottom, borderPaint)
            }
        }
        
        fun getSelectionRect(): Rect? {
            val left = minOf(startX, endX).toInt()
            val top = minOf(startY, endY).toInt()
            val right = maxOf(startX, endX).toInt()
            val bottom = maxOf(startY, endY).toInt()
            
            return if (right - left > 10 && bottom - top > 10) {
                Rect(left, top, right, bottom)
            } else {
                null
            }
        }
    }
}
