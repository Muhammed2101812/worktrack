import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/screens/home/widgets/today_summary_card.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/providers/entries_provider.dart';

void main() {
  group('TodaySummaryCard Widget Tests', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayEntriesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TodaySummaryCard(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display summary with entries',
        (WidgetTester tester) async {
      final entries = [
        WorkEntry(
          id: '1',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
        ),
        WorkEntry(
          id: '2',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '13:00',
          endTime: '17:30',
          workType: 'Yazılım',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayEntriesProvider.overrideWith((ref) => Future.value(entries)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TodaySummaryCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('2 Çalışma'), findsOneWidget);
      expect(find.text('Senkronize'), findsOneWidget);
    });

    testWidgets('should display 0 hours when no entries',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayEntriesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TodaySummaryCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('0 Çalışma'), findsOneWidget);
    });
  });
}
