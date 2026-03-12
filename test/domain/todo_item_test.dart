import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_item.dart';

void main() {
  group('TodoItem', () {
    test('creates with description only', () {
      final item = TodoItem(description: 'Call Mom');

      expect(item.description, 'Call Mom');
      expect(item.isCompleted, false);
      expect(item.priority, isNull);
      expect(item.creationDate, isNull);
      expect(item.completionDate, isNull);
      expect(item.projects, isEmpty);
      expect(item.contexts, isEmpty);
      expect(item.metadata, isEmpty);
    });

    test('creates with all fields', () {
      final item = TodoItem(
        isCompleted: true,
        priority: 'A',
        creationDate: DateTime(2011, 3, 2),
        completionDate: DateTime(2011, 3, 3),
        description: 'Call Mom',
        projects: ['+Family'],
        contexts: ['@phone'],
        metadata: {'due': '2011-03-04'},
      );

      expect(item.isCompleted, true);
      expect(item.priority, 'A');
      expect(item.creationDate, DateTime(2011, 3, 2));
      expect(item.completionDate, DateTime(2011, 3, 3));
      expect(item.description, 'Call Mom');
      expect(item.projects, ['+Family']);
      expect(item.contexts, ['@phone']);
      expect(item.metadata, {'due': '2011-03-04'});
    });

    test('copyWith returns new instance with changed fields', () {
      final original = TodoItem(description: 'Call Mom');
      final completed = original.copyWith(
        isCompleted: true,
        completionDate: DateTime(2011, 3, 3),
      );

      expect(completed.isCompleted, true);
      expect(completed.completionDate, DateTime(2011, 3, 3));
      expect(completed.description, 'Call Mom');
      expect(original.isCompleted, false);
    });

    test('copyWith preserves unchanged fields', () {
      final original = TodoItem(
        priority: 'A',
        description: 'Call Mom',
        projects: ['+Family'],
      );
      final updated = original.copyWith(description: 'Call Dad');

      expect(updated.priority, 'A');
      expect(updated.projects, ['+Family']);
      expect(updated.description, 'Call Dad');
    });

    test('equality by value', () {
      final a = TodoItem(description: 'Call Mom', priority: 'A');
      final b = TodoItem(description: 'Call Mom', priority: 'A');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', () {
      final a = TodoItem(description: 'Call Mom');
      final b = TodoItem(description: 'Call Dad');

      expect(a, isNot(equals(b)));
    });
  });
}
