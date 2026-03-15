import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/ui/widgets/tag_picker_sheet.dart';

Widget buildTestApp({
  required String title,
  required String prefix,
  List<String> available = const [],
  Set<String> selected = const {},
  ValueChanged<Set<String>>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TagPickerSheet(
        title: title,
        prefix: prefix,
        available: available,
        selected: selected,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('TagPickerSheet', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
      ));

      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('renders available items as FilterChips', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa', '+Trabajo'],
      ));

      expect(find.text('+Casa'), findsOneWidget);
      expect(find.text('+Trabajo'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testWidgets('marks selected items', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa', '+Trabajo'],
        selected: {'+Casa'},
      ));

      final casaChip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('+Casa'),
          matching: find.byType(FilterChip),
        ),
      );

      final trabajoChip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('+Trabajo'),
          matching: find.byType(FilterChip),
        ),
      );

      expect(casaChip.selected, isTrue);
      expect(trabajoChip.selected, isFalse);
    });

    testWidgets('toggling a chip calls onChanged with updated selection',
        (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa', '+Trabajo'],
        selected: {'+Casa'},
        onChanged: (s) => result = s,
      ));

      await tester.tap(find.text('+Trabajo'));
      await tester.pump();

      expect(result, {'+Casa', '+Trabajo'});
    });

    testWidgets('deselecting a chip removes it from selection',
        (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa', '+Trabajo'],
        selected: {'+Casa', '+Trabajo'},
        onChanged: (s) => result = s,
      ));

      await tester.tap(find.text('+Casa'));
      await tester.pump();

      expect(result, {'+Trabajo'});
    });

    testWidgets('has a text field to create new items', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Contexts',
        prefix: '@',
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('creates new item with prefix on submit', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Contexts',
        prefix: '@',
        available: ['@casa'],
        selected: {'@casa'},
        onChanged: (s) => result = s,
      ));

      await tester.enterText(find.byType(TextField), 'oficina');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, {'@casa', '@oficina'});
    });

    testWidgets('does not create empty item', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Contexts',
        prefix: '@',
        onChanged: (s) => result = s,
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('does not create item with spaces', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Contexts',
        prefix: '@',
        onChanged: (s) => result = s,
      ));

      await tester.enterText(find.byType(TextField), 'has space');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('does not create duplicate item', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa'],
        selected: {'+Casa'},
        onChanged: (s) => result = s,
      ));

      await tester.enterText(find.byType(TextField), 'Casa');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('clears text field after creating item', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Contexts',
        prefix: '@',
      ));

      await tester.enterText(find.byType(TextField), 'oficina');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('rejects input longer than 100 characters', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        onChanged: (s) => result = s,
      ));

      final longInput = 'a' * 101;
      await tester.enterText(find.byType(TextField), longInput);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('strips prefix if user includes it', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        onChanged: (s) => result = s,
      ));

      await tester.enterText(find.byType(TextField), '+MiProyecto');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, {'+MiProyecto'});
    });

    testWidgets('shows error for empty input', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error for input with spaces', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
      ));

      await tester.enterText(find.byType(TextField), 'has space');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Cannot contain spaces'), findsOneWidget);
    });

    testWidgets('shows error for input longer than 100 chars', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
      ));

      await tester.enterText(find.byType(TextField), 'a' * 101);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Maximum 100 characters'), findsOneWidget);
    });

    testWidgets('shows error for duplicate item', (tester) async {
      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa'],
      ));

      await tester.enterText(find.byType(TextField), 'Casa');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Already exists'), findsOneWidget);
    });

    testWidgets('closes sheet when selecting an existing item',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => TagPickerSheet(
                    title: 'Projects',
                    prefix: '+',
                    available: ['+Casa'],
                    onChanged: (_) {},
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TagPickerSheet), findsOneWidget);

      await tester.tap(find.text('+Casa'));
      await tester.pumpAndSettle();

      expect(find.byType(TagPickerSheet), findsNothing);
    });

    testWidgets('closes sheet when creating a new item', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => TagPickerSheet(
                    title: 'Projects',
                    prefix: '+',
                    onChanged: (_) {},
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TagPickerSheet), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'NuevoProyecto');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(TagPickerSheet), findsNothing);
    });

    testWidgets('adds bottom padding for keyboard insets', (tester) async {
      const fakeInsets = EdgeInsets.only(bottom: 300);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(viewInsets: fakeInsets),
            child: TagPickerSheet(
              title: 'Projects',
              prefix: '+',
              onChanged: (_) {},
            ),
          ),
        ),
      ));

      final padding = tester.widget<Padding>(
        find.byType(Padding).first,
      );

      expect(
        (padding.padding as EdgeInsets).bottom,
        greaterThanOrEqualTo(300),
      );
    });

    testWidgets('detects duplicate with different case', (tester) async {
      Set<String>? result;

      await tester.pumpWidget(buildTestApp(
        title: 'Projects',
        prefix: '+',
        available: ['+Casa'],
        onChanged: (s) => result = s,
      ));

      await tester.enterText(find.byType(TextField), 'casa');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, isNull);
      expect(find.text('Already exists'), findsOneWidget);
    });
  });
}
