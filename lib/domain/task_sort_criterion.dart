import 'package:don3txt/domain/todo_item.dart';

enum TaskSortCriterion {
  priority,
  due,
  threshold,
  creation;

  static TaskSortCriterion? parse(String? name) {
    if (name == null) return null;

    for (final c in values) {
      if (c.name == name) return c;
    }

    return null;
  }
}

typedef TaskComparator = int Function(TodoItem a, TodoItem b);

TaskComparator compareTasksBy(List<TaskSortCriterion> chain) {
  return (a, b) {
    for (final criterion in chain) {
      final result = _compareBy(criterion, a, b);
      if (result != 0) return result;
    }

    return 0;
  };
}

int _compareBy(TaskSortCriterion criterion, TodoItem a, TodoItem b) {
  switch (criterion) {
    case TaskSortCriterion.priority:
      return _comparePriority(a.priority, b.priority);
    case TaskSortCriterion.due:
      return _compareNullableString(a.metadata['due'], b.metadata['due']);
    case TaskSortCriterion.threshold:
      return _compareNullableString(a.metadata['t'], b.metadata['t']);
    case TaskSortCriterion.creation:
      return _compareNullableDate(a.creationDate, b.creationDate);
  }
}

int _comparePriority(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;

  return a.compareTo(b);
}

int _compareNullableString(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;

  return a.compareTo(b);
}

int _compareNullableDate(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;

  return a.compareTo(b);
}
