import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class SyncNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    return null;
  }

  Future<void> syncPending() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(syncServiceProvider).syncPendingEntries();
      state = AsyncValue.data(DateTime.now());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> fullSync() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(syncServiceProvider).fullSync();
      state = AsyncValue.data(DateTime.now());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final syncProvider = AsyncNotifierProvider<SyncNotifier, DateTime?>(SyncNotifier.new);