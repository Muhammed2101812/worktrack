import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/project.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDBService Tests', () {
    late LocalDBService dbService;

    setUp(() async {
      dbService = LocalDBService();
      try {
        await dbService.clearEntries();
        await dbService.clearClients();
        await dbService.clearProjects();
      } catch (_) {}
    });

    tearDown(() async {
      try {
        await dbService.clearEntries();
        await dbService.clearClients();
        await dbService.clearProjects();
      } catch (_) {}
    });

    group('Work Entries Operations', () {
      final sampleEntry = WorkEntry(
        id: 'entry-1',
        clientId: 'client-1',
        clientName: 'Client A',
        clientColor: '#FF0000',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Software',
        notes: 'Developing unit tests',
        synced: false,
      );

      test('insertEntry and getAllEntries', () async {
        await dbService.insertEntry(sampleEntry);
        final entries = await dbService.getAllEntries();

        expect(entries, hasLength(1));
        expect(entries.first.id, 'entry-1');
        expect(entries.first.clientName, 'Client A');
        expect(entries.first.synced, false);
      });

      test('getTodayEntries', () async {
        final entryToday = WorkEntry(
          id: 'entry-today',
          clientId: 'client-1',
          clientName: 'Client A',
          clientColor: '#FF0000',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Software',
          notes: 'Developing unit tests',
          synced: false,
        );
        final entryOtherDay = WorkEntry(
          id: 'entry-other',
          clientId: 'client-1',
          clientName: 'Client A',
          clientColor: '#FF0000',
          date: '16.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Software',
          notes: 'Developing unit tests',
          synced: false,
        );

        await dbService.insertEntry(entryToday);
        await dbService.insertEntry(entryOtherDay);

        final todayEntries = await dbService.getTodayEntries('15.03.2026');
        expect(todayEntries, hasLength(1));
        expect(todayEntries.first.id, 'entry-today');
      });

      test('getUnsyncedEntries', () async {
        final entryUnsynced = WorkEntry(
          id: 'entry-unsynced',
          clientId: 'client-1',
          clientName: 'Client A',
          clientColor: '#FF0000',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Software',
          notes: 'Developing unit tests',
          synced: false,
        );
        final entrySynced = WorkEntry(
          id: 'entry-synced',
          clientId: 'client-1',
          clientName: 'Client A',
          clientColor: '#FF0000',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Software',
          notes: 'Developing unit tests',
          synced: true,
        );

        await dbService.insertEntry(entryUnsynced);
        await dbService.insertEntry(entrySynced);

        final unsynced = await dbService.getUnsyncedEntries();
        expect(unsynced, hasLength(1));
        expect(unsynced.first.id, 'entry-unsynced');
      });

      test('updateEntrySync', () async {
        await dbService.insertEntry(sampleEntry);
        await dbService.updateEntrySync('entry-1', true);

        final entries = await dbService.getAllEntries();
        expect(entries.first.synced, true);
      });

      test('updateEntry', () async {
        await dbService.insertEntry(sampleEntry);
        final updatedEntry = sampleEntry.copyWith(notes: 'Updated description', synced: true);

        await dbService.updateEntry(updatedEntry);

        final entries = await dbService.getAllEntries();
        expect(entries.first.notes, 'Updated description');
        expect(entries.first.synced, true);
      });

      test('deleteEntry', () async {
        await dbService.insertEntry(sampleEntry);
        expect(await dbService.getAllEntries(), hasLength(1));

        await dbService.deleteEntry('entry-1');
        expect(await dbService.getAllEntries(), isEmpty);
      });

      test('clearEntries', () async {
        await dbService.insertEntry(sampleEntry);
        await dbService.insertEntry(WorkEntry(
          id: 'entry-2',
          clientId: 'client-1',
          clientName: 'Client A',
          clientColor: '#FF0000',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Software',
          notes: 'Developing unit tests',
          synced: false,
        ));

        await dbService.clearEntries();
        expect(await dbService.getAllEntries(), isEmpty);
      });
    });

    group('Clients Operations', () {
      final sampleClient = Client(
        id: 'client-1',
        name: 'Client A',
        color: '#FF5733',
      );

      test('insertClient and getAllClients', () async {
        await dbService.insertClient(sampleClient);
        final clients = await dbService.getAllClients();

        expect(clients, hasLength(1));
        expect(clients.first.id, 'client-1');
        expect(clients.first.name, 'Client A');
        expect(clients.first.color, '#FF5733');
      });

      test('updateClient', () async {
        await dbService.insertClient(sampleClient);
        final updatedClient = sampleClient.copyWith(name: 'Updated Client Name', color: '#00FF00');

        await dbService.updateClient(updatedClient);

        final clients = await dbService.getAllClients();
        expect(clients.first.name, 'Updated Client Name');
        expect(clients.first.color, '#00FF00');
      });

      test('deleteClient', () async {
        await dbService.insertClient(sampleClient);
        expect(await dbService.getAllClients(), hasLength(1));

        await dbService.deleteClient('client-1');
        expect(await dbService.getAllClients(), isEmpty);
      });

      test('clearClients', () async {
        await dbService.insertClient(sampleClient);
        await dbService.insertClient(Client(
          id: 'client-2',
          name: 'Client B',
          color: '#00FF00',
        ));

        await dbService.clearClients();
        expect(await dbService.getAllClients(), isEmpty);
      });
    });

    group('LocalDBService Batch Operations Tests', () {
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

      test('should update projects in batch successfully', () async {
        final projects = [
          Project(id: 'p1', clientId: 'c1', name: 'Proj 1', synced: false),
          Project(id: 'p2', clientId: 'c1', name: 'Proj 2', synced: false),
        ];

        await dbService.insertProjectsBatch(projects);

        // Update synced to true and change name
        final updatedProjects = [
          projects[0].copyWith(name: 'Proj 1 Updated', synced: true),
          projects[1].copyWith(name: 'Proj 2 Updated', synced: true),
        ];

        await dbService.updateProjectsBatch(updatedProjects);

        final retrieved = await dbService.getAllProjects();
        expect(retrieved.length, equals(2));
        expect(retrieved.any((p) => p.id == 'p1' && p.name == 'Proj 1 Updated' && p.synced), isTrue);
        expect(retrieved.any((p) => p.id == 'p2' && p.name == 'Proj 2 Updated' && p.synced), isTrue);
      });

      test('updateProjectsBatch should handle empty list gracefully', () async {
        await expectLater(dbService.updateProjectsBatch([]), completes);
      });

      test('benchmark update projects batch vs individual updates', () async {
        final count = 100;
        final projects = List.generate(count, (i) => Project(
          id: 'bench_proj_$i',
          clientId: 'c1',
          name: 'Bench Project $i',
          synced: false,
        ));

        // Insert baseline projects
        await dbService.clearProjects();
        await dbService.insertProjectsBatch(projects);

        // Measure individual updates
        final individualStopwatch = Stopwatch()..start();
        for (final p in projects) {
          await dbService.updateProject(p.copyWith(synced: true));
        }
        individualStopwatch.stop();
        final individualTime = individualStopwatch.elapsedMilliseconds;

        // Reset and insert projects again for batch run
        await dbService.clearProjects();
        await dbService.insertProjectsBatch(projects);

        // Measure batch updates
        final batchStopwatch = Stopwatch()..start();
        final updatedList = projects.map((p) => p.copyWith(synced: true)).toList();
        await dbService.updateProjectsBatch(updatedList);
        batchStopwatch.stop();
        final batchTime = batchStopwatch.elapsedMilliseconds;

        print('--- Performance Benchmark ---');
        print('Updated $count projects individually in: $individualTime ms');
        print('Updated $count projects in batch in:       $batchTime ms');
        final speedup = individualTime / (batchTime > 0 ? batchTime : 1);
        print('Speedup factor: ${speedup.toStringAsFixed(2)}x');
        print('-----------------------------');

        // Verify that they were actually synced
        final retrieved = await dbService.getAllProjects();
        expect(retrieved.every((p) => p.synced), isTrue);
      });
    });
  });
}
