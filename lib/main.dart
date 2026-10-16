import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:don3txt/infrastructure/android_storage_permission.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/shared_preferences_settings_repository.dart';
import 'package:don3txt/infrastructure/storage_permission.dart';
import 'package:don3txt/infrastructure/unrestricted_storage_permission.dart';
import 'package:don3txt/ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final defaultFilePath = '${directory.path}/todo.txt';
  final settingsRepository = SharedPreferencesSettingsRepository();
  final storagePermission = _storagePermissionForPlatform();

  final savedPath = await settingsRepository.loadTodoFilePath();

  if (savedPath != null) {
    await storagePermission.request();
  }

  final todoPath = savedPath ?? defaultFilePath;
  final repository = FileTodoRepository(todoPath);
  final doneRepository = FileTodoRepository(
      FileTodoRepository.donePathFor(todoPath));

  runApp(Don3txtApp(
    repository: repository,
    doneRepository: doneRepository,
    settingsRepository: settingsRepository,
    storagePermission: storagePermission,
    defaultFilePath: defaultFilePath,
  ));
}

StoragePermission _storagePermissionForPlatform() {
  if (Platform.isAndroid) return AndroidStoragePermission();

  return UnrestrictedStoragePermission();
}
