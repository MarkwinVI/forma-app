import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WorkoutRestPreferencesService {
  static const _storageKey = 'workout_rest_intervals_v1';

  Future<Map<String, int>> loadRestIntervals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};

    return {
      for (final entry in decoded.entries)
        if (entry.value is num && (entry.value as num).toInt() > 0)
          entry.key: (entry.value as num).toInt(),
    };
  }

  Future<void> saveRestInterval(String exerciseId, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadRestIntervals();

    if (seconds <= 0) {
      current.remove(exerciseId);
    } else {
      current[exerciseId] = seconds;
    }

    await prefs.setString(_storageKey, jsonEncode(current));
  }
}
