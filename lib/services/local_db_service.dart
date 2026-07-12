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
          version: 9,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final path = dbName == ':memory:' ? inMemoryDatabasePath : join(await getDatabasesPath(), dbName);
      return await openDatabase(
        path,
        version: 9,
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
    if (oldVersion < 9) {
      // Conflict resolution & soft-delete support columns
      await _addColumn(db, 'clients', 'created_at', "text DEFAULT ''");
      await _addColumn(db, 'clients', 'updated_at', "text DEFAULT ''");
      await _addColumn(db, 'clients', 'is_deleted', 'integer DEFAULT 0');
      await _addColumn(db, 'work_entries', 'created_at', "text DEFAULT ''");
      await _addColumn(db, 'work_entries', 'updated_at', "text DEFAULT ''");
      await _addColumn(db, 'work_entries', 'is_deleted', 'integer DEFAULT 0');
      await _addColumn(db, 'projects', 'updated_at', "text DEFAULT ''");
      await _addColumn(db, 'projects', 'is_deleted', 'integer DEFAULT 0');
      await _addColumn(db, 'payments', 'updated_at', "text DEFAULT ''");
      await _addColumn(db, 'payments', 'is_deleted', 'integer DEFAULT 0');
      // Performance: indexes for frequently filtered/sorted columns
      await _createIndex(db, 'idx_work_entries_client_id', 'work_entries', 'client_id');
      await _createIndex(db, 'idx_work_entries_date', 'work_entries', 'date');
      await _createIndex(db, 'idx_work_entries_synced', 'work_entries', 'synced');
      await _createIndex(db, 'idx_work_entries_deleted', 'work_entries', 'is_deleted');
      await _createIndex(db, 'idx_payments_client_id', 'payments', 'client_id');
      await _createIndex(db, 'idx_payments_date', 'payments', 'date');
      await _createIndex(db, 'idx_payments_synced', 'payments', 'synced');
      await _createIndex(db, 'idx_payments_deleted', 'payments', 'is_deleted');
      await _createIndex(db, 'idx_projects_client_id', 'projects', 'client_id');
      await _createIndex(db, 'idx_projects_synced', 'projects', 'synced');
      await _createIndex(db, 'idx_projects_deleted', 'projects', 'is_deleted');
    }
  }

  Future<void> _addColumn(Database db, String table, String column, String type) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (_) {}
  }

  Future<void> _createIndex(Database db, String indexName, String table, String column) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $table ($column)');
    } catch (_) {}
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
        total_price real default 0.0,
        created_at text default '',
        updated_at text default '',
        is_deleted integer default 0
      )
    ''');
    await db.execute('''
      create table clients (
        id text primary key,
        name text not null,
        color text not null,
        created_at text default '',
        updated_at text default '',
        is_deleted integer default 0
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
        updated_at text default '',
        synced integer default 0,
        is_deleted integer default 0
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
        created_at text not null,
        updated_at text default '',
        is_deleted integer default 0
      )
    ''');
    // Performance indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_work_entries_client_id ON work_entries (client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_work_entries_date ON work_entries (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_work_entries_synced ON work_entries (synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_work_entries_deleted ON work_entries (is_deleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_client_id ON payments (client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_date ON payments (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_synced ON payments (synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_deleted ON payments (is_deleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_client_id ON projects (client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_synced ON projects (synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_deleted ON projects (is_deleted)');
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
    // date is stored in display format "dd.MM.yyyy" which does not sort
    // correctly as a string, so we order by a sortable expression instead.
    final rows = await db.rawQuery('''
      SELECT * FROM work_entries
      WHERE is_deleted = 0
      ORDER BY
        substr(date, 7, 4) DESC,
        substr(date, 4, 2) DESC,
        substr(date, 1, 2) DESC,
        start_time DESC
    ''');
    return rows.map(WorkEntry.fromMap).toList();
  }

  Future<List<WorkEntry>> getTodayEntries(String today) async {
    final db = await database;
    final rows = await db.query('work_entries',
        where: 'date = ? AND is_deleted = 0', whereArgs: [today]);
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

  /// Soft-deletes an entry so the deletion can propagate to remote on sync.
  Future<void> softDeleteEntry(String id) async {
    final db = await database;
    await db.update('work_entries',
        {'is_deleted': 1, 'synced': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
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
    await db.insert('clients', client.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertClientsBatch(List<Client> clients) async {
    if (clients.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final client in clients) {
        batch.insert('clients', client.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final rows = await db.query('clients',
        where: 'is_deleted = 0', orderBy: 'name');
    return rows.map(Client.fromMap).toList();
  }

  Future<List<Client>> getAllClientsIncludingDeleted() async {
    final db = await database;
    final rows = await db.query('clients', orderBy: 'name');
    return rows.map(Client.fromMap).toList();
  }

  /// Soft-deletes a client so the deletion can propagate to remote on sync.
  Future<void> softDeleteClient(String id) async {
    final db = await database;
    await db.update('clients',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
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
    final rows = await db.query('projects',
        where: 'is_deleted = 0', orderBy: 'name');
    return rows.map(Project.fromMap).toList();
  }

  Future<List<Project>> getProjectsByClient(String clientId) async {
    final db = await database;
    final rows = await db.query('projects',
        where: 'client_id = ? AND is_deleted = 0',
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

  /// Soft-deletes a project so the deletion can propagate to remote on sync.
  Future<void> softDeleteProject(String id) async {
    final db = await database;
    await db.update('projects',
        {'is_deleted': 1, 'synced': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
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
    // date is "dd.MM.yyyy" — sort by sortable expression.
    final rows = await db.rawQuery('''
      SELECT * FROM payments
      WHERE is_deleted = 0
      ORDER BY
        substr(date, 7, 4) DESC,
        substr(date, 4, 2) DESC,
        substr(date, 1, 2) DESC,
        created_at DESC
    ''');
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

  /// Soft-deletes a payment so the deletion can propagate to remote on sync.
  Future<void> softDeletePayment(String id) async {
    final db = await database;
    await db.update('payments',
        {'is_deleted': 1, 'synced': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
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
        batch.insert('clients', client.toLocalMap(),
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