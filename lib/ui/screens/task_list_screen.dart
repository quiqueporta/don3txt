import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/widgets/task_tile.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';
import 'package:don3txt/ui/widgets/edit_task_field.dart';
import 'package:don3txt/ui/widgets/filter_bottom_sheet.dart';
import 'package:don3txt/ui/widgets/sidebar_drawer.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  SettingsNotifier? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settings = context.read<SettingsNotifier>();
    if (_settings != settings) {
      _settings?.removeListener(_syncFromSettings);
      _settings = settings;
      _settings!.addListener(_syncFromSettings);
      _syncFromSettings();
    }
  }

  void _syncFromSettings() {
    final notifier = context.read<TodoListNotifier>();
    notifier.upcomingDays = _settings!.upcomingDays;
    notifier.setSortCriteria(_settings!.sortCriteria);
  }

  @override
  void dispose() {
    _settings?.removeListener(_syncFromSettings);
    _searchController.dispose();
    super.dispose();
  }

  String _titleFor(TodoListNotifier notifier, AppLocalizations loc) {
    switch (notifier.activeFilter) {
      case TaskFilter.inbox:
        return loc.inbox;
      case TaskFilter.today:
        return loc.today;
      case TaskFilter.upcoming:
        return loc.upcoming;
      case TaskFilter.project:
        return notifier.selectedProject?.replaceFirst('+', '') ?? '';
      case TaskFilter.context:
        return notifier.selectedContext?.replaceFirst('@', '') ?? '';
      case TaskFilter.recurring:
        return loc.recurring;
      case TaskFilter.completed:
        return loc.completed;
    }
  }

  bool _supportsFiltering(TaskFilter filter) {
    return filter == TaskFilter.inbox ||
        filter == TaskFilter.today ||
        filter == TaskFilter.upcoming;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TodoListNotifier>(),
        child: const FilterBottomSheet(),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final notifier = context.read<TodoListNotifier>();
    final settings = context.read<SettingsNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notifier),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: AddTaskField(
          initialDueDate: _defaultDueDateFor(notifier.activeFilter),
          initialProjects: _defaultProjectsFor(notifier),
          initialContexts: _defaultContextsFor(notifier),
          onSubmit: (text, {dueDate, startDate, recurrence, priority}) {
            notifier.addTask(text,
                dueDate: dueDate,
                startDate: startDate,
                recurrence: recurrence,
                priority: priority);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  DateTime? _defaultDueDateFor(TaskFilter filter) {
    if (filter != TaskFilter.today) return null;

    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  Set<String> _defaultProjectsFor(TodoListNotifier notifier) {
    if (notifier.activeFilter != TaskFilter.project) return const {};

    final project = notifier.selectedProject;

    return project == null ? const {} : {project};
  }

  Set<String> _defaultContextsFor(TodoListNotifier notifier) {
    if (notifier.activeFilter != TaskFilter.context) return const {};

    final ctx = notifier.selectedContext;

    return ctx == null ? const {} : {ctx};
  }

  void _showEditTaskSheet(
      BuildContext context, TodoListNotifier notifier, int originalIndex) {
    final item = notifier.todoFile!.items[originalIndex];
    final settings = context.read<SettingsNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notifier),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: EditTaskField(
          item: item,
          onSave: (updatedItem) {
            notifier.updateTask(originalIndex, updatedItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch(TodoListNotifier notifier) {
    notifier.clearSearch();
    _searchController.clear();

    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();
    final loc = AppLocalizations.of(context);

    if (_isSearching && !notifier.hasActiveSearch && _searchController.text.isNotEmpty) {
      _isSearching = false;
      _searchController.clear();
    }

    final showFilter = _supportsFiltering(notifier.activeFilter);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.searchHint,
                  border: InputBorder.none,
                ),
                onChanged: (text) => notifier.setSearchQuery(text),
              )
            : Text(_titleFor(notifier, loc)),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _stopSearch(notifier),
            ),
          if (!_isSearching && showFilter)
            IconButton(
              icon: Icon(
                notifier.hasActiveFilters
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              ),
              onPressed: () => _showFilterSheet(context),
            ),
        ],
      ),
      drawer: const SidebarDrawer(),
      body: _buildBody(notifier),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(TodoListNotifier notifier) {
    final chips = <Widget>[];

    for (final p in notifier.filterProjects) {
      chips.add(Chip(
        label: Text(p),
        onDeleted: () => notifier.toggleFilterProject(p),
        deleteIcon: const Icon(Icons.close, size: 18),
      ));
    }

    for (final c in notifier.filterContexts) {
      chips.add(Chip(
        label: Text(c),
        onDeleted: () => notifier.toggleFilterContext(c),
        deleteIcon: const Icon(Icons.close, size: 18),
      ));
    }

    for (final p in notifier.filterPriorities) {
      chips.add(Chip(
        label: Text('($p)'),
        onDeleted: () => notifier.toggleFilterPriority(p),
        deleteIcon: const Icon(Icons.close, size: 18),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(spacing: 8, children: chips),
    );
  }

  Future<void> _onRefresh(TodoListNotifier notifier) async {
    await notifier.loadTasks();

    if (notifier.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notifier.error!)),
      );
    }
  }

  Widget _buildScrollableEmptyState() {
    final loc = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              loc.noPendingTasks,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(TodoListNotifier notifier) {
    if (notifier.todoFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = notifier.filteredTasks;

    if (tasks.isEmpty && !notifier.hasActiveFilters && !notifier.hasActiveSearch) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(notifier),
        child: _buildScrollableEmptyState(),
      );
    }

    return Column(
      children: [
        if (notifier.hasActiveFilters) _buildFilterChips(notifier),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _onRefresh(notifier),
            child: tasks.isEmpty
                ? _buildScrollableEmptyState()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      final isCompletedView =
                          notifier.activeFilter == TaskFilter.completed;
                      final originalIndex = isCompletedView
                          ? notifier.doneFile!.items.indexOf(item)
                          : notifier.todoFile!.items.indexOf(item);

                      return TaskTile(
                        item: item,
                        priorityColors:
                            context.watch<SettingsNotifier>().priorityColors,
                        onToggle: () {
                          if (isCompletedView) {
                            notifier.uncompleteTask(originalIndex);
                          } else {
                            notifier.toggleTask(originalIndex);

                            final loc = AppLocalizations.of(context);

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.taskCompletedSnack),
                                action: SnackBarAction(
                                  label: loc.undo,
                                  onPressed: () {
                                    final doneItems = notifier.doneFile?.items ?? [];
                                    if (doneItems.isNotEmpty) {
                                      notifier.uncompleteTask(doneItems.length - 1);
                                    }
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        onTap: isCompletedView
                            ? null
                            : () => _showEditTaskSheet(
                                context, notifier, originalIndex),
                        onDelete: () {
                          final deletedItem = item;
                          final deletedIndex = originalIndex;
                          notifier.deleteTask(deletedIndex);

                          final loc = AppLocalizations.of(context);

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.taskDeletedSnack),
                              action: SnackBarAction(
                                label: loc.undo,
                                onPressed: () {
                                  notifier.insertTask(
                                      deletedIndex, deletedItem);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
