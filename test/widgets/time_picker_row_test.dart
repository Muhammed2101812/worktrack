import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/screens/add_entry/widgets/time_picker_row.dart';
import 'package:worklog/core/theme.dart';
import 'package:worklog/core/widgets/app_widgets.dart';

void main() {
  group('TimePickerRow Widget Tests', () {
    testWidgets('should display time pickers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TimePickerRow(
              startTime: '09:00',
              endTime: '12:00',
              onStartTimeChanged: (_) {},
              onEndTimeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('BAŞLANGIÇ'), findsOneWidget);
      expect(find.text('BİTİŞ'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('should render cards as AppCard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TimePickerRow(
              startTime: '09:00',
              endTime: '12:00',
              onStartTimeChanged: (_) {},
              onEndTimeChanged: (_) {},
            ),
          ),
        ),
      );

      // 2 time-picker cards + 1 total card = 3 AppCard instances.
      expect(find.byType(AppCard), findsNWidgets(3));
    });

    testWidgets('should display calculated duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TimePickerRow(
              startTime: '09:00',
              endTime: '12:30',
              onStartTimeChanged: (_) {},
              onEndTimeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Toplam: 3.5 saat'), findsOneWidget);
    });

    testWidgets('should show 21.0 for overnight range', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TimePickerRow(
              startTime: '12:00',
              endTime: '09:00',
              onStartTimeChanged: (_) {},
              onEndTimeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Toplam: 21.0 saat'), findsOneWidget);
    });
  });
}
