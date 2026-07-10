import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => Stream.value([ConnectivityResult.wifi]);
}

class FakeLocalDBService extends Fake implements LocalDBService {
  final List<Client> clients = [];
  final List<WorkEntry> entries = [];
  bool clearedClients = false;
  bool clearedEntries = false;

  @override
  Future<List<Client>> getAllClients() async {
    return clients;
  }

  @override
  Future<void> clearClients() async {
    clearedClients = true;
    clients.clear();
  }

  @override
  Future<void> insertClient(Client client) async {
    clients.add(client);
  }

  @override
  Future<void> clearEntries() async {
    clearedEntries = true;
    entries.clear();
  }

  @override
  Future<void> insertEntry(WorkEntry entry) async {
    entries.add(entry);
  }
}

class FakeSupabaseService extends Fake implements SupabaseService {
  final List<Client> clients = [];
  final List<WorkEntry> entries = [];
  final List<List<Client>> upsertClientsCalls = [];

  @override
  Future<List<Client>> getAllClients() async {
    return clients;
  }

  @override
  Future<void> upsertClients(List<Client> clients) async {
    upsertClientsCalls.add(clients);
    // For each client, if it's not already in remote, upsert it
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
  Future<List<WorkEntry>> getAllEntries() async {
    return entries;
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

      // Setup Remote Clients
      supabase.clients.add(Client(id: 'r1', name: 'Existing Client', color: '#111111'));

      // Setup Local Clients
      localDB.clients.add(Client(id: 'r1', name: 'Existing Client', color: '#111111'));
      final localOnly1 = Client(id: 'l1', name: 'New Client 1', color: '#222222');
      final localOnly2 = Client(id: 'l2', name: 'New Client 2', color: '#333333');
      localDB.clients.add(localOnly1);
      localDB.clients.add(localOnly2);

      // Setup Remote Entries
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

      // Execute fullSync
      await syncService.fullSync();

      // Verify that upsertClients was called exactly once
      expect(supabase.upsertClientsCalls.length, equals(1));

      // Verify that the correct local-only clients were passed in bulk
      final upsertedClients = supabase.upsertClientsCalls.first;
      expect(upsertedClients.length, equals(2));
      expect(upsertedClients.any((c) => c.id == localOnly1.id), isTrue);
      expect(upsertedClients.any((c) => c.id == localOnly2.id), isTrue);

      // Verify that final remote list was merged and deduplicated into local db
      // Expected clients in local DB: "Existing Client", "New Client 1", "New Client 2"
      expect(localDB.clients.length, equals(3));
      expect(localDB.clients.any((c) => c.name == 'Existing Client'), isTrue);
      expect(localDB.clients.any((c) => c.name == 'New Client 1'), isTrue);
      expect(localDB.clients.any((c) => c.name == 'New Client 2'), isTrue);

      // Verify entries synchronized from remote
      expect(localDB.entries.length, equals(1));
      expect(localDB.entries.first.id, equals('e1'));
      expect(localDB.entries.first.synced, isTrue);
    });

    test('should not call upsertClients if there are no local-only clients to push', () async {
      final localDB = FakeLocalDBService();
      final supabase = FakeSupabaseService();
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      // Setup Remote Clients
      final client = Client(id: 'r1', name: 'Existing Client', color: '#111111');
      supabase.clients.add(client);
      localDB.clients.add(client);

      // Execute fullSync
      await syncService.fullSync();

      // Verify that upsertClients was not called
      expect(supabase.upsertClientsCalls, isEmpty);
    });
  });
}
