import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import 'core_providers.dart';

class EntriesNotifier extends AsyncNotifier<List<WorkEntry>> {
  @override
  Future<List<WorkEntry>> build() async {
    return ref.watch(localDBServiceProvider).getAllEntries();
  }

  Future<void> addEntry(WorkEntry entry) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    await db.insertEntry(entry);
    await sync.syncPendingEntries();
    ref.invalidateSelf();
  }

  Future<void> updateEntry(WorkEntry entry) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    await db.updateEntry(entry);
    await sync.syncPendingEntries();
    ref.invalidateSelf();
  }

  Future<void> deleteEntry(String id) async {
    final db = ref.read(localDBServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    await db.deleteEntry(id);
    try { await supabase.deleteEntry(id); } catch (_) {}
    ref.invalidateSelf();
  }

  Future<void> refresh() => Future(() => ref.invalidateSelf());
}

final entriesProvider = AsyncNotifierProvider<EntriesNotifier, List<WorkEntry>>(EntriesNotifier.new);

final todayEntriesProvider = FutureProvider<List<WorkEntry>>((ref) async {
  final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
  return ref.watch(localDBServiceProvider).getTodayEntries(today);
});

final unsyncedEntriesProvider = FutureProvider<List<WorkEntry>>((ref) async {
  return ref.watch(localDBServiceProvider).getUnsyncedEntries();
});