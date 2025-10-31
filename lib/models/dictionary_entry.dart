class DictionaryEntry {
  final String headword; // kanji / word
  final List<String> readings;
  final List<String> meanings;
  final List<String>? examples;

  DictionaryEntry({
    required this.headword,
    required this.readings,
    required this.meanings,
    this.examples,
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> m) {
    return DictionaryEntry(
      headword: m['headword'] as String? ?? '',
      readings: (m['readings'] as List<dynamic>?)?.cast<String>() ?? [],
      meanings: (m['meanings'] as List<dynamic>?)?.cast<String>() ?? [],
      examples: (m['examples'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
