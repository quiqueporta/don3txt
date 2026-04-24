import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const _todoFilePathKey = 'todo_file_path';
  static const _themeModeKey = 'theme_mode';
  static const _upcomingDaysKey = 'upcoming_days';
  static const _languageKey = 'language';
  static const _priorityColorsKey = 'priority_colors';

  @override
  Future<String?> loadTodoFilePath() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_todoFilePathKey);
  }

  @override
  Future<void> saveTodoFilePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();

    if (path == null) {
      await prefs.remove(_todoFilePathKey);
    } else {
      await prefs.setString(_todoFilePathKey, path);
    }
  }

  @override
  Future<AppThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);

    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(AppThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeModeKey, value.name);
  }

  @override
  Future<int> loadUpcomingDays() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_upcomingDaysKey) ?? 7;
  }

  @override
  Future<void> saveUpcomingDays(int value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_upcomingDaysKey, value);
  }

  @override
  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_languageKey);

    return AppLanguage.fromName(value);
  }

  @override
  Future<void> saveLanguage(AppLanguage value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_languageKey, value.name);
  }

  @override
  Future<PriorityColors> loadPriorityColors() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_priorityColorsKey);

    if (raw == null) return PriorityColors.defaults();

    return _parsePriorityColors(raw);
  }

  @override
  Future<void> savePriorityColors(PriorityColors value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_priorityColorsKey, jsonEncode(value.toMap()));
  }

  PriorityColors _parsePriorityColors(String raw) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return PriorityColors.defaults();

      final map = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is int) map[key] = value;
      });

      return PriorityColors.fromMap(map);
    } catch (_) {
      return PriorityColors.defaults();
    }
  }
}
