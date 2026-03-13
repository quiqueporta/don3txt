import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();
    final projects = notifier.availableProjectsForView;
    final contexts = notifier.availableContextsForView;
    final priorities = notifier.availablePrioritiesForView;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (projects.isNotEmpty) ...[
              _SectionHeader(title: 'Project'),
              Wrap(
                spacing: 8,
                children: projects.map((p) {
                  final selected = notifier.filterProjects.contains(p);

                  return FilterChip(
                    label: Text(p),
                    selected: selected,
                    onSelected: (_) => notifier.toggleFilterProject(p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (contexts.isNotEmpty) ...[
              _SectionHeader(title: 'Context'),
              Wrap(
                spacing: 8,
                children: contexts.map((c) {
                  final selected = notifier.filterContexts.contains(c);

                  return FilterChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => notifier.toggleFilterContext(c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (priorities.isNotEmpty) ...[
              _SectionHeader(title: 'Priority'),
              Wrap(
                spacing: 8,
                children: priorities.map((p) {
                  final selected = notifier.filterPriorities.contains(p);

                  return FilterChip(
                    label: Text('($p)'),
                    selected: selected,
                    onSelected: (_) => notifier.toggleFilterPriority(p),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
