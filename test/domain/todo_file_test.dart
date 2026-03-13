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

    test('addTask with startDate sets t metadata', () {
      final file = TodoFile([]);

      final updated = file.addTask('Review', startDate: DateTime(2026, 3, 18));

      expect(updated.items[0].metadata['t'], '2026-03-18');
    });

    test('addTask with startDate overrides t in description', () {
      final file = TodoFile([]);

      final updated = file.addTask(
        'Review t:2026-01-01',
        startDate: DateTime(2026, 3, 18),
      );

      expect(updated.items[0].metadata['t'], '2026-03-18');
    });

    test('addTask with recurrence sets rec metadata', () {
      final file = TodoFile([]);

      final updated = file.addTask('Pay bills', recurrence: '2w');

      expect(updated.items[0].metadata['rec'], '2w');
    });

    test('addTask with strict recurrence sets rec metadata', () {
      final file = TodoFile([]);

      final updated = file.addTask('Pay subscription', recurrence: '+3m');

      expect(updated.items[0].metadata['rec'], '+3m');
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

    test('completeTask with simple recurrence creates new task from completion date',
        () {
      final file = TodoFile([
        TodoItem(
          description: 'Pay bills',
          metadata: {'due': '2026-03-10', 'rec': '2w'},
          contexts: ['@personal'],
          projects: ['+Finance'],
        ),
      ]);

      final updated = file.completeTask(0);

      expect(updated.items.length, 2);
      expect(updated.items[0].isCompleted, true);

      final newTask = updated.items[1];
      expect(newTask.isCompleted, false);
      expect(newTask.description, 'Pay bills');
      expect(newTask.contexts, ['@personal']);
      expect(newTask.projects, ['+Finance']);
      expect(newTask.metadata['rec'], '2w');

      final now = DateTime.now();
      final expectedDue = DateTime(now.year, now.month, now.day + 14);
      final expectedDueStr =
          '${expectedDue.year}-${expectedDue.month.toString().padLeft(2, '0')}-${expectedDue.day.toString().padLeft(2, '0')}';
      expect(newTask.metadata['due'], expectedDueStr);
    });

    test('completeTask with strict recurrence creates new task from original dates',
        () {
      final file = TodoFile([
        TodoItem(
          description: 'Pay subscription',
          metadata: {
            'due': '2026-03-16',
            't': '2026-03-09',
            'rec': '+2w',
          },
        ),
      ]);

      final updated = file.completeTask(0);

      expect(updated.items.length, 2);
      expect(updated.items[0].isCompleted, true);

      final newTask = updated.items[1];
      expect(newTask.metadata['due'], '2026-03-30');
      expect(newTask.metadata['t'], '2026-03-23');
      expect(newTask.metadata['rec'], '+2w');
    });

    test('completeTask with simple recurrence preserves gap between t and due',
        () {
      final file = TodoFile([
        TodoItem(
          description: 'Review',
          metadata: {
            'due': '2026-03-16',
            't': '2026-03-09',
            'rec': '1w',
          },
        ),
      ]);

      final updated = file.completeTask(0);
      final newTask = updated.items[1];

      final now = DateTime.now();
      final expectedDue = DateTime(now.year, now.month, now.day + 7);
      final expectedT = expectedDue.subtract(const Duration(days: 7));

      final dueStr =
          '${expectedDue.year}-${expectedDue.month.toString().padLeft(2, '0')}-${expectedDue.day.toString().padLeft(2, '0')}';
      final tStr =
          '${expectedT.year}-${expectedT.month.toString().padLeft(2, '0')}-${expectedT.day.toString().padLeft(2, '0')}';

      expect(newTask.metadata['due'], dueStr);
      expect(newTask.metadata['t'], tStr);
    });

    test(
        'completeTask with strict recurrence without t falls back to simple behavior',
        () {
      final file = TodoFile([
        TodoItem(
          description: 'Pay bills',
          metadata: {'due': '2026-03-10', 'rec': '+2w'},
        ),
      ]);

      final updated = file.completeTask(0);

      expect(updated.items.length, 2);
      expect(updated.items[0].isCompleted, true);

      final newTask = updated.items[1];
      final now = DateTime.now();
      final expectedDue = DateTime(now.year, now.month, now.day + 14);
      final expectedDueStr =
          '${expectedDue.year}-${expectedDue.month.toString().padLeft(2, '0')}-${expectedDue.day.toString().padLeft(2, '0')}';
      expect(newTask.metadata['due'], expectedDueStr);
      expect(newTask.metadata['rec'], '+2w');
    });

    test('completeTask with recurrence does not create new task on uncomplete',
        () {
      final file = TodoFile([
        TodoItem(
          description: 'Recurring done',
          isCompleted: true,
          completionDate: DateTime(2026, 3, 10),
          metadata: {'rec': '1w', 'due': '2026-03-17'},
        ),
        TodoItem(description: 'Other'),
      ]);

      final updated = file.completeTask(0);

      expect(updated.items.length, 2);
      expect(updated.items[0].isCompleted, false);
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

    group('updateTask', () {
      test('replaces item at given index', () {
        final file = TodoFile([
          TodoItem(description: 'Task 1'),
          TodoItem(description: 'Task 2'),
          TodoItem(description: 'Task 3'),
        ]);

        final updated = file.updateTask(
            1, TodoItem(description: 'Task 2 edited'));

        expect(updated.items.length, 3);
        expect(updated.items[0].description, 'Task 1');
        expect(updated.items[1].description, 'Task 2 edited');
        expect(updated.items[2].description, 'Task 3');
      });

      test('preserves all other items unchanged', () {
        final file = TodoFile([
          TodoItem(
            description: 'Important',
            priority: 'A',
            projects: ['+Work'],
            contexts: ['@office'],
            metadata: {'due': '2026-03-20'},
          ),
          TodoItem(description: 'Edit me'),
        ]);

        final updated = file.updateTask(
            1, TodoItem(description: 'Edited'));

        expect(updated.items[0].priority, 'A');
        expect(updated.items[0].projects, ['+Work']);
        expect(updated.items[0].contexts, ['@office']);
        expect(updated.items[0].metadata['due'], '2026-03-20');
      });

      test('preserves custom tags in description', () {
        final file = TodoFile([
          TodoItem(description: 'My task next:'),
        ]);

        final updated = file.updateTask(
            0,
            TodoItem(
              description: 'My task next:',
              metadata: {'due': '2026-03-20'},
            ));

        expect(updated.items[0].description, 'My task next:');
        expect(updated.items[0].metadata['due'], '2026-03-20');
      });
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

        expect(file.allProjects(), ['+Health', '+Home', '+Work']);
      });

      test('excludes projects from completed tasks', () {
        final file = TodoFile([
          TodoItem(description: 'Done', projects: ['+Old'], isCompleted: true),
          TodoItem(description: 'Active', projects: ['+Current']),
        ]);

        expect(file.allProjects(), ['+Current']);
      });

      test('returns empty list when no projects', () {
        final file = TodoFile([
          TodoItem(description: 'No project'),
        ]);

        expect(file.allProjects(), isEmpty);
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

    group('allContexts', () {
      test('returns unique sorted contexts from pending tasks', () {
        final file = TodoFile([
          TodoItem(description: 'Task 1', contexts: ['@phone', '@home']),
          TodoItem(description: 'Task 2', contexts: ['@phone']),
          TodoItem(description: 'Task 3', contexts: ['@office']),
        ]);

        expect(file.allContexts(), ['@home', '@office', '@phone']);
      });

      test('excludes contexts from completed tasks', () {
        final file = TodoFile([
          TodoItem(
              description: 'Done',
              contexts: ['@old'],
              isCompleted: true),
          TodoItem(description: 'Active', contexts: ['@current']),
        ]);

        expect(file.allContexts(), ['@current']);
      });

      test('returns empty list when no contexts', () {
        final file = TodoFile([
          TodoItem(description: 'No context'),
        ]);

        expect(file.allContexts(), isEmpty);
      });
    });

    group('threshold filtering', () {
      final today = DateTime(2026, 3, 13);

      test('visiblePendingTasks excludes tasks with future t:', () {
        final file = TodoFile([
          TodoItem(description: 'Visible', metadata: {'t': '2026-03-13'}),
          TodoItem(description: 'Hidden', metadata: {'t': '2026-03-14'}),
          TodoItem(description: 'No threshold'),
        ]);

        final result = file.visiblePendingTasks(today);

        expect(result.length, 2);
        expect(result[0].description, 'Visible');
        expect(result[1].description, 'No threshold');
      });

      test('todayTasks includes tasks with t: <= today', () {
        final file = TodoFile([
          TodoItem(
            description: 'Ready',
            metadata: {'due': '2026-03-13', 't': '2026-03-12'},
          ),
        ]);

        final result = file.todayTasks(today);

        expect(result.length, 1);
        expect(result[0].description, 'Ready');
      });

      test('todayTasks excludes tasks with t: > today even if due today', () {
        final file = TodoFile([
          TodoItem(
            description: 'Not yet',
            metadata: {'due': '2026-03-13', 't': '2026-03-14'},
          ),
        ]);

        final result = file.todayTasks(today);

        expect(result, isEmpty);
      });

      test('overdueTasks excludes tasks with future t:', () {
        final file = TodoFile([
          TodoItem(
            description: 'Overdue visible',
            metadata: {'due': '2026-03-12', 't': '2026-03-10'},
          ),
          TodoItem(
            description: 'Overdue hidden',
            metadata: {'due': '2026-03-12', 't': '2026-03-14'},
          ),
        ]);

        final result = file.overdueTasks(today);

        expect(result.length, 1);
        expect(result[0].description, 'Overdue visible');
      });

      test('tasksByProject excludes tasks with future t:', () {
        final file = TodoFile([
          TodoItem(
            description: 'Visible',
            projects: ['+Work'],
            metadata: {'t': '2026-03-13'},
          ),
          TodoItem(
            description: 'Hidden',
            projects: ['+Work'],
            metadata: {'t': '2026-03-14'},
          ),
        ]);

        final result = file.tasksByProject('+Work', today);

        expect(result.length, 1);
        expect(result[0].description, 'Visible');
      });

      test('tasksByContext excludes tasks with future t:', () {
        final file = TodoFile([
          TodoItem(
            description: 'Visible',
            contexts: ['@phone'],
            metadata: {'t': '2026-03-13'},
          ),
          TodoItem(
            description: 'Hidden',
            contexts: ['@phone'],
            metadata: {'t': '2026-03-14'},
          ),
        ]);

        final result = file.tasksByContext('@phone', today);

        expect(result.length, 1);
        expect(result[0].description, 'Visible');
      });

      test('allProjects excludes projects from tasks with future t:', () {
        final file = TodoFile([
          TodoItem(
            description: 'Visible',
            projects: ['+Work'],
            metadata: {'t': '2026-03-13'},
          ),
          TodoItem(
            description: 'Hidden',
            projects: ['+Secret'],
            metadata: {'t': '2026-03-14'},
          ),
        ]);

        expect(file.allProjects(today), ['+Work']);
      });

      test('allContexts excludes contexts from tasks with future t:', () {
        final file = TodoFile([
          TodoItem(
            description: 'Visible',
            contexts: ['@phone'],
            metadata: {'t': '2026-03-13'},
          ),
          TodoItem(
            description: 'Hidden',
            contexts: ['@secret'],
            metadata: {'t': '2026-03-14'},
          ),
        ]);

        expect(file.allContexts(today), ['@phone']);
      });
    });

    group('recurringTasks', () {
      test('returns pending tasks with rec: metadata', () {
        final file = TodoFile([
          TodoItem(description: 'Recurring', metadata: {'rec': '1w'}),
          TodoItem(description: 'Normal'),
          TodoItem(
            description: 'Done recurring',
            isCompleted: true,
            metadata: {'rec': '1m'},
          ),
        ]);

        final result = file.recurringTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Recurring');
      });

      test('includes tasks with future threshold', () {
        final file = TodoFile([
          TodoItem(
            description: 'Future recurring',
            metadata: {'rec': '1w', 't': '2099-01-01'},
          ),
        ]);

        final result = file.recurringTasks;

        expect(result.length, 1);
        expect(result[0].description, 'Future recurring');
      });
    });

    group('tasksByContext', () {
      test('returns pending tasks matching context', () {
        final file = TodoFile([
          TodoItem(description: 'Task 1', contexts: ['@phone']),
          TodoItem(description: 'Task 2', contexts: ['@home']),
          TodoItem(description: 'Task 3', contexts: ['@phone', '@home']),
        ]);

        final result = file.tasksByContext('@phone');

        expect(result.length, 2);
        expect(result[0].description, 'Task 1');
        expect(result[1].description, 'Task 3');
      });

      test('excludes completed tasks', () {
        final file = TodoFile([
          TodoItem(
              description: 'Done',
              contexts: ['@phone'],
              isCompleted: true),
          TodoItem(description: 'Active', contexts: ['@phone']),
        ]);

        final result = file.tasksByContext('@phone');

        expect(result.length, 1);
        expect(result[0].description, 'Active');
      });
    });
  });
}
