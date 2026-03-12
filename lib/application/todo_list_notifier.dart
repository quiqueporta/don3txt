import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

class TodoListNotifier extends ChangeNotifier {
  final TodoRepository _repository;

  TodoFile? _todoFile;
  bool _isLoading = false;
  String? _error;

  TodoListNotifier(this._repository);

  TodoFile? get todoFile => _todoFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todoFile = await _repository.load();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String description) async {
    if (description.trim().isEmpty) return;
    if (_todoFile == null) return;

    _todoFile = _todoFile!.addTask(description);
    notifyListeners();

    await _repository.save(_todoFile!);
  }

  Future<void> toggleTask(int index) async {
    if (_todoFile == null) return;

    _todoFile = _todoFile!.completeTask(index);
    notifyListeners();

    await _repository.save(_todoFile!);
  }
}
