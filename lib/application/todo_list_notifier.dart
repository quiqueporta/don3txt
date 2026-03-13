import 'package:flutter/foundation.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

enum TaskFilter { inbox, today, upcoming, project, context, recurring }

class TodoListNotifier extends ChangeNotifier {
  TodoRepository _repository;

  TodoFile? _todoFile;
  bool _isLoading = false;
  String? _error;
  TaskFilter _activeFilter = TaskFilter.inbox;
  String? _selectedProject;
  String? _selectedContext;
  int _upcomingDays = 7;

  String _searchQuery = '';

  Set<String> _filterProjects = {};
  Set<String> _filterContexts = {};
  Set<String> _filterPriorities = {};

  TodoListNotifier(this._repository);

  TodoFile? get todoFile => _todoFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskFilter get activeFilter => _activeFilter;
  String? get selectedProject => _selectedProject;
  String? get selectedContext => _selectedContext;

  Set<String> get filterProjects => Set.unmodifiable(_filterProjects);
  Set<String> get filterContexts => Set.unmodifiable(_filterContexts);
  Set<String> get filterPriorities => Set.unmodifiable(_filterPriorities);

  String get searchQuery => _searchQuery;
  bool get hasActiveSearch => _searchQuery.isNotEmpty;

  bool get hasActiveFilters =>
      _filterProjects.isNotEmpty ||
      _filterContexts.isNotEmpty ||
      _filterPriorities.isNotEmpty;

  set activeFilter(TaskFilter value) {
    if (_activeFilter == value) return;

    _activeFilter = value;
    _selectedProject = null;
    _selectedContext = null;
    _searchQuery = '';
    _clearFiltersInternal();
    notifyListeners();
  }

  void selectProject(String project) {
    _activeFilter = TaskFilter.project;
    _selectedProject = project;
    _selectedContext = null;
    _searchQuery = '';
    notifyListeners();
  }

  void selectContext(String context) {
    _activeFilter = TaskFilter.context;
    _selectedContext = context;
    _selectedProject = null;
    _searchQuery = '';
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

  set upcomingDays(int value) {
    if (_upcomingDays == value) return;

    _upcomingDays = value;
    notifyListeners();
  }

  int get upcomingTaskCount {
    if (_todoFile == null) return 0;

    return _todoFile!.upcomingTasks(_today, _upcomingDays).length;
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

  List<TodoItem> get _unfilteredViewTasks {
    if (_todoFile == null) return [];

    final today = _today;

    switch (_activeFilter) {
      case TaskFilter.inbox:
        return _todoFile!.visiblePendingTasks(today);
      case TaskFilter.today:
        return _todoFile!.todayTasks(today);
      case TaskFilter.upcoming:
        return _todoFile!.upcomingTasks(today, _upcomingDays);
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

  static int _compareTasks(TodoItem a, TodoItem b) {
    final aPri = a.priority;
    final bPri = b.priority;
    if (aPri != null && bPri == null) return -1;
    if (aPri == null && bPri != null) return 1;
    if (aPri != null && bPri != null && aPri != bPri) {
      return aPri.compareTo(bPri);
    }

    final aDue = a.metadata['due'];
    final bDue = b.metadata['due'];
    if (aDue != null && bDue == null) return -1;
    if (aDue == null && bDue != null) return 1;
    if (aDue != null && bDue != null && aDue != bDue) {
      return aDue.compareTo(bDue);
    }

    final aCreation = a.creationDate;
    final bCreation = b.creationDate;
    if (aCreation != null && bCreation == null) return -1;
    if (aCreation == null && bCreation != null) return 1;
    if (aCreation != null && bCreation != null) {
      return aCreation.compareTo(bCreation);
    }

    return 0;
  }

  List<TodoItem> get filteredTasks {
    final tasks = List<TodoItem>.from(_unfilteredViewTasks)
      ..sort(_compareTasks);

    if (!hasActiveFilters && !hasActiveSearch) return tasks;

    final queryLower = _searchQuery.toLowerCase();

    return tasks.where((task) {
      if (_filterProjects.isNotEmpty &&
          !task.projects.any(_filterProjects.contains)) {
        return false;
      }

      if (_filterContexts.isNotEmpty &&
          !task.contexts.any(_filterContexts.contains)) {
        return false;
      }

      if (_filterPriorities.isNotEmpty &&
          !_filterPriorities.contains(task.priority)) {
        return false;
      }

      if (hasActiveSearch &&
          !task.description.toLowerCase().contains(queryLower)) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> get availableProjectsForView {
    final tasks = _unfilteredViewTasks;
    final projects = <String>{};

    for (final task in tasks) {
      projects.addAll(task.projects);
    }

    return projects.toList()..sort();
  }

  List<String> get availableContextsForView {
    final tasks = _unfilteredViewTasks;
    final contexts = <String>{};

    for (final task in tasks) {
      contexts.addAll(task.contexts);
    }

    return contexts.toList()..sort();
  }

  List<String> get availablePrioritiesForView {
    final tasks = _unfilteredViewTasks;
    final priorities = <String>{};

    for (final task in tasks) {
      if (task.priority != null) {
        priorities.add(task.priority!);
      }
    }

    return priorities.toList()..sort();
  }

  void toggleFilterProject(String project) {
    if (_filterProjects.contains(project)) {
      _filterProjects = Set.from(_filterProjects)..remove(project);
    } else {
      _filterProjects = Set.from(_filterProjects)..add(project);
    }

    notifyListeners();
  }

  void toggleFilterContext(String context) {
    if (_filterContexts.contains(context)) {
      _filterContexts = Set.from(_filterContexts)..remove(context);
    } else {
      _filterContexts = Set.from(_filterContexts)..add(context);
    }

    notifyListeners();
  }

  void toggleFilterPriority(String priority) {
    if (_filterPriorities.contains(priority)) {
      _filterPriorities = Set.from(_filterPriorities)..remove(priority);
    } else {
      _filterPriorities = Set.from(_filterPriorities)..add(priority);
    }

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';

    notifyListeners();
  }

  void clearFilters() {
    _clearFiltersInternal();
    notifyListeners();
  }

  void _clearFiltersInternal() {
    _filterProjects = {};
    _filterContexts = {};
    _filterPriorities = {};
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
      {DateTime? dueDate,
      DateTime? startDate,
      String? recurrence,
      String? priority}) async {
    if (description.trim().isEmpty) return;
    if (_todoFile == null) return;

    _todoFile = _todoFile!.addTask(description,
        dueDate: dueDate,
        startDate: startDate,
        recurrence: recurrence,
        priority: priority);
    notifyListeners();

    await _repository.save(_todoFile!);
  }

  String get rawContent => _todoFile?.serialize() ?? '';

  Future<void> saveRawContent(String content) async {
    final lines = content.split('\n');
    final items = <TodoItem>[];

    for (final line in lines) {
      final item = parseLine(line);
      if (item != null) {
        items.add(item);
      }
    }

    _todoFile = TodoFile(items);
    notifyListeners();

    await _repository.save(_todoFile!);
  }

  Future<void> updateTask(int index, TodoItem newItem) async {
    if (_todoFile == null) return;

    _todoFile = _todoFile!.updateTask(index, newItem);
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
