import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/project.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/services/backup_service.dart';
import 'package:worklog/services/local_db_service.dart';

// Custom Fake for PathProviderPlatform
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return path;
  }
}

// Custom Fake for LocalDBService
class FakeLocalDBService extends Fake implements LocalDBService {
  List<Client> clients = [];
  List<WorkEntry> entries = [];
  List<Project> projects = [];

  bool restoreBackupTransactionCalled = false;
  List<Client>? restoredClients;
  List<WorkEntry>? restoredEntries;
  List<Project>? restoredProjects;

  bool shouldThrowOnGetClients = false;
  bool shouldThrowOnRestore = false;

  @override
  Future<List<Client>> getAllClients() async {
    if (shouldThrowOnGetClients) {
      throw Exception('DB Error getting clients');
    }
    return clients;
  }

  @override
  Future<List<WorkEntry>> getAllEntries() async {
    return entries;
  }

  @override
  Future<List<Project>> getAllProjects() async {
    return projects;
  }

  @override
  Future<void> restoreBackupTransaction(
    List<Client> clients,
    List<WorkEntry> entries, [
    List<Project> projects = const [],
  ]) async {
    if (shouldThrowOnRestore) {
      throw Exception('DB Error during restore transaction');
    }
    restoreBackupTransactionCalled = true;
    restoredClients = clients;
    restoredEntries = entries;
    restoredProjects = projects;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalDBService mockDB;
  late BackupService backupService;
  late Directory tempDir;
  late FakePathProviderPlatform fakePathProvider;

  setUp(() {
    mockDB = FakeLocalDBService();
    backupService = BackupService(mockDB);

    // Create a unique temporary directory for each test
    tempDir = Directory.systemTemp.createTempSync('backup_test_');
    fakePathProvider = FakePathProviderPlatform(tempDir.path);
    PathProviderPlatform.instance = fakePathProvider;

    // Reset mock SharedPreferences values
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Clean up temporary directory
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('BackupService Tests', () {
    test('Initialization check', () {
      expect(backupService, isNotNull);
      expect(backupService.db, equals(mockDB));
    });

    group('triggerBackup Tests', () {
      test('triggerBackup - happy path with data', () async {
        // Prepare some mock data
        final client = Client(id: 'c1', name: 'Acme Corp', color: '#123456');
        final project = Project(id: 'p1', clientId: 'c1', name: 'Mobile App', description: 'Flutter app');
        final entry = WorkEntry(
          id: 'e1',
          clientId: 'c1',
          clientName: 'Acme Corp',
          clientColor: '#123456',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Software Development',
          notes: 'Unit testing',
          synced: true,
        );

        mockDB.clients = [client];
        mockDB.projects = [project];
        mockDB.entries = [entry];

        // Trigger backup
        await backupService.triggerBackup();

        // 1. Verify SharedPreferences backup
        final prefs = await SharedPreferences.getInstance();
        final prefData = prefs.getString('worktrack_json_backup_data');
        final prefTime = prefs.getString('worktrack_json_backup_time');

        expect(prefData, isNotNull);
        expect(prefTime, isNotNull);

        final backupMap = jsonDecode(prefData!) as Map<String, dynamic>;
        expect(backupMap['timestamp'], isNotNull);
        expect(backupMap['clients'], isNotEmpty);
        expect(backupMap['projects'], isNotEmpty);
        expect(backupMap['entries'], isNotEmpty);

        final restoredClient = Client.fromMap(backupMap['clients'][0] as Map<String, dynamic>);
        expect(restoredClient.id, equals('c1'));
        expect(restoredClient.name, equals('Acme Corp'));

        final restoredProject = Project.fromMap(backupMap['projects'][0] as Map<String, dynamic>);
        expect(restoredProject.id, equals('p1'));
        expect(restoredProject.name, equals('Mobile App'));

        final restoredEntry = WorkEntry.fromMap(backupMap['entries'][0] as Map<String, dynamic>);
        expect(restoredEntry.id, equals('e1'));
        expect(restoredEntry.notes, equals('Unit testing'));

        // 2. Verify physical backup file creation
        final file = File('${tempDir.path}/WorkTrack_Backups/worktrack_backup.json');
        expect(await file.exists(), isTrue);

        final fileContent = await file.readAsString();
        final fileBackupMap = jsonDecode(fileContent) as Map<String, dynamic>;
        expect(fileBackupMap['timestamp'], isNotNull);
        expect(fileBackupMap['clients'][0]['name'], equals('Acme Corp'));
        expect(fileBackupMap['projects'][0]['name'], equals('Mobile App'));
        expect(fileBackupMap['entries'][0]['notes'], equals('Unit testing'));
      });

      test('triggerBackup - database exception is handled gracefully', () async {
        mockDB.shouldThrowOnGetClients = true;

        // Should not throw exception since it has try-catch inside
        await expectLater(backupService.triggerBackup(), completes);

        // Verify no SharedPreferences or file was written
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('worktrack_json_backup_data'), null);

        final file = File('${tempDir.path}/WorkTrack_Backups/worktrack_backup.json');
        expect(await file.exists(), isFalse);
      });
    });

    group('checkBackup Tests', () {
      test('checkBackup - returns data from SharedPreferences if present', () async {
        final mockBackup = {
          'timestamp': '2026-03-15T09:00:00Z',
          'clients': [
            {'id': 'c1', 'name': 'Acme', 'color': '#000'}
          ],
          'entries': [],
          'projects': []
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('worktrack_json_backup_data', jsonEncode(mockBackup));

        final result = await backupService.checkBackup();
        expect(result, isNotNull);
        expect(result!['timestamp'], equals('2026-03-15T09:00:00Z'));
        expect(result['clients'][0]['name'], equals('Acme'));
      });

      test('checkBackup - falls back to physical file if SharedPreferences is empty', () async {
        final mockBackup = {
          'timestamp': '2026-03-15T12:00:00Z',
          'clients': [],
          'entries': [
            {'id': 'e1', 'client_id': 'c1', 'notes': 'File fallback test'}
          ],
          'projects': []
        };

        // Create backup directory and file manually
        final backupDir = Directory('${tempDir.path}/WorkTrack_Backups');
        await backupDir.create(recursive: true);
        final file = File('${backupDir.path}/worktrack_backup.json');
        await file.writeAsString(jsonEncode(mockBackup));

        final result = await backupService.checkBackup();
        expect(result, isNotNull);
        expect(result!['timestamp'], equals('2026-03-15T12:00:00Z'));
        expect(result['entries'][0]['notes'], equals('File fallback test'));
      });

      test('checkBackup - returns null when neither SharedPreferences nor physical file exists', () async {
        final result = await backupService.checkBackup();
        expect(result, isNull);
      });

      test('checkBackup - returns null and handles JSON parsing exception gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('worktrack_json_backup_data', 'invalid-json-{');

        final result = await backupService.checkBackup();
        expect(result, isNull);
      });
    });

    group('restoreBackup Tests', () {
      test('restoreBackup - parses backup data and calls DB transaction correctly', () async {
        final mockBackupMap = {
          'clients': [
            {'id': 'c1', 'name': 'Restored Client', 'color': '#111111'}
          ],
          'projects': [
            {
              'id': 'p1',
              'client_id': 'c1',
              'name': 'Restored Project',
              'description': 'Description',
              'status': 'active',
              'created_at': '2026-03-15T10:00:00Z',
              'synced': 1
            }
          ],
          'entries': [
            {
              'id': 'e1',
              'client_id': 'c1',
              'client_name': 'Restored Client',
              'client_color': '#111111',
              'date': '15.03.2026',
              'start_time': '10:00',
              'end_time': '11:00',
              'work_type': 'Testing',
              'notes': 'Restored Notes',
              'synced': 0
            }
          ]
        };

        await backupService.restoreBackup(mockBackupMap);

        expect(mockDB.restoreBackupTransactionCalled, isTrue);
        expect(mockDB.restoredClients, hasLength(1));
        expect(mockDB.restoredClients!.first.id, equals('c1'));
        expect(mockDB.restoredClients!.first.name, equals('Restored Client'));

        expect(mockDB.restoredProjects, hasLength(1));
        expect(mockDB.restoredProjects!.first.id, equals('p1'));
        expect(mockDB.restoredProjects!.first.name, equals('Restored Project'));

        expect(mockDB.restoredEntries, hasLength(1));
        expect(mockDB.restoredEntries!.first.id, equals('e1'));
        expect(mockDB.restoredEntries!.first.notes, equals('Restored Notes'));
      });

      test('restoreBackup - missing keys in map fallback to empty lists gracefully', () async {
        final mockBackupMap = <String, dynamic>{};

        await backupService.restoreBackup(mockBackupMap);

        expect(mockDB.restoreBackupTransactionCalled, isTrue);
        expect(mockDB.restoredClients, isEmpty);
        expect(mockDB.restoredEntries, isEmpty);
        expect(mockDB.restoredProjects, isEmpty);
      });

      test('restoreBackup - database transaction exception is rethrown', () async {
        mockDB.shouldThrowOnRestore = true;

        final mockBackupMap = <String, dynamic>{};

        expect(
          () => backupService.restoreBackup(mockBackupMap),
          throwsException,
        );
      });
    });
  });
}
