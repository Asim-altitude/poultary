import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


// ═══════════════════════════════════════════════════════════════════════════
//  ROUTINE PREFS
//  Key schema:
//    routine_status_{type}     → bool
//    routine_summary_{type}    → String
//    custom_routines_list      → JSON list of CustomRoutineEntry
//    farm_name                 → String
// ═══════════════════════════════════════════════════════════════════════════

class CustomRoutineEntry {
  final String id;
  final String name;
  final String emoji;
  final String summary;

  const CustomRoutineEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'id':      id,
        'name':    name,
        'emoji':   emoji,
        'summary': summary,
      };

  factory CustomRoutineEntry.fromJson(Map<String, dynamic> j) =>
      CustomRoutineEntry(
        id:      j['id'] as String,
        name:    j['name'] as String,
        emoji:   j['emoji'] as String,
        summary: j['summary'] as String,
      );
}

class RoutinePrefs {
  RoutinePrefs._();
  static RoutinePrefs get instance => _instance;
  static final _instance = RoutinePrefs._();

  static const _statusPrefix  = 'routine_status_';
  static const _summaryPrefix = 'routine_summary_';
  static const _customListKey = 'custom_routines_list';
  static const _farmNameKey   = 'farm_name';

  // ── Built-in routines ─────────────────────────────────────────────────

  Future<void> saveRoutine(String type, String summary) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_statusPrefix$type', true);
    await p.setString('$_summaryPrefix$type', summary);
  }

  Future<Map<String, bool>> loadAllStatuses(List<String> types) async {
    final p = await SharedPreferences.getInstance();
    return {for (final t in types) t: p.getBool('$_statusPrefix$t') ?? false};
  }

  Future<Map<String, String?>> loadAllSummaries(List<String> types) async {
    final p = await SharedPreferences.getInstance();
    return {for (final t in types) t: p.getString('$_summaryPrefix$t')};
  }

  Future<String?> loadSummary(String type) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('$_summaryPrefix$type');
  }

  Future<void> clearRoutine(String type) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('$_statusPrefix$type');
    await p.remove('$_summaryPrefix$type');
  }

  // ── Custom routines ───────────────────────────────────────────────────

  Future<void> saveCustomRoutine({
    required String id,
    required String name,
    required String emoji,
    required String summary,
  }) async {
    final list = await loadCustomRoutines();
    // Replace if id already exists (re-setup), otherwise append
    final idx = list.indexWhere((e) => e.id == id);
    final entry = CustomRoutineEntry(
        id: id, name: name, emoji: emoji, summary: summary);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _customListKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<CustomRoutineEntry>> loadCustomRoutines() async {
    final p    = await SharedPreferences.getInstance();
    final raw  = p.getString(_customListKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              CustomRoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteCustomRoutine(String id) async {
    final list = await loadCustomRoutines();
    list.removeWhere((e) => e.id == id);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _customListKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ── Farm name ─────────────────────────────────────────────────────────

  Future<String> getFarmName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_farmNameKey) ?? '';
  }

  Future<void> setFarmName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_farmNameKey, name);
  }
}
