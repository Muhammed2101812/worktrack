import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/backup_service.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/project.dart';
import 'package:worklog/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupService - restoreBackup', () {
    late LocalDBService dbService;
    late BackupService backupService;

    setUp(() async {
      dbService = LocalDBService(dbName: ':memory:');
      backupService = BackupService(dbService);
      // :memory: is shared across LocalDBService instances in sqflite_ffi, so
      // wipe all tables before each test to guarantee a clean slate.
      await dbService.clearClients();
      await dbService.clearEntries();
      await dbService.clearProjects();
      await dbService.clearPayments();
    });

    test('restores all entity types including payments (regression: payments were previously dropped)', () async {
      // Arrange: build a backup map containing all 4 entity types.
      final client = Client(
        id: 'client-1',
        name: 'Acme Corp',
        color: '#112233',
      );
      final entry = WorkEntry(
        id: 'entry-1',
        clientId: 'client-1',
        clientName: 'Acme Corp',
        clientColor: '#112233',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
        notes: 'Geliştirme',
      );
      final project = Project(
        id: 'project-1',
        clientId: 'client-1',
        name: 'Website Redesign',
        description: 'Full rebuild',
        status: 'active',
      );
      final payment = Payment(
        id: 'payment-1',
        clientId: 'client-1',
        clientName: 'Acme Corp',
        clientColor: '#112233',
        amount: 1500.0,
        date: '20.03.2026',
        notes: 'Peşin ödeme',
      );

      final backup = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'clients': [client.toLocalMap()],
        'entries': [entry.toLocalMap()],
        'projects': [project.toLocalMap()],
        'payments': [payment.toLocalMap()],
      };

      // Act
      await backupService.restoreBackup(backup);

      // Assert: every entity type is present in the DB.
      final clients = await dbService.getAllClients();
      final entries = await dbService.getAllEntries();
      final projects = await dbService.getAllProjects();
      final payments = await dbService.getAllPayments();

      expect(clients, hasLength(1));
      expect(clients.first.id, 'client-1');
      expect(clients.first.name, 'Acme Corp');

      expect(entries, hasLength(1));
      expect(entries.first.id, 'entry-1');
      expect(entries.first.workType, 'Yazılım');

      expect(projects, hasLength(1));
      expect(projects.first.id, 'project-1');
      expect(projects.first.name, 'Website Redesign');

      // Critical regression assertion: payments must be restored.
      expect(payments, hasLength(1), reason: 'payments must be restored — this regressed before restoreBackup supported the payments field');
      expect(payments.first.id, 'payment-1');
      expect(payments.first.amount, 1500.0);
      expect(payments.first.clientName, 'Acme Corp');
    });

    test('restoreBackup transaction replaces existing data (clear + insert)', () async {
      // Arrange: pre-populate the DB with "old" data that should be wiped.
      await dbService.insertClient(Client(id: 'old-client', name: 'Old Client', color: '#000000'));
      await dbService.insertEntry(WorkEntry(
        id: 'old-entry',
        clientId: 'old-client',
        clientName: 'Old Client',
        clientColor: '#000000',
        date: '01.01.2020',
        startTime: '08:00',
        endTime: '09:00',
        workType: 'Eski İş',
      ));
      await dbService.insertProject(Project(id: 'old-project', clientId: 'old-client', name: 'Old Project'));
      await dbService.insertPayment(Payment(
        id: 'old-payment',
        clientId: 'old-client',
        clientName: 'Old Client',
        clientColor: '#000000',
        amount: 99.0,
        date: '01.01.2020',
      ));

      // Sanity check the seed data landed.
      expect(await dbService.getAllClients(), hasLength(1));
      expect(await dbService.getAllEntries(), hasLength(1));
      expect(await dbService.getAllProjects(), hasLength(1));
      expect(await dbService.getAllPayments(), hasLength(1));

      // Build a completely different backup (different ids).
      final backup = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'clients': [
          Client(id: 'new-client', name: 'New Client', color: '#FFFFFF').toLocalMap(),
        ],
        'entries': [
          WorkEntry(
            id: 'new-entry',
            clientId: 'new-client',
            clientName: 'New Client',
            clientColor: '#FFFFFF',
            date: '15.07.2026',
            startTime: '10:00',
            endTime: '11:00',
            workType: 'Yeni İş',
          ).toLocalMap(),
        ],
        'projects': [
          Project(id: 'new-project', clientId: 'new-client', name: 'New Project').toLocalMap(),
        ],
        'payments': [
          Payment(
            id: 'new-payment',
            clientId: 'new-client',
            clientName: 'New Client',
            clientColor: '#FFFFFF',
            amount: 250.0,
            date: '15.07.2026',
          ).toLocalMap(),
        ],
      };

      // Act
      await backupService.restoreBackup(backup);

      // Assert: old data is gone, only the new backup data remains.
      final clients = await dbService.getAllClients();
      final entries = await dbService.getAllEntries();
      final projects = await dbService.getAllProjects();
      final payments = await dbService.getAllPayments();

      expect(clients.every((c) => c.id == 'new-client'), isTrue);
      expect(clients, hasLength(1));
      expect(clients.first.name, 'New Client');

      expect(entries, hasLength(1));
      expect(entries.first.id, 'new-entry');
      expect(entries.any((e) => e.id == 'old-entry'), isFalse);

      expect(projects, hasLength(1));
      expect(projects.first.id, 'new-project');
      expect(projects.any((p) => p.id == 'old-project'), isFalse);

      expect(payments, hasLength(1));
      expect(payments.first.id, 'new-payment');
      expect(payments.any((p) => p.id == 'old-payment'), isFalse);
    });

    test('restoreBackup handles backup with missing optional keys gracefully', () async {
      // Arrange: a legacy backup that only has clients & entries (no projects/payments keys).
      final backup = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'clients': [
          Client(id: 'c-legacy', name: 'Legacy Client', color: '#123456').toLocalMap(),
        ],
        'entries': [
          WorkEntry(
            id: 'e-legacy',
            clientId: 'c-legacy',
            clientName: 'Legacy Client',
            clientColor: '#123456',
            date: '10.10.2025',
            startTime: '09:00',
            endTime: '17:00',
            workType: 'Danışmanlık',
          ).toLocalMap(),
        ],
        // projects and payments intentionally omitted
      };

      // Act
      await backupService.restoreBackup(backup);

      // Assert
      expect(await dbService.getAllClients(), hasLength(1));
      expect(await dbService.getAllEntries(), hasLength(1));
      expect(await dbService.getAllProjects(), isEmpty);
      expect(await dbService.getAllPayments(), isEmpty);
    });
  });

  group('BackupService - triggerBackup / checkBackup roundtrip', () {
    late LocalDBService dbService;
    late BackupService backupService;

    setUp(() async {
      // SharedPreferences plugin must be mocked for the desktop test env.
      SharedPreferences.setMockInitialValues({});
      dbService = LocalDBService(dbName: ':memory:');
      backupService = BackupService(dbService);
      // :memory: is shared across LocalDBService instances in sqflite_ffi, so
      // wipe all tables before each test to guarantee a clean slate.
      await dbService.clearClients();
      await dbService.clearEntries();
      await dbService.clearProjects();
      await dbService.clearPayments();

      // Seed all 4 entity types.
      await dbService.insertClient(Client(id: 'rt-client', name: 'Roundtrip Client', color: '#AABBCC'));
      await dbService.insertEntry(WorkEntry(
        id: 'rt-entry',
        clientId: 'rt-client',
        clientName: 'Roundtrip Client',
        clientColor: '#AABBCC',
        date: '12.07.2026',
        startTime: '09:00',
        endTime: '12:30',
        workType: 'Test',
        notes: 'roundtrip',
      ));
      await dbService.insertProject(Project(id: 'rt-project', clientId: 'rt-client', name: 'RT Project'));
      await dbService.insertPayment(Payment(
        id: 'rt-payment',
        clientId: 'rt-client',
        clientName: 'Roundtrip Client',
        clientColor: '#AABBCC',
        amount: 750.0,
        date: '12.07.2026',
      ));
    });

    test('triggerBackup persists all 4 lists and checkBackup retrieves them', () async {
      // Act
      await backupService.triggerBackup();
      final restored = await backupService.checkBackup();

      // Assert
      expect(restored, isNotNull);
      expect(restored!.keys, containsAll(['clients', 'entries', 'projects', 'payments']));

      final clients = restored['clients'] as List<dynamic>;
      final entries = restored['entries'] as List<dynamic>;
      final projects = restored['projects'] as List<dynamic>;
      final payments = restored['payments'] as List<dynamic>;

      expect(clients, hasLength(1));
      expect((clients.first as Map<String, dynamic>)['id'], 'rt-client');

      expect(entries, hasLength(1));
      expect((entries.first as Map<String, dynamic>)['id'], 'rt-entry');

      expect(projects, hasLength(1));
      expect((projects.first as Map<String, dynamic>)['id'], 'rt-project');

      // Critical: payments must appear in the backup map too.
      expect(payments, hasLength(1), reason: 'payments must be persisted by triggerBackup');
      expect((payments.first as Map<String, dynamic>)['id'], 'rt-payment');
      expect((payments.first as Map<String, dynamic>)['amount'], 750.0);
    });

    test('checkBackup returns null when no backup has been written', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await backupService.checkBackup();
      expect(result, isNull);
    });
  });
}
