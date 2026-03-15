import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/ui/widgets/task_input_bar.dart';

Widget buildTestApp({
  VoidCallback? onPickDate,
  VoidCallback? onPickStartDate,
  VoidCallback? onPickRecurrence,
  VoidCallback? onPickPriority,
  VoidCallback? onPickProjects,
  VoidCallback? onPickContexts,
  DateTime? selectedDate,
  DateTime? selectedStartDate,
  String? recurrence,
  String? priority,
  Set<String> selectedProjects = const {},
  Set<String> selectedContexts = const {},
  VoidCallback? onClearDate,
  VoidCallback? onClearStartDate,
  VoidCallback? onClearRecurrence,
  VoidCallback? onClearPriority,
  ValueChanged<String>? onRemoveProject,
  ValueChanged<String>? onRemoveContext,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TaskInputBar(
        onPickDate: onPickDate ?? () {},
        onPickStartDate: onPickStartDate ?? () {},
        onPickRecurrence: onPickRecurrence ?? () {},
        onPickPriority: onPickPriority ?? () {},
        onPickProjects: onPickProjects ?? () {},
        onPickContexts: onPickContexts ?? () {},
        selectedDate: selectedDate,
        selectedStartDate: selectedStartDate,
        recurrence: recurrence,
        priority: priority,
        selectedProjects: selectedProjects,
        selectedContexts: selectedContexts,
        onClearDate: onClearDate ?? () {},
        onClearStartDate: onClearStartDate ?? () {},
        onClearRecurrence: onClearRecurrence ?? () {},
        onClearPriority: onClearPriority ?? () {},
        onRemoveProject: onRemoveProject ?? (_) {},
        onRemoveContext: onRemoveContext ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('TaskInputBar', () {
    testWidgets('renders all icon buttons', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.byIcon(Icons.tag), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
    });

    testWidgets('calls onPickDate when calendar icon is tapped',
        (tester) async {
      var called = false;

      await tester.pumpWidget(buildTestApp(onPickDate: () => called = true));

      await tester.tap(find.byIcon(Icons.calendar_today));

      expect(called, isTrue);
    });

    testWidgets('calls onPickStartDate when event icon is tapped',
        (tester) async {
      var called = false;

      await tester
          .pumpWidget(buildTestApp(onPickStartDate: () => called = true));

      await tester.tap(find.byIcon(Icons.event_available));

      expect(called, isTrue);
    });

    testWidgets('calls onPickRecurrence when repeat icon is tapped',
        (tester) async {
      var called = false;

      await tester
          .pumpWidget(buildTestApp(onPickRecurrence: () => called = true));

      await tester.tap(find.byIcon(Icons.repeat));

      expect(called, isTrue);
    });

    testWidgets('calls onPickPriority when flag icon is tapped',
        (tester) async {
      var called = false;

      await tester
          .pumpWidget(buildTestApp(onPickPriority: () => called = true));

      await tester.tap(find.byIcon(Icons.flag));

      expect(called, isTrue);
    });

    testWidgets('calls onPickProjects when tag icon is tapped',
        (tester) async {
      var called = false;

      await tester
          .pumpWidget(buildTestApp(onPickProjects: () => called = true));

      await tester.tap(find.byIcon(Icons.tag));

      expect(called, isTrue);
    });

    testWidgets('calls onPickContexts when alternate_email icon is tapped',
        (tester) async {
      var called = false;

      await tester
          .pumpWidget(buildTestApp(onPickContexts: () => called = true));

      await tester.tap(find.byIcon(Icons.alternate_email));

      expect(called, isTrue);
    });

    testWidgets('shows priority chip when priority is set', (tester) async {
      await tester.pumpWidget(buildTestApp(priority: 'A'));

      expect(find.text('(A)'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('shows date chip when date is set', (tester) async {
      await tester
          .pumpWidget(buildTestApp(selectedDate: DateTime(2026, 3, 20)));

      expect(find.text('2026-03-20'), findsOneWidget);
    });

    testWidgets('shows start date chip when start date is set',
        (tester) async {
      await tester
          .pumpWidget(buildTestApp(selectedStartDate: DateTime(2026, 3, 18)));

      expect(find.textContaining('Start: 2026-03-18'), findsOneWidget);
    });

    testWidgets('shows recurrence chip when recurrence is set',
        (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: '2w'));

      expect(find.textContaining('Every 2 weeks'), findsOneWidget);
    });

    testWidgets('shows strict recurrence label', (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: '+1m'));

      expect(find.textContaining('(strict) Every 1 month'), findsOneWidget);
    });

    testWidgets('shows project chips', (tester) async {
      await tester
          .pumpWidget(buildTestApp(selectedProjects: {'+Casa', '+Trabajo'}));

      expect(find.text('+Casa'), findsOneWidget);
      expect(find.text('+Trabajo'), findsOneWidget);
    });

    testWidgets('shows context chips', (tester) async {
      await tester.pumpWidget(
          buildTestApp(selectedContexts: {'@telefono', '@oficina'}));

      expect(find.text('@telefono'), findsOneWidget);
      expect(find.text('@oficina'), findsOneWidget);
    });

    testWidgets('calls onClearPriority when priority chip is deleted',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
          buildTestApp(priority: 'A', onClearPriority: () => called = true));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('calls onRemoveProject when project chip is deleted',
        (tester) async {
      String? removed;

      await tester.pumpWidget(buildTestApp(
        selectedProjects: {'+Casa'},
        onRemoveProject: (p) => removed = p,
      ));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(removed, '+Casa');
    });

    testWidgets('calls onRemoveContext when context chip is deleted',
        (tester) async {
      String? removed;

      await tester.pumpWidget(buildTestApp(
        selectedContexts: {'@oficina'},
        onRemoveContext: (c) => removed = c,
      ));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(removed, '@oficina');
    });

    testWidgets('does not crash with empty recurrence string', (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: ''));

      expect(tester.takeException(), isNull);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('does not crash with single character recurrence',
        (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: 'd'));

      expect(tester.takeException(), isNull);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('does not crash with non-numeric recurrence amount',
        (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: 'Xm'));

      expect(tester.takeException(), isNull);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('shows raw string for malformed recurrence', (tester) async {
      await tester.pumpWidget(buildTestApp(recurrence: ''));

      expect(find.text(''), findsOneWidget);
    });
  });
}
