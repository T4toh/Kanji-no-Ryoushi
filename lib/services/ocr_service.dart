import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para procesar imágenes con OCR usando Google ML Kit
class OCRService {
  final TextRecognizer _textRecognizer;

  OCRService()
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  /// Procesa una imagen desde assets y retorna el texto reconocido
  Future<String> processImageFromAssets(String assetPath) async {
    try {
      // Cargar imagen desde assets
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Guardar temporalmente para ML Kit (ML Kit requiere archivo)
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = await File('${tempDir.path}/$fileName').writeAsBytes(bytes);

      return await processImageFromFile(file);
    } catch (e) {
      throw Exception('Error al cargar imagen desde assets: $e');
    }
  }

  /// Procesa un archivo de imagen y retorna el texto reconocido
  Future<String> processImageFromFile(File imageFile) async {
    try {
      // Crear imagen de entrada
      final inputImage = InputImage.fromFile(imageFile);

      // Procesar imagen
      final result = await _textRecognizer.processImage(inputImage);

      return result.text.isEmpty ? 'No se reconoció texto' : result.text;
    } catch (e) {
      throw Exception('Error al procesar la imagen: $e');
    }
  }

  /// Limpia recursos del reconocedor de texto
  void dispose() {
    _textRecognizer.close();
  }
}
