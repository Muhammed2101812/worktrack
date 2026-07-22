import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/work_entry.dart';

class SortHelper {
  final WorkEntry entry;
  final DateTime parsedDate;
  final String startTime;

  SortHelper(this.entry, this.parsedDate, this.startTime);
}

Map<DateTime, List<WorkEntry>> groupByDateOriginal(
    List<WorkEntry> entries, String selectedSort) {
  final grouped = <DateTime, List<WorkEntry>>{};
  for (final entry in entries) {
    try {
      final parts = entry.date.split('.');
      if (parts.length == 3) {
        final entryDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        final date = DateTime(entryDate.year, entryDate.month, entryDate.day);
        grouped.putIfAbsent(date, () => []).add(entry);
      }
    } catch (e) {}
  }

  // Sort keys based on selectedSort
  final sortedKeys = grouped.keys.toList();
  if (selectedSort == 'Tarih (En Eski)') {
    sortedKeys.sort((a, b) => a.compareTo(b)); // oldest first
  } else {
    sortedKeys.sort((a, b) => b.compareTo(a)); // newest first (default)
  }

  final sortedGrouped = <DateTime, List<WorkEntry>>{};
  for (final key in sortedKeys) {
    final list = grouped[key]!;
    // Sort entries within the same day by start time
    list.sort((a, b) {
      if (selectedSort == 'Tarih (En Eski)') {
        return a.startTime.compareTo(b.startTime);
      } else {
        return b.startTime.compareTo(a.startTime);
      }
    });
    sortedGrouped[key] = list;
  }

  return sortedGrouped;
}

Map<DateTime, List<WorkEntry>> groupByDateOptimized(
    List<WorkEntry> entries, String selectedSort) {
  final helpers = <SortHelper>[];
  for (final entry in entries) {
    try {
      final parts = entry.date.split('.');
      if (parts.length == 3) {
        final date = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        helpers.add(SortHelper(entry, date, entry.startTime));
      }
    } catch (_) {}
  }

  final isOldestFirst = selectedSort == 'Tarih (En Eski)';
  if (isOldestFirst) {
    helpers.sort((a, b) {
      final dateCompare = a.parsedDate.compareTo(b.parsedDate);
      if (dateCompare != 0) return dateCompare;
      return a.startTime.compareTo(b.startTime);
    });
  } else {
    helpers.sort((a, b) {
      final dateCompare = b.parsedDate.compareTo(a.parsedDate);
      if (dateCompare != 0) return dateCompare;
      return b.startTime.compareTo(a.startTime);
    });
  }

  final grouped = <DateTime, List<WorkEntry>>{};
  for (final helper in helpers) {
    grouped.putIfAbsent(helper.parsedDate, () => []).add(helper.entry);
  }

  return grouped;
}

void main() {
  test('groupByDate - Correctness and Performance Benchmark', () {
    // Generate mock entries: 1,000 entries across 100 different days with various start times
    final entries = <WorkEntry>[];
    for (int day = 1; day <= 100; day++) {
      final dateStr = '${day.toString().padLeft(2, '0')}.03.2026';
      for (int hour = 8; hour < 18; hour++) {
        final startHour = hour.toString().padLeft(2, '0');
        final endHour = (hour + 1).toString().padLeft(2, '0');
        entries.add(WorkEntry(
          clientId: 'client-1',
          clientName: 'Client 1',
          clientColor: '#FF0000',
          date: dateStr,
          startTime: '$startHour:00',
          endTime: '$endHour:00',
          workType: 'Software Development',
        ));
      }
    }

    // --- Correctness Verification ---
    for (final sortOption in ['Tarih (En Yeni)', 'Tarih (En Eski)']) {
      final originalResult = groupByDateOriginal(entries, sortOption);
      final optimizedResult = groupByDateOptimized(entries, sortOption);

      expect(optimizedResult.length, equals(originalResult.length));
      final originalKeys = originalResult.keys.toList();
      final optimizedKeys = optimizedResult.keys.toList();
      expect(optimizedKeys, equals(originalKeys));

      for (final key in originalKeys) {
        final originalList = originalResult[key]!;
        final optimizedList = optimizedResult[key]!;
        expect(optimizedList.length, equals(originalList.length));
        for (int i = 0; i < originalList.length; i++) {
          expect(optimizedList[i].id, equals(originalList[i].id));
          expect(optimizedList[i].startTime, equals(originalList[i].startTime));
        }
      }
    }

    // --- Performance Benchmark ---
    // Warm up
    for (int i = 0; i < 5; i++) {
      groupByDateOriginal(entries, 'Tarih (En Yeni)');
      groupByDateOptimized(entries, 'Tarih (En Yeni)');
    }

    final stopwatch = Stopwatch();

    // Benchmark Original (Newest First)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 200; i++) {
      groupByDateOriginal(entries, 'Tarih (En Yeni)');
    }
    stopwatch.stop();
    final originalNewestMs = stopwatch.elapsedMilliseconds;

    // Benchmark Optimized (Newest First)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 200; i++) {
      groupByDateOptimized(entries, 'Tarih (En Yeni)');
    }
    stopwatch.stop();
    final optimizedNewestMs = stopwatch.elapsedMilliseconds;

    // Benchmark Original (Oldest First)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 200; i++) {
      groupByDateOriginal(entries, 'Tarih (En Eski)');
    }
    stopwatch.stop();
    final originalOldestMs = stopwatch.elapsedMilliseconds;

    // Benchmark Optimized (Oldest First)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 200; i++) {
      groupByDateOptimized(entries, 'Tarih (En Eski)');
    }
    stopwatch.stop();
    final optimizedOldestMs = stopwatch.elapsedMilliseconds;

    print(
        '=== Grouping & Sorting Benchmark (200 iterations over 1000 items) ===');
    print('Original (Newest First): $originalNewestMs ms');
    print('Optimized (Newest First): $optimizedNewestMs ms');
    print(
        'Speed-up (Newest First): ${(originalNewestMs / optimizedNewestMs).toStringAsFixed(2)}x');
    print('--------------------------------------------------');
    print('Original (Oldest First): $originalOldestMs ms');
    print('Optimized (Oldest First): $optimizedOldestMs ms');
    print(
        'Speed-up (Oldest First): ${(originalOldestMs / optimizedOldestMs).toStringAsFixed(2)}x');
    print(
        '=====================================================================');
  });
}
