import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/todo_item.dart';
import 'package:don3txt/ui/widgets/task_tile.dart';

void main() {
  group('TaskTile', () {
    testWidgets('renders task description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(description: 'Buy milk'),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Buy milk'), findsOneWidget);
    });

    testWidgets('shows unchecked circle for pending task', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(description: 'Buy milk'),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('shows checked circle for completed task', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(description: 'Buy milk', isCompleted: true),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onToggle when checkbox tapped', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(description: 'Buy milk'),
              onToggle: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));

      expect(toggled, true);
    });

    testWidgets('renders projects and contexts in grey', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(
                description: 'Call Mom',
                projects: ['+Family'],
                contexts: ['@phone'],
              ),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('+Family @phone'), findsOneWidget);
    });
  });
}
