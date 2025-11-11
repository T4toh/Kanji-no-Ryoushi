import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y cargar la última imagen procesada
class ImagePersistenceService {
  static const String _lastImagePathKey = 'last_image_path';
  static const String _isExampleImageKey = 'is_example_image';
  static const String _lastRecognizedTextKey = 'last_recognized_text';

  /// Guarda la última imagen procesada y su texto reconocido
  Future<void> saveLastImage({
    required File? imageFile,
    required bool isExampleImage,
    required String recognizedText,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (isExampleImage) {
      // Si es la imagen de ejemplo, solo guardamos esa info
      await prefs.setBool(_isExampleImageKey, true);
      await prefs.remove(_lastImagePathKey);
    } else if (imageFile != null) {
      // Validar que el archivo de origen no esté vacío
      if (await imageFile.exists()) {
        final fileSize = await imageFile.length();
        if (fileSize > 0) {
          // Guardar imagen en directorio persistente de la app
          final appDir = await getApplicationDocumentsDirectory();
          final savedImagePath = '${appDir.path}/last_processed_image.png';

          // Copiar imagen al directorio persistente
          final savedFile = await imageFile.copy(savedImagePath);

          // Verificar que el archivo copiado no esté vacío
          final savedSize = await savedFile.length();
          if (savedSize > 0) {
            await prefs.setBool(_isExampleImageKey, false);
            await prefs.setString(_lastImagePathKey, savedFile.path);
          } else {
            print('⚠️ Archivo copiado está vacío, no se guardará');
            await savedFile.delete();
            return;
          }
        } else {
          print('⚠️ Archivo de origen está vacío, no se guardará');
          return;
        }
      } else {
        print('⚠️ Archivo de origen no existe, no se guardará');
        return;
      }
    }

    // Guardar el texto reconocido
    await prefs.setString(_lastRecognizedTextKey, recognizedText);
  }

  /// Carga la última imagen procesada
  /// Retorna un Map con:
  /// - 'imageFile': File? (la imagen guardada, null si es de ejemplo)
  /// - 'isExampleImage': bool
  /// - 'recognizedText': String
  Future<Map<String, dynamic>> loadLastImage() async {
    final prefs = await SharedPreferences.getInstance();

    final isExampleImage = prefs.getBool(_isExampleImageKey) ?? true;
    final imagePath = prefs.getString(_lastImagePathKey);
    final recognizedText = prefs.getString(_lastRecognizedTextKey) ?? '';

    File? imageFile;
    if (!isExampleImage && imagePath != null) {
      final file = File(imagePath);
      // Verificar que el archivo existe Y no está vacío
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          imageFile = file;
        } else {
          // Archivo vacío, borrar y volver a imagen de ejemplo
          print('⚠️ Archivo de imagen vacío, eliminando: $imagePath');
          await file.delete();
          await prefs.setBool(_isExampleImageKey, true);
          await prefs.remove(_lastImagePathKey);
          return {
            'imageFile': null,
            'isExampleImage': true,
            'recognizedText': '',
          };
        }
      } else {
        // Si el archivo fue borrado, volver a imagen de ejemplo
        await prefs.setBool(_isExampleImageKey, true);
        await prefs.remove(_lastImagePathKey);
        return {
          'imageFile': null,
          'isExampleImage': true,
          'recognizedText': '',
        };
      }
    }

    return {
      'imageFile': imageFile,
      'isExampleImage': isExampleImage,
      'recognizedText': recognizedText,
    };
  }

  /// Limpia la última imagen guardada
  Future<void> clearLastImage() async {
    final prefs = await SharedPreferences.getInstance();

    // Eliminar archivo guardado si existe
    final imagePath = prefs.getString(_lastImagePathKey);
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Limpiar SharedPreferences
    await prefs.remove(_lastImagePathKey);
    await prefs.remove(_isExampleImageKey);
    await prefs.remove(_lastRecognizedTextKey);
  }
}
