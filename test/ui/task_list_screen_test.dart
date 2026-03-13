import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart' show TodoListNotifier, TaskFilter;
import 'package:don3txt/application/settings_notifier.dart';
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

class InMemorySettingsRepository implements SettingsRepository {
  @override
  Future<StartOfWeek> loadStartOfWeek() async => StartOfWeek.monday;
  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {}
  @override
  Future<String?> loadTodoFilePath() async => null;
  @override
  Future<void> saveTodoFilePath(String? path) async {}
  @override
  Future<AppThemeMode> loadThemeMode() async => AppThemeMode.system;
  @override
  Future<void> saveThemeMode(AppThemeMode value) async {}
  @override
  Future<int> loadUpcomingDays() async => 7;
  @override
  Future<void> saveUpcomingDays(int value) async {}
}

Widget buildTestApp(TodoListNotifier notifier) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notifier),
        ChangeNotifierProvider(
          create: (_) => SettingsNotifier(InMemorySettingsRepository()),
        ),
      ],
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

    testWidgets('shows Today title when filter is today', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.activeFilter = TaskFilter.today;

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('has a drawer', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('shows only today tasks when filter is today', (tester) async {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'No due'),
          TodoItem(description: 'Due today', metadata: {'due': todayStr}),
        ]),
      );
      final notifier = TodoListNotifier(repo);
      await notifier.loadTasks();
      notifier.activeFilter = TaskFilter.today;

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('No due'), findsNothing);
    });
  });
}
