import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/screens/home/widgets/finance_summary_card.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/payment.dart';

void main() {
  group('FinanceSummaryCard Widget Tests', () {
    testWidgets('should display correct financial totals', (WidgetTester tester) async {
      final entries = [
        WorkEntry(
          id: '1',
          clientId: 'client1',
          clientName: 'Client 1',
          clientColor: '#ff0000',
          date: '01.01.2023',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Hourly',
          hourlyRate: 100.0,
          totalPrice: 0.0,
          synced: true,
        ),
        WorkEntry(
          id: '2',
          clientId: 'client2',
          clientName: 'Client 2',
          clientColor: '#00ff00',
          date: '02.01.2023',
          startTime: '10:00',
          endTime: '11:00',
          workType: 'Fixed',
          hourlyRate: 0.0,
          totalPrice: 150.0,
          synced: true,
        ),
      ];

      final payments = [
        Payment(
          id: 'p1',
          clientId: 'client1',
          clientName: 'Client 1',
          clientColor: '#ff0000',
          amount: 200.0,
          date: '03.01.2023',
          synced: true,
        ),
      ];

      // totalEarned = (3 hours * 100.0) + 150.0 = 450.0
      // totalReceived = 200.0
      // remainingBalance = 450.0 - 200.0 = 250.0

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinanceSummaryCard(
              entries: entries,
              payments: payments,
              currency: 'TL',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check text matches
      expect(find.text('Kalan Alacak'), findsOneWidget);
      expect(find.text('250.0 TL'), findsOneWidget);
      expect(find.text('Toplam Hakediş'), findsOneWidget);
      expect(find.text('450.0 TL'), findsOneWidget);
      expect(find.text('Alınan Ödeme'), findsOneWidget);
      expect(find.text('200.0 TL'), findsOneWidget);
    });
  });
}
