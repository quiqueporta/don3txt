import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/shared_preferences_settings_repository.dart';
import 'package:don3txt/ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final defaultFilePath = '${directory.path}/todo.txt';
  final settingsRepository = SharedPreferencesSettingsRepository();

  final savedPath = await settingsRepository.loadTodoFilePath();

  if (savedPath != null) {
    await _requestStoragePermission();
  }

  final repository = FileTodoRepository(savedPath ?? defaultFilePath);

  runApp(Don3txtApp(
    repository: repository,
    settingsRepository: settingsRepository,
    defaultFilePath: defaultFilePath,
  ));
}

Future<void> _requestStoragePermission() async {
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}
