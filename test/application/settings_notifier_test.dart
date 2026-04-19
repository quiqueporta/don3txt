import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';

class InMemorySettingsRepository implements SettingsRepository {
  String? _todoFilePath;
  AppThemeMode _themeMode = AppThemeMode.system;
  int _upcomingDays = 7;
  AppLanguage _language = AppLanguage.system;

  InMemorySettingsRepository({
    String? todoFilePath,
    AppThemeMode? themeMode,
    int? upcomingDays,
    AppLanguage? language,
  }) {
    _todoFilePath = todoFilePath;
    if (themeMode != null) _themeMode = themeMode;
    if (upcomingDays != null) _upcomingDays = upcomingDays;
    if (language != null) _language = language;
  }

  @override
  Future<String?> loadTodoFilePath() async => _todoFilePath;

  @override
  Future<void> saveTodoFilePath(String? path) async {
    _todoFilePath = path;
  }

  @override
  Future<AppThemeMode> loadThemeMode() async => _themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode value) async {
    _themeMode = value;
  }

  @override
  Future<int> loadUpcomingDays() async => _upcomingDays;

  @override
  Future<void> saveUpcomingDays(int value) async {
    _upcomingDays = value;
  }

  @override
  Future<AppLanguage> loadLanguage() async => _language;

  @override
  Future<void> saveLanguage(AppLanguage value) async {
    _language = value;
  }
}

void main() {
  late InMemorySettingsRepository repository;
  late SettingsNotifier notifier;

  setUp(() {
    repository = InMemorySettingsRepository();
    notifier = SettingsNotifier(repository);
  });

  group('SettingsNotifier', () {
    test('notifies listeners on load', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.load();

      expect(notified, true);
    });

    test('todoFilePath defaults to null', () {
      expect(notifier.todoFilePath, isNull);
    });

    test('load reads todoFilePath from repository', () async {
      repository = InMemorySettingsRepository(todoFilePath: '/storage/todo.txt');
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.todoFilePath, '/storage/todo.txt');
    });

    test('setTodoFilePath updates and persists', () async {
      await notifier.setTodoFilePath('/storage/todo.txt');

      expect(notifier.todoFilePath, '/storage/todo.txt');

      final persisted = await repository.loadTodoFilePath();
      expect(persisted, '/storage/todo.txt');
    });

    test('setTodoFilePath notifies listeners', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setTodoFilePath('/storage/todo.txt');

      expect(notified, true);
    });

    test('themeMode defaults to system', () {
      expect(notifier.themeMode, AppThemeMode.system);
    });

    test('load reads themeMode from repository', () async {
      repository = InMemorySettingsRepository(themeMode: AppThemeMode.dark);
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.themeMode, AppThemeMode.dark);
    });

    test('setThemeMode updates and persists', () async {
      await notifier.setThemeMode(AppThemeMode.light);

      expect(notifier.themeMode, AppThemeMode.light);

      final persisted = await repository.loadThemeMode();
      expect(persisted, AppThemeMode.light);
    });

    test('setThemeMode notifies listeners', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setThemeMode(AppThemeMode.dark);

      expect(notified, true);
    });

    test('upcomingDays defaults to 7', () {
      expect(notifier.upcomingDays, 7);
    });

    test('load reads upcomingDays from repository', () async {
      repository = InMemorySettingsRepository(upcomingDays: 14);
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.upcomingDays, 14);
    });

    test('setUpcomingDays updates and persists', () async {
      await notifier.setUpcomingDays(14);

      expect(notifier.upcomingDays, 14);

      final persisted = await repository.loadUpcomingDays();
      expect(persisted, 14);
    });

    test('setUpcomingDays notifies listeners', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setUpcomingDays(14);

      expect(notified, true);
    });

    test('language defaults to system', () {
      expect(notifier.language, AppLanguage.system);
    });

    test('load reads language from repository', () async {
      repository = InMemorySettingsRepository(language: AppLanguage.french);
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.language, AppLanguage.french);
    });

    test('setLanguage updates and persists', () async {
      await notifier.setLanguage(AppLanguage.italian);

      expect(notifier.language, AppLanguage.italian);

      final persisted = await repository.loadLanguage();
      expect(persisted, AppLanguage.italian);
    });

    test('setLanguage notifies listeners', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setLanguage(AppLanguage.portuguese);

      expect(notified, true);
    });
  });
}
