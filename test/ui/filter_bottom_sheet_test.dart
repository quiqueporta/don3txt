import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/widgets/filter_bottom_sheet.dart';

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
}

Widget _buildConstrainedSheet(TodoListNotifier notifier, {double height = 220}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider.value(
      value: notifier,
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: const FilterBottomSheet(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FilterBottomSheet', () {
    testWidgets(
      'context chips remain reachable via scroll when many projects fill the height',
      (tester) async {
        final tasks = <TodoItem>[
          for (var i = 0; i < 30; i++)
            TodoItem(
              description: 'Task $i',
              projects: ['+Project${i.toString().padLeft(2, '0')}'],
            ),
          TodoItem(description: 'Phone task', contexts: ['@phone']),
        ];

        final notifier = TodoListNotifier(
          InMemoryTodoRepository(TodoFile(tasks)),
          InMemoryTodoRepository(),
        );
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        await tester.pumpWidget(_buildConstrainedSheet(notifier));
        await tester.pumpAndSettle();

        await tester.dragUntilVisible(
          find.widgetWithText(FilterChip, '@phone'),
          find.byType(FilterBottomSheet),
          const Offset(0, -80),
        );

        await tester.tap(find.widgetWithText(FilterChip, '@phone'));
        await tester.pumpAndSettle();

        expect(notifier.filterContexts.contains('@phone'), isTrue);
      },
    );
  });
}
