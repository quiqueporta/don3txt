import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repository;
  String? _todoFilePath;
  AppThemeMode _themeMode = AppThemeMode.system;
  int _upcomingDays = 7;
  AppLanguage _language = AppLanguage.system;

  SettingsNotifier(this._repository);

  String? get todoFilePath => _todoFilePath;
  AppThemeMode get themeMode => _themeMode;
  int get upcomingDays => _upcomingDays;
  AppLanguage get language => _language;

  Future<void> load() async {
    _todoFilePath = await _repository.loadTodoFilePath();
    _themeMode = await _repository.loadThemeMode();
    _upcomingDays = await _repository.loadUpcomingDays();
    _language = await _repository.loadLanguage();

    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode value) async {
    _themeMode = value;
    notifyListeners();

    await _repository.saveThemeMode(value);
  }

  Future<void> setTodoFilePath(String? path) async {
    _todoFilePath = path;
    notifyListeners();

    await _repository.saveTodoFilePath(path);
  }

  Future<void> setUpcomingDays(int value) async {
    _upcomingDays = value;
    notifyListeners();

    await _repository.saveUpcomingDays(value);
  }

  Future<void> setLanguage(AppLanguage value) async {
    _language = value;
    notifyListeners();

    await _repository.saveLanguage(value);
  }
}
