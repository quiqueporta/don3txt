import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:don3txt/application/task_view.dart';
import 'package:don3txt/domain/tag.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class TodoListNotifier extends ChangeNotifier {
  TodoRepository _todoRepository;
  TodoRepository _doneRepository;

  TodoFile? _todoFile;
  TodoFile? _doneFile;
  bool _isLoading = false;
  String? _error;
  TaskView _activeView = const TodayView();
  int _upcomingDays = 7;
  List<TaskSortCriterion> _sortCriteria = defaultSortCriteria;

  String _searchQuery = '';

  Set<String> _filterProjects = {};
  Set<String> _filterContexts = {};
  Set<String> _filterPriorities = {};
  Set<Tag> _filterTags = {};

  StreamSubscription<void>? _todoChanges;
  StreamSubscription<void>? _doneChanges;
  bool _reloadPending = false;

  TodoListNotifier(this._todoRepository, this._doneRepository) {
    _followChanges();
  }

  @override
  void dispose() {
    _stopFollowingChanges();
    super.dispose();
  }

  void _followChanges() {
    _todoChanges = _followChangesOf(_todoRepository);
    _doneChanges = _followChangesOf(_doneRepository);
  }

  // Watching only keeps the list fresh; data stays safe without it because every change rereads the file first.
  StreamSubscription<void> _followChangesOf(TodoRepository repository) {
    return repository.changes.listen(
      (_) => _reloadAfterChange(),
      onError: (Object _) {},
    );
  }

  void _reloadAfterChange() {
    if (_isLoading) {
      _reloadPending = true;

      return;
    }

    loadTasks();
  }

  void _stopFollowingChanges() {
    _todoChanges?.cancel();
    _doneChanges?.cancel();
  }

  TodoFile? get todoFile => _todoFile;
  TodoFile? get doneFile => _doneFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskView get activeView => _activeView;

  bool isShowing(TaskView view) => _activeView == view;

  bool get activeViewAcceptsFilters => _activeView.acceptsFilters;

  DateTime? get dueDateForNewTasks => _activeView.dueDateForNewTasks(_today);

  Set<String> get projectsForNewTasks => _activeView.projectsForNewTasks;

  Set<String> get contextsForNewTasks => _activeView.contextsForNewTasks;

  Set<Tag> get tagsForNewTasks {
    if (_todoFile == null) return const {};

    return _activeView.tagsForNewTasks(_todoFile!);
  }

  Set<String> get filterProjects => Set.unmodifiable(_filterProjects);
  Set<String> get filterContexts => Set.unmodifiable(_filterContexts);
  Set<String> get filterPriorities => Set.unmodifiable(_filterPriorities);
  Set<Tag> get filterTags => Set.unmodifiable(_filterTags);

  String get searchQuery => _searchQuery;
  bool get hasActiveSearch => _searchQuery.isNotEmpty;

  bool get hasActiveFilters =>
      _filterProjects.isNotEmpty ||
      _filterContexts.isNotEmpty ||
      _filterPriorities.isNotEmpty ||
      _filterTags.isNotEmpty;

  void showView(TaskView view) {
    if (isShowing(view)) return;

    _activeView = view;
    _searchQuery = '';
    _clearFiltersInternal();
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

  List<Tag> get allTags {
    if (_todoFile == null) return [];

    return _todoFile!.allTags();
  }

  set upcomingDays(int value) {
    if (_upcomingDays == value) return;

    _upcomingDays = value;
    notifyListeners();
  }

  List<TaskSortCriterion> get sortCriteria => List.unmodifiable(_sortCriteria);

  void setSortCriteria(List<TaskSortCriterion> value) {
    if (listEquals(_sortCriteria, value)) return;

    _sortCriteria = List<TaskSortCriterion>.unmodifiable(value);
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

  bool get hasCompletedTasks {
    if (_doneFile == null) return false;

    return _doneFile!.items.isNotEmpty;
  }

  int get todayTaskCount {
    if (_todoFile == null) return 0;

    return _todoFile!.todayTasks(_today).length;
  }

  int get pastTaskCount {
    if (_todoFile == null) return 0;

    return _todoFile!.pastTasks(_today).length;
  }

  List<TodoItem> get _unfilteredViewTasks {
    if (_todoFile == null) return [];

    return _activeView.tasksFrom(
      _todoFile!,
      _doneFile ?? TodoFile([]),
      today: _today,
      upcomingDays: _upcomingDays,
    );
  }

  List<TodoItem> get filteredTasks {
    final comparator = _activeView.comparatorFor(_sortCriteria);
    final tasks = List<TodoItem>.from(_unfilteredViewTasks)
      ..sort(comparator);

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

      if (_filterTags.isNotEmpty &&
          !_filterTags.any((tag) => tag.isIn(task.metadata))) {
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

  List<Tag> get availableTagsForView => TodoFile(_unfilteredViewTasks).allTags();

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

  void toggleFilterTag(Tag tag) {
    if (_filterTags.contains(tag)) {
      _filterTags = Set.from(_filterTags)..remove(tag);
    } else {
      _filterTags = Set.from(_filterTags)..add(tag);
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
    _filterTags = {};
  }

  Future<void> switchRepository(
      TodoRepository todoRepository, TodoRepository doneRepository) async {
    _stopFollowingChanges();
    _todoRepository = todoRepository;
    _doneRepository = doneRepository;
    _followChanges();

    await loadTasks();
  }

  Future<void> loadTasks() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todoFile = await _todoRepository.load();
      _doneFile = await _doneRepository.load();

      _migrateCompletedToDone();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (_reloadPending) {
      _reloadPending = false;
      await loadTasks();
    }
  }

  Future<void> addTask(String description,
      {DateTime? dueDate,
      DateTime? startDate,
      String? recurrence,
      String? priority}) async {
    if (description.trim().isEmpty) return;
    if (_todoFile == null) return;

    final todoFile = await _todoRepository.load();

    _todoFile = todoFile.addTask(description,
        dueDate: dueDate,
        startDate: startDate,
        recurrence: recurrence,
        priority: priority);
    notifyListeners();

    await _todoRepository.save(_todoFile!);
  }

  String get rawContent => _todoFile?.serialize() ?? '';

  Future<bool> saveRawContent(String content,
      {required String editedFrom}) async {
    final todoFile = await _todoRepository.load();

    if (todoFile.serialize() != editedFrom) {
      _showCurrentFiles(todoFile);

      return false;
    }

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

    await _todoRepository.save(_todoFile!);

    return true;
  }

  Future<bool> updateTask(TodoItem original, TodoItem newItem) async {
    if (_todoFile == null) return false;

    final todoFile = await _todoRepository.load();

    if (!todoFile.contains(original)) {
      _showCurrentFiles(todoFile);

      return false;
    }

    _todoFile = todoFile.updateTask(original, newItem);
    notifyListeners();

    await _todoRepository.save(_todoFile!);

    return true;
  }

  Future<bool> deleteTask(TodoItem item) async {
    if (_todoFile == null) return false;

    final todoFile = await _todoRepository.load();

    if (!todoFile.contains(item)) {
      _showCurrentFiles(todoFile);

      return false;
    }

    _todoFile = todoFile.deleteTask(item);
    notifyListeners();

    await _todoRepository.save(_todoFile!);

    return true;
  }

  Future<void> insertTask(int index, TodoItem item) async {
    if (_todoFile == null) return;

    final todoFile = await _todoRepository.load();

    _todoFile = todoFile.insertTask(index, item);
    notifyListeners();

    await _todoRepository.save(_todoFile!);
  }

  Future<TodoItem?> toggleTask(TodoItem item) async {
    if (_todoFile == null || _doneFile == null) return null;

    final todoFile = await _todoRepository.load();
    final doneFile = await _doneRepository.load();

    if (!todoFile.contains(item)) {
      _showCurrentFiles(todoFile, doneFile);

      return null;
    }

    final result = todoFile.completeTask(item);

    final completedItems = result.items.where((i) => i.isCompleted).toList();
    final pendingItems = result.items.where((i) => !i.isCompleted).toList();

    _todoFile = TodoFile(pendingItems);
    _doneFile = TodoFile([...doneFile.items, ...completedItems]);
    notifyListeners();

    await _saveDoneThenTodo();

    return completedItems.isEmpty ? null : completedItems.first;
  }

  void _showCurrentFiles(TodoFile todoFile, [TodoFile? doneFile]) {
    _todoFile = todoFile;
    _doneFile = doneFile ?? _doneFile;
    notifyListeners();
  }

  // done.txt goes first: if the second write fails the task ends up in both files instead of in neither.
  Future<void> _saveDoneThenTodo() async {
    await _doneRepository.save(_doneFile!);
    await _todoRepository.save(_todoFile!);
  }

  Future<bool> uncompleteTask(TodoItem doneItem) async {
    if (_todoFile == null || _doneFile == null) return false;

    final todoFile = await _todoRepository.load();
    final doneFile = await _doneRepository.load();

    if (!doneFile.contains(doneItem)) {
      _showCurrentFiles(todoFile, doneFile);

      return false;
    }

    final restoredItem = doneItem.copyWith(
      isCompleted: false,
      completionDate: null,
    );

    _doneFile = doneFile.deleteTask(doneItem);
    _todoFile = TodoFile([...todoFile.items, restoredItem]);
    notifyListeners();

    await _todoRepository.save(_todoFile!);
    await _doneRepository.save(_doneFile!);

    return true;
  }

  void _migrateCompletedToDone() {
    if (_todoFile == null || _doneFile == null) return;

    final completed = _todoFile!.completedTasks;
    if (completed.isEmpty) return;

    _todoFile = TodoFile(_todoFile!.pendingTasks);
    _doneFile = TodoFile([..._doneFile!.items, ...completed]);

    _todoRepository.save(_todoFile!);
    _doneRepository.save(_doneFile!);
  }
}
