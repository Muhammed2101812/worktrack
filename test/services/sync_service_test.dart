import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';

class FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => Stream.value([ConnectivityResult.wifi]);
}

class FakeLocalDBService extends Fake implements LocalDBService {
  final List<Client> clients = [];
  final List<WorkEntry> entries = [];
  final List<WorkEntry> unsyncedEntries;
  final List<String> updatedEntryIds = [];
  bool clearedClients = false;
  bool clearedEntries = false;

  FakeLocalDBService({this.unsyncedEntries = const []});

  @override
  Future<List<Client>> getAllClients() async => clients;

  @override
  Future<void> clearClients() async {
    clearedClients = true;
    clients.clear();
  }

  @override
  Future<void> insertClient(Client client) async => clients.add(client);

  @override
  Future<void> clearEntries() async {
    clearedEntries = true;
    entries.clear();
  }

  @override
  Future<void> insertEntry(WorkEntry entry) async => entries.add(entry);

  @override
  Future<List<Client>> getAllClientsBatch(List<String> ids) async => clients;

  @override
  Future<void> insertClientsBatch(List<Client> clients) async => this.clients.addAll(clients);

  @override
  Future<void> insertEntriesBatch(List<WorkEntry> entries) async => this.entries.addAll(entries);

  @override
  Future<List<WorkEntry>> getAllEntries() async => entries;

  @override
  Future<List<WorkEntry>> getUnsyncedEntries() async => unsyncedEntries;

  @override
  Future<void> updateEntrySync(String id, bool synced) async {
    if (synced) updatedEntryIds.add(id);
  }
}

class FakeSupabaseService extends Fake implements SupabaseService {
  final List<Client> clients = [];
  final List<WorkEntry> entries = [];
  final List<List<Client>> upsertClientsCalls = [];
  final bool failBulk;
  final List<WorkEntry> upsertedInBulk = [];
  final List<WorkEntry> upsertedIndividually = [];

  FakeSupabaseService({this.failBulk = false});

  @override
  Future<List<Client>> getAllClients() async => clients;

  @override
  Future<void> upsertClients(List<Client> clients) async {
    upsertClientsCalls.add(clients);
    for (final c in clients) {
      final index = this.clients.indexWhere((tc) => tc.id == c.id);
      if (index != -1) {
        this.clients[index] = c;
      } else {
        this.clients.add(c);
      }
    }
  }

  @override
  Future<List<WorkEntry>> getAllEntries() async => entries;

  @override
  Future<void> upsertEntries(List<WorkEntry> entries) async {
    if (failBulk) throw Exception('Bulk failed');
    upsertedInBulk.addAll(entries);
  }

  @override
  Future<void> upsertEntry(WorkEntry entry) async {
    upsertedIndividually.add(entry);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    ConnectivityPlatform.instance = FakeConnectivityPlatform();
  });

  group('SyncService - fullSync Tests', () {
    test('should push local-only clients to remote in a single bulk upsert call', () async {
      final localDB = FakeLocalDBService();
      final supabase = FakeSupabaseService();
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      supabase.clients.add(Client(id: 'r1', name: 'Existing Client', color: '#111111'));
      localDB.clients.add(Client(id: 'r1', name: 'Existing Client', color: '#111111'));
      final localOnly1 = Client(id: 'l1', name: 'New Client 1', color: '#222222');
      final localOnly2 = Client(id: 'l2', name: 'New Client 2', color: '#333333');
      localDB.clients.add(localOnly1);
      localDB.clients.add(localOnly2);

      supabase.entries.add(WorkEntry(
        id: 'e1',
        clientId: 'r1',
        clientName: 'Existing Client',
        clientColor: '#111111',
        date: '10.10.2025',
        startTime: '09:00',
        endTime: '17:00',
        workType: 'Yazılım',
      ));

      await syncService.fullSync();

      expect(supabase.upsertClientsCalls.length, equals(1));
      final upsertedClients = supabase.upsertClientsCalls.first;
      expect(upsertedClients.length, equals(2));
      expect(upsertedClients.any((c) => c.id == localOnly1.id), isTrue);
      expect(upsertedClients.any((c) => c.id == localOnly2.id), isTrue);

      expect(localDB.clients.length, equals(3));
      expect(localDB.clients.any((c) => c.name == 'Existing Client'), isTrue);
      expect(localDB.clients.any((c) => c.name == 'New Client 1'), isTrue);
      expect(localDB.clients.any((c) => c.name == 'New Client 2'), isTrue);

      expect(localDB.entries.length, equals(1));
      expect(localDB.entries.first.id, equals('e1'));
      expect(localDB.entries.first.synced, isTrue);
    });

    test('should not call upsertClients if there are no local-only clients to push', () async {
      final localDB = FakeLocalDBService();
      final supabase = FakeSupabaseService();
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      final client = Client(id: 'r1', name: 'Existing Client', color: '#111111');
      supabase.clients.add(client);
      localDB.clients.add(client);

      await syncService.fullSync();
      expect(supabase.upsertClientsCalls, isEmpty);
    });
  });

  group('SyncService Tests', () {
    test('should have SyncService class', () {
      expect(() => SyncService, returnsNormally);
    });

    test('should sync multiple entries in bulk and update local DB when successful', () async {
      final entries = [
        WorkEntry(
          id: '1',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
        ),
        WorkEntry(
          id: '2',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '13:00',
          endTime: '17:30',
          workType: 'Yazılım',
        ),
      ];

      final localDB = FakeLocalDBService(unsyncedEntries: entries);
      final supabase = FakeSupabaseService(failBulk: false);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingEntries();

      expect(supabase.upsertedInBulk, hasLength(2));
      expect(supabase.upsertedInBulk[0].id, '1');
      expect(supabase.upsertedInBulk[1].id, '2');
      expect(supabase.upsertedIndividually, isEmpty);
      expect(localDB.updatedEntryIds, containsAll(['1', '2']));
    });

    test('should fallback to individual upserts if bulk upsert fails', () async {
      final entries = [
        WorkEntry(
          id: '3',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
        ),
        WorkEntry(
          id: '4',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '13:00',
          endTime: '17:30',
          workType: 'Yazılım',
        ),
      ];

      final localDB = FakeLocalDBService(unsyncedEntries: entries);
      final supabase = FakeSupabaseService(failBulk: true);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingEntries();

      expect(supabase.upsertedInBulk, isEmpty);
      expect(supabase.upsertedIndividually, hasLength(2));
      expect(supabase.upsertedIndividually[0].id, '3');
      expect(supabase.upsertedIndividually[1].id, '4');
      expect(localDB.updatedEntryIds, containsAll(['3', '4']));
    });

    test('should return early and do nothing if unsynced list is empty', () async {
      final localDB = FakeLocalDBService(unsyncedEntries: []);
      final supabase = FakeSupabaseService(failBulk: false);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingEntries();

      expect(supabase.upsertedInBulk, isEmpty);
      expect(supabase.upsertedIndividually, isEmpty);
      expect(localDB.updatedEntryIds, isEmpty);
    });
  });
}
