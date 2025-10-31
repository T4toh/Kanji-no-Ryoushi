import 'dart:io';
// removed unused import
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Servicio para manipulación de imágenes (recorte, redimensionado, rotación)
class ImageService {
  /// Recorta la imagen [inputFile] usando las coordenadas en pixeles [cropRect]
  /// sobre la imagen original y retorna un nuevo [File] con la imagen recortada
  /// en formato JPEG.
  static Future<File> cropImage(File inputFile, CropRect cropRect) async {
    final bytes = await inputFile.readAsBytes();

    // Decodificar imagen usando package:image
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('No se pudo decodificar la imagen');

    // Asegurar que el rect esté en límites
    final left = cropRect.left.clamp(0, image.width.toDouble()).toInt();
    final top = cropRect.top.clamp(0, image.height.toDouble()).toInt();
    final width = cropRect.width
        .clamp(0, (image.width - left).toDouble())
        .toInt();
    final height = cropRect.height
        .clamp(0, (image.height - top).toDouble())
        .toInt();

    final cropped = img.copyCrop(
      image,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    // Encode JPEG
    final jpeg = img.encodeJpg(cropped, quality: 90);

    final tempDir = await getTemporaryDirectory();
    final outFile = File(
      '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await outFile.writeAsBytes(jpeg);
    return outFile;
  }
}

/// Simple rect type (en pixeles) usado por ImageService y el cropper.
class CropRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
