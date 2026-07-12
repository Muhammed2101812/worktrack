import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/project.dart';

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

  // Project support stubs
  final List<Project> projects = [];
  final List<Project> updatedProjectsBatchCalls = [];
  final List<Project> updatedProjectCalls = [];

  @override
  Future<List<Project>> getAllProjects() async => projects;

  @override
  Future<void> clearProjects() async => projects.clear();

  @override
  Future<void> insertProjectsBatch(List<Project> projects) async =>
      this.projects.addAll(projects);

  @override
  Future<void> updateProjectsBatch(List<Project> projects) async {
    updatedProjectsBatchCalls.addAll(projects);
    for (final p in projects) {
      final idx = this.projects.indexWhere((tp) => tp.id == p.id);
      if (idx != -1) {
        this.projects[idx] = p;
      } else {
        this.projects.add(p);
      }
    }
  }

  @override
  Future<void> updateProject(Project project) async {
    updatedProjectCalls.add(project);
    final idx = this.projects.indexWhere((tp) => tp.id == project.id);
    if (idx != -1) {
      this.projects[idx] = project;
    } else {
      this.projects.add(project);
    }
  }
}

class FakeSupabaseService extends Fake implements SupabaseService {
  final List<Client> clients = [];
  final List<WorkEntry> entries = [];
  final List<List<Client>> upsertClientsCalls = [];
  final bool failBulk;
  final List<WorkEntry> upsertedInBulk = [];
  final List<WorkEntry> upsertedIndividually = [];
  final List<Project> upsertedProjectsInBulk = [];
  final List<Project> upsertedProjectsIndividually = [];

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

  // Project support stubs
  final List<Project> projects = [];

  @override
  Future<List<Project>> getAllProjects() async => projects;

  @override
  Future<void> upsertProjects(List<Project> projects) async {
    if (failBulk) throw Exception('Bulk failed');
    upsertedProjectsInBulk.addAll(projects);
  }

  @override
  Future<void> upsertProject(Project project) async {
    upsertedProjectsIndividually.add(project);
  }

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

    test('should sync multiple projects in bulk and update local DB with updateProjectsBatch when successful', () async {
      final projects = [
        Project(id: 'p1', clientId: 'c1', name: 'Project 1', synced: false),
        Project(id: 'p2', clientId: 'c1', name: 'Project 2', synced: false),
      ];

      final localDB = FakeLocalDBService();
      localDB.projects.addAll(projects);
      final supabase = FakeSupabaseService(failBulk: false);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingProjects();

      expect(supabase.upsertedProjectsInBulk, hasLength(2));
      expect(supabase.upsertedProjectsInBulk[0].id, 'p1');
      expect(supabase.upsertedProjectsInBulk[1].id, 'p2');
      expect(supabase.upsertedProjectsIndividually, isEmpty);
      expect(localDB.updatedProjectsBatchCalls, hasLength(2));
      expect(localDB.updatedProjectsBatchCalls.any((p) => p.id == 'p1' && p.synced), isTrue);
      expect(localDB.updatedProjectsBatchCalls.any((p) => p.id == 'p2' && p.synced), isTrue);
      expect(localDB.updatedProjectCalls, isEmpty);
    });

    test('should fallback to individual upserts for projects if bulk upsert fails', () async {
      final projects = [
        Project(id: 'p3', clientId: 'c1', name: 'Project 3', synced: false),
        Project(id: 'p4', clientId: 'c1', name: 'Project 4', synced: false),
      ];

      final localDB = FakeLocalDBService();
      localDB.projects.addAll(projects);
      final supabase = FakeSupabaseService(failBulk: true);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingProjects();

      expect(supabase.upsertedProjectsInBulk, isEmpty);
      expect(supabase.upsertedProjectsIndividually, hasLength(2));
      expect(supabase.upsertedProjectsIndividually[0].id, 'p3');
      expect(supabase.upsertedProjectsIndividually[1].id, 'p4');
      expect(localDB.updatedProjectsBatchCalls, isEmpty);
      expect(localDB.updatedProjectCalls, hasLength(2));
      expect(localDB.updatedProjectCalls.any((p) => p.id == 'p3' && p.synced), isTrue);
      expect(localDB.updatedProjectCalls.any((p) => p.id == 'p4' && p.synced), isTrue);
    });
  });
}
