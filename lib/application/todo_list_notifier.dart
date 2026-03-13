import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

enum TaskFilter { inbox, today, project, context, recurring }

class TodoListNotifier extends ChangeNotifier {
  TodoRepository _repository;

  TodoFile? _todoFile;
  bool _isLoading = false;
  String? _error;
  TaskFilter _activeFilter = TaskFilter.inbox;
  String? _selectedProject;
  String? _selectedContext;

  TodoListNotifier(this._repository);

  TodoFile? get todoFile => _todoFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskFilter get activeFilter => _activeFilter;
  String? get selectedProject => _selectedProject;
  String? get selectedContext => _selectedContext;

  set activeFilter(TaskFilter value) {
    if (_activeFilter == value) return;

    _activeFilter = value;
    _selectedProject = null;
    _selectedContext = null;
    notifyListeners();
  }

  void selectProject(String project) {
    _activeFilter = TaskFilter.project;
    _selectedProject = project;
    _selectedContext = null;
    notifyListeners();
  }

  void selectContext(String context) {
    _activeFilter = TaskFilter.context;
    _selectedContext = context;
    _selectedProject = null;
    notifyListeners();
  }

  DateTime get _today {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  List<String> get allProjects {
    if (_todoFile == null) return [];

    return _todoFile!.allProjects(_today);
  }

  List<String> get allContexts {
    if (_todoFile == null) return [];

    return _todoFile!.allContexts(_today);
  }

  bool get hasRecurringTasks {
    if (_todoFile == null) return false;

    return _todoFile!.recurringTasks.isNotEmpty;
  }

  int get todayTaskCount {
    if (_todoFile == null) return 0;

    return _todoFile!.todayTasks(_today).length;
  }

  int get todayOnlyTaskCount => todayTaskCount - overdueTaskCount;

  int get overdueTaskCount {
    if (_todoFile == null) return 0;

    return _todoFile!.overdueTasks(_today).length;
  }

  List<TodoItem> get filteredTasks {
    if (_todoFile == null) return [];

    final today = _today;

    switch (_activeFilter) {
      case TaskFilter.inbox:
        return _todoFile!.visiblePendingTasks(today);
      case TaskFilter.today:
        return _todoFile!.todayTasks(today);
      case TaskFilter.project:
        if (_selectedProject == null) return [];
        return _todoFile!.tasksByProject(_selectedProject!, today);
      case TaskFilter.context:
        if (_selectedContext == null) return [];
        return _todoFile!.tasksByContext(_selectedContext!, today);
      case TaskFilter.recurring:
        return _todoFile!.recurringTasks;
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

  Future<void> addTask(String description,
      {DateTime? dueDate, DateTime? startDate, String? recurrence}) async {
    if (description.trim().isEmpty) return;
    if (_todoFile == null) return;

    _todoFile = _todoFile!.addTask(description,
        dueDate: dueDate, startDate: startDate, recurrence: recurrence);
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
