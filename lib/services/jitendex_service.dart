import 'dart:io';

import '../models/dictionary_entry.dart';

/// Stubbed JitendexService - dictionary functionality has been disabled per user request.
/// This keeps the API surface so UI code can call the service but no heavy work is done.
class JitendexService {
  JitendexService._();

  static Future<JitendexService> create() async => JitendexService._();

  /// Always return false: no local DB is present in this stubbed mode.
  Future<bool> isAvailable() async => false;

  /// No-op download/extract. Throws to indicate operation is intentionally disabled.
  Future<Directory> downloadAndExtract({String? url}) async {
    throw UnimplementedError('Dictionary import disabled');
  }

  /// No-op update.
  Future<void> update({String? url}) async {}

  /// Search returns empty list in stub mode.
  Future<List<DictionaryEntry>> search(String q) async => [];

  /// Cancel import (no-op in stub)
  void cancelImport() {}
}
