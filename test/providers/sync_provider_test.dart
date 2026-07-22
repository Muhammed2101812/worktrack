import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/sync_provider.dart';
import 'package:worklog/services/sync_service.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  group('SyncNotifier Tests', () {
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is null', () async {
      final container = createContainer();
      final state = await container.read(syncProvider.future);
      expect(state, isNull);
    });

    group('syncPending', () {
      test('success sets state to DateTime.now()', () async {
        final container = createContainer();
        when(() => mockSyncService.syncPendingEntries()).thenAnswer((_) async {});

        // Wait for the notifier's async build to finish and resolve to null
        await container.read(syncProvider.future);

        final states = <AsyncValue<DateTime?>>[];
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        // Now that build has finished, the immediate state should be data(null)
        expect(states[0], const AsyncValue<DateTime?>.data(null));

        await container.read(syncProvider.notifier).syncPending();

        verify(() => mockSyncService.syncPendingEntries()).called(1);

        // Expect state progression: data(null) -> loading() -> data(non-null)
        expect(states.length, greaterThanOrEqualTo(3));
        expect(states.any((s) => s is AsyncLoading), isTrue);

        final finalState = container.read(syncProvider);
        expect(finalState.value, isNotNull);
        expect(finalState.value, isA<DateTime>());
      });

      test('failure sets state to error and rethrows', () async {
        final container = createContainer();
        final exception = Exception('Sync failed');
        when(() => mockSyncService.syncPendingEntries()).thenThrow(exception);

        // Wait for build to complete
        await container.read(syncProvider.future);

        final states = <AsyncValue<DateTime?>>[];
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        expect(
          () => container.read(syncProvider.notifier).syncPending(),
          throwsA(equals(exception)),
        );

        verify(() => mockSyncService.syncPendingEntries()).called(1);

        expect(states.any((s) => s is AsyncLoading), isTrue);
        expect(container.read(syncProvider).hasError, isTrue);
        expect(container.read(syncProvider).error, equals(exception));
      });
    });

    group('fullSync', () {
      test('success sets state to DateTime.now()', () async {
        final container = createContainer();
        when(() => mockSyncService.fullSync()).thenAnswer((_) async {});

        // Wait for build to complete
        await container.read(syncProvider.future);

        final states = <AsyncValue<DateTime?>>[];
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        expect(states[0], const AsyncValue<DateTime?>.data(null));

        await container.read(syncProvider.notifier).fullSync();

        verify(() => mockSyncService.fullSync()).called(1);

        expect(states.length, greaterThanOrEqualTo(3));
        expect(states.any((s) => s is AsyncLoading), isTrue);

        final finalState = container.read(syncProvider);
        expect(finalState.value, isNotNull);
        expect(finalState.value, isA<DateTime>());
      });

      test('failure sets state to error and rethrows', () async {
        final container = createContainer();
        final exception = Exception('Full sync failed');
        when(() => mockSyncService.fullSync()).thenThrow(exception);

        // Wait for build to complete
        await container.read(syncProvider.future);

        final states = <AsyncValue<DateTime?>>[];
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        expect(
          () => container.read(syncProvider.notifier).fullSync(),
          throwsA(equals(exception)),
        );

        verify(() => mockSyncService.fullSync()).called(1);

        expect(states.any((s) => s is AsyncLoading), isTrue);
        expect(container.read(syncProvider).hasError, isTrue);
        expect(container.read(syncProvider).error, equals(exception));
      });
    });
  });
}
