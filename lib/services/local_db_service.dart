import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../models/project.dart';

class LocalDBService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      // Web üzerinde doğrudan databaseFactoryFfiWeb (ayrı çalışan) kullanılır, getDatabasesPath desteklenmez.
      return await databaseFactoryFfiWeb.openDatabase(
        'worklog.db',
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final path = join(await getDatabasesPath(), 'worklog.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN client_color text not null default "#4A90D9"');
      } catch (e) {
        // Sütun zaten varsa oluşan hatayı görmezden gel
      }
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
      } catch (e) {
        // Tablo zaten varsa oluşan hatayı görmezden gel
      }
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN project_id text');
      } catch (e) {
        // Sütun zaten varsa oluşan hatayı görmezden gel
      }
      try {
        await db.execute('ALTER TABLE work_entries ADD COLUMN project_name text');
      } catch (e) {
        // Sütun zaten varsa oluşan hatayı görmezden gel
      }
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
        project_name text
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

  Future<void> updateProjectsBatch(List<Project> projects) async {
    if (projects.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final project in projects) {
        batch.update(
          'projects',
          project.toLocalMap(),
          where: 'id = ?',
          whereArgs: [project.id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearProjects() async {
    final db = await database;
    await db.delete('projects');
  }

  // ── YEDEK GERİ YÜKLEME ──

  Future<void> restoreBackupTransaction(
      List<Client> clients, List<WorkEntry> entries,
      [List<Project> projects = const []]) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('work_entries');
      await txn.delete('clients');
      await txn.delete('projects');

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
      await batch.commit(noResult: true);
    });
  }
}