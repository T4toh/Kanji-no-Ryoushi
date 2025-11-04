package com.example.kanji_no_ryoushi

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "com.example.kanji_no_ryoushi/screen_capture"
    private val REQUEST_MEDIA_PROJECTION = 1001
    private val REQUEST_OVERLAY_PERMISSION = 1002
    
    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null
    private var shouldStartCaptureOnResume = false
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
                            pendingResult = result
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                
                "startScreenCapture" -> {
                    pendingResult = result
                    requestMediaProjection()
                }
                
                "startFloatingBubble" -> {
                    val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                        action = FloatingBubbleService.ACTION_START_BUBBLE
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                
                "stopFloatingBubble" -> {
                    val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                        action = FloatingBubbleService.ACTION_STOP_BUBBLE
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                
                "isFloatingBubbleRunning" -> {
                    result.success(FloatingBubbleService.isRunning)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Configurar callback para recibir capturas
        ScreenCaptureService.captureCallback = { imageBytes ->
            activity.runOnUiThread {
                if (imageBytes != null) {
                    methodChannel?.invokeMethod("onCaptureComplete", imageBytes)
                } else {
                    methodChannel?.invokeMethod("onCaptureCancelled", null)
                }
            }
        }
        
        // Configurar callback para cuando expira el permiso
        ScreenCaptureService.permissionExpiredCallback = {
            activity.runOnUiThread {
                methodChannel?.invokeMethod("onPermissionExpired", null)
            }
        }
    }
    
    private fun requestMediaProjection() {
        val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(
            mediaProjectionManager.createScreenCaptureIntent(),
            REQUEST_MEDIA_PROJECTION
        )
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_MEDIA_PROJECTION -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    // Guardar los datos en el FloatingBubbleService para uso futuro
                    FloatingBubbleService.captureResultCode = resultCode
                    FloatingBubbleService.captureResultData = data
                    
                    // NO iniciar captura inmediatamente en la primera vez
                    // Solo informar al usuario que ya está listo
                    methodChannel?.invokeMethod("onMediaProjectionGranted", null)
                    
                    pendingResult?.success(true)
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "MediaProjection permission denied", null)
                }
                pendingResult = null
            }
            
            REQUEST_OVERLAY_PERMISSION -> {
                val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(this)
                } else {
                    true
                }
                pendingResult?.success(hasPermission)
                pendingResult = null
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        ScreenCaptureService.captureCallback = null
        ScreenCaptureService.permissionExpiredCallback = null
        methodChannel?.setMethodCallHandler(null)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Manejar click desde el bubble flotante
        if (intent.action == "com.example.kanji_no_ryoushi.TRIGGER_SCREEN_CAPTURE") {
            shouldStartCaptureOnResume = true
        }
    }
    
    override fun onResume() {
        super.onResume()
        
        // Iniciar captura si viene del bubble
        if (shouldStartCaptureOnResume) {
            shouldStartCaptureOnResume = false
            methodChannel?.invokeMethod("triggerScreenCaptureFromBubble", null)
        }
    }
}
