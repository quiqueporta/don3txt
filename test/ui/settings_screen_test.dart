import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
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
  });
}
