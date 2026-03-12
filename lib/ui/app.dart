import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/ui/theme.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class Don3txtApp extends StatelessWidget {
  final TodoRepository repository;
  final SettingsRepository settingsRepository;

  const Don3txtApp({
    super.key,
    required this.repository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodoListNotifier(repository)..loadTasks(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsNotifier(settingsRepository)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'don3txt',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en')],
        home: const TaskListScreen(),
      ),
    );
  }
}
