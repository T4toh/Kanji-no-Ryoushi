import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/dictionary_entry.dart';
import 'definition_parser.dart';

/// JitendexService - Servicio para consultar el diccionario Jitendex desde SQLite
class JitendexService {
  static const String _databaseUrl =
      'https://github.com/T4toh/jitendex-parser/releases/download/v0.0.1/jitendex.db';

  Database? _database;

  JitendexService._();

  static Future<JitendexService> create({
    void Function(double progress)? onDownloadProgress,
  }) async {
    final service = JitendexService._();
    await service._initDatabase(onDownloadProgress: onDownloadProgress);
    return service;
  }

  /// Inicializa la base de datos descargándola o copiándola desde assets
  Future<void> _initDatabase({
    void Function(double progress)? onDownloadProgress,
  }) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "jitendex.db");

    // Verificar si la base de datos ya existe
    final exists = await databaseExists(path);

    if (!exists) {
      // Intentar descargar desde la URL
      try {
        await _downloadDatabase(path, onProgress: onDownloadProgress);
      } catch (e) {
        // Si falla la descarga, intentar copiar desde assets (fallback)
        try {
          await _copyFromAssets(path);
        } catch (assetError) {
          throw Exception(
            'No se pudo obtener el diccionario. Verifica tu conexión a internet.',
          );
        }
      }
    }

    // Abrir la base de datos en modo solo lectura
    _database = await openDatabase(path, readOnly: true);
  }

  /// Descarga la base de datos desde GitHub
  Future<void> _downloadDatabase(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Asegurar que el directorio existe
      await Directory(dirname(path)).create(recursive: true);

      // Hacer la petición HTTP
      final request = http.Request('GET', Uri.parse(_databaseUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Error al descargar: HTTP ${response.statusCode}');
      }

      // Obtener el tamaño total para el progreso
      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      int receivedBytes = 0;

      // Descargar en chunks y actualizar progreso
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = receivedBytes / contentLength;
          onProgress?.call(progress);
        }
      }

      // Escribir el archivo
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Copia la base de datos desde assets (fallback)
  Future<void> _copyFromAssets(String path) async {
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
      return [];
    }
  }

  /// No-op para compatibilidad con stub anterior
  Future<Directory> downloadAndExtract({String? url}) async {
    throw UnimplementedError('Use _downloadDatabase instead');
  }

  /// Fuerza la re-descarga del diccionario
  Future<void> update({String? url}) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "jitendex.db");

    // Cerrar la base de datos actual si está abierta
    await dispose();

    // Eliminar el archivo existente
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    // Descargar nuevamente
    await _downloadDatabase(path);

    // Reabrir la base de datos
    _database = await openDatabase(path, readOnly: true);
  }

  /// No-op para compatibilidad con stub anterior
  void cancelImport() {}

  /// Elimina la base de datos local (para testing)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "jitendex.db");

    await dispose();

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Cierra la base de datos
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
