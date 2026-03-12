import 'dart:io';

import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

abstract class TodoRepository {
  Future<TodoFile> load();
  Future<void> save(TodoFile todoFile);
}

class FileTodoRepository implements TodoRepository {
  final String _filePath;

  FileTodoRepository(this._filePath);

  @override
  Future<TodoFile> load() async {
    final file = File(_filePath);

    if (!await file.exists()) {
      return TodoFile([]);
    }

    final content = await file.readAsString();
    final lines = content.split('\n');
    final items = <TodoItem>[];

    for (final line in lines) {
      final item = parseLine(line);
      if (item != null) {
        items.add(item);
      }
    }

    return TodoFile(items);
  }

  @override
  Future<void> save(TodoFile todoFile) async {
    final file = File(_filePath);

    await file.writeAsString(todoFile.serialize());
  }
}
