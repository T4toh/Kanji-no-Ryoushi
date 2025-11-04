package com.example.kanji_no_ryoushi

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
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
    
    private var isCapturing = false
    
    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "screen_capture_channel"
        const val ACTION_START_CAPTURE = "com.example.kanji_no_ryoushi.START_CAPTURE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        
        var captureCallback: ((ByteArray?) -> Unit)? = null
        var permissionExpiredCallback: (() -> Unit)? = null
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_START_CAPTURE) {
            // Evitar inicios duplicados
            if (isCapturing) {
                android.util.Log.w("ScreenCapture", "Ya hay una captura en curso, ignorando")
                return START_NOT_STICKY
            }
            
            isCapturing = true
            resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
            resultData = intent.getParcelableExtra(EXTRA_RESULT_DATA)
            
            // Combinar MEDIA_PROJECTION (requerido) y SPECIAL_USE (para evitar restricciones)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    createNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or 
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, createNotification())
            }
            
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
        // Primero obtener las métricas reales de la pantalla
        val metrics = DisplayMetrics()
        windowManager?.defaultDisplay?.getRealMetrics(metrics)
        val screenHeight = metrics.heightPixels
        
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            screenHeight, // Usar altura exacta en lugar de MATCH_PARENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            y = 0
        }
        
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
        // Primero ocultar el overlay y esperar un momento
        hideOverlayTemporarily()
        
        // Delay para que el overlay se oculte completamente
        Handler(Looper.getMainLooper()).postDelayed({
            val metrics = DisplayMetrics()
            windowManager?.defaultDisplay?.getRealMetrics(metrics)
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi
            
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            
            val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            
            // Crear NUEVO MediaProjection cada vez (Android no permite reusar el mismo)
            // IMPORTANTE: esto invalida el token anterior
            mediaProjection?.stop()
            mediaProjection = null
            
            try {
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, resultData!!)
                
                // Registrar callback requerido en Android 14+
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        super.onStop()
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
                
                // Esperar un poco más para que la captura se complete
                Handler(Looper.getMainLooper()).postDelayed({
                    processCapture()
                }, 200)
            } catch (e: SecurityException) {
                android.util.Log.e("ScreenCapture", "SecurityException - Token de MediaProjection expirado o inválido", e)
                
                // INVALIDAR las credenciales guardadas para forzar nuevo permiso
                FloatingBubbleService.captureResultCode = 0
                FloatingBubbleService.captureResultData = null
                
                // Notificar que necesitamos pedir permiso de nuevo
                permissionExpiredCallback?.invoke()
                captureCallback?.invoke(null)
                stopOverlay()
            } catch (e: Exception) {
                android.util.Log.e("ScreenCapture", "Error creando MediaProjection", e)
                captureCallback?.invoke(null)
                stopOverlay()
            }
        }, 100)
    }
    
    private fun hideOverlayTemporarily() {
        overlayView?.visibility = View.INVISIBLE
    }
    
    private fun processCapture() {
        try {
            val image = imageReader?.acquireLatestImage()
            if (image != null) {
                val selectionRect = selectionView?.getSelectionRect()
                val overlaySize = selectionView?.let { Point(it.width, it.height) }
                
                val bitmap = imageToBitmap(image)
                image.close()
                
                // Escalar el rectángulo de selección a las coordenadas del bitmap
                // El overlay puede tener diferente tamaño que el bitmap (barras de sistema)
                val croppedBitmap = if (selectionRect != null && 
                    overlaySize != null &&
                    selectionRect.width() > 0 && 
                    selectionRect.height() > 0
                ) {
                    // Calcular escala entre el OVERLAY (donde se hizo la selección) y el BITMAP capturado
                    val scaleX = bitmap.width.toFloat() / overlaySize.x.toFloat()
                    val scaleY = bitmap.height.toFloat() / overlaySize.y.toFloat()
                    
                    // Escalar coordenadas del rectángulo
                    val scaledLeft = (selectionRect.left * scaleX).toInt()
                    val scaledTop = (selectionRect.top * scaleY).toInt()
                    val scaledRight = (selectionRect.right * scaleX).toInt()
                    val scaledBottom = (selectionRect.bottom * scaleY).toInt()
                    
                    val scaledWidth = scaledRight - scaledLeft
                    val scaledHeight = scaledBottom - scaledTop
                    
                    // Validar que las coordenadas escaladas estén dentro del bitmap
                    if (scaledLeft >= 0 && scaledTop >= 0 && 
                        scaledRight <= bitmap.width && scaledBottom <= bitmap.height &&
                        scaledWidth > 0 && scaledHeight > 0
                    ) {
                        Bitmap.createBitmap(
                            bitmap,
                            scaledLeft,
                            scaledTop,
                            scaledWidth,
                            scaledHeight
                        )
                    } else {
                        bitmap
                    }
                } else {
                    bitmap
                }
                
                val byteArray = bitmapToByteArray(croppedBitmap)
                
                // Enviar a Flutter
                captureCallback?.invoke(byteArray)
                
                // Pequeño delay para asegurar que el callback se procese
                Handler(Looper.getMainLooper()).postDelayed({
                    // Abrir la app automáticamente con la captura
                    val appIntent = Intent(this, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    startActivity(appIntent)
                }, 300)
                
                bitmap.recycle()
                if (croppedBitmap != bitmap) {
                    croppedBitmap.recycle()
                }
            } else {
                android.util.Log.e("ScreenCapture", "No se pudo obtener imagen")
                captureCallback?.invoke(null)
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenCapture", "Error procesando captura", e)
            e.printStackTrace()
            captureCallback?.invoke(null)
        } finally {
            // Delay antes de cerrar el overlay para permitir que el Intent se procese
            Handler(Looper.getMainLooper()).postDelayed({
                stopOverlay()
            }, 500)
        }
    }
    
    private fun imageToBitmap(image: Image): Bitmap {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width
        
        // Crear bitmap con padding extra para acomodar el rowStride
        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height,
            Bitmap.Config.ARGB_8888
        )
        
        // Copiar directamente desde el buffer
        buffer.rewind()
        bitmap.copyPixelsFromBuffer(buffer)
        
        // Si hay padding, recortar al tamaño real
        val finalBitmap = if (rowPadding != 0) {
            Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
        } else {
            bitmap
        }
        
        if (finalBitmap != bitmap) {
            bitmap.recycle()
        }
        
        return finalBitmap
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
        
        // NO invalidar las credenciales - se pueden reutilizar
        // Solo limpiamos el MediaProjection instance usado
        
        isCapturing = false
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
        
        // INVALIDAR credenciales después de cada captura
        // Android 14+ solo permite usar el token UNA vez
        FloatingBubbleService.captureResultCode = 0
        FloatingBubbleService.captureResultData = null
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
