import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

class TodoFile {
  final List<TodoItem> items;

  const TodoFile(this.items);

  List<TodoItem> get pendingTasks =>
      items.where((item) => !item.isCompleted).toList();

  TodoFile addTask(String description) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final newItem = TodoItem(
      description: description,
      creationDate: today,
    );

    return TodoFile([...items, newItem]);
  }

  TodoFile completeTask(int index) {
    final updatedItems = List<TodoItem>.from(items);
    final item = updatedItems[index];

    if (item.isCompleted) {
      updatedItems[index] = item.copyWith(
        isCompleted: false,
        completionDate: null,
      );
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      updatedItems[index] = item.copyWith(
        isCompleted: true,
        completionDate: today,
      );
    }

    return TodoFile(updatedItems);
  }

  String serialize() {
    if (items.isEmpty) return '';

    return items.map((item) => serializeLine(item)).join('\n') + '\n';
  }
}
