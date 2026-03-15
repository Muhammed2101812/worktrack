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
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) return;

    final remoteEntries = await supabase.getAllEntries();
    await localDB.clearEntries();
    for (final e in remoteEntries) {
      await localDB.insertEntry(e.copyWith(synced: true));
    }

    final remoteClients = await supabase.getAllClients();
    await localDB.clearClients();
    for (final c in remoteClients) {
      await localDB.insertClient(c);
    }
  }
}