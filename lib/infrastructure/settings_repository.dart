import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';

abstract class SettingsRepository {
  Future<String?> loadTodoFilePath();
  Future<void> saveTodoFilePath(String? path);
  Future<AppThemeMode> loadThemeMode();
  Future<void> saveThemeMode(AppThemeMode value);
  Future<int> loadUpcomingDays();
  Future<void> saveUpcomingDays(int value);
  Future<AppLanguage> loadLanguage();
  Future<void> saveLanguage(AppLanguage value);
  Future<PriorityColors> loadPriorityColors();
  Future<void> savePriorityColors(PriorityColors value);
}
