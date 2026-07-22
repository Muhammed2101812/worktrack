import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/providers/sync_provider.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/services/sync_service.dart';

class MockSyncService extends Mock implements SyncService {}

class FakeAsyncValue<T> extends Fake implements AsyncValue<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAsyncValue<DateTime?>());
  });

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

    test('initial state should be AsyncData(null) after initialization completes', () async {
      final container = createContainer();

      // Wait for the provider initialization to complete
      final futureVal = await container.read(syncProvider.future);
      expect(futureVal, isNull);

      final state = container.read(syncProvider);
      expect(state, const AsyncValue<DateTime?>.data(null));
    });

    group('syncPending', () {
      test('syncPending happy path: executes successfully and sets state to AsyncData(now)', () async {
        final container = createContainer();
        when(() => mockSyncService.syncPendingEntries()).thenAnswer((_) async {});

        // Await initialization so the starting state is AsyncData(null)
        await container.read(syncProvider.future);

        final listener = Listener<AsyncValue<DateTime?>>();
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          listener.call,
          fireImmediately: true,
        );

        verify(() => listener(null, const AsyncValue<DateTime?>.data(null))).called(1);

        final notifier = container.read(syncProvider.notifier);
        await notifier.syncPending();

        verifyInOrder([
          () => listener(const AsyncValue<DateTime?>.data(null), any(that: isA<AsyncLoading<DateTime?>>())),
          () => listener(any(that: isA<AsyncLoading<DateTime?>>()), any(that: isA<AsyncData<DateTime?>>())),
        ]);

        final state = container.read(syncProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isNotNull);
        expect(state.value, isA<DateTime>());
      });

      test('syncPending error path: sync fails, sets state to AsyncError and rethrows', () async {
        final container = createContainer();
        final testException = Exception('Sync failed');
        when(() => mockSyncService.syncPendingEntries()).thenThrow(testException);

        // Await initialization so the starting state is AsyncData(null)
        await container.read(syncProvider.future);

        final listener = Listener<AsyncValue<DateTime?>>();
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          listener.call,
          fireImmediately: true,
        );

        verify(() => listener(null, const AsyncValue<DateTime?>.data(null))).called(1);

        final notifier = container.read(syncProvider.notifier);

        await expectLater(
          () => notifier.syncPending(),
          throwsA(equals(testException)),
        );

        verifyInOrder([
          () => listener(const AsyncValue<DateTime?>.data(null), any(that: isA<AsyncLoading<DateTime?>>())),
          () => listener(any(that: isA<AsyncLoading<DateTime?>>()), any(that: isA<AsyncError<DateTime?>>())),
        ]);

        final state = container.read(syncProvider);
        expect(state.hasError, isTrue);
        expect(state.error, equals(testException));
      });
    });

    group('fullSync', () {
      test('fullSync happy path: executes successfully and sets state to AsyncData(now)', () async {
        final container = createContainer();
        when(() => mockSyncService.fullSync()).thenAnswer((_) async {});

        // Await initialization so the starting state is AsyncData(null)
        await container.read(syncProvider.future);

        final listener = Listener<AsyncValue<DateTime?>>();
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          listener.call,
          fireImmediately: true,
        );

        verify(() => listener(null, const AsyncValue<DateTime?>.data(null))).called(1);

        final notifier = container.read(syncProvider.notifier);
        await notifier.fullSync();

        verifyInOrder([
          () => listener(const AsyncValue<DateTime?>.data(null), any(that: isA<AsyncLoading<DateTime?>>())),
          () => listener(any(that: isA<AsyncLoading<DateTime?>>()), any(that: isA<AsyncData<DateTime?>>())),
        ]);

        final state = container.read(syncProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isNotNull);
        expect(state.value, isA<DateTime>());
      });

      test('fullSync error path: sync fails, sets state to AsyncError and rethrows', () async {
        final container = createContainer();
        final testException = Exception('Full sync failed');
        when(() => mockSyncService.fullSync()).thenThrow(testException);

        // Await initialization so the starting state is AsyncData(null)
        await container.read(syncProvider.future);

        final listener = Listener<AsyncValue<DateTime?>>();
        container.listen<AsyncValue<DateTime?>>(
          syncProvider,
          listener.call,
          fireImmediately: true,
        );

        verify(() => listener(null, const AsyncValue<DateTime?>.data(null))).called(1);

        final notifier = container.read(syncProvider.notifier);

        await expectLater(
          () => notifier.fullSync(),
          throwsA(equals(testException)),
        );

        verifyInOrder([
          () => listener(const AsyncValue<DateTime?>.data(null), any(that: isA<AsyncLoading<DateTime?>>())),
          () => listener(any(that: isA<AsyncLoading<DateTime?>>()), any(that: isA<AsyncError<DateTime?>>())),
        ]);

        final state = container.read(syncProvider);
        expect(state.hasError, isTrue);
        expect(state.error, equals(testException));
      });
    });
  });
}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}
