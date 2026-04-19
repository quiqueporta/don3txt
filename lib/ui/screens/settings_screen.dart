import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final loc = AppLocalizations.of(context);
    final todoFilePath = settings.todoFilePath;

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        children: [
          _SectionHeader(title: loc.sectionTodoFile),
          ListTile(
            title: Text(todoFilePath ?? loc.defaultFile),
            trailing: todoFilePath != null
                ? IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: () => _resetToDefault(context),
                  )
                : null,
            onTap: () => _selectFolder(context),
          ),
          const Divider(),
          _SectionHeader(title: loc.sectionTheme),
          RadioListTile<AppThemeMode>(
            title: Text(loc.themeSystem),
            value: AppThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(loc.themeLight),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(loc.themeDark),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (value) => settings.setThemeMode(value!),
          ),
          const Divider(),
          _SectionHeader(title: loc.sectionLanguage),
          RadioListTile<AppLanguage>(
            title: Text(loc.languageSystem),
            value: AppLanguage.system,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          RadioListTile<AppLanguage>(
            title: Text(loc.languageSpanish),
            value: AppLanguage.spanish,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          RadioListTile<AppLanguage>(
            title: Text(loc.languageEnglish),
            value: AppLanguage.english,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          RadioListTile<AppLanguage>(
            title: Text(loc.languageFrench),
            value: AppLanguage.french,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          RadioListTile<AppLanguage>(
            title: Text(loc.languageItalian),
            value: AppLanguage.italian,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          RadioListTile<AppLanguage>(
            title: Text(loc.languagePortuguese),
            value: AppLanguage.portuguese,
            groupValue: settings.language,
            onChanged: (value) => settings.setLanguage(value!),
          ),
          const Divider(),
          _SectionHeader(title: loc.sectionFirstDayOfWeek),
          RadioListTile<StartOfWeek>(
            title: Text(loc.dayMonday),
            value: StartOfWeek.monday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
          RadioListTile<StartOfWeek>(
            title: Text(loc.daySunday),
            value: StartOfWeek.sunday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
          const Divider(),
          _SectionHeader(title: loc.sectionUpcomingDays),
          for (final days in [3, 7, 14, 30])
            RadioListTile<int>(
              title: Text(loc.daysCount(days)),
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
    final newDoneRepository = FileTodoRepository(
        FileTodoRepository.donePathFor(path));

    await todoList.switchRepository(newRepository, newDoneRepository);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

const _sentinel = Object();
