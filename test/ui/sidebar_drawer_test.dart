import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/widgets/sidebar_drawer.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

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
  StartOfWeek _stored = StartOfWeek.monday;
  String? _todoFilePath;

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
  }

  @override
  Future<String?> loadTodoFilePath() async => _todoFilePath;

  @override
  Future<void> saveTodoFilePath(String? path) async {
    _todoFilePath = path;
  }

  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  Future<AppThemeMode> loadThemeMode() async => _themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode value) async {
    _themeMode = value;
  }
}

Widget buildTestApp(TodoListNotifier notifier, SettingsNotifier settingsNotifier) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: notifier),
      ChangeNotifierProvider.value(value: settingsNotifier),
      Provider<String>.value(value: '/default/todo.txt'),
    ],
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        drawer: const SidebarDrawer(),
        body: const SizedBox(),
      ),
    ),
  );
}

void main() {
  late TodoListNotifier notifier;
  late SettingsNotifier settingsNotifier;

  setUp(() {
    notifier = TodoListNotifier(InMemoryTodoRepository());
    settingsNotifier = SettingsNotifier(InMemorySettingsRepository());
  });

  group('SidebarDrawer', () {
    testWidgets('shows Inbox and Today items', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('selecting Today changes active filter', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(notifier.activeFilter, TaskFilter.today);
    });

    testWidgets('selecting Inbox changes active filter', (tester) async {
      notifier.activeFilter = TaskFilter.today;

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      expect(notifier.activeFilter, TaskFilter.inbox);
    });

    testWidgets('closes drawer after selection', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('Inbox icon has blue color', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));

      expect(icon.color, Colors.blue);
    });

    testWidgets('Today icon has amber color', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.today));

      expect(icon.color, Colors.amber);
    });

    testWidgets('shows Settings option', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('tapping Settings navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('shows grey badge for today-only tasks', (tester) async {
      final todayStr = _formatDate(DateTime.now());
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Task 1', metadata: {'due': todayStr}),
          TodoItem(description: 'Task 2', metadata: {'due': todayStr}),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final badges = tester.widgetList<Badge>(find.byType(Badge)).toList();

      expect(badges.length, 1);
      expect(badges[0].backgroundColor, Colors.grey);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows separate red badge for overdue and grey for today',
        (tester) async {
      final todayStr = _formatDate(DateTime.now());
      final yesterdayStr =
          _formatDate(DateTime.now().subtract(const Duration(days: 1)));
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Today', metadata: {'due': todayStr}),
          TodoItem(description: 'Overdue', metadata: {'due': yesterdayStr}),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final badges = tester.widgetList<Badge>(find.byType(Badge)).toList();

      expect(badges.length, 2);
      expect(badges[0].backgroundColor, Colors.red);
      expect(badges[1].backgroundColor, Colors.grey);
    });

    testWidgets('shows only red badge when all tasks are overdue',
        (tester) async {
      final yesterdayStr =
          _formatDate(DateTime.now().subtract(const Duration(days: 1)));
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Overdue', metadata: {'due': yesterdayStr}),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final badges = tester.widgetList<Badge>(find.byType(Badge)).toList();

      expect(badges.length, 1);
      expect(badges[0].backgroundColor, Colors.red);
    });

    testWidgets('does not show badges when no tasks due', (tester) async {
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'No due'),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('shows My Projects section with project list',
        (tester) async {
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Task 1', projects: ['+Work']),
          TodoItem(description: 'Task 2', projects: ['+Home']),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('My Projects'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('tapping project selects project filter', (tester) async {
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Task 1', projects: ['+Work']),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(notifier.activeFilter, TaskFilter.project);
      expect(notifier.selectedProject, '+Work');
    });

    testWidgets('does not show My Projects when no projects', (tester) async {
      notifier = TodoListNotifier(InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'No project'),
        ]),
      ));
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier, settingsNotifier));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('My Projects'), findsNothing);
    });
  });
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
