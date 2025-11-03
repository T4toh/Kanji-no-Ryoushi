import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Servicio para capturar áreas de la pantalla usando overlay flotante en Android
class ScreenCaptureService {
  static const MethodChannel _channel =
      MethodChannel('com.example.kanji_no_ryoushi/screen_capture');

  /// Callback que se ejecuta cuando se completa una captura
  static Function(Uint8List)? onCaptureComplete;

  /// Callback que se ejecuta cuando se cancela una captura
  static Function()? onCaptureCancelled;

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
    }
  }

  /// Verifica si la app tiene permiso de overlay
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkOverlayPermission');
      return result;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Solicita permiso de overlay al usuario
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool result =
          await _channel.invokeMethod('requestOverlayPermission');
      return result;
    } catch (e) {
      print('Error requesting overlay permission: $e');
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
      print('Error starting screen capture: $e');
      return false;
    }
  }

  /// Workflow completo: verificar permisos y iniciar captura
  static Future<bool> captureWithPermissionCheck() async {
    // Verificar si ya tenemos el permiso
    bool hasPermission = await checkOverlayPermission();

    // Si no lo tenemos, solicitarlo
    if (!hasPermission) {
      hasPermission = await requestOverlayPermission();
    }

    // Si no se otorgó el permiso, retornar false
    if (!hasPermission) {
      return false;
    }

    // Iniciar captura
    return await startScreenCapture();
  }
}
