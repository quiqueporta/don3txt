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
    repository = FileTodoRepository('${tempDir.path}/todo.txt');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('donePathFor', () {
    test('derives done.txt in same directory as todo.txt', () {
      expect(
        FileTodoRepository.donePathFor('/path/to/todo.txt'),
        '/path/to/done.txt',
      );
    });

    test('works with custom todo filename', () {
      expect(
        FileTodoRepository.donePathFor('/storage/my-tasks.txt'),
        '/storage/done.txt',
      );
    });
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

    test('save replaces the file in one step instead of rewriting it in place',
        () async {
      final todoPath = '${tempDir.path}/todo.txt';
      File(todoPath).writeAsStringSync('Old task\n');
      final hardLinkPath = '${tempDir.path}/hard-link-to-old-content.txt';
      Process.runSync('ln', [todoPath, hardLinkPath]);

      await repository.save(TodoFile([TodoItem(description: 'New task')]));

      expect(File(todoPath).readAsStringSync(), 'New task\n');
      expect(File(hardLinkPath).readAsStringSync(), 'Old task\n');
    });

    test('save does not touch the file Syncthing uses while downloading todo.txt',
        () async {
      final syncthingDownload = File('${tempDir.path}/.syncthing.todo.txt.tmp')
        ..writeAsStringSync('Downloading from another device\n');

      await repository.save(TodoFile([TodoItem(description: 'Task')]));

      expect(syncthingDownload.existsSync(), true);
      expect(syncthingDownload.readAsStringSync(),
          'Downloading from another device\n');
    });

    test('save leaves no temporary files behind', () async {
      await repository.save(TodoFile([TodoItem(description: 'Task')]));

      final fileNames = tempDir
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();

      expect(fileNames, ['todo.txt']);
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
