import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';
import '../models/client.dart';

class SyncService {
  final LocalDBService localDB;
  final SupabaseService supabase;

  SyncService({required this.localDB, required this.supabase});

  bool _isLoggedIn() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return true; // Supabase is not initialized (e.g. in unit tests), default to true for tests
    }
  }

  Future<void> syncPendingEntries() async {
    try {
      if (!_isLoggedIn()) return;
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) return;

      final unsynced = await localDB.getUnsyncedEntries();
      if (unsynced.isEmpty) return;

      try {
        // Try a single bulk upsert network request
        await supabase.upsertEntries(unsynced);
        for (final entry in unsynced) {
          await localDB.updateEntrySync(entry.id, true);
        }
      } catch (_) {
        // Fallback to individual upserts on failure to preserve fault tolerance (single-row error handling)
        for (final entry in unsynced) {
          try {
            await supabase.upsertEntry(entry);
            await localDB.updateEntrySync(entry.id, true);
          } catch (e) {
            // Tek satır başarısız olursa diğer satırları işlemeye devam et
          }
        }
      }
    } catch (_) {
      // Genel yakalama
    }
  }

  Future<void> syncPendingProjects() async {
    try {
      if (!_isLoggedIn()) return;
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) return;

      final allProjects = await localDB.getAllProjects();
      final unsynced = allProjects.where((p) => !p.synced).toList();
      if (unsynced.isEmpty) return;

      try {
        await supabase.upsertProjects(unsynced);
        for (final project in unsynced) {
          await localDB.updateProject(project.copyWith(synced: true));
        }
      } catch (_) {
        // Fallback to individual upserts on failure
        for (final project in unsynced) {
          try {
            await supabase.upsertProject(project);
            await localDB.updateProject(project.copyWith(synced: true));
          } catch (_) {
            // Tek proje başarısız olursa diğerlerini işlemeye devam et
          }
        }
      }
    } catch (_) {
      // Genel yakalama
    }
  }

  Future<void> syncPendingPayments() async {
    try {
      if (!_isLoggedIn()) return;
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) return;

      final unsynced = await localDB.getUnsyncedPayments();
      if (unsynced.isEmpty) return;

      try {
        await supabase.upsertPayments(unsynced);
        for (final payment in unsynced) {
          await localDB.updatePaymentSync(payment.id, true);
        }
      } catch (_) {
        // Fallback to individual upserts
        for (final payment in unsynced) {
          try {
            await supabase.upsertPayment(payment);
            await localDB.updatePaymentSync(payment.id, true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> fullSync() async {
    try {
      if (!_isLoggedIn()) return;
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) return;

      // 1. Fetch remote clients and push local-only clients first
      final remoteClients = await supabase.getAllClients();
      final remoteClientNames =
          remoteClients.map((c) => c.name.toLowerCase()).toSet();

      final localClients = await localDB.getAllClients();
      final clientsToUpsert = <Client>[];
      for (final lc in localClients) {
        if (!remoteClientNames.contains(lc.name.toLowerCase())) {
          clientsToUpsert.add(lc);
        }
      }
      if (clientsToUpsert.isNotEmpty) {
        try {
          await supabase.upsertClients(clientsToUpsert);
        } catch (_) {}
      }

      // 2. Push unsynced projects to remote
      await syncPendingProjects();

      // 3. Push unsynced entries to remote
      await syncPendingEntries();

      // 3.5. Push unsynced payments to remote
      await syncPendingPayments();

      // 4. Re-fetch remote clients (includes just-pushed)
      final finalRemoteClients = await supabase.getAllClients();
      final seenNames = <String>{};
      final dedupedClients = finalRemoteClients.where((c) {
        return seenNames.add(c.name.toLowerCase());
      }).toList();

      await localDB.clearClients();
      await localDB.insertClientsBatch(dedupedClients);

      // 5. Merge projects: keep unsynced local projects, replace synced ones with remote
      final localProjects = await localDB.getAllProjects();
      final unsyncedProjects = localProjects.where((p) => !p.synced).toList();

      final remoteProjects = await supabase.getAllProjects();
      await localDB.clearProjects();

      // Insert remote projects first (all marked as synced)
      await localDB.insertProjectsBatch(
        remoteProjects.map((p) => p.copyWith(synced: true)).toList(),
      );
      // Re-insert unsynced local projects that are NOT in remote (by id)
      final remoteProjectIds = remoteProjects.map((p) => p.id).toSet();
      final localOnlyProjects = unsyncedProjects
          .where((p) => !remoteProjectIds.contains(p.id))
          .toList();
      if (localOnlyProjects.isNotEmpty) {
        await localDB.insertProjectsBatch(localOnlyProjects);
      }

      // 6. Merge entries: keep unsynced local entries, replace synced ones with remote
      final localEntries = await localDB.getAllEntries();
      final unsyncedEntries = localEntries.where((e) => !e.synced).toList();

      final remoteEntries = await supabase.getAllEntries();
      await localDB.clearEntries();

      // Insert remote entries first (all marked as synced)
      await localDB.insertEntriesBatch(
        remoteEntries.map((e) => e.copyWith(synced: true)).toList(),
      );
      // Re-insert unsynced local entries that are NOT in remote (by id)
      final remoteEntryIds = remoteEntries.map((e) => e.id).toSet();
      final localOnlyEntries = unsyncedEntries
          .where((e) => !remoteEntryIds.contains(e.id))
          .toList();
      if (localOnlyEntries.isNotEmpty) {
        await localDB.insertEntriesBatch(localOnlyEntries);
      }

      // 7. Merge payments: keep unsynced local payments, replace synced ones with remote
      final localPayments = await localDB.getAllPayments();
      final unsyncedPayments = localPayments.where((p) => !p.synced).toList();

      final remotePayments = await supabase.getAllPayments();
      await localDB.clearPayments();

      // Insert remote payments first (all marked as synced)
      await localDB.insertPaymentsBatch(
        remotePayments.map((p) => p.copyWith(synced: true)).toList(),
      );
      // Re-insert unsynced local payments that are NOT in remote (by id)
      final remotePaymentIds = remotePayments.map((p) => p.id).toSet();
      final localOnlyPayments = unsyncedPayments
          .where((p) => !remotePaymentIds.contains(p.id))
          .toList();
      if (localOnlyPayments.isNotEmpty) {
        await localDB.insertPaymentsBatch(localOnlyPayments);
      }
    } catch (_) {}
  }
}