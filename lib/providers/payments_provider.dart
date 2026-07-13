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
    final sync = ref.read(syncServiceProvider);
    await db.insertPayment(payment);
    try {
      await sync.syncPendingPayments();
    } catch (e) {
      // Keep silent to prioritize local database insertion success
    }
    ref.invalidateSelf();
    try {
      await ref.read(backupServiceProvider).triggerBackup();
    } catch (e) {
      // Ignore backup failures for local data entry flow
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
