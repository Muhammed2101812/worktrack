import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';

class SyncService {
  final LocalDBService localDB;
  final SupabaseService supabase;

  SyncService({required this.localDB, required this.supabase});

  Future<void> syncPendingEntries() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) return;
      
      final unsynced = await localDB.getUnsyncedEntries();
      for (final entry in unsynced) {
        try {
          await supabase.upsertEntry(entry);
          await localDB.updateEntrySync(entry.id, true);
        } catch (e) {
          // Tek satır başarısız olursa diğer satırları işlemeye devam et
        }
      }
    } catch (_) {
      // Genel yakalama
    }
  }

  Future<void> fullSync() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) return;

      // 1. Fetch remote clients
      final remoteClients = await supabase.getAllClients();
      final remoteClientNames =
          remoteClients.map((c) => c.name.toLowerCase()).toSet();

      // 2. Push local-only clients to remote (name-based dedup)
      final localClients = await localDB.getAllClients();
      for (final lc in localClients) {
        if (!remoteClientNames.contains(lc.name.toLowerCase())) {
          try {
            await supabase.upsertClient(lc);
          } catch (_) {}
        }
      }

      // 3. Re-fetch remote (includes just-pushed clients)
      final finalRemoteClients = await supabase.getAllClients();

      // 4. Deduplicate by name (keep first occurrence)
      final seenNames = <String>{};
      final dedupedClients = finalRemoteClients.where((c) {
        return seenNames.add(c.name.toLowerCase());
      }).toList();

      await localDB.clearClients();
      for (final c in dedupedClients) {
        await localDB.insertClient(c);
      }

      // 5. Sync entries
      final remoteEntries = await supabase.getAllEntries();
      await localDB.clearEntries();
      for (final e in remoteEntries) {
        await localDB.insertEntry(e.copyWith(synced: true));
      }
    } catch (_) {}
  }
}