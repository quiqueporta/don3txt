import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_file.dart';

void main() {
  group('TodoFile', () {
    test('creates empty', () {
      final file = TodoFile([]);

      expect(file.items, isEmpty);
    });

    test('pendingTasks returns only incomplete items', () {
      final file = TodoFile([
        TodoItem(description: 'Task 1'),
        TodoItem(description: 'Task 2', isCompleted: true),
        TodoItem(description: 'Task 3'),
      ]);

      final pending = file.pendingTasks;

      expect(pending.length, 2);
      expect(pending[0].description, 'Task 1');
      expect(pending[1].description, 'Task 3');
    });

    test('addTask creates item with description and today as creation date', () {
      final file = TodoFile([]);

      final updated = file.addTask('Buy milk');
      final today = DateTime.now();

      expect(updated.items.length, 1);
      expect(updated.items[0].description, 'Buy milk');
      expect(updated.items[0].creationDate!.year, today.year);
      expect(updated.items[0].creationDate!.month, today.month);
      expect(updated.items[0].creationDate!.day, today.day);
      expect(updated.items[0].isCompleted, false);
    });

    test('addTask appends to existing items', () {
      final file = TodoFile([TodoItem(description: 'Task 1')]);

      final updated = file.addTask('Task 2');

      expect(updated.items.length, 2);
      expect(updated.items[1].description, 'Task 2');
    });

    test('addTask parses metadata from description', () {
      final file = TodoFile([]);

      final updated = file.addTask('Entregar informe +Trabajo @oficina due:2026-03-15');

      expect(updated.items[0].description, 'Entregar informe');
      expect(updated.items[0].projects, ['+Trabajo']);
      expect(updated.items[0].contexts, ['@oficina']);
      expect(updated.items[0].metadata['due'], '2026-03-15');
    });

    test('addTask with dueDate sets due metadata', () {
      final file = TodoFile([]);

      final updated = file.addTask('Buy milk', dueDate: DateTime(2026, 3, 20));

      expect(updated.items[0].description, 'Buy milk');
      expect(updated.items[0].metadata['due'], '2026-03-20');
    });

    test('addTask with dueDate overrides due in description', () {
      final file = TodoFile([]);

      final updated = file.addTask(
        'Buy milk due:2026-01-01',
        dueDate: DateTime(2026, 3, 20),
      );

      expect(updated.items[0].metadata['due'], '2026-03-20');
    });

    test('completeTask marks item as completed with today date', () {
      final file = TodoFile([
        TodoItem(description: 'Task 1'),
        TodoItem(description: 'Task 2'),
      ]);
      final today = DateTime.now();

      final updated = file.completeTask(0);

      expect(updated.items[0].isCompleted, true);
      expect(updated.items[0].completionDate!.year, today.year);
      expect(updated.items[0].completionDate!.month, today.month);
      expect(updated.items[0].completionDate!.day, today.day);
      expect(updated.items[1].isCompleted, false);
    });

    test('completeTask on already completed item uncompletes it', () {
      final file = TodoFile([
        TodoItem(
          description: 'Task 1',
          isCompleted: true,
          completionDate: DateTime(2011, 3, 3),
        ),
      ]);

      final updated = file.completeTask(0);

      expect(updated.items[0].isCompleted, false);
      expect(updated.items[0].completionDate, isNull);
    });

    test('serialize produces correct string', () {
      final file = TodoFile([
        TodoItem(description: 'Task 1', priority: 'A'),
        TodoItem(description: 'Task 2'),
      ]);

      final result = file.serialize();

      expect(result, '(A) Task 1\nTask 2\n');
    });

    test('serialize empty file produces empty string', () {
      final file = TodoFile([]);

      expect(file.serialize(), '');
    });

    group('todayTasks', () {
      final today = DateTime(2026, 3, 12);

      test('returns pending tasks with due date equal to today', () {
        final file = TodoFile([
          TodoItem(description: 'Task due today', metadata: {'due': '2026-03-12'}),
          TodoItem(description: 'Task no due'),
        ]);

        final result = file.todayTasks(today);

        expect(result.length, 1);
        expect(result[0].description, 'Task due today');
      });

      test('excludes completed tasks', () {
        final file = TodoFile([
          TodoItem(
            description: 'Done today',
            isCompleted: true,
            metadata: {'due': '2026-03-12'},
          ),
        ]);

        expect(file.todayTasks(today), isEmpty);
      });

      test('excludes tasks without due date', () {
        final file = TodoFile([
          TodoItem(description: 'No due'),
        ]);

        expect(file.todayTasks(today), isEmpty);
      });

      test('excludes tasks with future due date', () {
        final file = TodoFile([
          TodoItem(description: 'Tomorrow', metadata: {'due': '2026-03-13'}),
        ]);

        expect(file.todayTasks(today), isEmpty);
      });

      test('includes overdue tasks', () {
        final file = TodoFile([
          TodoItem(description: 'Yesterday', metadata: {'due': '2026-03-11'}),
        ]);

        final result = file.todayTasks(today);

        expect(result.length, 1);
        expect(result[0].description, 'Yesterday');
      });
    });

    group('overdueTasks', () {
      final today = DateTime(2026, 3, 12);

      test('returns pending tasks with due date before today', () {
        final file = TodoFile([
          TodoItem(description: 'Overdue', metadata: {'due': '2026-03-11'}),
          TodoItem(description: 'Today', metadata: {'due': '2026-03-12'}),
          TodoItem(description: 'Tomorrow', metadata: {'due': '2026-03-13'}),
        ]);

        final result = file.overdueTasks(today);

        expect(result.length, 1);
        expect(result[0].description, 'Overdue');
      });

      test('excludes completed tasks', () {
        final file = TodoFile([
          TodoItem(
            description: 'Done overdue',
            isCompleted: true,
            metadata: {'due': '2026-03-11'},
          ),
        ]);

        expect(file.overdueTasks(today), isEmpty);
      });

      test('excludes tasks without due date', () {
        final file = TodoFile([
          TodoItem(description: 'No due'),
        ]);

        expect(file.overdueTasks(today), isEmpty);
      });
    });

    group('allProjects', () {
      test('returns unique sorted projects from pending tasks', () {
        final file = TodoFile([
          TodoItem(description: 'Task 1', projects: ['+Work', '+Home']),
          TodoItem(description: 'Task 2', projects: ['+Work']),
          TodoItem(description: 'Task 3', projects: ['+Health']),
        ]);

        expect(file.allProjects, ['+Health', '+Home', '+Work']);
      });

      test('excludes projects from completed tasks', () {
        final file = TodoFile([
          TodoItem(description: 'Done', projects: ['+Old'], isCompleted: true),
          TodoItem(description: 'Active', projects: ['+Current']),
        ]);

        expect(file.allProjects, ['+Current']);
      });

      test('returns empty list when no projects', () {
        final file = TodoFile([
          TodoItem(description: 'No project'),
        ]);

        expect(file.allProjects, isEmpty);
      });
    });

    group('tasksByProject', () {
      test('returns pending tasks matching project', () {
        final file = TodoFile([
          TodoItem(description: 'Task 1', projects: ['+Work']),
          TodoItem(description: 'Task 2', projects: ['+Home']),
          TodoItem(description: 'Task 3', projects: ['+Work', '+Home']),
        ]);

        final result = file.tasksByProject('+Work');

        expect(result.length, 2);
        expect(result[0].description, 'Task 1');
        expect(result[1].description, 'Task 3');
      });

      test('excludes completed tasks', () {
        final file = TodoFile([
          TodoItem(
              description: 'Done',
              projects: ['+Work'],
              isCompleted: true),
          TodoItem(description: 'Active', projects: ['+Work']),
        ]);

        final result = file.tasksByProject('+Work');

        expect(result.length, 1);
        expect(result[0].description, 'Active');
      });
    });
  });
}
