import 'package:flutter/material.dart';
import 'package:don3txt/domain/todo_item.dart';

class TaskTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tags = [...item.projects, ...item.contexts];
    final dueDate = item.metadata['due'];
    final startDate = item.metadata['t'];
    final recurrence = item.metadata['rec'];
    final priority = item.priority;
    final hasMetadata = priority != null ||
        tags.isNotEmpty ||
        dueDate != null ||
        startDate != null ||
        recurrence != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 14),
              child: Icon(
                item.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: item.isCompleted
                    ? const Color(0xFF007AFF)
                    : Colors.grey.shade400,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 16,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey : null,
                  ),
                ),
                if (hasMetadata)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (priority != null)
                          _TagChip(
                            icon: Icons.flag,
                            label: priority,
                            color: Colors.orange,
                          ),
                        if (dueDate != null)
                          _MetadataChip(
                            icon: Icons.calendar_today,
                            label: dueDate,
                          ),
                        if (startDate != null)
                          _MetadataChip(
                            icon: Icons.event_available,
                            label: startDate,
                          ),
                        if (recurrence != null)
                          _MetadataChip(
                            icon: Icons.repeat,
                            label: recurrence,
                          ),
                        for (final project in item.projects)
                          _TagChip(
                            icon: Icons.tag,
                            label: project.replaceFirst('+', ''),
                            color: Colors.teal,
                          ),
                        for (final context in item.contexts)
                          _TagChip(
                            icon: Icons.alternate_email,
                            label: context.replaceFirst('@', ''),
                            color: Colors.deepPurple,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            ),
          ),
          if (onDelete != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'delete') onDelete!();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.shade400),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color.shade400),
        ),
      ],
    );
  }
}
