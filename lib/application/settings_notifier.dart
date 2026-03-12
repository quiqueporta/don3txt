import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repository;
  StartOfWeek _startOfWeek = StartOfWeek.monday;
  String? _todoFilePath;

  SettingsNotifier(this._repository);

  StartOfWeek get startOfWeek => _startOfWeek;
  String? get todoFilePath => _todoFilePath;

  Future<void> load() async {
    _startOfWeek = await _repository.loadStartOfWeek();
    _todoFilePath = await _repository.loadTodoFilePath();

    notifyListeners();
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
}
