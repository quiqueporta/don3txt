import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/application/todo_list_notifier.dart';

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

void main() {
  late InMemoryTodoRepository repository;
  late TodoListNotifier notifier;

  setUp(() {
    repository = InMemoryTodoRepository();
    notifier = TodoListNotifier(repository);
  });

  group('TodoListNotifier', () {
    test('initial state is loading with no tasks', () {
      expect(notifier.isLoading, false);
      expect(notifier.todoFile, isNull);
      expect(notifier.error, isNull);
    });

    test('loadTasks loads from repository', () async {
      repository = InMemoryTodoRepository(
        TodoFile([TodoItem(description: 'Task 1')]),
      );
      notifier = TodoListNotifier(repository);

      await notifier.loadTasks();

      expect(notifier.todoFile, isNotNull);
      expect(notifier.todoFile!.items.length, 1);
      expect(notifier.todoFile!.items[0].description, 'Task 1');
      expect(notifier.isLoading, false);
    });

    test('loadTasks sets error on failure', () async {
      notifier = TodoListNotifier(_FailingRepository());

      await notifier.loadTasks();

      expect(notifier.error, isNotNull);
      expect(notifier.isLoading, false);
    });

    test('addTask adds and persists', () async {
      await notifier.loadTasks();
      await notifier.addTask('Buy milk');

      expect(notifier.todoFile!.items.length, 1);
      expect(notifier.todoFile!.items[0].description, 'Buy milk');

      final reloaded = await repository.load();
      expect(reloaded.items.length, 1);
    });

    test('addTask with dueDate persists metadata', () async {
      await notifier.loadTasks();
      await notifier.addTask('Buy milk', dueDate: DateTime(2026, 3, 20));

      expect(notifier.todoFile!.items[0].metadata['due'], '2026-03-20');

      final reloaded = await repository.load();
      expect(reloaded.items[0].metadata['due'], '2026-03-20');
    });

    test('addTask does nothing for empty string', () async {
      await notifier.loadTasks();
      await notifier.addTask('');

      expect(notifier.todoFile!.items, isEmpty);
    });

    test('toggleTask completes and persists', () async {
      repository = InMemoryTodoRepository(
        TodoFile([TodoItem(description: 'Task 1')]),
      );
      notifier = TodoListNotifier(repository);
      await notifier.loadTasks();

      await notifier.toggleTask(0);

      expect(notifier.todoFile!.items[0].isCompleted, true);

      final reloaded = await repository.load();
      expect(reloaded.items[0].isCompleted, true);
    });

    test('toggleTask uncompletes completed task', () async {
      repository = InMemoryTodoRepository(
        TodoFile([
          TodoItem(
            description: 'Task 1',
            isCompleted: true,
            completionDate: DateTime(2011, 3, 3),
          ),
        ]),
      );
      notifier = TodoListNotifier(repository);
      await notifier.loadTasks();

      await notifier.toggleTask(0);

      expect(notifier.todoFile!.items[0].isCompleted, false);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      await notifier.loadTasks();
      await notifier.addTask('Task 1');

      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    group('switchRepository', () {
      test('loads tasks from new repository', () async {
        await notifier.loadTasks();

        final newRepository = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'New task')]),
        );

        await notifier.switchRepository(newRepository);

        expect(notifier.todoFile!.items.length, 1);
        expect(notifier.todoFile!.items[0].description, 'New task');
      });

      test('notifies listeners', () async {
        await notifier.loadTasks();
        var notified = false;
        notifier.addListener(() => notified = true);

        final newRepository = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'New task')]),
        );

        await notifier.switchRepository(newRepository);

        expect(notified, true);
      });
    });

    group('activeFilter', () {
      test('defaults to today', () {
        expect(notifier.activeFilter, TaskFilter.today);
      });

      test('can be changed to inbox', () {
        notifier.activeFilter = TaskFilter.inbox;

        expect(notifier.activeFilter, TaskFilter.inbox);
      });

      test('notifies listeners when changed', () {
        var notified = false;
        notifier.addListener(() => notified = true);

        notifier.activeFilter = TaskFilter.inbox;

        expect(notified, true);
      });

      test('does not notify when set to same value', () {
        var notifyCount = 0;
        notifier.addListener(() => notifyCount++);

        notifier.activeFilter = TaskFilter.today;

        expect(notifyCount, 0);
      });
    });

    group('filteredTasks', () {
      test('returns pendingTasks when filter is inbox', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1'),
            TodoItem(description: 'Task 2', metadata: {'due': '2026-03-12'}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result.length, 2);
      });

      test('returns todayTasks when filter is today', () async {
        final now = DateTime.now();
        final todayStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowStr =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No due'),
            TodoItem(description: 'Due today', metadata: {'due': todayStr}),
            TodoItem(
                description: 'Due tomorrow',
                metadata: {'due': tomorrowStr}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.today;

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Due today');
      });

      test('returns empty when no file loaded', () {
        expect(notifier.filteredTasks, isEmpty);
      });

      test('includes overdue tasks when filter is today', () async {
        final now = DateTime.now();
        final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
        final todayStr = _formatDate(now);
        final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
                description: 'Overdue', metadata: {'due': yesterdayStr}),
            TodoItem(
                description: 'Due today', metadata: {'due': todayStr}),
            TodoItem(
                description: 'Due tomorrow', metadata: {'due': tomorrowStr}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.today;

        final result = notifier.filteredTasks;

        expect(result.length, 2);
      });
    });

    group('todayTaskCount', () {
      test('returns count of today and overdue tasks', () async {
        final now = DateTime.now();
        final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
        final todayStr = _formatDate(now);
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No due'),
            TodoItem(
                description: 'Overdue', metadata: {'due': yesterdayStr}),
            TodoItem(
                description: 'Due today', metadata: {'due': todayStr}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.todayTaskCount, 2);
      });

      test('returns 0 when no file loaded', () {
        expect(notifier.todayTaskCount, 0);
      });
    });

    group('overdueTaskCount', () {
      test('returns count of overdue tasks only', () async {
        final now = DateTime.now();
        final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
        final todayStr = _formatDate(now);
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
                description: 'Overdue', metadata: {'due': yesterdayStr}),
            TodoItem(
                description: 'Due today', metadata: {'due': todayStr}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.overdueTaskCount, 1);
      });

      test('returns 0 when no file loaded', () {
        expect(notifier.overdueTaskCount, 0);
      });
    });

    group('allProjects', () {
      test('returns projects from pending tasks', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', projects: ['+Work']),
            TodoItem(description: 'Task 2', projects: ['+Home']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.allProjects, ['+Home', '+Work']);
      });

      test('returns empty when no file loaded', () {
        expect(notifier.allProjects, isEmpty);
      });
    });

    group('project filter', () {
      test('filters tasks by project', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', projects: ['+Work']),
            TodoItem(description: 'Task 2', projects: ['+Home']),
            TodoItem(description: 'Task 3', projects: ['+Work']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.selectProject('+Work');

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(notifier.activeFilter, TaskFilter.project);
        expect(notifier.selectedProject, '+Work');
      });

      test('title returns project name without prefix', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task', projects: ['+Work']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.selectProject('+Work');

        expect(notifier.selectedProject, '+Work');
      });
    });

    group('allContexts', () {
      test('returns contexts from pending tasks', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', contexts: ['@phone']),
            TodoItem(description: 'Task 2', contexts: ['@home']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.allContexts, ['@home', '@phone']);
      });

      test('returns empty when no file loaded', () {
        expect(notifier.allContexts, isEmpty);
      });
    });

    group('recurring filter', () {
      test('filteredTasks returns recurring tasks when filter is recurring',
          () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Normal task'),
            TodoItem(description: 'Recurring', metadata: {'rec': '1w'}),
            TodoItem(
              description: 'Future recurring',
              metadata: {'rec': '1m', 't': '2099-01-01'},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.recurring;

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(result[0].description, 'Recurring');
        expect(result[1].description, 'Future recurring');
      });
    });

    group('rawContent', () {
      test('returns serialized content of todoFile', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1'),
            TodoItem(description: 'Task 2'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.rawContent, 'Task 1\nTask 2\n');
      });

      test('returns empty string when no file loaded', () {
        expect(notifier.rawContent, '');
      });
    });

    group('saveRawContent', () {
      test('parses raw text and updates todoFile', () async {
        await notifier.loadTasks();

        await notifier.saveRawContent('Buy milk\n(A) Call mom +Family @phone\n');

        expect(notifier.todoFile!.items.length, 2);
        expect(notifier.todoFile!.items[0].description, 'Buy milk');
        expect(notifier.todoFile!.items[1].description, 'Call mom');
        expect(notifier.todoFile!.items[1].priority, 'A');
        expect(notifier.todoFile!.items[1].projects, ['+Family']);
        expect(notifier.todoFile!.items[1].contexts, ['@phone']);
      });

      test('persists to repository', () async {
        await notifier.loadTasks();

        await notifier.saveRawContent('Task from raw\n');

        final reloaded = await repository.load();
        expect(reloaded.items.length, 1);
        expect(reloaded.items[0].description, 'Task from raw');
      });

      test('notifies listeners', () async {
        await notifier.loadTasks();
        var notified = false;
        notifier.addListener(() => notified = true);

        await notifier.saveRawContent('New task\n');

        expect(notified, true);
      });

      test('skips empty lines', () async {
        await notifier.loadTasks();

        await notifier.saveRawContent('Task 1\n\nTask 2\n');

        expect(notifier.todoFile!.items.length, 2);
      });
    });

    group('updateTask', () {
      test('updates task and persists', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Original task'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        await notifier.updateTask(
            0, TodoItem(description: 'Updated task'));

        expect(notifier.todoFile!.items[0].description, 'Updated task');

        final reloaded = await repository.load();
        expect(reloaded.items[0].description, 'Updated task');
      });

      test('notifies listeners', () async {
        repository = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task')]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        var notified = false;
        notifier.addListener(() => notified = true);

        await notifier.updateTask(
            0, TodoItem(description: 'Edited'));

        expect(notified, true);
      });

      test('does nothing when no file loaded', () async {
        await notifier.updateTask(
            0, TodoItem(description: 'Should not crash'));

        expect(notifier.todoFile, isNull);
      });

      test('preserves custom tags in description', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'My task next: important'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        await notifier.updateTask(
            0,
            TodoItem(
              description: 'My task next: important',
              metadata: {'due': '2026-03-20'},
            ));

        expect(
            notifier.todoFile!.items[0].description, 'My task next: important');
        expect(notifier.todoFile!.items[0].metadata['due'], '2026-03-20');
      });
    });

    group('deleteTask', () {
      test('removes task and persists', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1'),
            TodoItem(description: 'Task 2'),
            TodoItem(description: 'Task 3'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        await notifier.deleteTask(1);

        expect(notifier.todoFile!.items.length, 2);
        expect(notifier.todoFile!.items[0].description, 'Task 1');
        expect(notifier.todoFile!.items[1].description, 'Task 3');

        final reloaded = await repository.load();
        expect(reloaded.items.length, 2);
      });

      test('notifies listeners', () async {
        repository = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Task 1')]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        var notified = false;
        notifier.addListener(() => notified = true);

        await notifier.deleteTask(0);

        expect(notified, true);
      });

      test('does nothing when no file loaded', () async {
        await notifier.deleteTask(0);

        expect(notifier.todoFile, isNull);
      });
    });

    group('insertTask', () {
      test('inserts task and persists', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1'),
            TodoItem(description: 'Task 3'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        await notifier.insertTask(1, TodoItem(description: 'Task 2'));

        expect(notifier.todoFile!.items.length, 3);
        expect(notifier.todoFile!.items[1].description, 'Task 2');

        final reloaded = await repository.load();
        expect(reloaded.items.length, 3);
      });

      test('notifies listeners', () async {
        repository = InMemoryTodoRepository(TodoFile([]));
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        var notified = false;
        notifier.addListener(() => notified = true);

        await notifier.insertTask(0, TodoItem(description: 'Task 1'));

        expect(notified, true);
      });

      test('does nothing when no file loaded', () async {
        await notifier.insertTask(0, TodoItem(description: 'Should not crash'));

        expect(notifier.todoFile, isNull);
      });
    });

    group('upcoming filter', () {
      test('filteredTasks returns upcoming tasks when filter is upcoming',
          () async {
        final now = DateTime.now();
        final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));
        final in3DaysStr = _formatDate(now.add(const Duration(days: 3)));
        final in8DaysStr = _formatDate(now.add(const Duration(days: 8)));
        final todayStr = _formatDate(now);
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Tomorrow', metadata: {'due': tomorrowStr}),
            TodoItem(description: 'In 3 days', metadata: {'due': in3DaysStr}),
            TodoItem(description: 'In 8 days', metadata: {'due': in8DaysStr}),
            TodoItem(description: 'Today', metadata: {'due': todayStr}),
            TodoItem(description: 'No due'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.upcoming;

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(result[0].description, 'Tomorrow');
        expect(result[1].description, 'In 3 days');
      });

      test('upcomingTaskCount returns correct count', () async {
        final now = DateTime.now();
        final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));
        final in3DaysStr = _formatDate(now.add(const Duration(days: 3)));
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Tomorrow', metadata: {'due': tomorrowStr}),
            TodoItem(description: 'In 3 days', metadata: {'due': in3DaysStr}),
            TodoItem(description: 'No due'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.upcomingTaskCount, 2);
      });

      test('upcomingTaskCount returns 0 when no file loaded', () {
        expect(notifier.upcomingTaskCount, 0);
      });

      test('respects upcomingDays setting', () async {
        final now = DateTime.now();
        final in3DaysStr = _formatDate(now.add(const Duration(days: 3)));
        final in5DaysStr = _formatDate(now.add(const Duration(days: 5)));
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'In 3 days', metadata: {'due': in3DaysStr}),
            TodoItem(description: 'In 5 days', metadata: {'due': in5DaysStr}),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.upcomingDays = 3;
        notifier.activeFilter = TaskFilter.upcoming;

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'In 3 days');
      });
    });

    group('context filter', () {
      test('filters tasks by context', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Task 1', contexts: ['@phone']),
            TodoItem(description: 'Task 2', contexts: ['@home']),
            TodoItem(description: 'Task 3', contexts: ['@phone']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.selectContext('@phone');

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(notifier.activeFilter, TaskFilter.context);
        expect(notifier.selectedContext, '@phone');
      });
    });

    group('view filters (project/context/priority)', () {
      late TodoListNotifier notifier;

      setUp(() async {
        final now = DateTime.now();
        final todayStr = _formatDate(now);
        final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Work email',
              projects: ['+Work'],
              contexts: ['@email'],
              priority: 'A',
            ),
            TodoItem(
              description: 'Home phone',
              projects: ['+Home'],
              contexts: ['@phone'],
              priority: 'B',
            ),
            TodoItem(
              description: 'Work phone',
              projects: ['+Work'],
              contexts: ['@phone'],
              priority: 'A',
            ),
            TodoItem(
              description: 'Home email',
              projects: ['+Home'],
              contexts: ['@email'],
            ),
            TodoItem(
              description: 'Due today work',
              projects: ['+Work'],
              metadata: {'due': todayStr},
              priority: 'C',
            ),
            TodoItem(
              description: 'Due tomorrow home',
              projects: ['+Home'],
              contexts: ['@email'],
              metadata: {'due': tomorrowStr},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;
      });

      test('empty filters do not alter results', () {
        final unfilteredCount = notifier.filteredTasks.length;

        expect(unfilteredCount, 6);
        expect(notifier.hasActiveFilters, false);
      });

      test('filter by one project returns only tasks with that project', () {
        notifier.toggleFilterProject('+Work');

        final result = notifier.filteredTasks;

        expect(result.every((t) => t.projects.contains('+Work')), true);
        expect(result.length, 3);
      });

      test('filter by multiple projects uses OR', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterProject('+Home');

        final result = notifier.filteredTasks;

        expect(result.length, 6);
      });

      test('filter by context', () {
        notifier.toggleFilterContext('@email');

        final result = notifier.filteredTasks;

        expect(result.every((t) => t.contexts.contains('@email')), true);
        expect(result.length, 3);
      });

      test('filter by priority', () {
        notifier.toggleFilterPriority('A');

        final result = notifier.filteredTasks;

        expect(result.every((t) => t.priority == 'A'), true);
        expect(result.length, 2);
      });

      test('combine project + context uses AND', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterContext('@phone');

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Work phone');
      });

      test('combine project + priority uses AND', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterPriority('A');

        final result = notifier.filteredTasks;

        expect(result.length, 2);
      });

      test('clearFilters resets all filters', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterContext('@email');
        notifier.toggleFilterPriority('A');

        notifier.clearFilters();

        expect(notifier.hasActiveFilters, false);
        expect(notifier.filteredTasks.length, 6);
      });

      test('changing view clears filters', () {
        notifier.toggleFilterProject('+Work');
        expect(notifier.hasActiveFilters, true);

        notifier.activeFilter = TaskFilter.today;

        expect(notifier.hasActiveFilters, false);
      });

      test('hasActiveFilters reflects state correctly', () {
        expect(notifier.hasActiveFilters, false);

        notifier.toggleFilterProject('+Work');
        expect(notifier.hasActiveFilters, true);

        notifier.toggleFilterProject('+Work');
        expect(notifier.hasActiveFilters, false);
      });

      test('toggle same filter twice removes it', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterProject('+Work');

        expect(notifier.filteredTasks.length, 6);
        expect(notifier.hasActiveFilters, false);
      });

      test('availableProjectsForView returns projects from current view', () {
        final projects = notifier.availableProjectsForView;

        expect(projects, containsAll(['+Work', '+Home']));
      });

      test('availableContextsForView returns contexts from current view', () {
        final contexts = notifier.availableContextsForView;

        expect(contexts, containsAll(['@email', '@phone']));
      });

      test('availablePrioritiesForView returns priorities from current view', () {
        final priorities = notifier.availablePrioritiesForView;

        expect(priorities, containsAll(['A', 'B', 'C']));
      });

      test('availableProjectsForView scoped to today view', () {
        notifier.activeFilter = TaskFilter.today;

        final projects = notifier.availableProjectsForView;

        expect(projects, ['+Work']);
      });

      test('availablePrioritiesForView scoped to today view', () {
        notifier.activeFilter = TaskFilter.today;

        final priorities = notifier.availablePrioritiesForView;

        expect(priorities, ['C']);
      });

      test('filters apply on today view', () {
        notifier.activeFilter = TaskFilter.today;
        notifier.toggleFilterPriority('C');

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Due today work');
      });

      test('filters apply on upcoming view', () {
        notifier.activeFilter = TaskFilter.upcoming;
        notifier.toggleFilterProject('+Home');

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Due tomorrow home');
      });

      test('filter getters return current selections', () {
        notifier.toggleFilterProject('+Work');
        notifier.toggleFilterContext('@email');
        notifier.toggleFilterPriority('A');

        expect(notifier.filterProjects, {'+Work'});
        expect(notifier.filterContexts, {'@email'});
        expect(notifier.filterPriorities, {'A'});
      });
    });

    group('search', () {
      test('searchQuery initial is empty', () {
        expect(notifier.searchQuery, '');
      });

      test('hasActiveSearch is false initially', () {
        expect(notifier.hasActiveSearch, false);
      });

      test('setSearchQuery updates query and notifies listeners', () async {
        var notified = false;
        notifier.addListener(() => notified = true);

        notifier.setSearchQuery('milk');

        expect(notifier.searchQuery, 'milk');
        expect(notified, true);
      });

      test('hasActiveSearch returns true when query is set', () {
        notifier.setSearchQuery('milk');

        expect(notifier.hasActiveSearch, true);
      });

      test('clearSearch clears query and notifies listeners', () async {
        notifier.setSearchQuery('milk');
        var notified = false;
        notifier.addListener(() => notified = true);

        notifier.clearSearch();

        expect(notifier.searchQuery, '');
        expect(notifier.hasActiveSearch, false);
        expect(notified, true);
      });

      test('filteredTasks filters by text in description case-insensitive',
          () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Buy milk'),
            TodoItem(description: 'Call mom'),
            TodoItem(description: 'Buy BREAD'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        notifier.setSearchQuery('buy');

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(result[0].description, 'Buy milk');
        expect(result[1].description, 'Buy BREAD');
      });

      test('search combines with existing filters', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Buy milk', projects: ['+Home']),
            TodoItem(description: 'Buy pens', projects: ['+Work']),
            TodoItem(description: 'Call mom', projects: ['+Home']),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        notifier.toggleFilterProject('+Home');
        notifier.setSearchQuery('buy');

        final result = notifier.filteredTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Buy milk');
      });

      test('changing view clears search', () {
        notifier.activeFilter = TaskFilter.inbox;
        notifier.setSearchQuery('milk');
        expect(notifier.hasActiveSearch, true);

        notifier.activeFilter = TaskFilter.today;

        expect(notifier.hasActiveSearch, false);
        expect(notifier.searchQuery, '');
      });
    });

    group('completed filter', () {
      test('filteredTasks returns completed tasks when filter is completed',
          () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Pending task'),
            TodoItem(
              description: 'Done task',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 10),
            ),
            TodoItem(
              description: 'Another done',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 12),
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.completed;

        final result = notifier.filteredTasks;

        expect(result.length, 2);
        expect(result.every((t) => t.isCompleted), true);
      });

      test('completed tasks sorted by completion date descending', () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Oldest',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 5),
            ),
            TodoItem(
              description: 'Newest',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 12),
            ),
            TodoItem(
              description: 'Middle',
              isCompleted: true,
              completionDate: DateTime(2026, 3, 8),
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.completed;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Newest');
        expect(result[1].description, 'Middle');
        expect(result[2].description, 'Oldest');
      });

      test('hasCompletedTasks returns true when completed tasks exist',
          () async {
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Pending'),
            TodoItem(description: 'Done', isCompleted: true),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.hasCompletedTasks, true);
      });

      test('hasCompletedTasks returns false when no completed tasks', () async {
        repository = InMemoryTodoRepository(
          TodoFile([TodoItem(description: 'Pending')]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();

        expect(notifier.hasCompletedTasks, false);
      });

      test('hasCompletedTasks returns false when no file loaded', () {
        expect(notifier.hasCompletedTasks, false);
      });
    });

    group('task ordering', () {
      test('sorts by priority first (A before B)', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'Low', priority: 'B'),
            TodoItem(description: 'High', priority: 'A'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'High');
        expect(result[1].description, 'Low');
      });

      test('tasks with priority come before tasks without', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No priority'),
            TodoItem(description: 'Has priority', priority: 'C'),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Has priority');
        expect(result[1].description, 'No priority');
      });

      test('same priority sorts by due date (earlier first)', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Later',
              priority: 'A',
              metadata: {'due': '2026-03-20'},
            ),
            TodoItem(
              description: 'Sooner',
              priority: 'A',
              metadata: {'due': '2026-03-15'},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Sooner');
        expect(result[1].description, 'Later');
      });

      test('tasks with due date come before tasks without (same priority)', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No due', priority: 'A'),
            TodoItem(
              description: 'Has due',
              priority: 'A',
              metadata: {'due': '2026-03-20'},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Has due');
        expect(result[1].description, 'No due');
      });

      test('same priority and due date sorts by creation date (older first)', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Newer',
              priority: 'A',
              metadata: {'due': '2026-03-20'},
              creationDate: DateTime(2026, 3, 10),
            ),
            TodoItem(
              description: 'Older',
              priority: 'A',
              metadata: {'due': '2026-03-20'},
              creationDate: DateTime(2026, 3, 5),
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Older');
        expect(result[1].description, 'Newer');
      });

      test('tasks with creation date come before tasks without (all else equal)', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No creation'),
            TodoItem(
              description: 'Has creation',
              creationDate: DateTime(2026, 3, 5),
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'Has creation');
        expect(result[1].description, 'No creation');
      });

      test('full ordering: priority > due > creation', () async {
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No priority no due'),
            TodoItem(
              description: 'B with late due',
              priority: 'B',
              metadata: {'due': '2026-03-25'},
            ),
            TodoItem(
              description: 'A with early due',
              priority: 'A',
              metadata: {'due': '2026-03-15'},
            ),
            TodoItem(
              description: 'A with late due',
              priority: 'A',
              metadata: {'due': '2026-03-20'},
            ),
            TodoItem(description: 'A no due', priority: 'A'),
            TodoItem(
              description: 'No priority with due',
              metadata: {'due': '2026-03-10'},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.inbox;

        final descriptions = notifier.filteredTasks
            .map((t) => t.description)
            .toList();

        expect(descriptions, [
          'A with early due',
          'A with late due',
          'A no due',
          'B with late due',
          'No priority with due',
          'No priority no due',
        ]);
      });

      test('ordering applies to today view', () async {
        final now = DateTime.now();
        final todayStr = _formatDate(now);
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Low priority',
              priority: 'C',
              metadata: {'due': todayStr},
            ),
            TodoItem(
              description: 'High priority',
              priority: 'A',
              metadata: {'due': todayStr},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.today;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'High priority');
        expect(result[1].description, 'Low priority');
      });

      test('ordering applies to upcoming view', () async {
        final now = DateTime.now();
        final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));
        final repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(
              description: 'Low priority',
              priority: 'B',
              metadata: {'due': tomorrowStr},
            ),
            TodoItem(
              description: 'High priority',
              priority: 'A',
              metadata: {'due': tomorrowStr},
            ),
          ]),
        );
        notifier = TodoListNotifier(repository);
        await notifier.loadTasks();
        notifier.activeFilter = TaskFilter.upcoming;

        final result = notifier.filteredTasks;

        expect(result[0].description, 'High priority');
        expect(result[1].description, 'Low priority');
      });
    });
  });
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _FailingRepository implements TodoRepository {
  @override
  Future<TodoFile> load() async => throw Exception('disk error');

  @override
  Future<void> save(TodoFile todoFile) async => throw Exception('disk error');
}
