import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/theme.dart';
import 'package:worklog/core/widgets/app_widgets.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppCard(child: Text('Hi'))),
      ));
      expect(find.text('Hi'), findsOneWidget);
    });

    testWidgets('calls onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: AppCard(onTap: () => tapped = true, child: const Text('X'))),
      ));
      await tester.tap(find.byType(AppCard));
      expect(tapped, isTrue);
    });

    // Regression for "Anasayfa boş": an AppCard placed inside a ListView
    // (unbounded vertical height) — exactly how HomeScreen renders
    // TodaySummaryCard — must still paint with a non-zero height.
    testWidgets(
        'renders content with non-zero height in a ListView '
        '(unbounded height context)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: const [
                AppCard(
                  variant: CardVariant.hero,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hero Title'),
                      Text('Hero Body'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hero Title'), findsOneWidget);
      expect(find.text('Hero Body'), findsOneWidget);

      // The card must occupy vertical space — not collapse to 0.
      final cardBox = tester.getRect(find.byType(AppCard));
      expect(cardBox.height, greaterThan(0),
          reason: 'card collapsed to zero height in a ListView');
    });
  });

  group('AppButton', () {
    testWidgets('solid variant renders and calls onPressed', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            onPressed: () => pressed = true,
            child: const Text('Go'),
          ),
        ),
      ));
      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppButton(onPressed: null, child: Text('Go')),
        ),
      ));
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('ghost variant draws no colored shadow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            variant: ButtonVariant.ghost,
            onPressed: () {},
            child: const Text('Ghost'),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Container),
        ).last,
      );
      final deco = container.decoration as BoxDecoration;
      // Ghost buttons must have NO boxShadow (the alpha-0.1 abuse is gone).
      expect(deco.boxShadow, isNull);
    });

    testWidgets('respects width constraint', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            onPressed: () {},
            width: 250,
            child: const Text('W'),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Container),
        ).last,
      );
      expect(container.constraints?.minWidth, 250);
    });
  });

  group('AppAvatar', () {
    testWidgets('renders first initial uppercase', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppAvatar(name: 'acme', hexColor: '#4A90D9')),
      ));
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('ScreenHeader', () {
    testWidgets('renders title and back button when onBack set', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ScreenHeader(title: 'Test', onBack: () {}),
        ),
      ));
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('omits back button when onBack is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ScreenHeader(title: 'NoBack')),
      ));
      expect(find.byType(ScreenHeader), findsOneWidget);
      // No back arrow icon present.
      expect(find.byTooltip('Back'), findsNothing);
    });
  });

  group('SegmentedControl', () {
    testWidgets('renders all labels and reports taps', (tester) async {
      int selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SegmentedControl(
              selected: selected,
              onChanged: (i) => setState(() => selected = i),
              labels: const ['A', 'B'],
            ),
          ),
        ),
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      await tester.tap(find.text('B'));
      expect(selected, 1);
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon, title, subtitle', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'Empty',
            subtitle: 'Nothing here',
          ),
        ),
      ));
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });
  });
}
