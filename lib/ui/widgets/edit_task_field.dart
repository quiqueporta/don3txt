import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/domain/todo_parser.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/widgets/recurrence_dialog.dart';
import 'package:don3txt/ui/widgets/tag_picker_sheet.dart';
import 'package:don3txt/ui/widgets/task_input_bar.dart';

class EditTaskField extends StatefulWidget {
  final TodoItem item;
  final void Function(TodoItem updatedItem) onSave;

  const EditTaskField({super.key, required this.item, required this.onSave});

  @override
  State<EditTaskField> createState() => _EditTaskFieldState();
}

class _EditTaskFieldState extends State<EditTaskField> {
  late final TextEditingController _controller;
  DateTime? _selectedDate;
  DateTime? _selectedStartDate;
  String? _recurrence;
  String? _priority;
  Set<String> _selectedProjects = {};
  Set<String> _selectedContexts = {};

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _controller = TextEditingController(text: _buildEditableText(item));

    final dueStr = item.metadata['due'];
    if (dueStr != null) {
      _selectedDate = DateTime.tryParse(dueStr);
    }

    final startStr = item.metadata['t'];
    if (startStr != null) {
      _selectedStartDate = DateTime.tryParse(startStr);
    }

    _recurrence = item.metadata['rec'];
    _priority = item.priority;
    _selectedProjects = item.projects.toSet();
    _selectedContexts = item.contexts.toSet();
  }

  String _buildEditableText(TodoItem item) {
    final parts = <String>[item.description];

    for (final entry in item.metadata.entries) {
      if (entry.key == 'due' || entry.key == 't' || entry.key == 'rec') {
        continue;
      }
      parts.add('${entry.key}:${entry.value}');
    }

    return parts.join(' ');
  }

  void _handleSubmit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    final parsed = parseLine(text);
    final metadata = Map<String, String>.from(parsed?.metadata ?? {});

    if (_selectedDate != null) {
      final y = _selectedDate!.year.toString().padLeft(4, '0');
      final m = _selectedDate!.month.toString().padLeft(2, '0');
      final d = _selectedDate!.day.toString().padLeft(2, '0');
      metadata['due'] = '$y-$m-$d';
    }

    if (_selectedStartDate != null) {
      final y = _selectedStartDate!.year.toString().padLeft(4, '0');
      final m = _selectedStartDate!.month.toString().padLeft(2, '0');
      final d = _selectedStartDate!.day.toString().padLeft(2, '0');
      metadata['t'] = '$y-$m-$d';
    }

    if (_recurrence != null) {
      metadata['rec'] = _recurrence!;
    }

    final parsedProjects = parsed?.projects ?? [];
    final parsedContexts = parsed?.contexts ?? [];
    // La fusión via Set deduplicar automáticamente si el usuario escribe un
    // token manualmente (+Trabajo) Y también lo tiene en el picker seleccionado.
    final allProjects = {..._selectedProjects, ...parsedProjects}.toList();
    final allContexts = {..._selectedContexts, ...parsedContexts}.toList();

    final updatedItem = widget.item.copyWith(
      description: parsed?.description ?? text,
      priority: _priority,
      projects: allProjects,
      contexts: allContexts,
      metadata: metadata,
    );

    widget.onSave(updatedItem);
  }

  Future<void> _pickRecurrence() async {
    final result = await showRecurrenceDialog(context, initial: _recurrence);

    if (result != null) {
      setState(() => _recurrence = result);
    }
  }

  void _pickPriority() {
    final colors = context.read<SettingsNotifier>().priorityColors;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(6, (i) {
              final letter = String.fromCharCode(65 + i);
              final stored = colors.colorFor(letter);
              final color = stored != null ? Color(stored) : null;

              return ActionChip(
                label: Text(
                  '($letter)',
                  style: color != null
                      ? TextStyle(color: color, fontWeight: FontWeight.w600)
                      : null,
                ),
                onPressed: () {
                  setState(() => _priority = letter);
                  Navigator.pop(context);
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Color? _priorityChipColor(PriorityColors colors) {
    if (_priority == null) return null;

    final stored = colors.colorFor(_priority!);

    return stored != null ? Color(stored) : null;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickProjects() {
    final notifier = context.read<TodoListNotifier>();
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TagPickerSheet(
        title: loc.projectsTitle,
        hint: loc.newProjectHint,
        prefix: '+',
        available: notifier.allProjects,
        selected: _selectedProjects,
        onChanged: (projects) {
          setState(() => _selectedProjects = projects);
        },
      ),
    );
  }

  void _pickContexts() {
    final notifier = context.read<TodoListNotifier>();
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TagPickerSheet(
        title: loc.contextsTitle,
        hint: loc.newContextHint,
        prefix: '@',
        available: notifier.allContexts,
        selected: _selectedContexts,
        onChanged: (contexts) {
          setState(() => _selectedContexts = contexts);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priorityColors = context.watch<SettingsNotifier>().priorityColors;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _handleSubmit,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).editTaskHint,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          TaskInputBar(
            onPickDate: _pickDate,
            onPickStartDate: _pickStartDate,
            onPickRecurrence: _pickRecurrence,
            onPickPriority: _pickPriority,
            onPickProjects: _pickProjects,
            onPickContexts: _pickContexts,
            selectedDate: _selectedDate,
            selectedStartDate: _selectedStartDate,
            recurrence: _recurrence,
            priority: _priority,
            priorityColor: _priorityChipColor(priorityColors),
            selectedProjects: _selectedProjects,
            selectedContexts: _selectedContexts,
            onClearDate: () => setState(() => _selectedDate = null),
            onClearStartDate: () => setState(() => _selectedStartDate = null),
            onClearRecurrence: () => setState(() => _recurrence = null),
            onClearPriority: () => setState(() => _priority = null),
            onRemoveProject: (p) =>
                setState(() => _selectedProjects.remove(p)),
            onRemoveContext: (c) =>
                setState(() => _selectedContexts.remove(c)),
          ),
        ],
      ),
    );
  }
}
