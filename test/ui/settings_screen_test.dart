import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored = StartOfWeek.monday;

  InMemorySettingsRepository([StartOfWeek? initial]) {
    if (initial != null) _stored = initial;
  }

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
  }
}

Widget buildTestApp(SettingsNotifier notifier) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: notifier,
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  late SettingsNotifier notifier;

  setUp(() {
    notifier = SettingsNotifier(InMemorySettingsRepository());
  });

  group('SettingsScreen', () {
    testWidgets('shows Monday and Sunday options', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('Monday is selected by default', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      final mondayRadio = tester.widget<RadioListTile<StartOfWeek>>(
        find.byWidgetPredicate(
          (w) => w is RadioListTile<StartOfWeek> && w.value == StartOfWeek.monday,
        ),
      );

      expect(mondayRadio.groupValue, StartOfWeek.monday);
    });

    testWidgets('tapping Sunday changes selection', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();

      expect(notifier.startOfWeek, StartOfWeek.sunday);
    });

    testWidgets('shows Settings as title', (tester) async {
      await tester.pumpWidget(buildTestApp(notifier));

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
