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
      date: '2023-10-01',
      notes: 'Notes A',
      synced: false,
    );

    final paymentB = Payment(
      id: 'p2',
      clientId: 'c2',
      clientName: 'Client B',
      clientColor: '#FF2222',
      amount: 200.0,
      date: '2023-10-02',
      notes: 'Notes B',
      synced: true,
    );

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSync = MockSyncService();
      mockBackup = MockBackupService();

      paymentsList = [paymentA, paymentB];

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

    group('build', () {
      test('fetches and returns payments from local DB under happy path', () async {
        final container = createContainer();

        final result = await container.read(paymentsProvider.future);

        expect(result, equals([paymentA, paymentB]));
        verify(() => mockLocalDB.getAllPayments()).called(1);
      });

      test('exposes error state when local DB getAllPayments throws an error', () async {
        final container = createContainer();
        final testException = Exception('Failed to load payments from DB');

        when(() => mockLocalDB.getAllPayments()).thenThrow(testException);

        // We listen to the provider to keep it active
        container.listen<AsyncValue<List<Payment>>>(
          paymentsProvider,
          (previous, next) {},
          fireImmediately: true,
        );

        // Awaiting the future should throw the exception
        await expectLater(
          () => container.read(paymentsProvider.future),
          throwsA(equals(testException)),
        );

        // Verify the provider's state is AsyncError
        final state = container.read(paymentsProvider);
        expect(state, isA<AsyncError<List<Payment>>>());
        expect(state.error, equals(testException));
      });
    });

    group('addPayment', () {
      test('adds a payment successfully, triggers sync & backup, and invalidates self', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c3',
          clientName: 'Client C',
          clientColor: '#FF3333',
          amount: 300.0,
          date: '2023-10-03',
          notes: 'Notes C',
          synced: false,
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

      test('handles non-fatal sync/backup errors gracefully during addPayment', () async {
        final container = createContainer();
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c3',
          clientName: 'Client C',
          clientColor: '#FF3333',
          amount: 300.0,
          date: '2023-10-03',
          notes: 'Notes C',
          synced: false,
        );

        when(() => mockSync.syncPendingPayments()).thenThrow(Exception('Sync failed'));
        when(() => mockBackup.triggerBackup()).thenThrow(Exception('Backup failed'));

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        // This should not throw since sync and backup failures are non-fatal
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

      test('rethrows local database error if insertPayment fails', () async {
        final container = createContainer();
        final dbException = Exception('DB insert failure');
        final newPayment = Payment(
          id: 'p3',
          clientId: 'c3',
          clientName: 'Client C',
          clientColor: '#FF3333',
          amount: 300.0,
          date: '2023-10-03',
          notes: 'Notes C',
          synced: false,
        );

        when(() => mockLocalDB.insertPayment(any())).thenThrow(dbException);

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        await expectLater(
          container.read(paymentsProvider.notifier).addPayment(newPayment),
          throwsA(equals(dbException)),
        );

        verify(() => mockLocalDB.insertPayment(newPayment)).called(1);
        verifyNever(() => mockSync.syncPendingPayments());
        verifyNever(() => mockBackup.triggerBackup());
      });
    });

    group('deletePayment', () {
      test('soft-deletes a payment locally, triggers sync and backup, and invalidates self', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Payment>>>(paymentsProvider, (_, __) {});

        // Fetch initial state first
        final initialPayments = await container.read(paymentsProvider.future);
        expect(initialPayments.length, equals(2));

        // Delete paymentA
        await container.read(paymentsProvider.notifier).deletePayment('p1');

        verify(() => mockLocalDB.softDeletePayment('p1')).called(1);
        verify(() => mockSync.syncPendingPayments()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedPayments = await container.read(paymentsProvider.future);
        expect(updatedPayments.any((p) => p.id == 'p1'), isFalse);
        expect(updatedPayments.length, equals(1));
      });
    });

    group('unsyncedPaymentsProvider', () {
      test('returns unsynced payments correctly', () async {
        final container = createContainer();

        final result = await container.read(unsyncedPaymentsProvider.future);

        expect(result, equals([paymentA]));
        verify(() => mockLocalDB.getUnsyncedPayments()).called(1);
      });
    });
  });
}
