import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class InMemoryTodoRepository implements TodoRepository {
  TodoFile _stored = TodoFile([]);

  InMemoryTodoRepository([TodoFile? initial]) {
    if (initial != null) _stored = initial;
  }

  @override
  Future<TodoFile> load() async => _stored;

  @override
  Future<void> save(TodoFile todoFile) async {
    _stored = todoFile;
  }
}

Widget buildTestApp(TodoListNotifier notifier) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: notifier,
      child: const TaskListScreen(),
    ),
  );
}

void main() {
  group('TaskListScreen', () {
    testWidgets('shows loading indicator when not yet loaded', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('No pending tasks'), findsOneWidget);
    });

    testWidgets('shows task list', (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Task 1'),
          TodoItem(description: 'Task 2'),
        ]),
      );
      final notifier = TodoListNotifier(repo);
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('shows only pending tasks', (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Pending'),
          TodoItem(description: 'Done', isCompleted: true),
        ]),
      );
      final notifier = TodoListNotifier(repo);
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('has FAB', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('has Inbox title', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Inbox'), findsOneWidget);
    });
  });
}
