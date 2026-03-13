import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';

abstract class SettingsRepository {
  Future<StartOfWeek> loadStartOfWeek();
  Future<void> saveStartOfWeek(StartOfWeek value);
  Future<String?> loadTodoFilePath();
  Future<void> saveTodoFilePath(String? path);
  Future<AppThemeMode> loadThemeMode();
  Future<void> saveThemeMode(AppThemeMode value);
  Future<int> loadUpcomingDays();
  Future<void> saveUpcomingDays(int value);
}
