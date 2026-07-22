import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/payment.dart';

void main() {
  test('Overview calculations benchmark', () {
    // Generate a large collection of WorkEntry and Payment objects
    final entries = List.generate(
      10000,
      (index) => WorkEntry(
        id: 'entry-$index',
        clientId: 'client-1',
        clientName: 'Test Client',
        clientColor: '#000000',
        date: '01.01.2026',
        startTime: '09:00',
        endTime: '17:00',
        workType: 'Yazılım',
        billingType: 'hourly',
        hourlyRate: 100.0,
      ),
    );

    final payments = List.generate(
      5000,
      (index) => Payment(
        id: 'payment-$index',
        clientId: 'client-1',
        clientName: 'Test Client',
        clientColor: '#000000',
        amount: 200.0,
        date: '01.01.2026',
      ),
    );

    // Warm up
    for (int i = 0; i < 100; i++) {
      double totalEarned = 0;
      double totalHours = 0;
      for (final e in entries) {
        totalEarned += e.effectivePrice;
        totalHours += e.durationHours;
      }
      double totalReceived = 0;
      for (final p in payments) {
        totalReceived += p.amount;
      }
      expect(totalEarned, 8000000.0);
      expect(totalHours, 80000.0);
      expect(totalReceived, 1000000.0);
    }

    final stopwatch = Stopwatch()..start();

    // 1. Baseline loop-based calculations executed 100 times
    double baselineTotalEarned = 0;
    double baselineTotalHours = 0;
    double baselineTotalReceived = 0;

    for (int i = 0; i < 100; i++) {
      baselineTotalEarned = 0;
      baselineTotalHours = 0;
      for (final e in entries) {
        baselineTotalEarned += e.effectivePrice;
        baselineTotalHours += e.durationHours;
      }
      baselineTotalReceived = 0;
      for (final p in payments) {
        baselineTotalReceived += p.amount;
      }
    }

    stopwatch.stop();
    final baselineTime = stopwatch.elapsedMilliseconds;
    print('Baseline loop duration for 100 iterations: $baselineTime ms');

    // 2. Separate Fold-based calculations
    stopwatch.reset();
    stopwatch.start();

    double foldTotalEarned = 0;
    double foldTotalHours = 0;
    double foldTotalReceived = 0;

    for (int i = 0; i < 100; i++) {
      foldTotalEarned = entries.fold(0.0, (sum, e) => sum + e.effectivePrice);
      foldTotalHours = entries.fold(0.0, (sum, e) => sum + e.durationHours);
      foldTotalReceived = payments.fold(0.0, (sum, p) => sum + p.amount);
    }

    stopwatch.stop();
    final foldTime = stopwatch.elapsedMilliseconds;
    print('Fold (separate) duration for 100 iterations: $foldTime ms');

    // 3. Record-based Fold calculations
    stopwatch.reset();
    stopwatch.start();

    double recordFoldTotalEarned = 0;
    double recordFoldTotalHours = 0;
    double recordFoldTotalReceived = 0;

    for (int i = 0; i < 100; i++) {
      final (earned, hours) = entries.fold<(double, double)>(
        (0.0, 0.0),
        (acc, e) => (acc.$1 + e.effectivePrice, acc.$2 + e.durationHours),
      );
      recordFoldTotalEarned = earned;
      recordFoldTotalHours = hours;
      recordFoldTotalReceived = payments.fold(0.0, (sum, p) => sum + p.amount);
    }

    stopwatch.stop();
    final recordFoldTime = stopwatch.elapsedMilliseconds;
    print('Record fold duration for 100 iterations: $recordFoldTime ms');

    expect(foldTotalEarned, baselineTotalEarned);
    expect(foldTotalHours, baselineTotalHours);
    expect(foldTotalReceived, baselineTotalReceived);

    expect(recordFoldTotalEarned, baselineTotalEarned);
    expect(recordFoldTotalHours, baselineTotalHours);
    expect(recordFoldTotalReceived, baselineTotalReceived);
  });
}
