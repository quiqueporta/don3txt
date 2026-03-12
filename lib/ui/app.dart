import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/ui/theme.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class Don3txtApp extends StatelessWidget {
  final TodoRepository repository;

  const Don3txtApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoListNotifier(repository)..loadTasks(),
      child: MaterialApp(
        title: 'don3txt',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const TaskListScreen(),
      ),
    );
  }
}
