import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/app_theme_mode.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored;
  String? _todoFilePath;

  InMemorySettingsRepository([this._stored = StartOfWeek.monday]);

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
  }

  @override
  Future<String?> loadTodoFilePath() async => _todoFilePath;

  @override
  Future<void> saveTodoFilePath(String? path) async {
    _todoFilePath = path;
  }

  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  Future<AppThemeMode> loadThemeMode() async => _themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode value) async {
    _themeMode = value;
  }
}

Widget buildTestApp({
  required void Function(String text, {DateTime? dueDate, String? recurrence}) onSubmit,
  SettingsNotifier? settingsNotifier,
}) {
  settingsNotifier ??= SettingsNotifier(InMemorySettingsRepository());

  return ChangeNotifierProvider.value(
    value: settingsNotifier,
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      home: Scaffold(
        body: AddTaskField(onSubmit: onSubmit),
      ),
    ),
  );
}

Future<void> confirmDatePicker(WidgetTester tester) async {
  final okButton = find.byWidgetPredicate(
    (widget) => widget is TextButton,
  );
  await tester.tap(okButton.last);
}

void main() {
  group('AddTaskField', () {
    testWidgets('renders text field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('calls onSubmit with text when submitted', (tester) async {
      String? submitted;

      await tester.pumpWidget(
        buildTestApp(onSubmit: (text, {dueDate, recurrence}) => submitted = text),
      );

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, 'Buy milk');
    });

    testWidgets('clears field after submit', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('has calendar icon button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows date chip after selecting date', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await confirmDatePicker(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('can clear selected date', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await confirmDatePicker(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('onSubmit receives dueDate when date is selected', (tester) async {
      DateTime? receivedDate;

      await tester.pumpWidget(
        buildTestApp(onSubmit: (text, {dueDate, recurrence}) => receivedDate = dueDate),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await confirmDatePicker(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(receivedDate, isNotNull);
    });

    testWidgets('clears date after submit', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await confirmDatePicker(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('DatePicker uses monday locale when startOfWeek is monday', (tester) async {
      final settings = SettingsNotifier(InMemorySettingsRepository());
      await settings.load();

      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}, settingsNotifier: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );

      expect(localizations.firstDayOfWeekIndex, 1);
    });

    testWidgets('DatePicker uses sunday locale when startOfWeek is sunday', (tester) async {
      final settings = SettingsNotifier(
        InMemorySettingsRepository(StartOfWeek.sunday),
      );
      await settings.load();

      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}, settingsNotifier: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );

      expect(localizations.firstDayOfWeekIndex, 0);
    });

    testWidgets('has repeat icon button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );

      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('shows recurrence chip after selecting recurrence',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(onSubmit: (_, {dueDate, recurrence}) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.repeat));
      await tester.pumpAndSettle();

      expect(find.text('Every'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Every'), findsOneWidget);
    });

    testWidgets('onSubmit receives recurrence when set', (tester) async {
      String? receivedRec;

      await tester.pumpWidget(
        buildTestApp(
            onSubmit: (text, {dueDate, recurrence}) =>
                receivedRec = recurrence),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.repeat));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Pay bills');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(receivedRec, isNotNull);
    });
  });
}
