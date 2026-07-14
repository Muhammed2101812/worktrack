import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog/core/theme.dart';
import 'package:worklog/screens/home/widgets/today_summary_card.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/providers/entries_provider.dart';

class FakeEntriesNotifier extends EntriesNotifier {
  final List<WorkEntry> _entries;
  FakeEntriesNotifier(this._entries);

  @override
  Future<List<WorkEntry>> build() async {
    return _entries;
  }
}

class FakeLoadingEntriesNotifier extends EntriesNotifier {
  @override
  Future<List<WorkEntry>> build() {
    return Completer<List<WorkEntry>>().future;
  }
}

void main() {
  group('TodaySummaryCard Widget Tests', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesProvider.overrideWith(() => FakeLoadingEntriesNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
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
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
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
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: TodaySummaryCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('0 Çalışma'), findsOneWidget);
    });

    // Regression for "Anasayfa boş": HomeScreen renders TodaySummaryCard
    // directly inside a ListView (unbounded vertical height). In that context
    // the AppCard ledger Row must not collapse the content to zero height.
    testWidgets(
        'renders summary content inside a ListView (home-screen layout)',
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
          endTime: '11:00',
          workType: 'Yazılım',
          synced: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesProvider.overrideWith(() => FakeEntriesNotifier(entries)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: ListView(
                children: const [TodaySummaryCard()],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // These texts live inside the ledger AppCard's Column; if the ledger
      // Row collapses the height they will not paint / be findable.
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 hours
      expect(find.text('1 Çalışma'), findsOneWidget);
    });
  });
}
