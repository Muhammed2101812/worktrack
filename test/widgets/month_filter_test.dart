import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:worklog/screens/history/widgets/month_filter.dart';

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'tr_TR';
    initializeDateFormatting();
  });

  group('MonthFilter Widget Tests', () {
    testWidgets('should display navigation buttons',
        (WidgetTester tester) async {
      final now = DateTime(2026, 3, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthFilter(
              selectedMonth: now,
              onMonthChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
