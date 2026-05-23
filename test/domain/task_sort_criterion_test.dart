import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_item.dart';

TodoItem _task({
  String description = 'Task',
  String? priority,
  String? due,
  String? threshold,
  DateTime? creationDate,
}) {
  final metadata = <String, String>{};

  if (due != null) metadata['due'] = due;
  if (threshold != null) metadata['t'] = threshold;

  return TodoItem(
    description: description,
    priority: priority,
    creationDate: creationDate,
    metadata: metadata,
  );
}

void main() {
  group('compareTasksBy', () {
    group('priority criterion', () {
      final compare = compareTasksBy([TaskSortCriterion.priority]);

      test('task with priority comes before one without', () {
        final withPri = _task(priority: 'A');
        final withoutPri = _task();

        expect(compare(withPri, withoutPri), isNegative);
        expect(compare(withoutPri, withPri), isPositive);
      });

      test('higher priority (A) comes before lower (B)', () {
        final a = _task(priority: 'A');
        final b = _task(priority: 'B');

        expect(compare(a, b), isNegative);
      });

      test('same priority is tie', () {
        final a = _task(priority: 'B');
        final b = _task(priority: 'B');

        expect(compare(a, b), 0);
      });
    });

    group('due criterion', () {
      final compare = compareTasksBy([TaskSortCriterion.due]);

      test('task with due comes before one without', () {
        final withDue = _task(due: '2026-03-10');
        final withoutDue = _task();

        expect(compare(withDue, withoutDue), isNegative);
      });

      test('earlier due comes first', () {
        final earlier = _task(due: '2026-03-01');
        final later = _task(due: '2026-03-10');

        expect(compare(earlier, later), isNegative);
      });
    });

    group('threshold criterion', () {
      final compare = compareTasksBy([TaskSortCriterion.threshold]);

      test('task with t comes before one without', () {
        final withT = _task(threshold: '2026-03-10');
        final withoutT = _task();

        expect(compare(withT, withoutT), isNegative);
      });

      test('earlier t comes first', () {
        final earlier = _task(threshold: '2026-03-01');
        final later = _task(threshold: '2026-03-10');

        expect(compare(earlier, later), isNegative);
      });
    });

    group('creation criterion', () {
      final compare = compareTasksBy([TaskSortCriterion.creation]);

      test('task with creation date comes before one without', () {
        final withDate = _task(creationDate: DateTime(2026, 3, 1));
        final withoutDate = _task();

        expect(compare(withDate, withoutDate), isNegative);
      });

      test('earlier creation comes first', () {
        final earlier = _task(creationDate: DateTime(2026, 3, 1));
        final later = _task(creationDate: DateTime(2026, 3, 10));

        expect(compare(earlier, later), isNegative);
      });
    });

    group('chained criteria', () {
      test('falls through to next criterion on tie', () {
        final compare = compareTasksBy([
          TaskSortCriterion.priority,
          TaskSortCriterion.due,
        ]);

        final a = _task(priority: 'A', due: '2026-03-10');
        final b = _task(priority: 'A', due: '2026-03-01');

        expect(compare(a, b), isPositive);
      });

      test('first criterion wins when it discriminates', () {
        final compare = compareTasksBy([
          TaskSortCriterion.priority,
          TaskSortCriterion.due,
        ]);

        final aHighPriLateDue = _task(priority: 'A', due: '2026-12-31');
        final bLowPriEarlyDue = _task(priority: 'B', due: '2026-01-01');

        expect(compare(aHighPriLateDue, bLowPriEarlyDue), isNegative);
      });

      test('full chain priority -> due -> creation returns 0 when all equal',
          () {
        final compare = compareTasksBy([
          TaskSortCriterion.priority,
          TaskSortCriterion.due,
          TaskSortCriterion.creation,
        ]);

        final a = _task(
          priority: 'A',
          due: '2026-03-10',
          creationDate: DateTime(2026, 1, 1),
        );
        final b = _task(
          priority: 'A',
          due: '2026-03-10',
          creationDate: DateTime(2026, 1, 1),
        );

        expect(compare(a, b), 0);
      });
    });

    test('empty chain returns 0 for any pair', () {
      final compare = compareTasksBy([]);

      final a = _task(priority: 'A', due: '2026-01-01');
      final b = _task();

      expect(compare(a, b), 0);
    });
  });

  group('TaskSortCriterion.parse', () {
    test('round-trips known names', () {
      for (final c in TaskSortCriterion.values) {
        expect(TaskSortCriterion.parse(c.name), c);
      }
    });

    test('returns null for unknown name', () {
      expect(TaskSortCriterion.parse('nope'), isNull);
      expect(TaskSortCriterion.parse(null), isNull);
    });
  });
}
