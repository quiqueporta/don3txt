import 'package:flutter/material.dart';
import 'package:don3txt/domain/todo_item.dart';

class TaskTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;

  const TaskTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tags = [...item.projects, ...item.contexts];
    final hasMetadata = tags.isNotEmpty;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 16,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                if (hasMetadata)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tags.join(' '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
