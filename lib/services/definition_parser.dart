import 'dart:convert';

/// Parser para convertir definiciones en formato JSON de Jitendex a texto legible
class DefinitionParser {
  /// Parsea una definición JSON y extrae el texto de forma recursiva
  static String parse(String jsonDefinition) {
    try {
      // Si ya es texto plano, retornarlo directamente
      if (!jsonDefinition.trim().startsWith('{') &&
          !jsonDefinition.trim().startsWith('[')) {
        return jsonDefinition.trim();
      }

      final dynamic parsed = jsonDecode(jsonDefinition);
      return _extractText(parsed);
    } catch (e) {
      // Si falla el parsing, devolver el string original limpio
      return jsonDefinition.trim();
    }
  }

  /// Extrae texto recursivamente de estructuras JSON
  static String _extractText(dynamic node) {
    if (node == null) return '';

    // Si es un string, devolverlo
    if (node is String) {
      return node;
    }

    // Si es un mapa (objeto JSON)
    if (node is Map) {
      final tag = node['tag'] as String?;
      final content = node['content'];

      // Ignorar tags de metadata
      if (tag == 'rt' || // furigana
          tag == 'span' && node['data']?['content'] == 'attribution-footnote') {
        return '';
      }

      // Para listas ordenadas, agregar números
      if (tag == 'ol' && content is List) {
        return content
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${_extractText(e.value)}')
            .where((s) => s.trim().isNotEmpty)
            .join('\n');
      }

      // Para listas no ordenadas, agregar bullets
      if (tag == 'ul' && content is List) {
        return content
            .map((item) => '• ${_extractText(item)}')
            .where((s) => s.trim().isNotEmpty)
            .join('\n');
      }

      // Para items de lista, solo extraer el contenido
      if (tag == 'li') {
        return _extractText(content);
      }

      // Para div, procesar el contenido
      if (tag == 'div') {
        // Ignorar ejemplos si son muy largos
        final divContent = node['data']?['content'];
        if (divContent == 'example-sentence' ||
            divContent == 'example-sentence-a' ||
            divContent == 'example-sentence-b') {
          return ''; // Omitir ejemplos por ahora
        }
        return _extractText(content);
      }

      // Para ruby (kanji con furigana), solo tomar el kanji
      if (tag == 'ruby' && content is List) {
        return content
            .where((item) => item is! Map || item['tag'] != 'rt')
            .map(_extractText)
            .join();
      }

      // Para otros tags, procesar el contenido
      if (content != null) {
        return _extractText(content);
      }

      return '';
    }

    // Si es una lista
    if (node is List) {
      return node.map(_extractText).where((s) => s.trim().isNotEmpty).join(' ');
    }

    return node.toString();
  }

  /// Extrae definiciones múltiples de un JSON complejo
  static List<String> parseMultipleDefinitions(String jsonDefinition) {
    try {
      // Si es texto plano, retornarlo
      if (!jsonDefinition.trim().startsWith('{') &&
          !jsonDefinition.trim().startsWith('[')) {
        return [jsonDefinition.trim()];
      }

      // El formato de Jitendex usa formato de diccionarios Python (comillas simples)
      // Necesitamos convertirlo a JSON válido y parsear múltiples objetos
      final results = <String>[];
      final trimmed = jsonDefinition.trim();

      // Extraer todos los objetos separados
      int depth = 0;
      int start = -1;

      for (int i = 0; i < trimmed.length; i++) {
        if (trimmed[i] == '{') {
          if (depth == 0) start = i;
          depth++;
        } else if (trimmed[i] == '}') {
          depth--;
          if (depth == 0 && start != -1) {
            // Convertir dict de Python a JSON válido
            String jsonStr = trimmed.substring(start, i + 1);
            jsonStr = _pythonDictToJson(jsonStr);

            try {
              final parsed = jsonDecode(jsonStr);
              final defs = _extractDefinitions(parsed);
              results.addAll(defs);
            } catch (_) {
              // Ignorar objetos que no se pueden parsear
            }
            start = -1;
          }
        }
      }

      return results.where((s) => s.trim().isNotEmpty).toList();
    } catch (e) {
      return [jsonDefinition.trim()];
    }
  }

  /// Convierte un dict de Python a JSON válido
  static String _pythonDictToJson(String pythonDict) {
    // Reemplazar comillas simples por dobles, pero cuidando las que están dentro de strings
    String result = '';
    bool inString = false;
    String quoteChar = '';

    for (int i = 0; i < pythonDict.length; i++) {
      final char = pythonDict[i];

      if ((char == '"' || char == "'") &&
          (i == 0 || pythonDict[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          quoteChar = char;
          result += '"'; // Usar comillas dobles para JSON
        } else if (char == quoteChar) {
          inString = false;
          quoteChar = '';
          result += '"';
        } else {
          // Escapar comillas dentro del string
          result += '\\"';
        }
      } else {
        result += char;
      }
    }

    return result;
  }

  /// Extrae definiciones individuales de una estructura JSON
  static List<String> _extractDefinitions(dynamic node) {
    if (node is Map) {
      final tag = node['tag'] as String?;

      // Ignorar metadata de part-of-speech
      if (tag == 'span' && node['data']?['content'] == 'part-of-speech-info') {
        return [];
      }

      if (tag == 'ol') {
        // Lista ordenada de sentidos/definiciones
        final content = node['content'];

        // Caso 1: content es una lista de items
        if (content is List) {
          return content
              .map((item) {
                if (item is Map && item['tag'] == 'li') {
                  final glossary = _findGlossary(item);
                  if (glossary != null) {
                    return _extractText(glossary);
                  }
                }
                return '';
              })
              .where((s) => s.trim().isNotEmpty)
              .toList();
        }

        // Caso 2: content es un solo item 'li'
        if (content is Map && content['tag'] == 'li') {
          final glossary = _findGlossary(content);
          if (glossary != null) {
            final text = _extractText(glossary);
            return text.isNotEmpty ? [text] : [];
          }
        }
      } else if (tag == 'ul') {
        // Lista simple de definiciones
        final content = node['content'];
        if (content is List) {
          return content
              .map((item) => _extractText(item))
              .where((s) => s.trim().isNotEmpty)
              .toList();
        } else if (content is Map && content['tag'] == 'li') {
          return [_extractText(content['content'])];
        }
      }
    }

    // Fallback: intentar extraer como texto simple
    final text = _extractText(node);
    return text.isNotEmpty ? [text] : [];
  }

  /// Encuentra el nodo de glosario dentro de un item
  static dynamic _findGlossary(Map node) {
    final content = node['content'];
    if (content is List) {
      for (final item in content) {
        if (item is Map &&
            item['tag'] == 'ul' &&
            item['data']?['content'] == 'glossary') {
          return item;
        }
      }
    }
    return null;
  }
}
