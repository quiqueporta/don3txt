import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/widgets/edit_task_field.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored;
  String? _todoFilePath;

  InMemorySettingsRepository([this._stored = StartOfWeek.monday]);

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

  @override
  Future<int> loadUpcomingDays() async => 7;

  @override
  Future<void> saveUpcomingDays(int value) async {}
}

Widget buildTestApp({
  required TodoItem item,
  required void Function(TodoItem updatedItem) onSave,
}) {
  final settingsNotifier = SettingsNotifier(InMemorySettingsRepository());

  return ChangeNotifierProvider.value(
    value: settingsNotifier,
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      home: Scaffold(
        body: EditTaskField(item: item, onSave: onSave),
      ),
    ),
  );
}

Future<void> confirmDatePicker(WidgetTester tester) async {
  final okButton = find.byWidgetPredicate(
    (widget) => widget is TextButton,
  );
  await tester.tap(okButton.last);
}

void main() {
  group('EditTaskField', () {
    testWidgets('renders text field with existing description', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Buy milk'),
          onSave: (_) {},
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller!.text, 'Buy milk');
    });

    testWidgets('shows existing due date as chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            metadata: {'due': '2026-03-20'},
          ),
          onSave: (_) {},
        ),
      );

      expect(find.text('2026-03-20'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('shows existing start date as chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            metadata: {'t': '2026-03-18'},
          ),
          onSave: (_) {},
        ),
      );

      expect(find.textContaining('2026-03-18'), findsOneWidget);
    });

    testWidgets('shows existing recurrence as chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            metadata: {'rec': '2w'},
          ),
          onSave: (_) {},
        ),
      );

      expect(find.textContaining('Every 2 weeks'), findsOneWidget);
    });

    testWidgets('calls onSave with updated description', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Original',
            creationDate: DateTime(2026, 3, 10),
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Updated');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.description, 'Updated');
    });

    testWidgets('preserves creationDate on save', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            creationDate: DateTime(2026, 3, 10),
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.creationDate, DateTime(2026, 3, 10));
    });

    testWidgets('preserves priority on save', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            priority: 'A',
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.priority, 'A');
    });

    testWidgets('preserves custom metadata on save', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            metadata: {'due': '2026-03-20', 'custom': 'value'},
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.metadata['custom'], 'value');
      expect(saved!.metadata['due'], '2026-03-20');
    });

    testWidgets('preserves custom tags in description on save',
        (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'My task next:'),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.description, 'My task next:');
    });

    testWidgets('can clear due date', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            metadata: {'due': '2026-03-20'},
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.metadata.containsKey('due'), false);
    });

    testWidgets('does not call onSave with empty description', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Task'),
          onSave: (item) => saved = item,
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved, isNull);
    });

    testWidgets('parses projects and contexts from edited description',
        (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Task'),
          onSave: (item) => saved = item,
        ),
      );

      await tester.enterText(
          find.byType(TextField), 'Updated +Work @office');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.description, 'Updated');
      expect(saved!.projects, ['+Work']);
      expect(saved!.contexts, ['@office']);
    });

    testWidgets('shows existing priority as chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Task', priority: 'A'),
          onSave: (_) {},
        ),
      );

      expect(find.text('(A)'), findsOneWidget);
    });

    testWidgets('can change priority', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Task', priority: 'A'),
          onSave: (item) => saved = item,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.flag));
      await tester.pumpAndSettle();
      await tester.tap(find.text('(B)'));
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.priority, 'B');
    });

    testWidgets('can clear priority', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(description: 'Task', priority: 'A'),
          onSave: (item) => saved = item,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.priority, isNull);
    });
  });
}
