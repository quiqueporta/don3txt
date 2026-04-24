/// Widget compartido de entrada de metadatos de tarea.
///
/// Renderiza la fila de iconos (fecha de vencimiento, fecha de inicio,
/// recurrencia, prioridad, proyectos y contextos) y la zona de chips
/// eliminables que refleja el estado actual de selección.
///
/// Es un [StatelessWidget] puro: no tiene lógica de negocio ni estado propio.
/// Todo el estado vive en el padre ([AddTaskField] o [EditTaskField]) y se
/// comunica hacia abajo via parámetros y hacia arriba via callbacks.
///
/// Uso:
/// ```dart
/// TaskInputBar(
///   onPickDate: _pickDate,
///   onPickProjects: _pickProjects,
///   selectedProjects: _selectedProjects,
///   onRemoveProject: (p) => setState(() => _selectedProjects.remove(p)),
///   // ... resto de parámetros requeridos
/// )
/// ```
import 'package:flutter/material.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';

class TaskInputBar extends StatelessWidget {
  final VoidCallback onPickDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickRecurrence;
  final VoidCallback onPickPriority;
  final VoidCallback onPickProjects;
  final VoidCallback onPickContexts;

  final DateTime? selectedDate;
  final DateTime? selectedStartDate;
  final String? recurrence;
  final String? priority;
  final Color? priorityColor;
  final Set<String> selectedProjects;
  final Set<String> selectedContexts;

  final VoidCallback onClearDate;
  final VoidCallback onClearStartDate;
  final VoidCallback onClearRecurrence;
  final VoidCallback onClearPriority;
  final ValueChanged<String> onRemoveProject;
  final ValueChanged<String> onRemoveContext;

  const TaskInputBar({
    super.key,
    required this.onPickDate,
    required this.onPickStartDate,
    required this.onPickRecurrence,
    required this.onPickPriority,
    required this.onPickProjects,
    required this.onPickContexts,
    this.selectedDate,
    this.selectedStartDate,
    this.recurrence,
    this.priority,
    this.priorityColor,
    this.selectedProjects = const {},
    this.selectedContexts = const {},
    required this.onClearDate,
    required this.onClearStartDate,
    required this.onClearRecurrence,
    required this.onClearPriority,
    required this.onRemoveProject,
    required this.onRemoveContext,
  });

  /// Convierte una cadena de recurrencia en formato todo.txt a texto legible
  /// y localizado.
  ///
  /// El formato de entrada es `[+]Nu` donde `+` indica modo estricto, `N` es
  /// un entero positivo y `u` es la unidad (`d`, `w`, `m`, `y`).
  ///
  /// Si la cadena está malformada (longitud insuficiente o parte numérica no
  /// parseable), devuelve [rec] sin modificar como fallback seguro para no
  /// romper el build.
  String _recurrenceLabel(String rec, AppLocalizations loc) {
    final strict = rec.startsWith('+');
    final body = strict ? rec.substring(1) : rec;

    if (body.length < 2) {
      return rec;
    }

    final parsedAmount = int.tryParse(body.substring(0, body.length - 1));

    if (parsedAmount == null) {
      return rec;
    }

    final unit = body[body.length - 1];
    final label = switch (unit) {
      'd' => loc.recurrenceEveryDays(parsedAmount),
      'w' => loc.recurrenceEveryWeeks(parsedAmount),
      'm' => loc.recurrenceEveryMonths(parsedAmount),
      'y' => loc.recurrenceEveryYears(parsedAmount),
      _ => rec,
    };

    final prefix = strict ? loc.recurrenceStrictPrefix : '';

    return '$prefix$label';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onPickDate,
              ),
              IconButton(
                icon: const Icon(Icons.event_available),
                onPressed: onPickStartDate,
              ),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: onPickRecurrence,
              ),
              IconButton(
                icon: const Icon(Icons.flag),
                onPressed: onPickPriority,
              ),
              IconButton(
                icon: const Icon(Icons.tag),
                onPressed: onPickProjects,
              ),
              IconButton(
                icon: const Icon(Icons.alternate_email),
                onPressed: onPickContexts,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            if (priority != null)
              Chip(
                label: Text(
                  '($priority)',
                  style: priorityColor != null
                      ? TextStyle(color: priorityColor, fontWeight: FontWeight.w600)
                      : null,
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onClearPriority,
              ),
            if (selectedDate != null)
              Chip(
                label: Text(_formatDate(selectedDate!)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onClearDate,
              ),
            if (selectedStartDate != null)
              Chip(
                label: Text(
                    loc.startChipPrefix(_formatDate(selectedStartDate!))),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onClearStartDate,
              ),
            if (recurrence != null)
              Chip(
                label: Text(_recurrenceLabel(recurrence!, loc)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onClearRecurrence,
              ),
            for (final project in selectedProjects)
              Chip(
                label: Text(project),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onRemoveProject(project),
              ),
            for (final ctx in selectedContexts)
              Chip(
                label: Text(ctx),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onRemoveContext(ctx),
              ),
          ],
        ),
      ],
    );
  }
}
