import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repository;
  StartOfWeek _startOfWeek = StartOfWeek.monday;
  String? _todoFilePath;
  AppThemeMode _themeMode = AppThemeMode.system;
  int _upcomingDays = 7;

  SettingsNotifier(this._repository);

  StartOfWeek get startOfWeek => _startOfWeek;
  String? get todoFilePath => _todoFilePath;
  AppThemeMode get themeMode => _themeMode;
  int get upcomingDays => _upcomingDays;

  Future<void> load() async {
    _startOfWeek = await _repository.loadStartOfWeek();
    _todoFilePath = await _repository.loadTodoFilePath();
    _themeMode = await _repository.loadThemeMode();
    _upcomingDays = await _repository.loadUpcomingDays();

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

  Future<void> setStartOfWeek(StartOfWeek value) async {
    _startOfWeek = value;
    notifyListeners();

    await _repository.saveStartOfWeek(value);
  }

  Future<void> setUpcomingDays(int value) async {
    _upcomingDays = value;
    notifyListeners();

    await _repository.saveUpcomingDays(value);
  }
}
