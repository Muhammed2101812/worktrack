import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/payment.dart';

class LocalDBService {
  final String dbName;
  Database? _db;

  LocalDBService({this.dbName = 'worklog.db'});

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        dbName,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final path = dbName == ':memory:' ? inMemoryDatabasePath : join(await getDatabasesPath(), dbName);
      return await openDatabase(
        path,
        version: 8,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN client_color text not null default "#4A90D9"');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          create table projects (
            id text primary key,
            client_id text,
            name text not null,
            description text default '',
            status text default 'active',
            created_at text not null,
            synced integer default 0
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN project_id text');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN project_name text');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN description text DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN status text DEFAULT 'active'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN created_at text DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN synced integer DEFAULT 0");
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('DROP TABLE IF EXISTS projects');
        await db.execute('''
          create table projects (
            id text primary key,
            client_id text,
            name text not null,
            description text default '',
            status text default 'active',
            created_at text not null,
            synced integer default 0
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute("ALTER TABLE work_entries ADD COLUMN billing_type text DEFAULT 'hourly'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE work_entries ADD COLUMN hourly_rate real DEFAULT 0.0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE work_entries ADD COLUMN total_price real DEFAULT 0.0");
      } catch (_) {}
      try {
        await db.execute('''
          create table payments (
            id text primary key,
            client_id text not null,
            client_name text not null,
            client_color text not null default '#4A90D9',
            amount real not null,
            date text not null,
            notes text default '',
            synced integer default 0,
            created_at text not null
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      create table work_entries (
        id text primary key,
        client_id text,
        client_name text not null,
        client_color text not null,
        date text not null,
        start_time text not null,
        end_time text not null,
        duration_hours real not null,
        work_type text not null,
        notes text default '',
        synced integer default 0,
        project_id text,
        project_name text,
        billing_type text default 'hourly',
        hourly_rate real default 0.0,
        total_price real default 0.0
      )
    ''');
    await db.execute('''
      create table clients (
        id text primary key,
        name text not null,
        color text not null
      )
    ''');
    await db.execute('''
      create table projects (
        id text primary key,
        client_id text,
        name text not null,
        description text default '',
        status text default 'active',
        created_at text not null,
        synced integer default 0
      )
    ''');
    await db.execute('''
      create table payments (
        id text primary key,
        client_id text not null,
        client_name text not null,
        client_color text not null default '#4A90D9',
        amount real not null,
        date text not null,
        notes text default '',
        synced integer default 0,
        created_at text not null
      )
    ''');
  }

  // ── KAYITLAR ──

  Future<void> insertEntry(WorkEntry entry) async {
    final db = await database;
    await db.insert('work_entries', entry.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertEntriesBatch(List<WorkEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('work_entries', entry.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<WorkEntry>> getAllEntries() async {
    final db = await database;
    final rows = await db.query('work_entries', orderBy: 'date desc, start_time desc');
    return rows.map(WorkEntry.fromMap).toList();
  }

  Future<List<WorkEntry>> getTodayEntries(String today) async {
    final db = await database;
    final rows = await db.query('work_entries',
        where: 'date = ?', whereArgs: [today]);
    return rows.map(WorkEntry.fromMap).toList();
  }

  Future<List<WorkEntry>> getUnsyncedEntries() async {
    final db = await database;
    final rows = await db.query('work_entries',
        where: 'synced = 0');
    return rows.map(WorkEntry.fromMap).toList();
  }

  Future<void> updateEntrySync(String id, bool synced) async {
    final db = await database;
    await db.update('work_entries', {'synced': synced ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateEntry(WorkEntry entry) async {
    final db = await database;
    await db.update(
      'work_entries',
      entry.toLocalMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('work_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearEntries() async {
    final db = await database;
    await db.delete('work_entries');
  }

  // ── MÜŞTERİLER ──

  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert('clients', client.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertClientsBatch(List<Client> clients) async {
    if (clients.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final client in clients) {
        batch.insert('clients', client.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final rows = await db.query('clients', orderBy: 'name');
    return rows.map(Client.fromMap).toList();
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearClients() async {
    final db = await database;
    await db.delete('clients');
  }

  // ── PROJELER ──

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert('projects', project.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProjectsBatch(List<Project> projects) async {
    if (projects.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final project in projects) {
        batch.insert('projects', project.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'name');
    return rows.map(Project.fromMap).toList();
  }

  Future<List<Project>> getProjectsByClient(String clientId) async {
    final db = await database;
    final rows = await db.query('projects',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'name');
    return rows.map(Project.fromMap).toList();
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update(
      'projects',
      project.toLocalMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearProjects() async {
    final db = await database;
    await db.delete('projects');
  }

  // ── ÖDEMELER (PAYMENTS) ──

  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPaymentsBatch(List<Payment> payments) async {
    if (payments.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final payment in payments) {
        batch.insert('payments', payment.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final rows = await db.query('payments', orderBy: 'date desc, created_at desc');
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getUnsyncedPayments() async {
    final db = await database;
    final rows = await db.query('payments', where: 'synced = 0');
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> updatePaymentSync(String id, bool synced) async {
    final db = await database;
    await db.update('payments', {'synced': synced ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePayment(Payment payment) async {
    final db = await database;
    await db.update(
      'payments',
      payment.toLocalMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearPayments() async {
    final db = await database;
    await db.delete('payments');
  }

  // ── YEDEK GERİ YÜKLEME ──

  Future<void> restoreBackupTransaction(
      List<Client> clients, List<WorkEntry> entries,
      [List<Project> projects = const [], List<Payment> payments = const []]) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('work_entries');
      await txn.delete('clients');
      await txn.delete('projects');
      await txn.delete('payments');

      final batch = txn.batch();
      for (final client in clients) {
        batch.insert('clients', client.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final entry in entries) {
        batch.insert('work_entries', entry.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final project in projects) {
        batch.insert('projects', project.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final payment in payments) {
        batch.insert('payments', payment.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }
}