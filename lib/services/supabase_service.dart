import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../core/constants.dart';

class SupabaseService {
  final _db = Supabase.instance.client;

  // ── KAYITLAR ──────────────────────────────────

  Future<void> upsertEntry(WorkEntry entry) async {
    try {
      await _db.from(AppConstants.entriesTable).upsert(entry.toMap());
    } on PostgrestException catch (e) {
      // Eğer Supabase tablosunda client_color veya diğer sonradan eklenen sütunlar
      // yoksa, Bad Request (400) döner. Bu durumda eksik sütunu hariç tutarak deniyoruz.
      if (e.message.contains('client_color')) {
        final map = entry.toMap();
        map.remove('client_color');
        await _db.from(AppConstants.entriesTable).upsert(map);
      } else {
        // Hata türü client_color'dan kaynaklı olduğundan emin olamadığımız durumlar için
        // güvenlik amaçlı map'i temizleyip bir daha denetiyoruz:
        final map = entry.toMap();
        map.remove('client_color');
        try {
          await _db.from(AppConstants.entriesTable).upsert(map);
        } catch (_) {
          rethrow;
        }
      }
    }
  }

  Future<List<WorkEntry>> getAllEntries() async {
    final data = await _db
        .from(AppConstants.entriesTable)
        .select()
        .order('date', ascending: false);
    return (data as List).map((e) => WorkEntry.fromMap(e)).toList();
  }

  Future<void> deleteEntry(String id) async {
    await _db.from(AppConstants.entriesTable).delete().eq('id', id);
  }

  // ── MÜŞTERİLER ───────────────────────────────

  Future<void> addClient(Client client) async {
    await _db.from(AppConstants.clientsTable).insert(client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final data = await _db
        .from(AppConstants.clientsTable)
        .select()
        .order('name');
    return (data as List).map((e) => Client.fromMap(e)).toList();
  }

  Future<void> updateClient(Client client) async {
    await _db
        .from(AppConstants.clientsTable)
        .update(client.toMap())
        .eq('id', client.id);
  }

  Future<void> deleteClient(String id) async {
    await _db.from(AppConstants.clientsTable).delete().eq('id', id);
  }
}