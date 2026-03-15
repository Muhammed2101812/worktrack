import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import 'core_providers.dart';

class ClientsNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    return ref.watch(localDBServiceProvider).getAllClients();
  }

  Future<void> addClient(Client client) async {
    final db = ref.read(localDBServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    // Prevent duplicate names (case-insensitive)
    final existing = await db.getAllClients();
    if (existing.any(
        (c) => c.name.toLowerCase() == client.name.toLowerCase())) {
      return;
    }
    await db.insertClient(client);
    try {
      await supabase.upsertClient(client);
    } catch (_) {}
    ref.invalidateSelf();
  }

  Future<void> updateClient(Client client) async {
    final db = ref.read(localDBServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    await db.updateClient(client);
    try { await supabase.updateClient(client); } catch (_) {}
    ref.invalidateSelf();
  }

  Future<void> deleteClient(String id) async {
    final db = ref.read(localDBServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    await db.deleteClient(id);
    try { await supabase.deleteClient(id); } catch (_) {}
    ref.invalidateSelf();
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);