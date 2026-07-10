import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog/screens/home/widgets/today_summary_card.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/providers/entries_provider.dart';

class FakeEntriesNotifier extends EntriesNotifier {
  final List<WorkEntry> initialEntries;
  FakeEntriesNotifier(this.initialEntries);

  @override
  Future<List<WorkEntry>> build() async {
    return initialEntries;
  }
}

void main() {
  group('TodaySummaryCard Widget Tests', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
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
      final todayStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
      final entries = [
        WorkEntry(
          id: '1',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: todayStr,
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
          synced: true,
        ),
        WorkEntry(
          id: '2',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: todayStr,
          startTime: '13:00',
          endTime: '17:30',
          workType: 'Yazılım',
          synced: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesProvider.overrideWith(() => FakeEntriesNotifier(entries)),
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
            entriesProvider.overrideWith(() => FakeEntriesNotifier([])),
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
