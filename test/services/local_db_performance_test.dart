import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/services/local_db_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Benchmark DB insertion speed: loop vs batch', () async {
    final localDB = LocalDBService();

    // Generate 100 test entries
    final entries = List.generate(100, (i) => WorkEntry(
      id: 'entry_$i',
      clientId: 'client_1',
      clientName: 'Client 1',
      clientColor: '#4A90D9',
      date: '20.03.2026',
      startTime: '09:00',
      endTime: '17:00',
      workType: 'Yazılım',
      notes: 'Notes for entry $i',
      synced: false,
    ));

    // Clear db
    await localDB.clearEntries();

    // 1. Loop insertion (baseline)
    final stopwatchLoop = Stopwatch()..start();
    for (final e in entries) {
      await localDB.insertEntry(e);
    }
    stopwatchLoop.stop();
    print('Baseline Loop: Inserted 100 entries in ${stopwatchLoop.elapsedMilliseconds} ms');

    // Confirm entries were inserted
    final insertedCount = (await localDB.getAllEntries()).length;
    expect(insertedCount, equals(100));

    // Clear db again
    await localDB.clearEntries();

    // 2. Batched insertion (optimized)
    final db = await localDB.database;
    final stopwatchBatch = Stopwatch()..start();
    final batch = db.batch();
    for (final e in entries) {
      batch.insert('work_entries', e.toLocalMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    stopwatchBatch.stop();
    print('Optimized Batch: Inserted 100 entries in ${stopwatchBatch.elapsedMilliseconds} ms');

    final insertedBatchCount = (await localDB.getAllEntries()).length;
    expect(insertedBatchCount, equals(100));
  });
}
