import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/mood_entry.dart';
import 'models/crisis_plan.dart';

/// Servicio para gestión offline - guarda datos localmente cuando no hay conexión
class OfflineService {
  static const String _keyMoodEntries = 'offline_mood_entries';
  static const String _keyPendingSync = 'pending_sync';
  static const String _keyLastSync = 'last_sync';
  static const String _keyOfflineMode = 'offline_mode';

  /// Guardar entrada de humor offline
  static Future<void> saveMoodEntryOffline(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _getEntries(prefs);
    entries.add(entry.toMap());
    await prefs.setString(_keyMoodEntries, jsonEncode(entries));
    
    // Marcar como pendiente de sincronización
    await _markPendingSync(prefs);
  }

  /// Obtener entradas guardadas offline
  static Future<List<MoodEntry>> getOfflineEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _getEntries(prefs);
    return entries.map((e) => MoodEntry.fromMap(e)).toList();
  }

  /// Verificar si hay datos pendientes de sincronizar
  static Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_keyPendingSync) ?? [];
    return pending.isNotEmpty;
  }

  /// Marcar operación pendiente de sincronizar
  static Future<void> _markPendingSync(SharedPreferences prefs) async {
    final pending = prefs.getStringList(_keyPendingSync) ?? [];
    pending.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_keyPendingSync, pending);
  }

  /// Limpiar marca de sincronización pendiente
  static Future<void> clearPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPendingSync, []);
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Obtener timestamp de última sincronización
  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_keyLastSync);
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  /// Obtener número de entradas pendientes
  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_keyPendingSync) ?? [];
    return pending.length;
  }

  /// Guardar plan de crisis localmente
  static Future<void> saveCrisisPlanOffline(CrisisPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_crisis_plan', jsonEncode(plan.toMap()));
  }

  /// Obtener plan de crisis offline
  static Future<CrisisPlan?> getOfflineCrisisPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('offline_crisis_plan');
    if (data == null) return null;
    return CrisisPlan.fromMap(jsonDecode(data));
  }

  /// Limpiar todos los datos offline
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMoodEntries);
    await prefs.remove(_keyPendingSync);
    await prefs.remove('offline_crisis_plan');
  }

  /// Obtener entradas como lista de Maps
  static List<Map<String, dynamic>> _getEntries(SharedPreferences prefs) {
    final data = prefs.getString(_keyMoodEntries);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
