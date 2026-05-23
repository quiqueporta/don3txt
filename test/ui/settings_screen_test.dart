import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

class InMemorySettingsRepository implements SettingsRepository {
  String? _todoFilePath;

  InMemorySettingsRepository();

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

  List<TaskSortCriterion> _sortCriteria = defaultSortCriteria;

  @override
  Future<List<TaskSortCriterion>> loadSortCriteria() async => _sortCriteria;

  @override
  Future<void> saveSortCriteria(List<TaskSortCriterion> value) async {
    _sortCriteria = value;
  }
}

class InMemoryTodoRepository implements TodoRepository {
  @override
  Future<TodoFile> load() async => TodoFile([]);

  @override
  Future<void> save(TodoFile todoFile) async {}
}

Widget buildTestApp(SettingsNotifier notifier) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notifier),
        ChangeNotifierProvider(
          create: (_) => TodoListNotifier(InMemoryTodoRepository(), InMemoryTodoRepository()),
        ),
        Provider<String>.value(value: '/default/todo.txt'),
      ],
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  late SettingsNotifier notifier;

  setUp(() {
    notifier = SettingsNotifier(InMemorySettingsRepository());
  });

  group('SettingsScreen', () {
    testWidgets('shows Settings as title', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows todo file tile with Default when no custom path', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Todo file'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('shows custom path when todoFilePath is set', (tester) async {
      final repo = InMemorySettingsRepository();
      notifier = SettingsNotifier(repo);
      await notifier.setTodoFilePath('/storage/emulated/0/todo.txt');

      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('/storage/emulated/0/todo.txt'), findsOneWidget);
    });

    testWidgets('shows theme options', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('System theme is selected by default', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      final systemRadio = tester.widget<RadioListTile<AppThemeMode>>(
        find.byWidgetPredicate(
          (w) => w is RadioListTile<AppThemeMode> && w.value == AppThemeMode.system,
        ),
      );

      expect(systemRadio.groupValue, AppThemeMode.system);
    });

    testWidgets('tapping Dark changes theme selection', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(notifier.themeMode, AppThemeMode.dark);
    });

    testWidgets('does not contain file selection options in UI', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Select existing file'), findsNothing);
      expect(find.text('Create new file'), findsNothing);
    });

    testWidgets('shows language options', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Português'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);
    });

    testWidgets('System language is selected by default', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      final systemRadio = tester.widget<RadioListTile<AppLanguage>>(
        find.byWidgetPredicate(
          (w) => w is RadioListTile<AppLanguage> && w.value == AppLanguage.system,
        ),
      );

      expect(systemRadio.groupValue, AppLanguage.system);
    });

    testWidgets('tapping French updates language selection', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Français'), 200,
          scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(notifier.language, AppLanguage.french);
    });

    testWidgets('shows priority colors section with a row per A-F letter',
        (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Priority colors'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Priority colors'), findsOneWidget);

      for (final letter in PriorityColors.supportedLetters) {
        await tester.scrollUntilVisible(
          find.text('Priority $letter'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Priority $letter'), findsOneWidget);
      }
    });

    testWidgets('tapping a priority row opens color picker sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Reset to defaults'), 200,
          scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('Priority A'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Choose a color'), findsOneWidget);
    });

    testWidgets('selecting a color in the sheet updates priorityColors',
        (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Reset to defaults'), 200,
          scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('Priority A'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final swatch = find.byKey(const ValueKey('priority_color_swatch_0'));
      expect(swatch, findsOneWidget);

      await tester.tap(swatch);
      await tester.pumpAndSettle();

      expect(notifier.priorityColors.colorFor('A'), isNotNull);
    });

    testWidgets('reset tile restores defaults', (tester) async {
      await notifier.setPriorityColor('A', 0xFF000000);

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Reset to defaults'), 200,
          scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();

      expect(notifier.priorityColors, PriorityColors.defaults());
    });

    group('task ordering section', () {
      testWidgets('shows section header and default criteria', (tester) async {
        await tester.pumpWidget(buildTestApp(notifier));
        await tester.scrollUntilVisible(find.text('Task ordering'), 200,
            scrollable: find.byType(Scrollable).first);

        expect(find.text('Task ordering'), findsOneWidget);
        expect(find.text('Priority'), findsWidgets);
        expect(find.text('Due date'), findsOneWidget);
        expect(find.text('Creation date'), findsOneWidget);
        expect(find.text('Threshold date'), findsNothing);
      });

      testWidgets('Add criterion offers only missing criteria',
          (tester) async {
        await tester.pumpWidget(buildTestApp(notifier));
        await tester.scrollUntilVisible(find.text('Add criterion'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.text('Add criterion'));
        await tester.pumpAndSettle();

        expect(find.text('Threshold date'), findsNothing);

        await tester.tap(find.text('Add criterion'));
        await tester.pumpAndSettle();

        expect(find.text('Threshold date'), findsOneWidget);
      });

      testWidgets('selecting a criterion appends it to the chain',
          (tester) async {
        await tester.pumpWidget(buildTestApp(notifier));
        await tester.scrollUntilVisible(find.text('Add criterion'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.text('Add criterion'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add criterion'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Threshold date'));
        await tester.pumpAndSettle();

        expect(notifier.sortCriteria.last,
            equals(TaskSortCriterion.threshold));
      });

      testWidgets('remove button drops a criterion', (tester) async {
        await tester.pumpWidget(buildTestApp(notifier));
        await tester.scrollUntilVisible(find.text('Task ordering'), 200,
            scrollable: find.byType(Scrollable).first);

        final removeButtons = find.byKey(
            const ValueKey('remove_sort_criterion_due'));

        expect(removeButtons, findsOneWidget);

        await tester.tap(removeButtons);
        await tester.pumpAndSettle();

        expect(notifier.sortCriteria.contains(TaskSortCriterion.due), isFalse);
      });

      testWidgets('remove button is hidden when only one criterion remains',
          (tester) async {
        await notifier.setSortCriteria([TaskSortCriterion.priority]);

        await tester.pumpWidget(buildTestApp(notifier));
        await tester.scrollUntilVisible(find.text('Task ordering'), 200,
            scrollable: find.byType(Scrollable).first);

        expect(
          find.byKey(const ValueKey('remove_sort_criterion_priority')),
          findsNothing,
        );
      });
    });
  });
}
