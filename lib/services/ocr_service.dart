import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import '../models/ocr_history_entry.dart';
import 'package:path_provider/path_provider.dart';

/// Resultado del OCR con texto e idiomas detectados
class OCRResult {
  final String text;
  final List<String> recognizedLanguages;
  final List<OCRBlockInfo> blocks;

  OCRResult({
    required this.text,
    required this.recognizedLanguages,
    this.blocks = const [],
  });
}

/// Servicio para procesar imágenes con OCR usando Google ML Kit
class OCRService {
  final TextRecognizer _textRecognizer;
  final LanguageIdentifier _languageIdentifier;

  OCRService()
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese),
      _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  /// Procesa una imagen desde assets y retorna el texto reconocido
  Future<OCRResult> processImageFromAssets(String assetPath) async {
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
  Future<OCRResult> processImageFromFile(File imageFile) async {
    try {
      // Crear imagen de entrada
      final inputImage = InputImage.fromFile(imageFile);

      // Procesar imagen
      final result = await _textRecognizer.processImage(inputImage);

      // Extraer idiomas únicos de todos los bloques.
      // Si ML Kit TextRecognizer no retorna un idioma útil (por ejemplo 'und'),
      // intentamos identificar el idioma usando LanguageIdentifier sobre el texto
      // del bloque para tener un resultado más fiable.
      final Set<String> languages = {};
      final List<OCRBlockInfo> blockInfos = [];
      for (final block in result.blocks) {
        // Añadir idiomas reportados por el bloque, filtrando 'und' y vacíos
        if (block.recognizedLanguages.isNotEmpty) {
          languages.addAll(
            block.recognizedLanguages.where((l) => l.isNotEmpty && l != 'und'),
          );
        }

        // Intentar identificar por contenido del bloque usando LanguageIdentifier
        String? chosenLang;
        double? chosenConfidence;
        try {
          final possible = await _languageIdentifier.identifyPossibleLanguages(
            block.text,
          );
          if (possible.isNotEmpty) {
            // Elegir el primer candidato (el más probable) como top
            final top = possible.first;
            if (top.languageTag.isNotEmpty && top.languageTag != 'und') {
              chosenLang = top.languageTag;
              chosenConfidence = top.confidence;
              languages.add(top.languageTag);
            }
          }
        } catch (e) {
          // No romper el flujo en caso de error
        }

        blockInfos.add(
          OCRBlockInfo(
            text: block.text,
            languageTag: chosenLang,
            confidence: chosenConfidence,
          ),
        );
      }

      // Si aún no detectamos ningún idioma válido, intentar identificar sobre
      // todo el texto reconocido como fallback.
      if (languages.isEmpty && result.text.trim().isNotEmpty) {
        try {
          final possibleOverall = await _languageIdentifier
              .identifyPossibleLanguages(result.text);
          for (final p in possibleOverall) {
            if (p.languageTag.isNotEmpty && p.languageTag != 'und') {
              languages.add(p.languageTag);
            }
          }
        } catch (e) {
          // ignorar
        }
      }

      final text = result.text.isEmpty ? 'No se reconoció texto' : result.text;

      return OCRResult(
        text: text,
        recognizedLanguages: languages.toList(),
        blocks: blockInfos,
      );
    } catch (e) {
      throw Exception('Error al procesar la imagen: $e');
    }
  }

  /// Limpia recursos del reconocedor de texto
  void dispose() {
    _textRecognizer.close();
    _languageIdentifier.close();
  }
}
