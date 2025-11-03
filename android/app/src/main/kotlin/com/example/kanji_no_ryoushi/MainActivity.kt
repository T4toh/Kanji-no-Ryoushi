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
                    // Iniciar servicio de captura
                    val serviceIntent = Intent(this, ScreenCaptureService::class.java).apply {
                        action = ScreenCaptureService.ACTION_START_CAPTURE
                        putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, resultCode)
                        putExtra(ScreenCaptureService.EXTRA_RESULT_DATA, data)
                    }
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
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
        methodChannel?.setMethodCallHandler(null)
    }
}
