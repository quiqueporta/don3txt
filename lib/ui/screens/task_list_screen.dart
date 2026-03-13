import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/widgets/task_tile.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';
import 'package:don3txt/ui/widgets/edit_task_field.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(notifier)),
      ),
      drawer: const SidebarDrawer(),
      body: _buildBody(notifier),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TodoListNotifier notifier) {
    if (notifier.todoFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = notifier.filteredTasks;

    if (tasks.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final item = tasks[index];
        final originalIndex = notifier.todoFile!.items.indexOf(item);

        return TaskTile(
          item: item,
          onToggle: () => notifier.toggleTask(originalIndex),
          onTap: () => _showEditTaskSheet(context, notifier, originalIndex),
        );
      },
    );
  }
}
