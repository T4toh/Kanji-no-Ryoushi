class DictionaryEntry {
  final String headword; // kanji / word (term)
  final List<String> readings;
  final List<String> meanings; // definitions
  final List<String>? examples;
  final int?
  popularity; // Popularidad del término (0-200, siendo 200 el más común)
  final int? sequence; // ID único de JMdict

  DictionaryEntry({
    required this.headword,
    required this.readings,
    required this.meanings,
    this.examples,
    this.popularity,
    this.sequence,
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> m) {
    return DictionaryEntry(
      headword: m['term'] as String? ?? m['headword'] as String? ?? '',
      readings: m['reading'] != null
          ? [m['reading'] as String]
          : (m['readings'] as List<dynamic>?)?.cast<String>() ?? [],
      meanings: m['definition'] != null
          ? [m['definition'] as String]
          : (m['meanings'] as List<dynamic>?)?.cast<String>() ?? [],
      examples: (m['examples'] as List<dynamic>?)?.cast<String>(),
      popularity: m['popularity'] as int?,
      sequence: m['sequence'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'term': headword,
      'reading': readings.isNotEmpty ? readings.first : '',
      'definition': meanings.isNotEmpty ? meanings.first : '',
      'popularity': popularity,
      'sequence': sequence,
    };
  }

  /// Retorna un icono de frecuencia basado en la popularidad
  String get frequencyIcon {
    if (popularity == null) return '';
    if (popularity! >= 180) return '⭐⭐⭐'; // Muy común
    if (popularity! >= 120) return '⭐⭐'; // Común
    if (popularity! >= 60) return '⭐'; // Moderado
    return ''; // Poco común
  }

  /// Retorna una descripción de frecuencia en español
  String get frequencyLabel {
    if (popularity == null) return '';
    if (popularity! >= 180) return 'Muy común';
    if (popularity! >= 120) return 'Común';
    if (popularity! >= 60) return 'Moderado';
    return 'Poco común';
  }
}
