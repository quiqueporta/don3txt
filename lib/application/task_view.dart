import 'package:don3txt/domain/task_sort_criterion.dart';
import 'package:don3txt/domain/todo_file.dart';
import 'package:don3txt/domain/todo_item.dart';

sealed class TaskView {
  const TaskView();

  List<TodoItem> tasksFrom(
    TodoFile pending,
    TodoFile done, {
    required DateTime today,
    required int upcomingDays,
  });

  bool get acceptsFilters => false;

  TaskComparator comparatorFor(List<TaskSortCriterion> criteria) =>
      compareTasksBy(criteria);

  DateTime? dueDateForNewTasks(DateTime today) => null;

  Set<String> get projectsForNewTasks => const {};

  Set<String> get contextsForNewTasks => const {};

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class InboxView extends TaskView {
  const InboxView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.visiblePendingTasks(today);

  @override
  bool get acceptsFilters => true;
}

class PastView extends TaskView {
  const PastView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.pastTasks(today);

  @override
  bool get acceptsFilters => true;
}

class TodayView extends TaskView {
  const TodayView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.todayTasks(today);

  @override
  bool get acceptsFilters => true;

  @override
  DateTime? dueDateForNewTasks(DateTime today) => today;
}

class UpcomingView extends TaskView {
  const UpcomingView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.upcomingTasks(today, upcomingDays);

  @override
  bool get acceptsFilters => true;
}

class ProjectView extends TaskView {
  final String project;

  const ProjectView(this.project);

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.tasksByProject(project, today);

  @override
  Set<String> get projectsForNewTasks => {project};

  @override
  bool operator ==(Object other) =>
      other is ProjectView && other.project == project;

  @override
  int get hashCode => Object.hash(ProjectView, project);
}

class ContextView extends TaskView {
  final String context;

  const ContextView(this.context);

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.tasksByContext(context, today);

  @override
  Set<String> get contextsForNewTasks => {context};

  @override
  bool operator ==(Object other) =>
      other is ContextView && other.context == context;

  @override
  int get hashCode => Object.hash(ContextView, context);
}

class RecurringView extends TaskView {
  const RecurringView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      pending.recurringTasks;
}

class CompletedView extends TaskView {
  const CompletedView();

  @override
  List<TodoItem> tasksFrom(TodoFile pending, TodoFile done,
          {required DateTime today, required int upcomingDays}) =>
      done.items;

  @override
  TaskComparator comparatorFor(List<TaskSortCriterion> criteria) =>
      _byCompletionDateDescending;

  static int _byCompletionDateDescending(TodoItem a, TodoItem b) {
    final aDate = a.completionDate;
    final bDate = b.completionDate;

    if (aDate != null && bDate != null) return bDate.compareTo(aDate);
    if (aDate != null && bDate == null) return -1;
    if (aDate == null && bDate != null) return 1;

    return 0;
  }
}
