import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored = StartOfWeek.monday;
  String? _todoFilePath;

  InMemorySettingsRepository([StartOfWeek? initial]) {
    if (initial != null) _stored = initial;
  }

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

class InMemoryTodoRepository implements TodoRepository {
  @override
  Future<TodoFile> load() async => TodoFile([]);

  @override
  Future<void> save(TodoFile todoFile) async {}
}

Widget buildTestApp(SettingsNotifier notifier) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notifier),
        ChangeNotifierProvider(
          create: (_) => TodoListNotifier(InMemoryTodoRepository()),
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
    testWidgets('shows Monday and Sunday options', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('Monday is selected by default', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      final mondayRadio = tester.widget<RadioListTile<StartOfWeek>>(
        find.byWidgetPredicate(
          (w) => w is RadioListTile<StartOfWeek> && w.value == StartOfWeek.monday,
        ),
      );

      expect(mondayRadio.groupValue, StartOfWeek.monday);
    });

    testWidgets('tapping Sunday changes selection', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();

      expect(notifier.startOfWeek, StartOfWeek.sunday);
    });

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
  });
}
