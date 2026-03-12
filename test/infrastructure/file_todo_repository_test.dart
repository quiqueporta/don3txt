import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

void main() {
  late Directory tempDir;
  late FileTodoRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('don3txt_test_');
    repository = FileTodoRepository(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('FileTodoRepository', () {
    test('load returns empty TodoFile when file does not exist', () async {
      final todoFile = await repository.load();

      expect(todoFile.items, isEmpty);
    });

    test('load reads existing file', () async {
      final file = File('${tempDir.path}/todo.txt');
      file.writeAsStringSync('(A) Call Mom\nBuy milk\n');

      final todoFile = await repository.load();

      expect(todoFile.items.length, 2);
      expect(todoFile.items[0].priority, 'A');
      expect(todoFile.items[0].description, 'Call Mom');
      expect(todoFile.items[1].description, 'Buy milk');
    });

    test('load skips empty lines', () async {
      final file = File('${tempDir.path}/todo.txt');
      file.writeAsStringSync('Call Mom\n\nBuy milk\n');

      final todoFile = await repository.load();

      expect(todoFile.items.length, 2);
    });

    test('save writes TodoFile to disk', () async {
      final todoFile = TodoFile([
        TodoItem(description: 'Call Mom', priority: 'A'),
        TodoItem(description: 'Buy milk'),
      ]);

      await repository.save(todoFile);

      final content = File('${tempDir.path}/todo.txt').readAsStringSync();
      expect(content, '(A) Call Mom\nBuy milk\n');
    });

    test('round-trip: save then load yields same items', () async {
      final original = TodoFile([
        TodoItem(
          description: 'Call Mom',
          priority: 'A',
          projects: ['+Family'],
          contexts: ['@phone'],
        ),
        TodoItem(description: 'Buy milk'),
      ]);

      await repository.save(original);
      final loaded = await repository.load();

      expect(loaded.items.length, original.items.length);
      for (var i = 0; i < original.items.length; i++) {
        expect(loaded.items[i], equals(original.items[i]));
      }
    });
  });
}
