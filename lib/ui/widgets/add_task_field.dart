import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/settings_notifier.dart';

class AddTaskField extends StatefulWidget {
  final void Function(String text,
      {DateTime? dueDate, DateTime? startDate, String? recurrence}) onSubmit;

  const AddTaskField({super.key, required this.onSubmit});

  @override
  State<AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<AddTaskField> {
  final _controller = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedStartDate;
  String? _recurrence;

  void _handleSubmit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    widget.onSubmit(text,
        dueDate: _selectedDate,
        startDate: _selectedStartDate,
        recurrence: _recurrence);
    _controller.clear();
    setState(() {
      _selectedDate = null;
      _selectedStartDate = null;
      _recurrence = null;
    });
  }

  String _recurrenceLabel(String rec) {
    final strict = rec.startsWith('+');
    final body = strict ? rec.substring(1) : rec;
    final amount = body.substring(0, body.length - 1);
    final unit = body[body.length - 1];

    const unitLabels = {'d': 'day', 'w': 'week', 'm': 'month', 'y': 'year'};
    final label = unitLabels[unit] ?? unit;
    final plural = int.parse(amount) > 1 ? '${label}s' : label;
    final prefix = strict ? '(strict) ' : '';

    return '${prefix}Every $amount $plural';
  }

  Future<void> _pickRecurrence() async {
    int amount = 1;
    String unit = 'd';
    bool strict = false;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recurrence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Every'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      controller: TextEditingController(text: '$amount'),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          amount = parsed;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(value: 'd', child: Text('days')),
                      DropdownMenuItem(value: 'w', child: Text('weeks')),
                      DropdownMenuItem(value: 'm', child: Text('months')),
                      DropdownMenuItem(value: 'y', child: Text('years')),
                    ],
                    onChanged: (v) => setDialogState(() => unit = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: strict,
                    onChanged: (v) => setDialogState(() => strict = v!),
                  ),
                  const Text('Strict (from start date)'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final prefix = strict ? '+' : '';
                Navigator.pop(context, '$prefix$amount$unit');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _recurrence = result);
    }
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
                  decoration: const InputDecoration(
                    hintText: 'New task...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
              IconButton(
                icon: const Icon(Icons.event_available),
                onPressed: _pickStartDate,
              ),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: _pickRecurrence,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              if (_selectedDate != null)
                Chip(
                  label: Text(
                    '${_selectedDate!.year}-'
                    '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                    '${_selectedDate!.day.toString().padLeft(2, '0')}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _selectedDate = null),
                ),
              if (_selectedStartDate != null)
                Chip(
                  label: Text(
                    'Start: ${_selectedStartDate!.year}-'
                    '${_selectedStartDate!.month.toString().padLeft(2, '0')}-'
                    '${_selectedStartDate!.day.toString().padLeft(2, '0')}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () =>
                      setState(() => _selectedStartDate = null),
                ),
              if (_recurrence != null)
                Chip(
                  label: Text(_recurrenceLabel(_recurrence!)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _recurrence = null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
