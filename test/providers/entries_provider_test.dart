import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/services/backup_service.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/entries_provider.dart';

class MockLocalDBService extends Mock implements LocalDBService {}
class MockSyncService extends Mock implements SyncService {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockBackupService extends Mock implements BackupService {}

class FakeWorkEntry extends Fake implements WorkEntry {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWorkEntry());
  });

  group('EntriesProvider Tests', () {
    late MockLocalDBService mockLocalDB;
    late MockSyncService mockSync;
    late MockSupabaseService mockSupabase;
    late MockBackupService mockBackup;
    late ProviderContainer container;

    final testEntry = WorkEntry(
      id: 'test-entry-id',
      clientId: 'test-client-id',
      clientName: 'Test Client',
      clientColor: '#FF0000',
      date: '10.03.2026',
      startTime: '09:00',
      endTime: '12:00',
      workType: 'Yazılım',
      notes: 'Test Notes',
      synced: false,
    );

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSync = MockSyncService();
      mockSupabase = MockSupabaseService();
      mockBackup = MockBackupService();

      container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDB),
          syncServiceProvider.overrideWithValue(mockSync),
          supabaseServiceProvider.overrideWithValue(mockSupabase),
          backupServiceProvider.overrideWithValue(mockBackup),
        ],
      );

      // Default stubs
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async => <WorkEntry>[]);
      when(() => mockLocalDB.insertEntry(any())).thenAnswer((_) async => {});
      when(() => mockLocalDB.updateEntry(any())).thenAnswer((_) async => {});
      when(() => mockLocalDB.deleteEntry(any())).thenAnswer((_) async => {});
      when(() => mockSync.syncPendingEntries()).thenAnswer((_) async => {});
      when(() => mockBackup.triggerBackup()).thenAnswer((_) async => {});
    });

    tearDown(() {
      container.dispose();
    });

    test('initial build loads entries from LocalDBService', () async {
      final entries = [testEntry];
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async => entries);

      final result = await container.read(entriesProvider.future);

      expect(result, equals(entries));
      verify(() => mockLocalDB.getAllEntries()).called(1);
    });

    test('addEntry inserts entry, triggers sync and backup, and invalidates self', () async {
      int getAllEntriesCallCount = 0;
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async {
        getAllEntriesCallCount++;
        if (getAllEntriesCallCount == 1) {
          return <WorkEntry>[];
        } else {
          return [testEntry];
        }
      });

      // Initially read to trigger the build
      var list = await container.read(entriesProvider.future);
      expect(list, isEmpty);
      expect(getAllEntriesCallCount, equals(1));

      // Call addEntry
      await container.read(entriesProvider.notifier).addEntry(testEntry);

      // Verify dependencies were called
      verify(() => mockLocalDB.insertEntry(testEntry)).called(1);
      verify(() => mockSync.syncPendingEntries()).called(1);
      verify(() => mockBackup.triggerBackup()).called(1);

      // Re-read provider to verify it invalidated and reloaded
      list = await container.read(entriesProvider.future);
      expect(list, equals([testEntry]));
      expect(getAllEntriesCallCount, equals(2));
    });

    test('updateEntry updates entry, triggers sync and backup, and invalidates self', () async {
      int getAllEntriesCallCount = 0;
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async {
        getAllEntriesCallCount++;
        return <WorkEntry>[testEntry];
      });

      // Initially read to trigger the build
      var list = await container.read(entriesProvider.future);
      expect(list, equals([testEntry]));

      // Call updateEntry
      await container.read(entriesProvider.notifier).updateEntry(testEntry);

      // Verify dependencies were called
      verify(() => mockLocalDB.updateEntry(testEntry)).called(1);
      verify(() => mockSync.syncPendingEntries()).called(1);
      verify(() => mockBackup.triggerBackup()).called(1);

      // Verify reload
      list = await container.read(entriesProvider.future);
      expect(list, equals([testEntry]));
      expect(getAllEntriesCallCount, equals(2));
    });

    test('deleteEntry deletes entry locally and from Supabase, triggers backup and invalidates self', () async {
      when(() => mockSupabase.deleteEntry(any())).thenAnswer((_) async => {});

      int getAllEntriesCallCount = 0;
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async {
        getAllEntriesCallCount++;
        if (getAllEntriesCallCount == 1) {
          return <WorkEntry>[testEntry];
        } else {
          return <WorkEntry>[];
        }
      });

      // Initially read to trigger the build
      var list = await container.read(entriesProvider.future);
      expect(list, equals([testEntry]));

      // Call deleteEntry
      await container.read(entriesProvider.notifier).deleteEntry('test-entry-id');

      // Verify dependencies were called
      verify(() => mockLocalDB.deleteEntry('test-entry-id')).called(1);
      verify(() => mockSupabase.deleteEntry('test-entry-id')).called(1);
      verify(() => mockBackup.triggerBackup()).called(1);

      // Verify reload
      list = await container.read(entriesProvider.future);
      expect(list, isEmpty);
      expect(getAllEntriesCallCount, equals(2));
    });

    test('deleteEntry still succeeds even when Supabase deletion fails', () async {
      when(() => mockSupabase.deleteEntry(any())).thenThrow(Exception('Supabase Error'));

      int getAllEntriesCallCount = 0;
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async {
        getAllEntriesCallCount++;
        if (getAllEntriesCallCount == 1) {
          return <WorkEntry>[testEntry];
        } else {
          return <WorkEntry>[];
        }
      });

      // Initially read to trigger the build
      var list = await container.read(entriesProvider.future);
      expect(list, equals([testEntry]));

      // Call deleteEntry (exception in Supabase should be caught and ignored)
      await expectLater(
        container.read(entriesProvider.notifier).deleteEntry('test-entry-id'),
        completes,
      );

      // Verify dependencies were called
      verify(() => mockLocalDB.deleteEntry('test-entry-id')).called(1);
      verify(() => mockSupabase.deleteEntry('test-entry-id')).called(1);
      verify(() => mockBackup.triggerBackup()).called(1);

      // Verify reload
      list = await container.read(entriesProvider.future);
      expect(list, isEmpty);
      expect(getAllEntriesCallCount, equals(2));
    });

    test('refresh invalidates and reloads the notifier', () async {
      int getAllEntriesCallCount = 0;
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async {
        getAllEntriesCallCount++;
        return <WorkEntry>[];
      });

      // Initial load
      await container.read(entriesProvider.future);
      expect(getAllEntriesCallCount, equals(1));

      // Refresh
      await container.read(entriesProvider.notifier).refresh();

      // Verify reload
      await container.read(entriesProvider.future);
      expect(getAllEntriesCallCount, equals(2));
    });

    test('todayEntriesProvider loads today\'s entries from LocalDBService', () async {
      final todayStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
      final todayEntry = testEntry.copyWith(date: todayStr);

      when(() => mockLocalDB.getTodayEntries(todayStr))
          .thenAnswer((_) async => [todayEntry]);

      final result = await container.read(todayEntriesProvider.future);

      expect(result, equals([todayEntry]));
      verify(() => mockLocalDB.getTodayEntries(todayStr)).called(1);
    });

    test('unsyncedEntriesProvider loads unsynced entries from LocalDBService', () async {
      when(() => mockLocalDB.getUnsyncedEntries())
          .thenAnswer((_) async => [testEntry]);

      final result = await container.read(unsyncedEntriesProvider.future);

      expect(result, equals([testEntry]));
      verify(() => mockLocalDB.getUnsyncedEntries()).called(1);
    });
  });
}
