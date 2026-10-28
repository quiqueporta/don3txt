import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/text_size.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/application/task_view.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/infrastructure/storage_permission.dart';
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

  TextSize _textSize = TextSize.normal;

  @override
  Future<TextSize> loadTextSize() async => _textSize;

  @override
  Future<void> saveTextSize(TextSize value) async {
    _textSize = value;
  }
}

class InMemoryTodoRepository implements TodoRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<TodoFile> load() async => TodoFile([]);

  @override
  Future<void> save(TodoFile todoFile) async {}
}

class FakeStoragePermission implements StoragePermission {
  final bool granted;

  const FakeStoragePermission({required this.granted});

  @override
  Future<bool> request() async => granted;
}

class FakeFilePicker extends FilePickerPlatform {
  final String? directoryPath;
  bool directoryPickerOpened = false;

  FakeFilePicker(this.directoryPath);

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    directoryPickerOpened = true;

    return directoryPath;
  }
}

Widget buildTestApp(
  SettingsNotifier notifier, {
  StoragePermission storagePermission = const FakeStoragePermission(granted: true),
}) {
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
        Provider<StoragePermission>.value(value: storagePermission),
      ],
      child: const SettingsScreen(),
    ),
  );
}

Future<void> tapAndWaitUntil(
  WidgetTester tester,
  Finder target,
  bool Function() condition,
) async {
  await tester.runAsync(() => tester.tap(target));

  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }

  await tester.pumpAndSettle();
}

bool dialogIsShown() => find.byType(AlertDialog).evaluate().isNotEmpty;

bool Function() switchedToNewFile(WidgetTester tester, SettingsNotifier notifier) {
  return () {
    final todoList =
        tester.element(find.byType(SettingsScreen)).read<TodoListNotifier>();

    return notifier.todoFilePath != null && !todoList.isLoading;
  };
}

Widget buildTestAppPushedFromHome(
  SettingsNotifier notifier,
  TodoListNotifier todoListNotifier, {
  String defaultPath = '/default/todo.txt',
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: notifier),
      ChangeNotifierProvider.value(value: todoListNotifier),
      Provider<String>.value(value: defaultPath),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('open settings'),
            ),
          ),
        ),
      ),
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

    testWidgets('tapping a text size selects it and keeps it for the next launch',
        (tester) async {
      final repo = InMemorySettingsRepository();
      notifier = SettingsNotifier(repo);
      await notifier.load();

      await tester.pumpWidget(buildTestApp(notifier));
      await tester.scrollUntilVisible(find.text('Language'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Text size'), findsOneWidget);
      for (final option in ['Small', 'Normal', 'Large', 'Extra large']) {
        expect(find.text(option), findsOneWidget);
      }

      await tester.tap(find.text('Extra large'));
      await tester.pumpAndSettle();

      final nextLaunch = SettingsNotifier(repo);
      await nextLaunch.load();

      expect(notifier.textSize, TextSize.extraLarge);
      expect(nextLaunch.textSize, TextSize.extraLarge);
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
      await tester.scrollUntilVisible(find.text('System default'), 200,
          scrollable: find.byType(Scrollable).first);

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

    group('todo file switch', () {
      testWidgets(
          'selecting a folder switches to its todo.txt when storage permission is granted',
          (tester) async {
        final folder = Directory.systemTemp.createTempSync('don3txt_folder_');
        addTearDown(() => folder.deleteSync(recursive: true));
        FilePickerPlatform.instance = FakeFilePicker(folder.path);

        await tester.pumpWidget(buildTestApp(
          notifier,
          storagePermission: const FakeStoragePermission(granted: true),
        ));

        await tapAndWaitUntil(tester, find.text('Default'), dialogIsShown);

        expect(find.text('${folder.path}/todo.txt'), findsOneWidget);
        await tapAndWaitUntil(tester, find.text('OK'), switchedToNewFile(tester, notifier));

        expect(notifier.todoFilePath, '${folder.path}/todo.txt');
        expect(File('${folder.path}/todo.txt').existsSync(), isTrue);
      });

      testWidgets('uses an existing .todotxt file without changing its content',
          (tester) async {
        final folder = Directory.systemTemp.createTempSync('don3txt_custom_');
        addTearDown(() => folder.deleteSync(recursive: true));
        final file = File('${folder.path}/_TODO.todotxt');
        final settingsRepository = InMemorySettingsRepository();
        notifier = SettingsNotifier(settingsRepository);
        const content = '(A) Keep my Obsidian task +Vault\n';
        file.writeAsStringSync(content);
        FilePickerPlatform.instance = FakeFilePicker(folder.path);

        await tester.pumpWidget(buildTestApp(notifier));
        await tapAndWaitUntil(tester, find.text('Default'), dialogIsShown);
        await tester.enterText(find.byType(TextFormField), '_TODO.todotxt');
        await tester.pumpAndSettle();
        expect(find.text(file.path), findsOneWidget);

        await tapAndWaitUntil(tester, find.text('OK'), switchedToNewFile(tester, notifier));

        expect(notifier.todoFilePath, file.path);
        expect(file.readAsStringSync(), content);
        expect(File('${folder.path}/todo.txt').existsSync(), isFalse);
        final nextLaunch = SettingsNotifier(settingsRepository);
        await nextLaunch.load();
        expect(nextLaunch.todoFilePath, file.path);
      });

      testWidgets('cancelling the filename dialog leaves the folder untouched',
          (tester) async {
        final folder = Directory.systemTemp.createTempSync('don3txt_cancel_');
        addTearDown(() => folder.deleteSync(recursive: true));
        FilePickerPlatform.instance = FakeFilePicker(folder.path);
        await tester.pumpWidget(buildTestApp(notifier));
        await tapAndWaitUntil(tester, find.text('Default'), dialogIsShown);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(notifier.todoFilePath, isNull);
        expect(folder.listSync(), isEmpty);
      });

      testWidgets('an inaccessible file leaves the selected path unchanged',
          (tester) async {
        final folder = Directory.systemTemp.createTempSync('don3txt_error_');
        addTearDown(() => folder.deleteSync(recursive: true));
        Directory('${folder.path}/todo.txt').createSync();
        FilePickerPlatform.instance = FakeFilePicker(folder.path);
        await tester.pumpWidget(buildTestApp(notifier));
        await tapAndWaitUntil(tester, find.text('Default'), dialogIsShown);
        await tapAndWaitUntil(tester, find.text('OK'), () => find.byType(SnackBar).evaluate().isNotEmpty);

        expect(notifier.todoFilePath, isNull);
        expect(find.text('Unable to open this file for writing. '
            'Check the folder and storage permissions.'), findsOneWidget);
      });

      testWidgets('cancelling the folder picker does not ask for a filename',
          (tester) async {
        FilePickerPlatform.instance = FakeFilePicker(null);
        await tester.pumpWidget(buildTestApp(notifier));
        await tester.runAsync(() async {
          await tester.tap(find.text('Default'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(notifier.todoFilePath, isNull);
      });

      for (final name in [
        '', '.', '..', '../other.txt', 'sub/file.txt', r'sub\file.txt', 'done.txt',
      ]) {
        testWidgets('rejects invalid or reserved filename "$name"', (tester) async {
          FilePickerPlatform.instance = FakeFilePicker('/somewhere');
          await tester.pumpWidget(buildTestApp(notifier));
          await tester.tap(find.text('Default'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextFormField), name);
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(notifier.todoFilePath, isNull);
          expect(find.text('Enter a valid file name other than done.txt.'),
              findsOneWidget);
        });
      }

      testWidgets(
          'selecting a folder does not open the folder picker when storage permission is denied',
          (tester) async {
        final filePicker = FakeFilePicker('/somewhere');
        FilePickerPlatform.instance = filePicker;

        await tester.pumpWidget(buildTestApp(
          notifier,
          storagePermission: const FakeStoragePermission(granted: false),
        ));

        await tester.runAsync(() async {
          await tester.tap(find.text('Default'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(filePicker.directoryPickerOpened, false);
        expect(notifier.todoFilePath, isNull);
      });

      testWidgets(
          'reset to default switches active filter to inbox and pops settings',
          (tester) async {
        notifier = SettingsNotifier(InMemorySettingsRepository());
        await notifier.setTodoFilePath('/storage/custom/todo.txt');
        final todoListNotifier = TodoListNotifier(
          InMemoryTodoRepository(),
          InMemoryTodoRepository(),
        );
        await todoListNotifier.loadTasks();
        todoListNotifier.showView(const TodayView());

        await tester.pumpWidget(
          buildTestAppPushedFromHome(notifier, todoListNotifier),
        );
        await tester.tap(find.text('open settings'));
        await tester.pumpAndSettle();

        final restoreButton = find.widgetWithIcon(IconButton, Icons.restore);
        expect(restoreButton, findsOneWidget);

        await tester.tap(restoreButton);
        await tester.pumpAndSettle();

        expect(todoListNotifier.activeView, const InboxView());
        expect(find.byType(SettingsScreen), findsNothing);
      });
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
        await tester.ensureVisible(removeButtons);
        await tester.pumpAndSettle();

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
