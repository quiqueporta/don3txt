import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/infrastructure/storage_permission.dart';
import 'package:don3txt/ui/app.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class InMemoryTodoRepository implements TodoRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  TodoFile _stored = TodoFile([]);

  @override
  Future<TodoFile> load() async => _stored;

  @override
  Future<void> save(TodoFile todoFile) async {
    _stored = todoFile;
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  final AppLanguage language;

  InMemorySettingsRepository(this.language);

  @override
  Future<String?> loadTodoFilePath() async => null;
  @override
  Future<void> saveTodoFilePath(String? path) async {}
  @override
  Future<AppThemeMode> loadThemeMode() async => AppThemeMode.light;
  @override
  Future<void> saveThemeMode(AppThemeMode value) async {}
  @override
  Future<int> loadUpcomingDays() async => 7;
  @override
  Future<void> saveUpcomingDays(int value) async {}
  @override
  Future<AppLanguage> loadLanguage() async => language;
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

class FakeStoragePermission implements StoragePermission {
  @override
  Future<bool> request() async => true;
}

void main() {
  testWidgets('Material widgets are translated to the selected language', (tester) async {
    await tester.pumpWidget(Don3txtApp(
      repository: InMemoryTodoRepository(),
      doneRepository: InMemoryTodoRepository(),
      settingsRepository: InMemorySettingsRepository(AppLanguage.spanish),
      storagePermission: FakeStoragePermission(),
      defaultFilePath: '/tmp/todo.txt',
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TaskListScreen));

    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Cancelar');
  });

  testWidgets('screens can use the storage permission given to the app', (tester) async {
    final storagePermission = FakeStoragePermission();

    await tester.pumpWidget(Don3txtApp(
      repository: InMemoryTodoRepository(),
      doneRepository: InMemoryTodoRepository(),
      settingsRepository: InMemorySettingsRepository(AppLanguage.english),
      storagePermission: storagePermission,
      defaultFilePath: '/tmp/todo.txt',
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TaskListScreen));

    expect(context.read<StoragePermission>(), same(storagePermission));
  });
}
