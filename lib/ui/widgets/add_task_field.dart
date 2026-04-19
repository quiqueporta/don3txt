import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/widgets/recurrence_dialog.dart';
import 'package:don3txt/ui/widgets/tag_picker_sheet.dart';
import 'package:don3txt/ui/widgets/task_input_bar.dart';

class AddTaskField extends StatefulWidget {
  final void Function(String text,
      {DateTime? dueDate,
      DateTime? startDate,
      String? recurrence,
      String? priority}) onSubmit;

  const AddTaskField({super.key, required this.onSubmit});

  @override
  State<AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<AddTaskField> {
  final _controller = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedStartDate;
  String? _recurrence;
  String? _priority;
  Set<String> _selectedProjects = {};
  Set<String> _selectedContexts = {};

  // Compara por token completo (split por espacios) en vez de subcadena para
  // evitar falsos positivos: "+Casa" no debe considerarse presente si el texto
  // contiene "+Casanova".
  bool _containsToken(String text, String token) {
    final words = text.split(' ');

    return words.contains(token);
  }

  void _handleSubmit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    final projectTokens = _selectedProjects
        .where((p) => !_containsToken(text, p))
        .toList();
    final contextTokens = _selectedContexts
        .where((c) => !_containsToken(text, c))
        .toList();

    final fullText = [text, ...projectTokens, ...contextTokens].join(' ');

    widget.onSubmit(fullText,
        dueDate: _selectedDate,
        startDate: _selectedStartDate,
        recurrence: _recurrence,
        priority: _priority);
    _controller.clear();

    setState(() {
      _selectedDate = null;
      _selectedStartDate = null;
      _recurrence = null;
      _priority = null;
      _selectedProjects = {};
      _selectedContexts = {};
    });
  }

  Future<void> _pickRecurrence() async {
    final result = await showRecurrenceDialog(context);

    if (result != null) {
      setState(() => _recurrence = result);
    }
  }

  void _pickPriority() {
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

              return ActionChip(
                label: Text('($letter)'),
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final settings = context.read<SettingsNotifier>();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      locale: settings.startOfWeek.datePickerLocale,
    );

    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final settings = context.read<SettingsNotifier>();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      locale: settings.startOfWeek.datePickerLocale,
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
                    hintText: AppLocalizations.of(context).newTaskHint,
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
