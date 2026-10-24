import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/text_size.dart';
import 'package:don3txt/domain/tag.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/task_view.dart';
import 'package:don3txt/application/todo_list_notifier.dart' show TodoListNotifier;
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class InMemoryTodoRepository implements TodoRepository {
  @override
  Stream<void> get changes => const Stream.empty();

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
  @override
  Future<AppLanguage> loadLanguage() async => AppLanguage.system;
  @override
  Future<void> saveLanguage(AppLanguage value) async {}
  @override
  Future<PriorityColors> loadPriorityColors() async =>
      PriorityColors.defaults();
  @override
  Future<void> savePriorityColors(PriorityColors value) async {}

  @override
  Future<List<TaskSortCriterion>> loadSortCriteria() async => defaultSortCriteria;

  @override
  Future<void> saveSortCriteria(List<TaskSortCriterion> value) async {}

  TextSize _textSize = TextSize.normal;

  @override
  Future<TextSize> loadTextSize() async => _textSize;

  @override
  Future<void> saveTextSize(TextSize value) async {
    _textSize = value;
  }
}

Widget buildTestApp(TodoListNotifier notifier) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
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
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const InboxView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('shows dividers between tasks', (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Task 1'),
          TodoItem(description: 'Task 2'),
          TodoItem(description: 'Task 3'),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const InboxView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('shows only pending tasks', (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Pending'),
          TodoItem(description: 'Done', isCompleted: true),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const InboxView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('has FAB', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB preloads due:today when filter is Today', (tester) async {
      final notifier = TodoListNotifier(
          InMemoryTodoRepository(), InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const TodayView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final todayStr = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      expect(find.text(todayStr), findsOneWidget);
    });

    testWidgets('FAB does not preload due when filter is Inbox',
        (tester) async {
      final notifier = TodoListNotifier(
          InMemoryTodoRepository(), InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const InboxView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('FAB preloads project chip when viewing a project',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([TodoItem(description: 'Task', projects: ['+Casa'])]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(ProjectView('+Casa'));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, '+Casa'), findsOneWidget);
    });

    testWidgets('FAB preloads the tag of the tag view and the new task gets it',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Ask Quique', metadata: {'waiting': 'quique'}),
          TodoItem(description: 'Ask Ana', metadata: {'waiting': 'ana'}),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(TagView(Tag('waiting', 'quique')));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, 'waiting:quique'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Send invoice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final created = notifier.todoFile!.items
          .firstWhere((item) => item.description == 'Send invoice');
      expect(created.metadata['waiting'], 'quique');
    });

    testWidgets('FAB preloads the only value of the key shown by a tag view',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'First', metadata: {'next': 'yes'}),
          TodoItem(description: 'Second', metadata: {'next': 'yes'}),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(TagView(Tag('next')));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, 'next:yes'), findsOneWidget);
    });

    testWidgets('FAB preloads no tag when the key shown has several values',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Ask Quique', metadata: {'waiting': 'quique'}),
          TodoItem(description: 'Ask Ana', metadata: {'waiting': 'ana'}),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(TagView(Tag('waiting')));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('removing the preloaded tag chip creates the task without it',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([
          TodoItem(description: 'Ask Quique', metadata: {'waiting': 'quique'}),
        ]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(TagView(Tag('waiting', 'quique')));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final removeTag = find.descendant(
        of: find.widgetWithText(Chip, 'waiting:quique'),
        matching: find.byIcon(Icons.close),
      );
      expect(removeTag, findsOneWidget);
      await tester.tap(removeTag);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, 'waiting:quique'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Send invoice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final created = notifier.todoFile!.items
          .firstWhere((item) => item.description == 'Send invoice');
      expect(created.metadata.containsKey('waiting'), isFalse);
    });

    testWidgets('FAB preloads context chip when viewing a context',
        (tester) async {
      final repo = InMemoryTodoRepository(
        TodoFile([TodoItem(description: 'Task', contexts: ['@oficina'])]),
      );
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(ContextView('@oficina'));

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, '@oficina'), findsOneWidget);
    });

    testWidgets('has Today title by default', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
      await notifier.loadTasks();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows Today title when filter is today', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const TodayView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
    });

    for (final (tag, title) in [
      (Tag('waiting'), 'waiting'),
      (Tag('waiting', 'quique'), 'waiting:quique'),
    ]) {
      testWidgets('shows $title as title when viewing that tag', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(TagView(tag));

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.text(title), findsOneWidget);
      });
    }

    testWidgets('has a drawer', (tester) async {
      final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
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
      final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
      await notifier.loadTasks();
      notifier.showView(const TodayView());

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.pump();

      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('No due'), findsNothing);
    });

    group('filter icon', () {
      testWidgets('shows filter icon in Inbox view', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task', projects: ['+Work'])]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });

      testWidgets('shows filter icon in Today view', (tester) async {
        final now = DateTime.now();
        final todayStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task', metadata: {'due': todayStr}),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const TodayView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });

      testWidgets('shows filter icon in Upcoming view', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const UpcomingView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });

      testWidgets('does NOT show filter icon in Project view', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task', projects: ['+Work'])]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(ProjectView('+Work'));

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.byIcon(Icons.filter_list_off), findsNothing);
      });

      testWidgets('does NOT show filter icon in Context view', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task', contexts: ['@home'])]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(ContextView('@home'));

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.byIcon(Icons.filter_list_off), findsNothing);
      });

      testWidgets('does NOT show filter icon in Recurring view', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const RecurringView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.byIcon(Icons.filter_list_off), findsNothing);
      });

      testWidgets('shows filled filter icon when filters active', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', projects: ['+Work']),
            TodoItem(description: 'Task 2', projects: ['+Home']),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.toggleFilterProject('+Work');

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      });
    });

    group('search', () {
      testWidgets('shows search icon in AppBar', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task 1')]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('tapping search icon shows TextField', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task 1')]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('typing text filters tasks', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Buy milk'),
            TodoItem(description: 'Call mom'),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'buy');
        await tester.pump();

        expect(find.text('Buy milk'), findsOneWidget);
        expect(find.text('Call mom'), findsNothing);
      });

      testWidgets('tapping close clears search and restores title',
          (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Buy milk'),
            TodoItem(description: 'Call mom'),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'buy');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(find.text('Inbox'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Buy milk'), findsOneWidget);
        expect(find.text('Call mom'), findsOneWidget);
      });

      testWidgets('search icon is available in all views', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task', projects: ['+Work'])]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(ProjectView('+Work'));

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('returning to the app', () {
      testWidgets('shows the tasks another device added while it was in the background',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await repo.save(TodoFile([
          TodoItem(description: 'Buy milk'),
          TodoItem(description: 'Buy bread'),
        ]));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(find.text('Buy bread'), findsOneWidget);
      });
    });

    group('task changed on another device', () {
      testWidgets(
          'completing a task edited elsewhere warns and shows the current tasks',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();
        await repo.save(TodoFile([TodoItem(description: 'Buy oat milk')]));

        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pumpAndSettle();

        expect(find.text('This task was changed on another device'),
            findsOneWidget);
        expect(find.text('Buy oat milk'), findsOneWidget);
        expect(find.text('Task completed'), findsNothing);
      });

      testWidgets(
          'deleting a task edited elsewhere warns and keeps the current tasks',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();
        await repo.save(TodoFile([TodoItem(description: 'Buy oat milk')]));

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('This task was changed on another device'),
            findsOneWidget);
        expect(find.text('Buy oat milk'), findsOneWidget);
        expect(find.text('Task deleted'), findsNothing);
      });

      testWidgets('editing a task edited elsewhere warns and keeps the other version',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();
        await repo.save(TodoFile([TodoItem(description: 'Buy oat milk')]));

        await tester.tap(find.text('Buy milk'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'Buy soy milk');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('This task was changed on another device'),
            findsOneWidget);
        expect(find.text('Buy oat milk'), findsOneWidget);
        expect(find.text('Buy soy milk'), findsNothing);
      });

      testWidgets(
          'restoring a completed task removed elsewhere warns and shows the current tasks',
          (tester) async {
        final doneTask = TodoItem(
          description: 'Done task',
          isCompleted: true,
          completionDate: DateTime(2026, 3, 10),
        );
        final doneRepo = InMemoryTodoRepository(TodoFile([doneTask]));
        final notifier = TodoListNotifier(InMemoryTodoRepository(), doneRepo);
        await notifier.loadTasks();
        notifier.showView(const CompletedView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();
        await doneRepo.save(TodoFile([]));

        await tester.tap(find.byIcon(Icons.check_circle));
        await tester.pumpAndSettle();

        expect(find.text('This task was changed on another device'),
            findsOneWidget);
        expect(notifier.todoFile!.items, isEmpty);
      });
    });

    group('task deletion snackbar', () {
      testWidgets('snackbar disappears on its own after a while',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('Task deleted'), findsNothing);
      });
    });

    group('task completion snackbar', () {
      testWidgets('shows snackbar with undo when completing a task',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pump();

        expect(find.text('Task completed'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
      });

      testWidgets('snackbar disappears on its own after a while',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('Task completed'), findsNothing);
      });

      testWidgets(
          'snackbar disappears on its own when an accessibility service is active',
          (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('Task completed'), findsNothing);
      });

      testWidgets('tapping undo restores the task', (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Buy milk')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.radio_button_unchecked));
        await tester.pump();

        expect(find.text('Buy milk'), findsNothing);

        await tester.pump(const Duration(milliseconds: 750));
        await tester.tap(find.text('Undo'));
        await tester.pump();
        await tester.pump();

        expect(notifier.todoFile!.items[0].isCompleted, false);
        expect(find.text('Buy milk'), findsOneWidget);
      });

      testWidgets('does not show snackbar when uncompleting a task',
          (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Done task',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 10),
            ),
          ]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const CompletedView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.check_circle));
        await tester.pump();

        expect(find.text('Task completed'), findsNothing);
      });
    });

    group('pull-to-refresh', () {
      testWidgets('RefreshIndicator is present with tasks loaded', (tester) async {
        final repo = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task 1')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('RefreshIndicator is present on empty list', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
        await notifier.loadTasks();

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('empty list is scrollable for pull-to-refresh', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository());
        await notifier.loadTasks();

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('pull-to-refresh triggers loadTasks', (tester) async {
        final repo = _CountingRepository(
          TodoFile([TodoItem(description: 'Task 1')]),
        );
        final notifier = TodoListNotifier(repo, InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.showView(const InboxView());

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        final initialLoadCount = repo.loadCallCount;

        await tester.fling(find.text('Task 1'), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(repo.loadCallCount, greaterThan(initialLoadCount));
      });
    });

    group('filter chips', () {
      testWidgets('shows chips when filters are active', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', projects: ['+Work']),
            TodoItem(description: 'Task 2', projects: ['+Home']),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.toggleFilterProject('+Work');

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byType(Chip), findsOneWidget);
        expect(find.text('+Work'), findsOneWidget);
      });

      testWidgets('dismissing chip removes filter', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', projects: ['+Work']),
            TodoItem(description: 'Task 2', projects: ['+Home']),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.toggleFilterProject('+Work');

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(notifier.hasActiveFilters, false);
        expect(find.byType(Chip), findsNothing);
      });

      testWidgets('shows multiple chips for different filter types', (tester) async {
        final notifier = TodoListNotifier(InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Task',
              projects: ['+Work'],
              contexts: ['@email'],
              priority: 'A',
            ),
          ]),
        ), InMemoryTodoRepository());
        await notifier.loadTasks();
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterContext('@email');
        notifier.toggleFilterPriority('A');

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.pump();

        expect(find.byType(Chip), findsNWidgets(3));
      });
    });
  });
}

class _CountingRepository implements TodoRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  TodoFile _stored;
  int loadCallCount = 0;

  _CountingRepository(this._stored);

  @override
  Future<TodoFile> load() async {
    loadCallCount++;

    return _stored;
  }

  @override
  Future<void> save(TodoFile todoFile) async {
    _stored = todoFile;
  }
}
