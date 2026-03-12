import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final repository = FileTodoRepository(directory.path);

  runApp(Don3txtApp(repository: repository));
}
