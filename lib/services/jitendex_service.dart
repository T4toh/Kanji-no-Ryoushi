import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/dictionary_entry.dart';
import 'definition_parser.dart';

/// JitendexService - Servicio para consultar el diccionario Jitendex desde SQLite
class JitendexService {
  Database? _database;

  JitendexService._();

  static Future<JitendexService> create() async {
    final service = JitendexService._();
    await service._initDatabase();
    return service;
  }

  /// Inicializa la base de datos copiándola desde assets si es necesario
  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "jitendex.db");

    // Verificar si la base de datos ya existe
    final exists = await databaseExists(path);

    if (!exists) {
      print("Creando copia de la base de datos desde assets");

      // Asegurar que el directorio existe
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copiar desde assets
      ByteData data = await rootBundle.load("assets/dicts/jitendex.db");
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Escribir los bytes
      await File(path).writeAsBytes(bytes, flush: true);
    }

    // Abrir la base de datos en modo solo lectura
    _database = await openDatabase(path, readOnly: true);
  }

  /// Verifica si la base de datos está disponible
  Future<bool> isAvailable() async => _database != null;

  /// Busca términos en el diccionario
  /// Retorna una lista de DictionaryEntry con todos los matches
  Future<List<DictionaryEntry>> search(String query) async {
    if (_database == null || query.trim().isEmpty) {
      return [];
    }

    try {
      final List<Map<String, dynamic>> results = await _database!.rawQuery(
        '''
        SELECT t.term, t.reading, t.popularity, t.sequence, d.definition
        FROM terms t
        INNER JOIN definitions d ON t.id = d.term_id
        WHERE t.term = ? OR t.reading = ?
        ORDER BY t.popularity DESC
        ''',
        [query.trim(), query.trim()],
      );

      // Agrupar definiciones por término y lectura
      final Map<String, DictionaryEntry> grouped = {};

      for (final row in results) {
        final term = row['term'] as String;
        final reading = row['reading'] as String;
        final popularity = row['popularity'] as int?;
        final sequence = row['sequence'] as int?;
        final definitionRaw = row['definition'] as String;
        final key = '$term|$reading';

        // Parsear la definición JSON
        final parsedDefinitions = DefinitionParser.parseMultipleDefinitions(
          definitionRaw,
        );

        if (grouped.containsKey(key)) {
          // Agregar definiciones al entry existente
          grouped[key]!.meanings.addAll(parsedDefinitions);
        } else {
          // Crear nuevo entry
          grouped[key] = DictionaryEntry(
            headword: term,
            readings: [reading],
            meanings: parsedDefinitions,
            popularity: popularity,
            sequence: sequence,
          );
        }
      }

      return grouped.values.toList();
    } catch (e) {
      print('Error al buscar en el diccionario: $e');
      return [];
    }
  }

  /// No-op para compatibilidad con stub anterior
  Future<Directory> downloadAndExtract({String? url}) async {
    throw UnimplementedError('Dictionary download not implemented');
  }

  /// No-op para compatibilidad con stub anterior
  Future<void> update({String? url}) async {}

  /// No-op para compatibilidad con stub anterior
  void cancelImport() {}

  /// Cierra la base de datos
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
