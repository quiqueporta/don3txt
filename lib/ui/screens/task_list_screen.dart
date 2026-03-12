import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/widgets/task_tile.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  void _showAddTaskSheet(BuildContext context) {
    final notifier = context.read<TodoListNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTaskField(
        onSubmit: (text) {
          notifier.addTask(text);
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
        title: const Text('Inbox'),
      ),
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

    final pending = notifier.todoFile!.pendingTasks;

    if (pending.isEmpty) {
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
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final item = pending[index];
        final originalIndex = notifier.todoFile!.items.indexOf(item);

        return TaskTile(
          item: item,
          onToggle: () => notifier.toggleTask(originalIndex),
        );
      },
    );
  }
}
