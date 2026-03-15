import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/screens/home/widgets/entry_list_tile.dart';
import 'package:worklog/models/work_entry.dart';

void main() {
  group('EntryListTile Widget Tests', () {
    testWidgets('should display entry information',
        (WidgetTester tester) async {
      final entry = WorkEntry(
        id: '1',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
        notes: 'Test notes',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EntryListTile(entry: entry),
            ),
          ),
        ),
      );

      expect(find.text('Test Client'), findsOneWidget);
      expect(find.text('Yazılım'), findsOneWidget);
      expect(find.text('3.0 sa'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
    });

    testWidgets('should show first letter of client name',
        (WidgetTester tester) async {
      final entry = WorkEntry(
        id: '1',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EntryListTile(entry: entry),
            ),
          ),
        ),
      );

      expect(find.text('T'), findsOneWidget);
    });
  });
}
