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
  });
}

class _FailingRepository implements TodoRepository {
  @override
  Future<TodoFile> load() async => throw Exception('disk error');

  @override
  Future<void> save(TodoFile todoFile) async => throw Exception('disk error');
}
