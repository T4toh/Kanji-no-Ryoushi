import 'dart:convert';

/// Información de idioma por bloque de texto
class OCRBlockInfo {
  final String text;
  final String? languageTag;
  final double? confidence;

  OCRBlockInfo({required this.text, this.languageTag, this.confidence});

  Map<String, dynamic> toJson() => {
    'text': text,
    'languageTag': languageTag,
    'confidence': confidence,
  };

  factory OCRBlockInfo.fromJson(Map<String, dynamic> json) => OCRBlockInfo(
    text: json['text'] as String? ?? '',
    languageTag: json['languageTag'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble(),
  );
}

/// Entrada del historial de OCR
class OCRHistoryEntry {
  final String id;
  final String text;
  final DateTime timestamp;
  final String? imagePath;
  final List<String> recognizedLanguages;

  /// Información por bloque: texto, idioma detectado y confianza
  final List<OCRBlockInfo> blocks;

  OCRHistoryEntry({
    required this.id,
    required this.text,
    required this.timestamp,
    this.imagePath,
    this.recognizedLanguages = const [],
    this.blocks = const [],
  });

  /// Obtiene la bandera emoji del idioma principal detectado
  String get languageFlag {
    // Preferir idioma del primer bloque si está disponible
    final firstLang = blocks.isNotEmpty && blocks.first.languageTag != null
        ? blocks.first.languageTag!.toLowerCase()
        : (recognizedLanguages.isNotEmpty
              ? recognizedLanguages.first.toLowerCase()
              : null);

    if (firstLang == null) return '🌐';

    final language = firstLang;

    // Mapeo de códigos de idioma a banderas emoji
    final languageFlags = {
      'ja': '🇯🇵', // Japonés
      'jpn': '🇯🇵', // Japonés (código de 3 letras)
      'en': '🇺🇸', // Inglés
      'eng': '🇺🇸', // Inglés (código de 3 letras)
      'es': '🇪🇸', // Español
      'spa': '🇪🇸', // Español (código de 3 letras)
      'zh': '🇨🇳', // Chino
      'chi': '🇨🇳', // Chino (código de 3 letras)
      'zho': '🇨🇳', // Chino (código de 3 letras alternativo)
      'ko': '🇰🇷', // Coreano
      'kor': '🇰🇷', // Coreano (código de 3 letras)
      'fr': '🇫🇷', // Francés
      'fra': '🇫🇷', // Francés (código de 3 letras)
      'de': '🇩🇪', // Alemán
      'deu': '🇩🇪', // Alemán (código de 3 letras)
      'it': '🇮🇹', // Italiano
      'ita': '🇮🇹', // Italiano (código de 3 letras)
      'pt': '🇵🇹', // Portugués
      'por': '🇵🇹', // Portugués (código de 3 letras)
      'ru': '🇷🇺', // Ruso
      'rus': '🇷🇺', // Ruso (código de 3 letras)
      'ar': '🇸🇦', // Árabe
      'ara': '🇸🇦', // Árabe (código de 3 letras)
      'hi': '🇮🇳', // Hindi
      'hin': '🇮🇳', // Hindi (código de 3 letras)
      'th': '🇹🇭', // Tailandés
      'tha': '🇹🇭', // Tailandés (código de 3 letras)
      'vi': '🇻🇳', // Vietnamita
      'vie': '🇻🇳', // Vietnamita (código de 3 letras)
    };

    return languageFlags[language] ?? '🌐';
  }

  /// Obtiene el nombre del idioma en español
  String get languageName {
    final firstLang = blocks.isNotEmpty && blocks.first.languageTag != null
        ? blocks.first.languageTag!.toLowerCase()
        : (recognizedLanguages.isNotEmpty
              ? recognizedLanguages.first.toLowerCase()
              : null);

    if (firstLang == null) return 'Desconocido';

    final language = firstLang;

    final languageNames = {
      'ja': 'Japonés',
      'jpn': 'Japonés',
      'en': 'Inglés',
      'eng': 'Inglés',
      'es': 'Español',
      'spa': 'Español',
      'zh': 'Chino',
      'chi': 'Chino',
      'zho': 'Chino',
      'ko': 'Coreano',
      'kor': 'Coreano',
      'fr': 'Francés',
      'fra': 'Francés',
      'de': 'Alemán',
      'deu': 'Alemán',
      'it': 'Italiano',
      'ita': 'Italiano',
      'pt': 'Portugués',
      'por': 'Portugués',
      'ru': 'Ruso',
      'rus': 'Ruso',
      'ar': 'Árabe',
      'ara': 'Árabe',
      'hi': 'Hindi',
      'hin': 'Hindi',
      'th': 'Tailandés',
      'tha': 'Tailandés',
      'vi': 'Vietnamita',
      'vie': 'Vietnamita',
    };

    return languageNames[language] ?? 'Desconocido';
  }

  /// Divide el texto en bloques separados por líneas vacías o saltos de línea
  List<String> get textBlocks {
    // Si tenemos bloques con texto, devolverlos
    if (blocks.isNotEmpty)
      return blocks
          .map((b) => b.text)
          .where((t) => t.trim().isNotEmpty)
          .toList();

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
      'recognizedLanguages': recognizedLanguages,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  /// Crea desde JSON
  factory OCRHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OCRHistoryEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String?,
      recognizedLanguages:
          (json['recognizedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      blocks:
          (json['blocks'] as List<dynamic>?)
              ?.map((e) => OCRBlockInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
