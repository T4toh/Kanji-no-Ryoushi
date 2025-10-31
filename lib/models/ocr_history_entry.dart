import 'dart:convert';

/// Entrada del historial de OCR
class OCRHistoryEntry {
  final String id;
  final String text;
  final DateTime timestamp;
  final String? imagePath;

  OCRHistoryEntry({
    required this.id,
    required this.text,
    required this.timestamp,
    this.imagePath,
  });

  /// Divide el texto en bloques separados por líneas vacías o saltos de línea
  List<String> get textBlocks {
    if (text.isEmpty) return [];

    // Separar por dobles saltos de línea (párrafos)
    final paragraphs = text.split(RegExp(r'\n\s*\n'));

    // Si no hay párrafos separados, dividir por líneas individuales
    if (paragraphs.length == 1 && paragraphs.first.contains('\n')) {
      return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    }

    return paragraphs.where((p) => p.trim().isNotEmpty).toList();
  }

  /// Convierte a JSON para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  /// Crea desde JSON
  factory OCRHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OCRHistoryEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Convierte a String para shared_preferences
  String toJsonString() => jsonEncode(toJson());

  /// Crea desde String
  factory OCRHistoryEntry.fromJsonString(String jsonString) {
    return OCRHistoryEntry.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
