import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

enum TaskFilter { inbox, today }

class TodoListNotifier extends ChangeNotifier {
  TodoRepository _repository;

  TodoFile? _todoFile;
  bool _isLoading = false;
  String? _error;
  TaskFilter _activeFilter = TaskFilter.inbox;

  TodoListNotifier(this._repository);

  TodoFile? get todoFile => _todoFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskFilter get activeFilter => _activeFilter;

  set activeFilter(TaskFilter value) {
    if (_activeFilter == value) return;

    _activeFilter = value;
    notifyListeners();
  }

  List<TodoItem> get filteredTasks {
    if (_todoFile == null) return [];

    switch (_activeFilter) {
      case TaskFilter.inbox:
        return _todoFile!.pendingTasks;
      case TaskFilter.today:
        final now = DateTime.now();
        return _todoFile!.todayTasks(DateTime(now.year, now.month, now.day));
    }
  }

  Future<void> switchRepository(TodoRepository repository) async {
    _repository = repository;

    await loadTasks();
  }

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

  Future<void> addTask(String description, {DateTime? dueDate}) async {
    if (description.trim().isEmpty) return;
    if (_todoFile == null) return;

    _todoFile = _todoFile!.addTask(description, dueDate: dueDate);
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
