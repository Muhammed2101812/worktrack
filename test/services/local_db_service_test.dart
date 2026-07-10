import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/services/local_db_service.dart';

void main() {
  // Setup sqflite_common_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDBService Tests', () {
    late LocalDBService dbService;

    setUp(() async {
      dbService = LocalDBService();
      // Ensure we start with a clean state or use in-memory database for testing.
      // But since LocalDBService connects to a physical file 'worklog.db' at getDatabasesPath(),
      // let's clear both tables before each test to ensure test independence.
      try {
        await dbService.clearEntries();
        await dbService.clearClients();
      } catch (_) {
        // Database might not be initialized yet, which is fine
      }
    });

    tearDown(() async {
      try {
        await dbService.clearEntries();
        await dbService.clearClients();
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
  });
}
