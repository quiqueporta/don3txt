import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_language.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/priority_colors.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/priority_color_palette.dart';

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
          _SectionHeader(title: loc.sectionUpcomingDays),
          for (final days in [3, 7, 14, 30])
            RadioListTile<int>(
              title: Text(loc.daysCount(days)),
              value: days,
              groupValue: settings.upcomingDays,
              onChanged: (value) => settings.setUpcomingDays(value!),
            ),
          const Divider(),
          _SectionHeader(title: loc.sectionPriorityColors),
          for (final letter in PriorityColors.supportedLetters)
            _PriorityColorTile(
              letter: letter,
              color: Color(settings.priorityColors.colorFor(letter)!),
              onPick: (picked) => settings.setPriorityColor(letter, picked),
            ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(loc.resetToDefaults),
            onTap: () => settings.resetPriorityColors(),
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

class _PriorityColorTile extends StatelessWidget {
  final String letter;
  final Color color;
  final ValueChanged<int> onPick;

  const _PriorityColorTile({
    required this.letter,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListTile(
      title: Text(loc.priorityLabel(letter)),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
      ),
      onTap: () => _showPicker(context),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final loc = AppLocalizations.of(context);

    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _PriorityColorPickerSheet(
        title: loc.priorityColorPickerTitle,
        currentColor: color,
      ),
    );

    if (picked != null) onPick(picked);
  }
}

class _PriorityColorPickerSheet extends StatelessWidget {
  final String title;
  final Color currentColor;

  const _PriorityColorPickerSheet({
    required this.title,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < kPriorityColorPalette.length; i++)
                  _ColorSwatch(
                    key: ValueKey('priority_color_swatch_$i'),
                    color: kPriorityColorPalette[i],
                    isSelected: kPriorityColorPalette[i].value == currentColor.value,
                    onTap: () =>
                        Navigator.of(context).pop(kPriorityColorPalette[i].value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black26,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
