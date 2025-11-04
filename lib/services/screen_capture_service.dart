import 'package:flutter/services.dart';

/// Servicio para capturar áreas de la pantalla usando overlay flotante en Android
class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.kanji_no_ryoushi/screen_capture',
  );

  /// Callback que se ejecuta cuando se completa una captura
  static Function(Uint8List)? onCaptureComplete;

  /// Callback que se ejecuta cuando se cancela una captura
  static Function()? onCaptureCancelled;

  /// Callback que se ejecuta cuando se otorga el permiso MediaProjection
  static Function()? onMediaProjectionGranted;

  /// Callback que se ejecuta cuando expira el permiso MediaProjection
  static Function()? onPermissionExpired;

  /// Inicializa el servicio y configura los callbacks
  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Maneja las llamadas desde el código nativo
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCaptureComplete':
        final Uint8List imageBytes = call.arguments as Uint8List;
        onCaptureComplete?.call(imageBytes);
        break;
      case 'onCaptureCancelled':
        onCaptureCancelled?.call();
        break;
      case 'triggerScreenCaptureFromBubble':
        // El bubble flotante quiere iniciar una captura
        await captureWithPermissionCheck();
        break;
      case 'onMediaProjectionGranted':
        // Se otorgó el permiso de MediaProjection por primera vez
        onMediaProjectionGranted?.call();
        break;
      case 'onPermissionExpired':
        // El token de MediaProjection expiró, necesitamos pedir permiso de nuevo
        onPermissionExpired?.call();
        break;
    }
  }

  /// Verifica si la app tiene permiso de overlay
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkOverlayPermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Solicita permiso de overlay al usuario
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'requestOverlayPermission',
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Inicia el proceso de captura de pantalla
  /// Muestra el overlay flotante para seleccionar área
  static Future<bool> startScreenCapture() async {
    try {
      final bool result = await _channel.invokeMethod('startScreenCapture');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Workflow completo: verificar permisos y iniciar captura
  static Future<bool> captureWithPermissionCheck() async {
    // Verificar si ya tenemos el permiso de overlay
    bool hasPermission = await checkOverlayPermission();

    // Si no lo tenemos, solicitarlo
    if (!hasPermission) {
      hasPermission = await requestOverlayPermission();
    }

    // Si no se otorgó el permiso, retornar false
    if (!hasPermission) {
      return false;
    }

    // SIEMPRE iniciar captura, esto pedirá MediaProjection automáticamente si es necesario
    // porque las credenciales se invalidan después de cada captura en Android 14+
    return await startScreenCapture();
  }

  /// Inicia el bubble flotante persistente
  static Future<bool> startFloatingBubble() async {
    try {
      // Verificar permiso primero
      bool hasPermission = await checkOverlayPermission();
      if (!hasPermission) {
        hasPermission = await requestOverlayPermission();
      }

      if (!hasPermission) {
        return false;
      }

      final bool result = await _channel.invokeMethod('startFloatingBubble');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Detiene el bubble flotante
  static Future<bool> stopFloatingBubble() async {
    try {
      final bool result = await _channel.invokeMethod('stopFloatingBubble');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el bubble flotante está activo
  static Future<bool> isFloatingBubbleRunning() async {
    try {
      final bool result = await _channel.invokeMethod(
        'isFloatingBubbleRunning',
      );
      return result;
    } catch (e) {
      return false;
    }
  }
}
