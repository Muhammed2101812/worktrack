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
    await sync.syncPendingPayments();
    ref.invalidateSelf();
    await ref.read(backupServiceProvider).triggerBackup();
  }

  Future<void> deletePayment(String id) async {
    final db = ref.read(localDBServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    await db.deletePayment(id);
    try {
      await supabase.deletePayment(id);
    } catch (_) {}
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
