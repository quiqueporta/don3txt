import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/text_size.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/infrastructure/file_todo_repository.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/infrastructure/storage_permission.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/theme.dart';
import 'package:don3txt/ui/screens/task_list_screen.dart';

class Don3txtApp extends StatelessWidget {
  final TodoRepository repository;
  final TodoRepository doneRepository;
  final SettingsRepository settingsRepository;
  final StoragePermission storagePermission;
  final String defaultFilePath;

  const Don3txtApp({
    super.key,
    required this.repository,
    required this.doneRepository,
    required this.settingsRepository,
    required this.storagePermission,
    required this.defaultFilePath,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodoListNotifier(repository, doneRepository)..loadTasks(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsNotifier(settingsRepository)..load(),
        ),
        Provider<String>.value(value: defaultFilePath),
        Provider<StoragePermission>.value(value: storagePermission),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (_, settings, _) {
          return MaterialApp(
            title: 'don3txt',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: _toThemeMode(settings.themeMode),
            locale: settings.language.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                _withTextSize(context, settings.textSize, child!),
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

Widget _withTextSize(BuildContext context, TextSize textSize, Widget child) {
  final media = MediaQuery.of(context);
  final systemScale = media.textScaler.scale(1);

  return MediaQuery(
    data: media.copyWith(
      textScaler: TextScaler.linear(systemScale * textSize.scale),
    ),
    child: child,
  );
}
