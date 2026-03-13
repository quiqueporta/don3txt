import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/screens/debug_screen.dart';

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
  return ChangeNotifierProvider.value(
    value: notifier,
    child: const MaterialApp(
      home: DebugScreen(),
    ),
  );
}

void main() {
  late InMemoryTodoRepository repository;
  late TodoListNotifier notifier;

  setUp(() {
    repository = InMemoryTodoRepository(
      TodoFile([
        TodoItem(description: 'Task 1'),
        TodoItem(description: 'Task 2'),
      ]),
    );
    notifier = TodoListNotifier(repository);
  });

  group('DebugScreen', () {
    testWidgets('shows raw content in text field', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Task 1\nTask 2\n'), findsOneWidget);
    });

    testWidgets('has Debug title in app bar', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Debug'), findsOneWidget);
    });

    testWidgets('has save button in app bar', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('tapping save calls saveRawContent and pops', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifier,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebugScreen()),
                    );
                  },
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'New task from debug\n');
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(notifier.todoFile!.items.length, 1);
      expect(notifier.todoFile!.items[0].description, 'New task from debug');
      expect(find.byType(DebugScreen), findsNothing);
    });

    testWidgets('uses monospace font', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.style?.fontFamily, 'monospace');
    });

    testWidgets('does not wrap long lines', (tester) async {
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));

      final singleChildScrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );

      expect(singleChildScrollView.scrollDirection, Axis.horizontal);
    });
  });
}
