import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/ui/theme.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class Don3txtApp extends StatelessWidget {
  final TodoRepository repository;
  final SettingsRepository settingsRepository;
  final String defaultFilePath;

  const Don3txtApp({
    super.key,
    required this.repository,
    required this.settingsRepository,
    required this.defaultFilePath,
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
        Provider<String>.value(value: defaultFilePath),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (_, settings, __) {
          return MaterialApp(
            title: 'don3txt',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: _toThemeMode(settings.themeMode),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es'), Locale('en')],
            home: const TaskListScreen(),
          );
        },
      ),
    );
  }
}

ThemeMode _toThemeMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
}
