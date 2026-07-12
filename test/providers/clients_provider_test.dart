import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/providers/clients_provider.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/services/backup_service.dart';

class MockLocalDBService extends Mock implements LocalDBService {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockBackupService extends Mock implements BackupService {}

class FakeClient extends Fake implements Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeClient());
  });

  group('ClientsNotifier Tests', () {
    late MockLocalDBService mockLocalDB;
    late MockSupabaseService mockSupabase;
    late MockBackupService mockBackup;
    late List<Client> clientsList;

    final clientA = Client(id: 'c1', name: 'Client A', color: '#FF1111');
    final clientB = Client(id: 'c2', name: 'Client B', color: '#FF2222');

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSupabase = MockSupabaseService();
      mockBackup = MockBackupService();

      clientsList = [clientA, clientB];

      // Setup default mock answers
      when(() => mockLocalDB.getAllClients()).thenAnswer((_) async => List.from(clientsList));
      when(() => mockLocalDB.insertClient(any())).thenAnswer((invocation) async {
        final client = invocation.positionalArguments[0] as Client;
        clientsList.add(client);
      });
      when(() => mockLocalDB.updateClient(any())).thenAnswer((invocation) async {
        final client = invocation.positionalArguments[0] as Client;
        final index = clientsList.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          clientsList[index] = client;
        }
      });
      when(() => mockLocalDB.deleteClient(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        clientsList.removeWhere((c) => c.id == id);
      });

      when(() => mockSupabase.upsertClient(any())).thenAnswer((_) async {});
      when(() => mockSupabase.updateClient(any())).thenAnswer((_) async {});
      when(() => mockSupabase.deleteClient(any())).thenAnswer((_) async {});
      when(() => mockBackup.triggerBackup()).thenAnswer((_) async {});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWith((ref) => mockLocalDB),
          supabaseServiceProvider.overrideWith((ref) => mockSupabase),
          backupServiceProvider.overrideWith((ref) => mockBackup),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build fetches and returns clients from local DB', () async {
      final container = createContainer();

      final result = await container.read(clientsProvider.future);

      expect(result, equals([clientA, clientB]));
      verify(() => mockLocalDB.getAllClients()).called(1);
    });

    group('addClient', () {
      test('adds a unique client successfully and triggers backup', () async {
        final container = createContainer();
        final newClient = Client(id: 'c3', name: 'Client C', color: '#FF3333');

        // We listen to the provider to keep it active and alive
        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await container.read(clientsProvider.notifier).addClient(newClient);

        // Verify local DB and remote upsert calls
        verify(() => mockLocalDB.insertClient(newClient)).called(1);
        verify(() => mockSupabase.upsertClient(newClient)).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify notifier state is updated
        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients, contains(newClient));
        expect(updatedClients.length, equals(3));
      });

      test('prevents adding a duplicate client (case-insensitive) and does not call insert/upsert', () async {
        final container = createContainer();
        final duplicateClient = Client(id: 'c3', name: 'client a', color: '#FF3333');

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await container.read(clientsProvider.notifier).addClient(duplicateClient);

        // Verify no DB/Supabase/Backup operations are called
        verifyNever(() => mockLocalDB.insertClient(any()));
        verifyNever(() => mockSupabase.upsertClient(any()));
        verifyNever(() => mockBackup.triggerBackup());

        // Verify notifier state remains unchanged
        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients.length, equals(2));
        expect(updatedClients.any((c) => c.name == 'client a'), isFalse);
      });

      test('handles Supabase exception gracefully during addClient', () async {
        final container = createContainer();
        final newClient = Client(id: 'c3', name: 'Client C', color: '#FF3333');

        when(() => mockSupabase.upsertClient(any())).thenThrow(Exception('Network error'));

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await expectLater(
          container.read(clientsProvider.notifier).addClient(newClient),
          completes,
        );

        // Verify local DB is inserted and backup is triggered even if supabase fails
        verify(() => mockLocalDB.insertClient(newClient)).called(1);
        verify(() => mockSupabase.upsertClient(newClient)).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // State is still updated locally
        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients, contains(newClient));
      });
    });

    group('updateClient', () {
      test('updates client successfully and triggers backup', () async {
        final container = createContainer();
        final updatedClient = clientA.copyWith(name: 'Client A Updated');

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await container.read(clientsProvider.notifier).updateClient(updatedClient);

        verify(() => mockLocalDB.updateClient(updatedClient)).called(1);
        verify(() => mockSupabase.updateClient(updatedClient)).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients.any((c) => c.name == 'Client A Updated'), isTrue);
        expect(updatedClients.length, equals(2));
      });

      test('handles Supabase exception gracefully during updateClient', () async {
        final container = createContainer();
        final updatedClient = clientA.copyWith(name: 'Client A Updated');

        when(() => mockSupabase.updateClient(any())).thenThrow(Exception('Network error'));

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await expectLater(
          container.read(clientsProvider.notifier).updateClient(updatedClient),
          completes,
        );

        // Verify local DB is updated and backup is triggered even if supabase fails
        verify(() => mockLocalDB.updateClient(updatedClient)).called(1);
        verify(() => mockSupabase.updateClient(updatedClient)).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients.any((c) => c.name == 'Client A Updated'), isTrue);
      });
    });

    group('deleteClient', () {
      test('deletes client successfully and triggers backup', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await container.read(clientsProvider.notifier).deleteClient('c1');

        verify(() => mockLocalDB.deleteClient('c1')).called(1);
        verify(() => mockSupabase.deleteClient('c1')).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients.any((c) => c.id == 'c1'), isFalse);
        expect(updatedClients.length, equals(1));
      });

      test('handles Supabase exception gracefully during deleteClient', () async {
        final container = createContainer();

        when(() => mockSupabase.deleteClient(any())).thenThrow(Exception('Network error'));

        container.listen<AsyncValue<List<Client>>>(clientsProvider, (_, __) {});

        await expectLater(
          container.read(clientsProvider.notifier).deleteClient('c1'),
          completes,
        );

        verify(() => mockLocalDB.deleteClient('c1')).called(1);
        verify(() => mockSupabase.deleteClient('c1')).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedClients = await container.read(clientsProvider.future);
        expect(updatedClients.any((c) => c.id == 'c1'), isFalse);
      });
    });
  });
}
