import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/payment.dart';
import '../core/constants.dart';

class SupabaseService {
  final SupabaseClient _db;

  SupabaseService({SupabaseClient? client}) : _db = client ?? Supabase.instance.client;

  // ── KAYITLAR ──────────────────────────────────

  Future<void> upsertEntry(WorkEntry entry) async {
    try {
      await _db.from(AppConstants.entriesTable).upsert(entry.toMap());
    } on PostgrestException {
      // Eğer Supabase tablosunda client_color veya diğer sonradan eklenen sütunlar
      // yoksa, Bad Request (400) döner. Bu durumda eksik sütunu hariç tutarak deniyoruz.
      final map = entry.toMap();
      map.remove('client_color');
      await _db.from(AppConstants.entriesTable).upsert(map);
    }
  }

  Future<void> upsertEntries(List<WorkEntry> entries) async {
    if (entries.isEmpty) return;
    final maps = entries.map((e) => e.toMap()).toList();
    try {
      await _db.from(AppConstants.entriesTable).upsert(maps);
    } on PostgrestException {
      // Eğer Supabase tablosunda client_color veya diğer sonradan eklenen sütunlar
      // yoksa, Bad Request (400) döner. Bu durumda eksik sütunu hariç tutarak deniyoruz.
      for (final map in maps) {
        map.remove('client_color');
      }
      await _db.from(AppConstants.entriesTable).upsert(maps);
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

  Future<void> upsertClient(Client client) async {
    await _db.from(AppConstants.clientsTable).upsert(client.toMap());
  }

  Future<void> upsertClients(List<Client> clients) async {
    if (clients.isEmpty) return;
    await _db.from(AppConstants.clientsTable).upsert(
          clients.map((c) => c.toMap()).toList(),
        );
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

  // ── PROJELER ─────────────────────────────────

  Future<void> upsertProject(Project project) async {
    await _db.from(AppConstants.projectsTable).upsert(project.toMap());
  }

  Future<void> upsertProjects(List<Project> projects) async {
    if (projects.isEmpty) return;
    await _db.from(AppConstants.projectsTable).upsert(
          projects.map((p) => p.toMap()).toList(),
        );
  }

  Future<List<Project>> getAllProjects() async {
    final data = await _db
        .from(AppConstants.projectsTable)
        .select()
        .order('name');
    return (data as List).map((e) => Project.fromMap(e)).toList();
  }

  Future<void> deleteProject(String id) async {
    await _db.from(AppConstants.projectsTable).delete().eq('id', id);
  }

  // ── ÖDEMELER ─────────────────────────────────

  Future<void> upsertPayment(Payment payment) async {
    await _db.from(AppConstants.paymentsTable).upsert(payment.toMap());
  }

  Future<void> upsertPayments(List<Payment> payments) async {
    if (payments.isEmpty) return;
    await _db
        .from(AppConstants.paymentsTable)
        .upsert(payments.map((p) => p.toMap()).toList());
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final data = await _db
          .from(AppConstants.paymentsTable)
          .select()
          .order('date', ascending: false);
      return (data as List).map((e) => Payment.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deletePayment(String id) async {
    await _db.from(AppConstants.paymentsTable).delete().eq('id', id);
  }
}