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

    testWidgets('renders projects and contexts as separate tags',
        (tester) async {
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

      expect(find.text('Family'), findsOneWidget);
      expect(find.text('phone'), findsOneWidget);
    });

    testWidgets('shows tag icon for projects', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(
                description: 'Call Mom',
                projects: ['+Family'],
              ),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tag), findsOneWidget);
    });

    testWidgets('shows alternate_email icon for contexts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(
                description: 'Call Mom',
                contexts: ['@phone'],
              ),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
    });

    testWidgets('shows no tag icons when no projects or contexts',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              item: TodoItem(description: 'Simple task'),
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tag), findsNothing);
      expect(find.byIcon(Icons.alternate_email), findsNothing);
    });
  });
}
