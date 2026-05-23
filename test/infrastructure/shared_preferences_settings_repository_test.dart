import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/infrastructure/shared_preferences_settings_repository.dart';

void main() {
  group('SharedPreferencesSettingsRepository', () {
    late SharedPreferencesSettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = SharedPreferencesSettingsRepository();
    });

    test('loadTodoFilePath returns null by default', () async {
      final result = await repository.loadTodoFilePath();

      expect(result, isNull);
    });

    test('saveTodoFilePath persists path', () async {
      await repository.saveTodoFilePath('/storage/todo.txt');

      final result = await repository.loadTodoFilePath();

      expect(result, '/storage/todo.txt');
    });

    test('saveTodoFilePath with null clears path', () async {
      await repository.saveTodoFilePath('/storage/todo.txt');
      await repository.saveTodoFilePath(null);

      final result = await repository.loadTodoFilePath();

      expect(result, isNull);
    });

    test('loadThemeMode returns system by default', () async {
      final result = await repository.loadThemeMode();

      expect(result, AppThemeMode.system);
    });

    test('saveThemeMode persists dark', () async {
      await repository.saveThemeMode(AppThemeMode.dark);

      final result = await repository.loadThemeMode();

      expect(result, AppThemeMode.dark);
    });

    test('saveThemeMode persists light', () async {
      await repository.saveThemeMode(AppThemeMode.light);

      final result = await repository.loadThemeMode();

      expect(result, AppThemeMode.light);
    });
    test('loadUpcomingDays returns 7 by default', () async {
      final result = await repository.loadUpcomingDays();

      expect(result, 7);
    });

    test('saveUpcomingDays persists value', () async {
      await repository.saveUpcomingDays(14);

      final result = await repository.loadUpcomingDays();

      expect(result, 14);
    });

    test('loadLanguage returns system by default', () async {
      final result = await repository.loadLanguage();

      expect(result, AppLanguage.system);
    });

    test('saveLanguage persists french', () async {
      await repository.saveLanguage(AppLanguage.french);

      final result = await repository.loadLanguage();

      expect(result, AppLanguage.french);
    });

    test('saveLanguage persists portuguese', () async {
      await repository.saveLanguage(AppLanguage.portuguese);

      final result = await repository.loadLanguage();

      expect(result, AppLanguage.portuguese);
    });

    test('loadPriorityColors returns defaults when nothing is stored',
        () async {
      final result = await repository.loadPriorityColors();

      expect(result, PriorityColors.defaults());
    });

    test('savePriorityColors persists custom colors', () async {
      final custom =
          PriorityColors.defaults().withColor('A', 0xFF001122);

      await repository.savePriorityColors(custom);

      final result = await repository.loadPriorityColors();

      expect(result, custom);
    });

    test('loadSortCriteria returns default chain when nothing stored',
        () async {
      final result = await repository.loadSortCriteria();

      expect(result, [
        TaskSortCriterion.priority,
        TaskSortCriterion.due,
        TaskSortCriterion.creation,
      ]);
    });

    test('saveSortCriteria round-trips the chain', () async {
      final chain = [
        TaskSortCriterion.due,
        TaskSortCriterion.priority,
        TaskSortCriterion.threshold,
      ];

      await repository.saveSortCriteria(chain);

      final result = await repository.loadSortCriteria();

      expect(result, chain);
    });

    test('loadSortCriteria falls back to default when stored value is invalid',
        () async {
      SharedPreferences.setMockInitialValues({'sort_criteria': 'foo,bar'});

      final result = await repository.loadSortCriteria();

      expect(result, [
        TaskSortCriterion.priority,
        TaskSortCriterion.due,
        TaskSortCriterion.creation,
      ]);
    });

    test('loadSortCriteria skips unknown entries while keeping known ones',
        () async {
      SharedPreferences.setMockInitialValues(
          {'sort_criteria': 'due,nope,priority'});

      final result = await repository.loadSortCriteria();

      expect(result, [TaskSortCriterion.due, TaskSortCriterion.priority]);
    });

    test('saveSortCriteria with empty list falls back to default on load',
        () async {
      await repository.saveSortCriteria([]);

      final result = await repository.loadSortCriteria();

      expect(result, [
        TaskSortCriterion.priority,
        TaskSortCriterion.due,
        TaskSortCriterion.creation,
      ]);
    });
  });
}
