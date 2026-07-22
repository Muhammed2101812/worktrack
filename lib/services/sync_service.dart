import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/work_entry.dart';
import '../models/payment.dart';

/// Compares two ISO-8601 timestamps. Returns:
///  > 0 if [a] is newer than [b]
///  < 0 if [a] is older than [b]
///  = 0 if equal
/// Treats empty/null strings as the oldest possible value so that records
/// without an updatedAt never silently overwrite a dated record.
int compareUpdatedAt(String? a, String? b) {
  final sa = (a == null || a.isEmpty) ? '' : a;
  final sb = (b == null || b.isEmpty) ? '' : b;
  return sa.compareTo(sb);
}

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
        await localDB.updateEntriesSyncBatch(
            unsynced.map((e) => e.id).toList(), true);
      } catch (_) {
        // Fallback to individual upserts on failure to preserve fault tolerance (single-row error handling)
        final successfulIds = <String>[];
        for (final entry in unsynced) {
          try {
            await supabase.upsertEntry(entry);
            successfulIds.add(entry.id);
          } catch (e) {
            // Tek satır başarısız olursa diğer satırları işlemeye devam et
          }
        }
        if (successfulIds.isNotEmpty) {
          await localDB.updateEntriesSyncBatch(successfulIds, true);
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
        // Batch-mark all as synced in one transaction (PR #31 optimisation).
        await localDB.updateProjectsSyncBatch(
            unsynced.map((p) => p.id).toList(), true);
      } catch (_) {
        // Fallback to individual upserts on failure
        final successfulIds = <String>[];
        for (final project in unsynced) {
          try {
            await supabase.upsertProject(project);
            successfulIds.add(project.id);
          } catch (_) {
            // Tek proje başarısız olursa diğerlerini işlemeye devam et
          }
        }
        if (successfulIds.isNotEmpty) {
          await localDB.updateProjectsSyncBatch(successfulIds, true);
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
        await localDB.updatePaymentsSyncBatch(
            unsynced.map((p) => p.id).toList(), true);
      } catch (_) {
        // Fallback to individual upserts
        final successfulIds = <String>[];
        for (final payment in unsynced) {
          try {
            await supabase.upsertPayment(payment);
            successfulIds.add(payment.id);
          } catch (_) {}
        }
        if (successfulIds.isNotEmpty) {
          await localDB.updatePaymentsSyncBatch(successfulIds, true);
        }
      }
    } catch (_) {}
  }

  /// Bi-directional merge using last-write-wins by `updated_at`.
  ///
  /// Unlike the previous clear+replace strategy, this preserves local edits
  /// that are newer than their remote counterpart for the same id, and never
  /// blows away locally-unsynced records. Soft-deleted records are pushed so
  /// the deletion propagates to remote.
  Future<void> fullSync() async {
    try {
      if (!_isLoggedIn()) return;
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) return;

      // 1. Push local-only clients to remote first (name-based dedup)
      final remoteClients = await supabase.getAllClients();
      final remoteClientNames =
          remoteClients.map((c) => c.name.toLowerCase()).toSet();

      final localClientsAll = await localDB.getAllClientsIncludingDeleted();
      final clientsToUpsert = <Client>[];
      for (final lc in localClientsAll) {
        if (!remoteClientNames.contains(lc.name.toLowerCase())) {
          clientsToUpsert.add(lc);
        }
      }
      if (clientsToUpsert.isNotEmpty) {
        try {
          await supabase.upsertClients(clientsToUpsert);
        } catch (_) {}
      }

      // 2. Push unsynced projects, entries and payments to remote
      await syncPendingProjects();
      await syncPendingEntries();
      await syncPendingPayments();

      // 3. Merge clients (dedupe by name, keep newest by updated_at)
      final finalRemoteClients = await supabase.getAllClients();
      final localById = <String, Client>{
        for (final c in localClientsAll) c.id: c,
      };

      final mergedClients = <Client>[];
      final seenNames = <String>{};
      for (final rc in finalRemoteClients) {
        final nameKey = rc.name.toLowerCase();
        if (!seenNames.add(nameKey)) continue; // dedupe within remote
        final existing = localById[rc.id];
        if (existing != null) {
          // Keep whichever side is newer; preserve local-only fields.
          mergedClients.add(
            compareUpdatedAt(rc.updatedAt, existing.updatedAt) >= 0
                ? existing.copyWith(
                    name: rc.name,
                    color: rc.color,
                  )
                : existing,
          );
        } else {
          mergedClients.add(rc.copyWith(
            updatedAt: rc.updatedAt,
          ));
        }
      }
      // Keep local clients whose id is not present remotely.
      final remoteClientIds = finalRemoteClients.map((c) => c.id).toSet();
      for (final lc in localClientsAll) {
        if (!remoteClientIds.contains(lc.id)) {
          mergedClients.add(lc);
        }
      }
      await localDB.clearClients();
      await localDB.insertClientsBatch(mergedClients);

      // 4. Merge projects (upsert-by-id with timestamp comparison)
      await _mergeProjects();
      // 5. Merge entries
      await _mergeEntries();
      // 6. Merge payments
      await _mergePayments();
    } catch (_) {}
  }

  Future<void> _mergeProjects() async {
    final localProjects = await localDB.getAllProjects();
    final localById = <String, Project>{
      for (final p in localProjects) p.id: p,
    };

    final remoteProjects = await supabase.getAllProjects();
    final seenIds = <String>{};
    final merged = <Project>[];
    for (final rp in remoteProjects) {
      seenIds.add(rp.id);
      final existing = localById[rp.id];
      if (existing != null &&
          compareUpdatedAt(rp.updatedAt, existing.updatedAt) < 0) {
        // Local is newer — keep it, but mark as synced.
        merged.add(existing.copyWith(synced: true));
      } else {
        // Remote wins or is new.
        merged.add(rp.copyWith(synced: true));
      }
    }
    // Preserve local-only projects (unsynced offline creations).
    for (final lp in localProjects) {
      if (!seenIds.contains(lp.id)) {
        merged.add(lp);
      }
    }
    await localDB.clearProjects();
    await localDB.insertProjectsBatch(merged);
  }

  Future<void> _mergeEntries() async {
    final localEntries = await localDB.getAllEntries();
    final localById = <String, WorkEntry>{
      for (final e in localEntries) e.id: e,
    };

    final remoteEntries = await supabase.getAllEntries();
    final seenIds = <String>{};
    final merged = <WorkEntry>[];
    for (final re in remoteEntries) {
      seenIds.add(re.id);
      final existing = localById[re.id];
      if (existing != null &&
          compareUpdatedAt(re.updatedAt, existing.updatedAt) < 0) {
        merged.add(existing.copyWith(synced: true));
      } else {
        merged.add(re.copyWith(synced: true));
      }
    }
    for (final le in localEntries) {
      if (!seenIds.contains(le.id)) {
        merged.add(le);
      }
    }
    await localDB.clearEntries();
    await localDB.insertEntriesBatch(merged);
  }

  Future<void> _mergePayments() async {
    final localPayments = await localDB.getAllPayments();
    final localById = <String, Payment>{
      for (final p in localPayments) p.id: p,
    };

    final remotePayments = await supabase.getAllPayments();
    final seenIds = <String>{};
    final merged = <Payment>[];
    for (final rp in remotePayments) {
      seenIds.add(rp.id);
      final existing = localById[rp.id];
      if (existing != null &&
          compareUpdatedAt(rp.updatedAt, existing.updatedAt) < 0) {
        merged.add(existing.copyWith(synced: true));
      } else {
        merged.add(rp.copyWith(synced: true));
      }
    }
    for (final lp in localPayments) {
      if (!seenIds.contains(lp.id)) {
        merged.add(lp);
      }
    }
    await localDB.clearPayments();
    await localDB.insertPaymentsBatch(merged);
  }
}
