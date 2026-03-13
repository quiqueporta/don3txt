import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/widgets/task_tile.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';
import 'package:don3txt/ui/widgets/edit_task_field.dart';
import 'package:don3txt/ui/widgets/filter_bottom_sheet.dart';
import 'package:don3txt/ui/widgets/sidebar_drawer.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  String _titleFor(TodoListNotifier notifier) {
    switch (notifier.activeFilter) {
      case TaskFilter.inbox:
        return 'Inbox';
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.upcoming:
        return 'Upcoming';
      case TaskFilter.project:
        return notifier.selectedProject?.replaceFirst('+', '') ?? '';
      case TaskFilter.context:
        return notifier.selectedContext?.replaceFirst('@', '') ?? '';
      case TaskFilter.recurring:
        return 'Recurring';
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
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TodoListNotifier>(),
        child: const FilterBottomSheet(),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final notifier = context.read<TodoListNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTaskField(
        onSubmit: (text, {dueDate, startDate, recurrence}) {
          notifier.addTask(text,
              dueDate: dueDate,
              startDate: startDate,
              recurrence: recurrence);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditTaskSheet(
      BuildContext context, TodoListNotifier notifier, int originalIndex) {
    final item = notifier.todoFile!.items[originalIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditTaskField(
        item: item,
        onSave: (updatedItem) {
          notifier.updateTask(originalIndex, updatedItem);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();

    final showFilter = _supportsFiltering(notifier.activeFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(notifier)),
        actions: [
          if (showFilter)
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

  Widget _buildBody(TodoListNotifier notifier) {
    if (notifier.todoFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = notifier.filteredTasks;

    if (tasks.isEmpty && !notifier.hasActiveFilters) {
      return Center(
        child: Text(
          'No pending tasks',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (notifier.hasActiveFilters) _buildFilterChips(notifier),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No pending tasks',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final item = tasks[index];
                    final originalIndex =
                        notifier.todoFile!.items.indexOf(item);

                    return TaskTile(
                      item: item,
                      onToggle: () => notifier.toggleTask(originalIndex),
                      onTap: () => _showEditTaskSheet(
                          context, notifier, originalIndex),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
