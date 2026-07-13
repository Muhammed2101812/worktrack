import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import 'core_providers.dart';

class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() async {
    return ref.watch(localDBServiceProvider).getAllPayments();
  }

  Future<void> addPayment(Payment payment) async {
    final db = ref.read(localDBServiceProvider);
    bool insertSucceeded = false;
    try {
      await db.insertPayment(payment);
      insertSucceeded = true;

      try {
        await ref.read(syncServiceProvider).syncPendingPayments();
      } catch (e) {
        debugPrint('addPayment: sync failed (non-fatal): $e');
      }

      ref.invalidateSelf();

      try {
        await ref.read(backupServiceProvider).triggerBackup();
      } catch (e) {
        debugPrint('addPayment: backup failed (non-fatal): $e');
      }
    } catch (e) {
      debugPrint('addPayment error: $e');
      if (!insertSucceeded) {
        rethrow;
      }
    }
  }

  Future<void> deletePayment(String id) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    // Soft-delete locally so the deletion propagates to remote on next sync,
    // instead of being resurrected by fullSync's remote pull.
    await db.softDeletePayment(id);
    await sync.syncPendingPayments();
    ref.invalidateSelf();
    await ref.read(backupServiceProvider).triggerBackup();
  }

  Future<void> refresh() => Future(() => ref.invalidateSelf());
}

final paymentsProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(PaymentsNotifier.new);

final unsyncedPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  return ref.watch(localDBServiceProvider).getUnsyncedPayments();
});
