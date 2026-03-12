import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/settings_notifier.dart';

class AddTaskField extends StatefulWidget {
  final void Function(String text, {DateTime? dueDate}) onSubmit;

  const AddTaskField({super.key, required this.onSubmit});

  @override
  State<AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<AddTaskField> {
  final _controller = TextEditingController();
  DateTime? _selectedDate;

  void _handleSubmit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    widget.onSubmit(text, dueDate: _selectedDate);
    _controller.clear();
    setState(() => _selectedDate = null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final settings = context.read<SettingsNotifier>();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
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
            ],
          ),
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
        ],
      ),
    );
  }
}
