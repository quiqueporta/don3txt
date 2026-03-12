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
        repository = InMemoryTodoRepository(
          TodoFile([
            TodoItem(description: 'No due'),
            TodoItem(description: 'Due today', metadata: {'due': '2026-03-12'}),
            TodoItem(description: 'Due tomorrow', metadata: {'due': '2026-03-13'}),
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
    });
  });
}

class _FailingRepository implements TodoRepository {
  @override
  Future<TodoFile> load() async => throw Exception('disk error');

  @override
  Future<void> save(TodoFile todoFile) async => throw Exception('disk error');
}
