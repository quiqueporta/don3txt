import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

void main() {
  group('parseLine', () {
    test('parses simple description', () {
      final item = parseLine('Call Mom');

      expect(item, isNotNull);
      expect(item!.description, 'Call Mom');
      expect(item.isCompleted, false);
    });

    test('parses priority', () {
      final item = parseLine('(A) Call Mom');

      expect(item!.priority, 'A');
      expect(item.description, 'Call Mom');
    });

    test('parses creation date', () {
      final item = parseLine('2011-03-02 Call Mom');

      expect(item!.creationDate, DateTime(2011, 3, 2));
      expect(item.description, 'Call Mom');
    });

    test('parses priority and creation date', () {
      final item = parseLine('(A) 2011-03-02 Call Mom');

      expect(item!.priority, 'A');
      expect(item.creationDate, DateTime(2011, 3, 2));
      expect(item.description, 'Call Mom');
    });

    test('parses projects', () {
      final item = parseLine('Call Mom +Family +Important');

      expect(item!.projects, ['+Family', '+Important']);
      expect(item.description, 'Call Mom');
    });

    test('parses contexts', () {
      final item = parseLine('Call Mom @phone @home');

      expect(item!.contexts, ['@phone', '@home']);
      expect(item.description, 'Call Mom');
    });

    test('parses completed task', () {
      final item = parseLine('x 2011-03-03 2011-03-01 Review PR');

      expect(item!.isCompleted, true);
      expect(item.completionDate, DateTime(2011, 3, 3));
      expect(item.creationDate, DateTime(2011, 3, 1));
      expect(item.description, 'Review PR');
    });

    test('parses completed task without creation date', () {
      final item = parseLine('x 2011-03-03 Review PR');

      expect(item!.isCompleted, true);
      expect(item.completionDate, DateTime(2011, 3, 3));
      expect(item.creationDate, isNull);
      expect(item.description, 'Review PR');
    });

    test('parses metadata key:value', () {
      final item = parseLine('Call Mom due:2011-03-04 rec:1w');

      expect(item!.metadata, {'due': '2011-03-04', 'rec': '1w'});
      expect(item.description, 'Call Mom');
    });

    test('preserves URLs in description', () {
      final item = parseLine('Check https://example.com/page for info');

      expect(item!.description, 'Check https://example.com/page for info');
      expect(item.metadata, isEmpty);
    });

    test('preserves http URL in description', () {
      final item = parseLine('Visit http://example.com +Project');

      expect(item!.description, 'Visit http://example.com');
      expect(item.projects, ['+Project']);
      expect(item.metadata, isEmpty);
    });

    test('preserves URL alongside metadata', () {
      final item = parseLine(
        'Check https://example.com/page due:2026-03-15 t:2026-03-10',
      );

      expect(item!.description, 'Check https://example.com/page');
      expect(item.metadata['due'], '2026-03-15');
      expect(item.metadata['t'], '2026-03-10');
    });

    test('returns null for empty line', () {
      expect(parseLine(''), isNull);
      expect(parseLine('   '), isNull);
    });

    test('parses full complex line', () {
      final item = parseLine(
        '(A) 2011-03-02 Call Mom +Family @phone due:2011-03-04',
      );

      expect(item!.priority, 'A');
      expect(item.creationDate, DateTime(2011, 3, 2));
      expect(item.description, 'Call Mom');
      expect(item.projects, ['+Family']);
      expect(item.contexts, ['@phone']);
      expect(item.metadata, {'due': '2011-03-04'});
    });
  });

  group('serializeLine', () {
    test('serializes simple description', () {
      final item = TodoItem(description: 'Call Mom');

      expect(serializeLine(item), 'Call Mom');
    });

    test('serializes with priority', () {
      final item = TodoItem(priority: 'A', description: 'Call Mom');

      expect(serializeLine(item), '(A) Call Mom');
    });

    test('serializes with creation date', () {
      final item = TodoItem(
        creationDate: DateTime(2011, 3, 2),
        description: 'Call Mom',
      );

      expect(serializeLine(item), '2011-03-02 Call Mom');
    });

    test('serializes completed task', () {
      final item = TodoItem(
        isCompleted: true,
        completionDate: DateTime(2011, 3, 3),
        creationDate: DateTime(2011, 3, 1),
        description: 'Review PR',
      );

      expect(serializeLine(item), 'x 2011-03-03 2011-03-01 Review PR');
    });

    test('serializes with projects and contexts', () {
      final item = TodoItem(
        description: 'Call Mom',
        projects: ['+Family'],
        contexts: ['@phone'],
      );

      expect(serializeLine(item), 'Call Mom +Family @phone');
    });

    test('serializes with metadata', () {
      final item = TodoItem(
        description: 'Call Mom',
        metadata: {'due': '2011-03-04'},
      );

      expect(serializeLine(item), 'Call Mom due:2011-03-04');
    });

    test('serializes full complex item', () {
      final item = TodoItem(
        priority: 'A',
        creationDate: DateTime(2011, 3, 2),
        description: 'Call Mom',
        projects: ['+Family'],
        contexts: ['@phone'],
        metadata: {'due': '2011-03-04'},
      );

      expect(
        serializeLine(item),
        '(A) 2011-03-02 Call Mom +Family @phone due:2011-03-04',
      );
    });
  });

  group('round-trip', () {
    test('parse then serialize then parse yields same item', () {
      final lines = [
        'Call Mom',
        '(A) Call Mom',
        '(B) 2011-03-02 Call Mom +Family @phone due:2011-03-04',
        'x 2011-03-03 2011-03-01 Review PR +Project @github',
        'Check https://example.com/page for info',
      ];

      for (final line in lines) {
        final item = parseLine(line)!;
        final serialized = serializeLine(item);
        final reparsed = parseLine(serialized)!;

        expect(reparsed, equals(item), reason: 'Failed round-trip for: $line');
      }
    });
  });
}
