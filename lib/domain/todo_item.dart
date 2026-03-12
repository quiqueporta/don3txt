import 'package:flutter/foundation.dart';

const _sentinel = Object();

class TodoItem {
  final bool isCompleted;
  final String? priority;
  final DateTime? creationDate;
  final DateTime? completionDate;
  final String description;
  final List<String> projects;
  final List<String> contexts;
  final Map<String, String> metadata;

  const TodoItem({
    this.isCompleted = false,
    this.priority,
    this.creationDate,
    this.completionDate,
    required this.description,
    this.projects = const [],
    this.contexts = const [],
    this.metadata = const {},
  });

  TodoItem copyWith({
    bool? isCompleted,
    Object? priority = _sentinel,
    Object? creationDate = _sentinel,
    Object? completionDate = _sentinel,
    String? description,
    List<String>? projects,
    List<String>? contexts,
    Map<String, String>? metadata,
  }) {
    return TodoItem(
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority == _sentinel ? this.priority : priority as String?,
      creationDate: creationDate == _sentinel
          ? this.creationDate
          : creationDate as DateTime?,
      completionDate: completionDate == _sentinel
          ? this.completionDate
          : completionDate as DateTime?,
      description: description ?? this.description,
      projects: projects ?? this.projects,
      contexts: contexts ?? this.contexts,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoItem &&
        other.isCompleted == isCompleted &&
        other.priority == priority &&
        other.creationDate == creationDate &&
        other.completionDate == completionDate &&
        other.description == description &&
        listEquals(other.projects, projects) &&
        listEquals(other.contexts, contexts) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      isCompleted,
      priority,
      creationDate,
      completionDate,
      description,
      Object.hashAll(projects),
      Object.hashAll(contexts),
      Object.hashAll(metadata.entries),
    );
  }
}
