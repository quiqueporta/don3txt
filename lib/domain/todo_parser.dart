import 'package:don3txt/domain/todo_item.dart';

final _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _priorityRegex = RegExp(r'^\(([A-Z])\)$');
final _projectRegex = RegExp(r'^\+\S+$');
final _contextRegex = RegExp(r'^@\S+$');
final _metadataRegex = RegExp(r'^(\S+):(\S+)$');
final _urlRegex = RegExp(r'^https?://', caseSensitive: false);

DateTime? _tryParseDate(String s) {
  if (!_dateRegex.hasMatch(s)) return null;

  return DateTime.tryParse(s);
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');

  return '$y-$m-$d';
}

TodoItem? parseLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;

  final tokens = trimmed.split(RegExp(r'\s+'));
  var index = 0;

  var isCompleted = false;
  DateTime? completionDate;
  DateTime? creationDate;
  String? priority;

  if (tokens[index] == 'x') {
    isCompleted = true;
    index++;

    if (index < tokens.length) {
      final date = _tryParseDate(tokens[index]);
      if (date != null) {
        completionDate = date;
        index++;

        if (index < tokens.length) {
          final date2 = _tryParseDate(tokens[index]);
          if (date2 != null) {
            creationDate = date2;
            index++;
          }
        }
      }
    }
  } else {
    final priorityMatch = _priorityRegex.firstMatch(tokens[index]);
    if (priorityMatch != null) {
      priority = priorityMatch.group(1);
      index++;
    }

    if (index < tokens.length) {
      final date = _tryParseDate(tokens[index]);
      if (date != null) {
        creationDate = date;
        index++;
      }
    }
  }

  final descriptionParts = <String>[];
  final projects = <String>[];
  final contexts = <String>[];
  final metadata = <String, String>{};

  for (var i = index; i < tokens.length; i++) {
    final token = tokens[i];

    if (_projectRegex.hasMatch(token)) {
      projects.add(token);
    } else if (_contextRegex.hasMatch(token)) {
      contexts.add(token);
    } else {
      final metaMatch = _metadataRegex.firstMatch(token);
      if (metaMatch != null && !token.startsWith('//') && !_urlRegex.hasMatch(token) && metaMatch.group(1) != token) {
        metadata[metaMatch.group(1)!] = metaMatch.group(2)!;
      } else {
        descriptionParts.add(token);
      }
    }
  }

  return TodoItem(
    isCompleted: isCompleted,
    priority: priority,
    creationDate: creationDate,
    completionDate: completionDate,
    description: descriptionParts.join(' '),
    projects: projects,
    contexts: contexts,
    metadata: metadata,
  );
}

String serializeLine(TodoItem item) {
  final parts = <String>[];

  if (item.isCompleted) {
    parts.add('x');
    if (item.completionDate != null) {
      parts.add(_formatDate(item.completionDate!));
    }
    if (item.creationDate != null) {
      parts.add(_formatDate(item.creationDate!));
    }
  } else {
    if (item.priority != null) {
      parts.add('(${item.priority})');
    }
    if (item.creationDate != null) {
      parts.add(_formatDate(item.creationDate!));
    }
  }

  parts.add(item.description);

  for (final project in item.projects) {
    parts.add(project);
  }

  for (final context in item.contexts) {
    parts.add(context);
  }

  for (final entry in item.metadata.entries) {
    parts.add('${entry.key}:${entry.value}');
  }

  return parts.join(' ');
}
