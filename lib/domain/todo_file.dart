import 'package:don3txt/domain/recurrence.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';

class TodoFile {
  final List<TodoItem> items;

  const TodoFile(this.items);

  List<TodoItem> get pendingTasks =>
      items.where((item) => !item.isCompleted).toList();

  List<TodoItem> visiblePendingTasks(DateTime today) {
    return pendingTasks.where((item) => _isVisible(item, today)).toList();
  }

  List<TodoItem> todayTasks(DateTime today) {
    final todayString = _formatDate(today);

    return items
        .where((item) =>
            !item.isCompleted &&
            _isVisible(item, today) &&
            item.metadata['due'] != null &&
            item.metadata['due']!.compareTo(todayString) <= 0)
        .toList();
  }

  List<TodoItem> overdueTasks(DateTime today) {
    final todayString = _formatDate(today);

    return items
        .where((item) =>
            !item.isCompleted &&
            _isVisible(item, today) &&
            item.metadata['due'] != null &&
            item.metadata['due']!.compareTo(todayString) < 0)
        .toList();
  }

  List<String> allProjects([DateTime? today]) {
    final source = today != null ? visiblePendingTasks(today) : pendingTasks;
    final projects = source
        .expand((item) => item.projects)
        .toSet()
        .toList()
      ..sort();

    return projects;
  }

  List<TodoItem> tasksByProject(String project, [DateTime? today]) {
    return items
        .where((item) =>
            !item.isCompleted &&
            (today == null || _isVisible(item, today)) &&
            item.projects.contains(project))
        .toList();
  }

  List<String> allContexts([DateTime? today]) {
    final source = today != null ? visiblePendingTasks(today) : pendingTasks;
    final contexts = source
        .expand((item) => item.contexts)
        .toSet()
        .toList()
      ..sort();

    return contexts;
  }

  List<TodoItem> tasksByContext(String context, [DateTime? today]) {
    return items
        .where((item) =>
            !item.isCompleted &&
            (today == null || _isVisible(item, today)) &&
            item.contexts.contains(context))
        .toList();
  }

  List<TodoItem> get recurringTasks =>
      pendingTasks.where((item) => item.metadata.containsKey('rec')).toList();

  bool _isVisible(TodoItem item, DateTime today) {
    final threshold = item.metadata['t'];
    if (threshold == null) return true;

    return threshold.compareTo(_formatDate(today)) <= 0;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  TodoFile addTask(String description,
      {DateTime? dueDate, DateTime? startDate, String? recurrence}) {
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

    if (startDate != null) {
      final y = startDate.year.toString().padLeft(4, '0');
      final m = startDate.month.toString().padLeft(2, '0');
      final d = startDate.day.toString().padLeft(2, '0');
      metadata['t'] = '$y-$m-$d';
    }

    if (recurrence != null) {
      metadata['rec'] = recurrence;
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

      return TodoFile(updatedItems);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    updatedItems[index] = item.copyWith(
      isCompleted: true,
      completionDate: today,
    );

    final recValue = item.metadata['rec'];
    if (recValue != null) {
      final rec = parseRecurrence(recValue);
      if (rec != null) {
        final nextTask = _createNextRecurrence(item, rec, today);
        updatedItems.add(nextTask);
      }
    }

    return TodoFile(updatedItems);
  }

  TodoItem _createNextRecurrence(
      TodoItem item, Recurrence rec, DateTime completionDate) {
    final newMetadata = Map<String, String>.from(item.metadata);

    if (rec.isStrict && newMetadata.containsKey('t')) {
      if (newMetadata.containsKey('due')) {
        final oldDue = DateTime.parse(newMetadata['due']!);
        newMetadata['due'] = _formatDate(rec.applyTo(oldDue));
      }

      if (newMetadata.containsKey('t')) {
        final oldT = DateTime.parse(newMetadata['t']!);
        newMetadata['t'] = _formatDate(rec.applyTo(oldT));
      }
    } else {
      final newDue = rec.applyTo(completionDate);
      newMetadata['due'] = _formatDate(newDue);

      if (newMetadata.containsKey('t') && newMetadata.containsKey('due')) {
        final oldDue = DateTime.parse(item.metadata['due']!);
        final oldT = DateTime.parse(newMetadata['t']!);
        final gap = oldDue.difference(oldT);
        final newT = newDue.subtract(gap);
        newMetadata['t'] = _formatDate(newT);
      }
    }

    return TodoItem(
      description: item.description,
      creationDate: completionDate,
      projects: List.from(item.projects),
      contexts: List.from(item.contexts),
      metadata: newMetadata,
    );
  }

  TodoFile updateTask(int index, TodoItem newItem) {
    final updatedItems = List<TodoItem>.from(items);
    updatedItems[index] = newItem;

    return TodoFile(updatedItems);
  }

  String serialize() {
    if (items.isEmpty) return '';

    return items.map((item) => serializeLine(item)).join('\n') + '\n';
  }
}
