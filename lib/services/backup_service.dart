import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_db_service.dart';
import '../models/client.dart';
import '../models/work_entry.dart';
import '../models/project.dart';

class BackupService {
  final LocalDBService db;
  static const String _prefKeyData = 'worktrack_json_backup_data';
  static const String _prefKeyTime = 'worktrack_json_backup_time';

  BackupService(this.db);

  /// Triggers an automatic backup of all clients, projects and entries.
  Future<void> triggerBackup() async {
    try {
      final clients = await db.getAllClients();
      final entries = await db.getAllEntries();
      final projects = await db.getAllProjects();

      final backupMap = {
        'timestamp': DateTime.now().toIso8601String(),
        'clients': clients.map((c) => c.toMap()).toList(),
        'entries': entries.map((e) => e.toLocalMap()).toList(),
        'projects': projects.map((p) => p.toLocalMap()).toList(),
      };

      final jsonStr = jsonEncode(backupMap);

      // 1. Save to SharedPreferences (Works everywhere including Web)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyData, jsonStr);
      await prefs.setString(_prefKeyTime, DateTime.now().toString());

      // 2. On Desktop (Windows/Mac/Linux), write to physical Documents folder
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${directory.path}/WorkTrack_Backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        final file = File('${backupDir.path}/worktrack_backup.json');
        await file.writeAsString(jsonStr);
      }
    } catch (e) {
      debugPrint('Auto-backup failed: $e');
    }
  }

  /// Checks if a valid backup exists in SharedPreferences or local file system.
  Future<Map<String, dynamic>?> checkBackup() async {
    try {
      // 1. Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString(_prefKeyData);
      if (prefData != null) {
        return jsonDecode(prefData) as Map<String, dynamic>;
      }

      // 2. If on Desktop and SharedPrefs is empty, check Documents folder
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/WorkTrack_Backups/worktrack_backup.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Check backup failed: $e');
    }
    return null;
  }

  /// Restores database from a given backup map.
  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    try {
      final clientsJson = backup['clients'] as List<dynamic>? ?? [];
      final entriesJson = backup['entries'] as List<dynamic>? ?? [];
      final projectsJson = backup['projects'] as List<dynamic>? ?? [];

      final List<Client> clients = clientsJson
          .map((c) => Client.fromMap(c as Map<String, dynamic>))
          .toList();
      final List<WorkEntry> entries = entriesJson
          .map((e) => WorkEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      final List<Project> projects = projectsJson
          .map((p) => Project.fromMap(p as Map<String, dynamic>))
          .toList();

      await db.restoreBackupTransaction(clients, entries, projects);
    } catch (e) {
      debugPrint('Restore backup failed: $e');
      rethrow;
    }
  }
}
