import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/todo_file.dart';
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

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
  }
}

Widget buildTestApp(TodoListNotifier notifier, SettingsNotifier settingsNotifier) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: notifier),
      ChangeNotifierProvider.value(value: settingsNotifier),
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
  });
}
