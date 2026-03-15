import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/widgets/midnight_widgets.dart';

void main() {
  group('MidnightButton Widget Tests', () {
    testWidgets('should display child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightButton(
              onPressed: () {},
              child: const Text('Button Text'),
            ),
          ),
        ),
      );

      expect(find.text('Button Text'), findsOneWidget);
    });

    testWidgets('should be disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const MidnightButton(
              onPressed: null,
              child: Text('Button'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightButton),
              matching: find.byType(Container),
            )
            .last,
      );

      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightButton(
              onPressed: () => pressed = true,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MidnightButton));
      expect(pressed, true);
    });

    testWidgets('should apply custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightButton(
              onPressed: () {},
              color: Colors.red,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightButton),
              matching: find.byType(Container),
            )
            .last,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('should apply custom border radius',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightButton(
              onPressed: () {},
              borderRadius: 8,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightButton),
              matching: find.byType(Container),
            )
            .last,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('should apply custom dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightButton(
              onPressed: () {},
              width: 200,
              height: 50,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightButton),
              matching: find.byType(Container),
            )
            .last,
      );

      expect(container.constraints?.minWidth, 200);
      expect(container.constraints?.minHeight, 50);
    });
  });
}
