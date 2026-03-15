import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/widgets/midnight_widgets.dart';

void main() {
  group('MidnightCard Widget Tests', () {
    testWidgets('should display child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightCard(
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightCard(
              padding: const EdgeInsets.all(20),
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightCard),
              matching: find.byType(Container),
            )
            .first,
      );

      final padding = container.padding as EdgeInsets;
      expect(padding, const EdgeInsets.all(20));
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightCard(
              onTap: () => tapped = true,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MidnightCard));
      expect(tapped, true);
    });

    testWidgets('should apply custom border radius',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidnightCard(
              borderRadius: 8,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MidnightCard),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });
  });
}
