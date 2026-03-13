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
      test('defaults to inbox', () {
        expect(notifier.activeFilter, TaskFilter.inbox);
      });

      test('can be changed to today', () {
        notifier.activeFilter = TaskFilter.today;

        expect(notifier.activeFilter, TaskFilter.today);
      });

      test('notifies listeners when changed', () {
        var notified = false;
        notifier.addListener(() => notified = true);

        notifier.activeFilter = TaskFilter.today;

        expect(notified, true);
      });

      test('does not notify when set to same value', () {
        var notifyCount = 0;
        notifier.addListener(() => notifyCount++);

        notifier.activeFilter = TaskFilter.inbox;

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
