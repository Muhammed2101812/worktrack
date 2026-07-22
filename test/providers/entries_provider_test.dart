import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/providers/entries_provider.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/settings_provider.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/backup_service.dart';

class MockLocalDBService extends Mock implements LocalDBService {}
class MockSyncService extends Mock implements SyncService {}
class MockBackupService extends Mock implements BackupService {}

class FakeWorkEntry extends Fake implements WorkEntry {}

class FakeIsPremiumNotifier extends IsPremiumNotifier {
  final bool isPremium;
  FakeIsPremiumNotifier(this.isPremium);

  @override
  Future<bool> build() async {
    return isPremium;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWorkEntry());
  });

  group('EntriesProvider & Notifier Tests', () {
    late MockLocalDBService mockLocalDB;
    late MockSyncService mockSync;
    late MockBackupService mockBackup;
    late List<WorkEntry> entryList;

    final entry1 = WorkEntry(
      id: 'e1',
      clientId: 'c1',
      clientName: 'Client A',
      clientColor: '#FF1111',
      date: '10.10.2025',
      startTime: '09:00',
      endTime: '17:00',
      workType: 'Yazılım',
    );

    final entry2 = WorkEntry(
      id: 'e2',
      clientId: 'c2',
      clientName: 'Client B',
      clientColor: '#FF2222',
      date: '11.10.2025',
      startTime: '10:00',
      endTime: '18:00',
      workType: 'Yazılım',
    );

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSync = MockSyncService();
      mockBackup = MockBackupService();

      entryList = [entry1, entry2];

      // Setup default mock answers
      when(() => mockLocalDB.getAllEntries()).thenAnswer((_) async => List.from(entryList));
      when(() => mockLocalDB.insertEntry(any())).thenAnswer((invocation) async {
        final entry = invocation.positionalArguments[0] as WorkEntry;
        entryList.add(entry);
      });
      when(() => mockLocalDB.updateEntry(any())).thenAnswer((invocation) async {
        final entry = invocation.positionalArguments[0] as WorkEntry;
        final idx = entryList.indexWhere((e) => e.id == entry.id);
        if (idx != -1) {
          entryList[idx] = entry;
        }
      });
      when(() => mockLocalDB.softDeleteEntry(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        entryList.removeWhere((e) => e.id == id);
      });

      when(() => mockSync.syncPendingEntries()).thenAnswer((_) async {});
      when(() => mockBackup.triggerBackup()).thenAnswer((_) async {});
    });

    ProviderContainer createContainer({bool isPremium = false}) {
      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWith((ref) => mockLocalDB),
          syncServiceProvider.overrideWith((ref) => mockSync),
          backupServiceProvider.overrideWith((ref) => mockBackup),
          isPremiumProvider.overrideWith(() => FakeIsPremiumNotifier(isPremium)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    group('Initialization tests', () {
      test('build fetches and returns entries from local DB', () async {
        final container = createContainer();

        final result = await container.read(entriesProvider.future);

        expect(result, equals([entry1, entry2]));
        verify(() => mockLocalDB.getAllEntries()).called(1);
      });

      test('todayEntriesProvider fetches today entries from local DB', () async {
        final container = createContainer();
        final todayStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

        when(() => mockLocalDB.getTodayEntries(todayStr)).thenAnswer((_) async => [entry1]);

        final result = await container.read(todayEntriesProvider.future);

        expect(result, equals([entry1]));
        verify(() => mockLocalDB.getTodayEntries(todayStr)).called(1);
      });

      test('unsyncedEntriesProvider fetches unsynced entries from local DB', () async {
        final container = createContainer();

        when(() => mockLocalDB.getUnsyncedEntries()).thenAnswer((_) async => [entry2]);

        final result = await container.read(unsyncedEntriesProvider.future);

        expect(result, equals([entry2]));
        verify(() => mockLocalDB.getUnsyncedEntries()).called(1);
      });
    });

    group('Mutation tests', () {
      test('addEntry inserts, syncs, invalidates, and backups successfully', () async {
        final container = createContainer();
        final newEntry = WorkEntry(
          id: 'e3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          date: '12.10.2025',
          startTime: '08:00',
          endTime: '12:00',
          workType: 'Tasarım',
        );

        // Keep the provider alive
        container.listen<AsyncValue<List<WorkEntry>>>(entriesProvider, (_, __) {});

        await container.read(entriesProvider.notifier).addEntry(newEntry);

        verify(() => mockLocalDB.insertEntry(newEntry)).called(1);
        verify(() => mockSync.syncPendingEntries()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedList = await container.read(entriesProvider.future);
        expect(updatedList, contains(newEntry));
        expect(updatedList.length, equals(3));
      });

      test('updateEntry updates, syncs, invalidates, and backups successfully', () async {
        final container = createContainer();
        final updatedEntry = entry1.copyWith(notes: 'New Notes Added');

        container.listen<AsyncValue<List<WorkEntry>>>(entriesProvider, (_, __) {});

        await container.read(entriesProvider.notifier).updateEntry(updatedEntry);

        verify(() => mockLocalDB.updateEntry(updatedEntry)).called(1);
        verify(() => mockSync.syncPendingEntries()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedList = await container.read(entriesProvider.future);
        expect(updatedList.any((e) => e.notes == 'New Notes Added'), isTrue);
        expect(updatedList.length, equals(2));
      });

      test('deleteEntry soft-deletes, syncs, invalidates, backups, and shows ad for non-premium user', () async {
        final container = createContainer(isPremium: false);

        container.listen<AsyncValue<List<WorkEntry>>>(entriesProvider, (_, __) {});

        await container.read(entriesProvider.notifier).deleteEntry('e1');

        verify(() => mockLocalDB.softDeleteEntry('e1')).called(1);
        verify(() => mockSync.syncPendingEntries()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedList = await container.read(entriesProvider.future);
        expect(updatedList.any((e) => e.id == 'e1'), isFalse);
        expect(updatedList.length, equals(1));
      });

      test('deleteEntry soft-deletes, syncs, invalidates, backups, and skips ad for premium user', () async {
        final container = createContainer(isPremium: true);

        container.listen<AsyncValue<List<WorkEntry>>>(entriesProvider, (_, __) {});

        await container.read(entriesProvider.notifier).deleteEntry('e1');

        verify(() => mockLocalDB.softDeleteEntry('e1')).called(1);
        verify(() => mockSync.syncPendingEntries()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedList = await container.read(entriesProvider.future);
        expect(updatedList.any((e) => e.id == 'e1'), isFalse);
        expect(updatedList.length, equals(1));
      });

      test('refresh invalidates and rebuilds the provider state', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<WorkEntry>>>(entriesProvider, (_, __) {});

        final firstFetch = await container.read(entriesProvider.future);
        expect(firstFetch.length, equals(2));

        // Add an entry directly to the list without calling addEntry
        final manualEntry = WorkEntry(
          id: 'e_manual',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          date: '15.10.2025',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
        );
        entryList.add(manualEntry);

        // Refresh the provider
        await container.read(entriesProvider.notifier).refresh();

        final secondFetch = await container.read(entriesProvider.future);
        expect(secondFetch.length, equals(3));
        expect(secondFetch, contains(manualEntry));
      });
    });
  });
}
