import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/widgets/edit_task_field.dart';
import 'package:don3txt/ui/widgets/tag_picker_sheet.dart';

class InMemorySettingsRepository implements SettingsRepository {
  String? _todoFilePath;

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

  AppLanguage _language = AppLanguage.system;

  @override
  Future<AppLanguage> loadLanguage() async => _language;

  @override
  Future<void> saveLanguage(AppLanguage value) async {
    _language = value;
  }

  PriorityColors _priorityColors = PriorityColors.defaults();

  @override
  Future<PriorityColors> loadPriorityColors() async => _priorityColors;

  @override
  Future<void> savePriorityColors(PriorityColors value) async {
    _priorityColors = value;
  }
}

Widget buildTestApp({
  required TodoItem item,
  required void Function(TodoItem updatedItem) onSave,
}) {
  final settingsNotifier = SettingsNotifier(InMemorySettingsRepository());

  return ChangeNotifierProvider.value(
    value: settingsNotifier,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('shows existing projects as chips', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            projects: ['+Casa', '+Trabajo'],
          ),
          onSave: (_) {},
        ),
      );

      expect(find.text('+Casa'), findsOneWidget);
      expect(find.text('+Trabajo'), findsOneWidget);
    });

    testWidgets('shows existing contexts as chips', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            contexts: ['@oficina', '@telefono'],
          ),
          onSave: (_) {},
        ),
      );

      expect(find.text('@oficina'), findsOneWidget);
      expect(find.text('@telefono'), findsOneWidget);
    });

    testWidgets('does not include projects in text field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Buy milk',
            projects: ['+Casa'],
          ),
          onSave: (_) {},
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller!.text, 'Buy milk');
    });

    testWidgets('does not include contexts in text field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Call mom',
            contexts: ['@telefono'],
          ),
          onSave: (_) {},
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller!.text, 'Call mom');
    });

    testWidgets('saves projects from chips on submit', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            projects: ['+Casa'],
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.projects, contains('+Casa'));
    });

    testWidgets('saves contexts from chips on submit', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            contexts: ['@oficina'],
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.contexts, contains('@oficina'));
    });

    testWidgets('can remove project chip', (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            projects: ['+Casa'],
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('+Casa'), findsNothing);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.projects, isEmpty);
    });

    testWidgets('can remove context chip and saved contexts is empty',
        (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            contexts: ['@oficina'],
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('@oficina'), findsNothing);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.contexts, isEmpty);
    });

    testWidgets('opens TagPickerSheet for projects', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(TodoFile([
        TodoItem(description: 'Task', projects: ['+Casa', '+Trabajo']),
      ])), InMemoryTodoRepository(TodoFile([])));
      await notifier.loadTasks();

      await tester.pumpWidget(
        buildTestAppWithNotifier(
          item: TodoItem(description: 'Task', projects: ['+Casa']),
          onSave: (_) {},
          todoListNotifier: notifier,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tag));
      await tester.pumpAndSettle();

      expect(find.text('Projects'), findsOneWidget);
      expect(find.byType(TagPickerSheet), findsOneWidget);
    });

    testWidgets('opens TagPickerSheet for contexts', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(TodoFile([
        TodoItem(description: 'Task', contexts: ['@oficina']),
      ])), InMemoryTodoRepository(TodoFile([])));
      await notifier.loadTasks();

      await tester.pumpWidget(
        buildTestAppWithNotifier(
          item: TodoItem(description: 'Task'),
          onSave: (_) {},
          todoListNotifier: notifier,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.alternate_email));
      await tester.pumpAndSettle();

      expect(find.text('Contexts'), findsOneWidget);
      expect(find.byType(TagPickerSheet), findsOneWidget);
    });

    testWidgets('combines picker projects with typed projects on save',
        (tester) async {
      TodoItem? saved;

      await tester.pumpWidget(
        buildTestApp(
          item: TodoItem(
            description: 'Task',
            projects: ['+Casa'],
          ),
          onSave: (item) => saved = item,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Task +Trabajo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(saved!.projects, containsAll(['+Casa', '+Trabajo']));
    });
  });
}

class InMemoryTodoRepository implements TodoRepository {
  final TodoFile _file;

  InMemoryTodoRepository(this._file);

  @override
  Future<TodoFile> load() async => _file;

  @override
  Future<void> save(TodoFile todoFile) async {}
}

Widget buildTestAppWithNotifier({
  required TodoItem item,
  required void Function(TodoItem updatedItem) onSave,
  required TodoListNotifier todoListNotifier,
  SettingsNotifier? settingsNotifier,
}) {
  settingsNotifier ??= SettingsNotifier(InMemorySettingsRepository());

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settingsNotifier),
      ChangeNotifierProvider.value(value: todoListNotifier),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EditTaskField(item: item, onSave: onSave),
      ),
    ),
  );
}
