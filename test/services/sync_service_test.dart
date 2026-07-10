import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/work_entry.dart';

class MockConnectivityPlatform extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }
}

class FakeLocalDBService implements LocalDBService {
  final List<WorkEntry> unsyncedEntries;
  final List<String> updatedEntryIds = [];

  FakeLocalDBService({required this.unsyncedEntries});

  @override
  Future<List<WorkEntry>> getUnsyncedEntries() async => unsyncedEntries;

  @override
  Future<void> updateEntrySync(String id, bool synced) async {
    if (synced) {
      updatedEntryIds.add(id);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupabaseService implements SupabaseService {
  final bool failBulk;
  final List<WorkEntry> upsertedInBulk = [];
  final List<WorkEntry> upsertedIndividually = [];

  FakeSupabaseService({this.failBulk = false});

  @override
  Future<void> upsertEntries(List<WorkEntry> entries) async {
    if (failBulk) {
      throw Exception('Bulk failed');
    }
    upsertedInBulk.addAll(entries);
  }

  @override
  Future<void> upsertEntry(WorkEntry entry) async {
    upsertedIndividually.add(entry);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    ConnectivityPlatform.instance = MockConnectivityPlatform();
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

      // Verify bulk upsert was called with the entries
      expect(supabase.upsertedInBulk, hasLength(2));
      expect(supabase.upsertedInBulk[0].id, '1');
      expect(supabase.upsertedInBulk[1].id, '2');

      // Verify no individual upsert was called
      expect(supabase.upsertedIndividually, isEmpty);

      // Verify local DB update was called for both
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
      // Fail the bulk request
      final supabase = FakeSupabaseService(failBulk: true);
      final syncService = SyncService(localDB: localDB, supabase: supabase);

      await syncService.syncPendingEntries();

      // Verify bulk upsert failed and has no completed entries
      expect(supabase.upsertedInBulk, isEmpty);

      // Verify fallback called individual upserts
      expect(supabase.upsertedIndividually, hasLength(2));
      expect(supabase.upsertedIndividually[0].id, '3');
      expect(supabase.upsertedIndividually[1].id, '4');

      // Verify local DB was updated for both individual successes
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
