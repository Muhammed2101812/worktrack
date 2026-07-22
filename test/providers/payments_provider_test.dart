import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/models/payment.dart';
import 'package:worklog/providers/payments_provider.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/backup_service.dart';

class MockLocalDBService extends Mock implements LocalDBService {}
class MockSyncService extends Mock implements SyncService {}
class MockBackupService extends Mock implements BackupService {}

class FakePayment extends Fake implements Payment {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePayment());
  });

  group('PaymentsNotifier Tests', () {
    late MockLocalDBService mockLocalDB;
    late MockSyncService mockSync;
    late MockBackupService mockBackup;
    late List<Payment> paymentsList;

    final paymentA = Payment(
      id: 'p1',
      clientId: 'c1',
      clientName: 'Client A',
      clientColor: '#FF1111',
      amount: 100.0,
      date: '10.05.2026',
    );
    final paymentB = Payment(
      id: 'p2',
      clientId: 'c2',
      clientName: 'Client B',
      clientColor: '#FF2222',
      amount: 250.0,
      date: '12.05.2026',
    );

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSync = MockSyncService();
      mockBackup = MockBackupService();

      paymentsList = [paymentA, paymentB];

      // Default mocks behavior
      when(() => mockLocalDB.getAllPayments()).thenAnswer((_) async => List.from(paymentsList));
      when(() => mockLocalDB.getUnsyncedPayments()).thenAnswer((_) async => paymentsList.where((p) => !p.synced).toList());
      when(() => mockLocalDB.insertPayment(any())).thenAnswer((invocation) async {
        final payment = invocation.positionalArguments[0] as Payment;
        paymentsList.add(payment);
      });
      when(() => mockLocalDB.softDeletePayment(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        paymentsList.removeWhere((p) => p.id == id);
      });

      when(() => mockSync.syncPendingPayments()).thenAnswer((_) async {});
      when(() => mockBackup.triggerBackup()).thenAnswer((_) async {});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWith((ref) => mockLocalDB),
          syncServiceProvider.overrideWith((ref) => mockSync),
          backupServiceProvider.overrideWith((ref) => mockBackup),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build fetches and returns payments from local DB', () async {
      final container = createContainer();

      final result = await container.read(paymentsProvider.future);

      expect(result, equals([paymentA, paymentB]));
      verify(() => mockLocalDB.getAllPayments()).called(1);
    });

    group('addPayment', () {
      test('adds payment successfully, syncs, invalidates self, and triggers backup', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
        );

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        await container.read(paymentsProvider.notifier).addPayment(newPayment);

        verify(() => mockLocalDB.insertPayment(newPayment)).called(1);
        verify(() => mockSync.syncPendingPayments()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedPayments = await container.read(paymentsProvider.future);
        expect(updatedPayments, contains(newPayment));
        expect(updatedPayments.length, equals(3));
      });

      test('handles sync exception gracefully and still triggers backup/updates state', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
        );

        when(() => mockSync.syncPendingPayments()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        // This should not throw since sync failure is caught and logged as non-fatal
        await expectLater(
          container.read(paymentsProvider.notifier).addPayment(newPayment),
          completes,
        );

        verify(() => mockLocalDB.insertPayment(newPayment)).called(1);
        verify(() => mockSync.syncPendingPayments()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedPayments = await container.read(paymentsProvider.future);
        expect(updatedPayments, contains(newPayment));
      });

      test('handles backup exception gracefully and still updates state', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
        );

        when(() => mockBackup.triggerBackup()).thenThrow(Exception('Backup failed'));

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        // This should not throw since backup failure is caught and logged as non-fatal
        await expectLater(
          container.read(paymentsProvider.notifier).addPayment(newPayment),
          completes,
        );

        verify(() => mockLocalDB.insertPayment(newPayment)).called(1);
        verify(() => mockSync.syncPendingPayments()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedPayments = await container.read(paymentsProvider.future);
        expect(updatedPayments, contains(newPayment));
      });

      test('rethrows when insertPayment fails locally', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
        );

        when(() => mockLocalDB.insertPayment(any())).thenThrow(Exception('Local DB error'));

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        await expectLater(
          container.read(paymentsProvider.notifier).addPayment(newPayment),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.insertPayment(newPayment)).called(1);
        // Sync and backup are not triggered since insert failed
        verifyNever(() => mockSync.syncPendingPayments());
        verifyNever(() => mockBackup.triggerBackup());
      });
    });

    group('deletePayment', () {
      test('soft-deletes payment, syncs, invalidates, and triggers backup', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        await container.read(paymentsProvider.notifier).deletePayment('p1');

        verify(() => mockLocalDB.softDeletePayment('p1')).called(1);
        verify(() => mockSync.syncPendingPayments()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedPayments = await container.read(paymentsProvider.future);
        expect(updatedPayments, isNot(contains(paymentA)));
        expect(updatedPayments.length, equals(1));
      });

      test('rethrows if soft-delete fails', () async {
        final container = createContainer();

        when(() => mockLocalDB.softDeletePayment(any())).thenThrow(Exception('Delete failed'));

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        await expectLater(
          container.read(paymentsProvider.notifier).deletePayment('p1'),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.softDeletePayment('p1')).called(1);
        verifyNever(() => mockSync.syncPendingPayments());
        verifyNever(() => mockBackup.triggerBackup());
      });
    });

    group('refresh', () {
      test('refresh invalidates and rebuilds state', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        // Fetch initial state
        final initialPayments = await container.read(paymentsProvider.future);
        expect(initialPayments.length, equals(2));

        // Let's modify localDB data directly to see if invalidation refetches the new data
        paymentsList.add(Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
        ));

        // Call refresh
        await container.read(paymentsProvider.notifier).refresh();

        // Get updated state
        final refreshedPayments = await container.read(paymentsProvider.future);
        expect(refreshedPayments.length, equals(3));
        verify(() => mockLocalDB.getAllPayments()).called(2);
      });
    });

    group('unsyncedPaymentsProvider', () {
      test('returns unsynced payments from local DB', () async {
        final unsyncedPayment = Payment(
          id: 'p3',
          clientId: 'c1',
          clientName: 'Client A',
          clientColor: '#FF1111',
          amount: 50.0,
          date: '15.05.2026',
          synced: false,
        );
        final syncedPayment = Payment(
          id: 'p4',
          clientId: 'c2',
          clientName: 'Client B',
          clientColor: '#FF2222',
          amount: 75.0,
          date: '16.05.2026',
          synced: true,
        );

        paymentsList = [unsyncedPayment, syncedPayment];

        final container = createContainer();

        final unsynced = await container.read(unsyncedPaymentsProvider.future);

        expect(unsynced, contains(unsyncedPayment));
        expect(unsynced, isNot(contains(syncedPayment)));
        verify(() => mockLocalDB.getUnsyncedPayments()).called(1);
      });
    });
  });
}
