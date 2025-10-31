import 'package:shared_preferences/shared_preferences.dart';
import '../models/ocr_history_entry.dart';

/// Servicio para gestionar el historial de textos reconocidos
class HistoryService {
  static const String _historyKey = 'ocr_history';
  static const int _maxHistoryEntries = 50;

  /// Obtiene todas las entradas del historial
  Future<List<OCRHistoryEntry>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList(_historyKey) ?? [];

      return historyStrings
          .map((str) {
            try {
              return OCRHistoryEntry.fromJsonString(str);
            } catch (e) {
              return null;
            }
          })
          .whereType<OCRHistoryEntry>()
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  /// Agrega una nueva entrada al historial
  Future<void> addEntry(OCRHistoryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Agregar al inicio
      history.insert(0, entry);

      // Limitar el número de entradas
      if (history.length > _maxHistoryEntries) {
        history.removeRange(_maxHistoryEntries, history.length);
      }

      // Guardar
      final historyStrings = history.map((e) => e.toJsonString()).toList();
      await prefs.setStringList(_historyKey, historyStrings);
    } catch (e) {
      // Error al guardar, pero no bloqueamos la funcionalidad principal
    }
  }

  /// Elimina una entrada del historial
  Future<void> deleteEntry(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      history.removeWhere((entry) => entry.id == id);

      final historyStrings = history.map((e) => e.toJsonString()).toList();
      await prefs.setStringList(_historyKey, historyStrings);
    } catch (e) {
      // Error al eliminar
    }
  }

  /// Limpia todo el historial
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Error al limpiar
    }
  }
}
