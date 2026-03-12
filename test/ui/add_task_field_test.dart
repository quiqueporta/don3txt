import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/ui/widgets/add_task_field.dart';

void main() {
  group('AddTaskField', () {
    testWidgets('renders text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskField(onSubmit: (_) {}),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('calls onSubmit with text when submitted', (tester) async {
      String? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskField(onSubmit: (text) => submitted = text),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, 'Buy milk');
    });

    testWidgets('clears field after submit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskField(onSubmit: (_) {}),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });
  });
}
