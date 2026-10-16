import 'dart:io';

import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

abstract class TodoRepository {
  Future<TodoFile> load();
  Future<void> save(TodoFile todoFile);
  Stream<void> get changes;
}

class FileTodoRepository implements TodoRepository {
  final String _filePath;

  FileTodoRepository(this._filePath);

  static String donePathFor(String todoPath) {
    final lastSlash = todoPath.lastIndexOf('/');

    return lastSlash >= 0
        ? '${todoPath.substring(0, lastSlash)}/done.txt'
        : 'done.txt';
  }

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

  // The folder is watched instead of the file because every save replaces todo.txt with a renamed file.
  @override
  Stream<void> get changes => File(_filePath)
      .parent
      .watch()
      .where(_touchesThisFile)
      .map((_) {});

  bool _touchesThisFile(FileSystemEvent event) {
    final destination = event is FileSystemMoveEvent ? event.destination : null;

    return _isThisFile(event.path) || _isThisFile(destination);
  }

  bool _isThisFile(String? path) {
    return path != null && File(path).absolute.path == File(_filePath).absolute.path;
  }

  @override
  Future<void> save(TodoFile todoFile) async {
    await _replaceContent(todoFile.serialize());
  }

  Future<void> _replaceContent(String content) async {
    final temporaryFile = File(_temporaryPath());

    await temporaryFile.writeAsString(content, flush: true);
    await temporaryFile.rename(_filePath);
  }

  // Syncthing never syncs files named like its own temporaries; the don3txt- prefix keeps it apart from the one Syncthing uses while downloading this same file.
  String _temporaryPath() {
    final lastSlash = _filePath.lastIndexOf('/');
    final directory = _filePath.substring(0, lastSlash + 1);
    final fileName = _filePath.substring(lastSlash + 1);

    return '$directory.syncthing.don3txt-$fileName.tmp';
  }
}
