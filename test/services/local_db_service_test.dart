import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDBService Batch Operations Tests', () {
    late LocalDBService dbService;

    setUp(() async {
      dbService = LocalDBService();
      await dbService.clearClients();
      await dbService.clearEntries();
    });

    test('should insert clients in batch successfully', () async {
      final clients = [
        Client(id: 'c1', name: 'Client 1', color: '#111111'),
        Client(id: 'c2', name: 'Client 2', color: '#222222'),
        Client(id: 'c3', name: 'Client 3', color: '#333333'),
      ];

      await dbService.insertClientsBatch(clients);

      final retrieved = await dbService.getAllClients();
      expect(retrieved.length, equals(3));
      expect(retrieved.any((c) => c.id == 'c1' && c.name == 'Client 1'), isTrue);
      expect(retrieved.any((c) => c.id == 'c2' && c.name == 'Client 2'), isTrue);
      expect(retrieved.any((c) => c.id == 'c3' && c.name == 'Client 3'), isTrue);
    });

    test('should insert entries in batch successfully', () async {
      final entries = [
        WorkEntry(
          id: 'e1',
          clientId: 'c1',
          clientName: 'Client 1',
          clientColor: '#111111',
          date: '01.01.2025',
          startTime: '09:00',
          endTime: '10:00',
          workType: 'Development',
        ),
        WorkEntry(
          id: 'e2',
          clientId: 'c1',
          clientName: 'Client 1',
          clientColor: '#111111',
          date: '02.01.2025',
          startTime: '10:00',
          endTime: '12:00',
          workType: 'Design',
        ),
      ];

      await dbService.insertEntriesBatch(entries);

      final retrieved = await dbService.getAllEntries();
      expect(retrieved.length, equals(2));
      expect(retrieved.any((e) => e.id == 'e1' && e.workType == 'Development'), isTrue);
      expect(retrieved.any((e) => e.id == 'e2' && e.workType == 'Design'), isTrue);
    });

    test('insertClientsBatch should handle empty list gracefully', () async {
      await expectLater(dbService.insertClientsBatch([]), completes);
    });

    test('insertEntriesBatch should handle empty list gracefully', () async {
      await expectLater(dbService.insertEntriesBatch([]), completes);
    });
  });
}
