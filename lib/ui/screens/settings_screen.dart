import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final todoFilePath = settings.todoFilePath;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Todo file',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            title: Text(todoFilePath ?? 'Default'),
            trailing: todoFilePath != null
                ? IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: () => _resetToDefault(context),
                  )
                : null,
            onTap: () => _selectFolder(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('System'),
            value: AppThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'First day of the week',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          RadioListTile<StartOfWeek>(
            title: const Text('Monday'),
            value: StartOfWeek.monday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
          RadioListTile<StartOfWeek>(
            title: const Text('Sunday'),
            value: StartOfWeek.sunday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Upcoming days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          for (final days in [3, 7, 14, 30])
            RadioListTile<int>(
              title: Text('$days days'),
              value: days,
              groupValue: settings.upcomingDays,
              onChanged: (value) => settings.setUpcomingDays(value!),
            ),
        ],
      ),
    );
  }

  Future<void> _selectFolder(BuildContext context) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) return;
    }

    if (!context.mounted) return;

    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    if (!context.mounted) return;

    final path = '$directoryPath/todo.txt';
    final file = File(path);

    if (!await file.exists()) {
      await file.writeAsString('');
    }

    if (!context.mounted) return;

    await _switchToFile(context, path);
  }

  Future<void> _resetToDefault(BuildContext context) async {
    final defaultPath = context.read<String>();

    await _switchToFile(context, defaultPath, savePath: null);
  }

  Future<void> _switchToFile(
    BuildContext context,
    String path, {
    Object? savePath = _sentinel,
  }) async {
    final settings = context.read<SettingsNotifier>();
    final todoList = context.read<TodoListNotifier>();

    await settings.setTodoFilePath(savePath == _sentinel ? path : savePath as String?);

    final newRepository = FileTodoRepository(path);

    await todoList.switchRepository(newRepository);
  }
}

const _sentinel = Object();
