import 'package:shared_preferences/shared_preferences.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const _key = 'start_of_week';
  static const _todoFilePathKey = 'todo_file_path';
  static const _themeModeKey = 'theme_mode';
  static const _upcomingDaysKey = 'upcoming_days';

  @override
  Future<StartOfWeek> loadStartOfWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    if (value == 'sunday') return StartOfWeek.sunday;

    return StartOfWeek.monday;
  }

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key, value.name);
  }

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
}
