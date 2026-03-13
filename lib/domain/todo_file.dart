import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

class TodoFile {
  final List<TodoItem> items;

  const TodoFile(this.items);

  List<TodoItem> get pendingTasks =>
      items.where((item) => !item.isCompleted).toList();

  List<TodoItem> todayTasks(DateTime today) {
    final todayString = _formatDate(today);

    return items
        .where((item) =>
            !item.isCompleted &&
            item.metadata['due'] != null &&
            item.metadata['due']!.compareTo(todayString) <= 0)
        .toList();
  }

  List<TodoItem> overdueTasks(DateTime today) {
    final todayString = _formatDate(today);

    return items
        .where((item) =>
            !item.isCompleted &&
            item.metadata['due'] != null &&
            item.metadata['due']!.compareTo(todayString) < 0)
        .toList();
  }

  List<String> get allProjects {
    final projects = pendingTasks
        .expand((item) => item.projects)
        .toSet()
        .toList()
      ..sort();

    return projects;
  }

  List<TodoItem> tasksByProject(String project) {
    return items
        .where((item) => !item.isCompleted && item.projects.contains(project))
        .toList();
  }

  List<String> get allContexts {
    final contexts = pendingTasks
        .expand((item) => item.contexts)
        .toSet()
        .toList()
      ..sort();

    return contexts;
  }

  List<TodoItem> tasksByContext(String context) {
    return items
        .where((item) => !item.isCompleted && item.contexts.contains(context))
        .toList();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  TodoFile addTask(String description, {DateTime? dueDate}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final parsed = parseLine(description);
    final metadata = Map<String, String>.from(parsed?.metadata ?? {});

    if (dueDate != null) {
      final y = dueDate.year.toString().padLeft(4, '0');
      final m = dueDate.month.toString().padLeft(2, '0');
      final d = dueDate.day.toString().padLeft(2, '0');
      metadata['due'] = '$y-$m-$d';
    }

    final newItem = TodoItem(
      description: parsed?.description ?? description,
      creationDate: today,
      projects: parsed?.projects ?? [],
      contexts: parsed?.contexts ?? [],
      metadata: metadata,
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
