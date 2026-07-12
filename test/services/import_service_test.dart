import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:excel/excel.dart';
import 'package:worklog/services/import_service.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/backup_service.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/clients_provider.dart';
import 'package:worklog/providers/entries_provider.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/project.dart';

// --- Integration Test Mock ---
class MockWidgetRefIntegration implements WidgetRef {
  final ProviderContainer container;
  MockWidgetRefIntegration(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Unit Test Mocks ---
class MockLocalDBServiceUnit extends Fake implements LocalDBService {
  final List<Client> mockClients = [];
  final List<Client> insertedClients = [];
  final List<WorkEntry> insertedEntries = [];
  final List<Project> mockProjects = [];
  final List<Project> insertedProjects = [];
  bool shouldThrowOnInsertEntry = false;

  @override
  Future<List<Client>> getAllClients() async {
    return mockClients;
  }

  @override
  Future<void> insertClient(Client client) async {
    insertedClients.add(client);
  }

  @override
  Future<void> insertEntry(WorkEntry entry) async {
    if (shouldThrowOnInsertEntry) {
      throw Exception('Database Error inserting entry');
    }
    insertedEntries.add(entry);
  }

  @override
  Future<List<Project>> getAllProjects() async {
    return mockProjects;
  }

  @override
  Future<void> insertProject(Project project) async {
    insertedProjects.add(project);
  }
}

class MockBackupService extends Fake implements BackupService {
  @override
  Future<void> triggerBackup() async {
    // do nothing
  }
}

class MockWidgetRefUnit implements WidgetRef {
  final Map<ProviderListenable<dynamic>, dynamic> _providerValues;
  final List<ProviderOrFamily> invalidatedProviders = [];

  MockWidgetRefUnit(this._providerValues);

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_providerValues.containsKey(provider)) {
      return _providerValues[provider] as T;
    }
    throw UnimplementedError('Provider not mocked: $provider');
  }

  @override
  void invalidate(ProviderOrFamily provider) {
    invalidatedProviders.add(provider);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ImportService Unit Tests', () {
    late MockLocalDBServiceUnit mockDB;
    late MockWidgetRefUnit mockRef;

    setUp(() {
      mockDB = MockLocalDBServiceUnit();
      final mockBackup = MockBackupService();
      mockRef = MockWidgetRefUnit({
        localDBServiceProvider: mockDB,
        backupServiceProvider: mockBackup,
      });
    });

    List<int> createExcelBytes(List<List<String>> rows) {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Header row
      sheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Müşteri'),
        TextCellValue('Başlangıç'),
        TextCellValue('Bitiş'),
        TextCellValue('İş Türü'),
        TextCellValue('Proje'),
        TextCellValue('Notlar'),
        TextCellValue('Ücret Tipi'),
        TextCellValue('Ücret'),
      ]);

      // Data rows
      for (final r in rows) {
        sheet.appendRow(r.map((val) => TextCellValue(val)).toList());
      }

      return excel.encode()!;
    }

    test('should successfully import valid rows and create new client', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Yeni Müşteri', '09:00', '12:00', 'Yazılım', 'Örnek Proje', 'İlk not'],
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(1));
      expect(mockDB.insertedClients.length, equals(1));
      expect(mockDB.insertedClients.first.name, equals('Yeni Müşteri'));
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.clientName, equals('Yeni Müşteri'));
      expect(mockDB.insertedEntries.first.startTime, equals('09:00'));
      expect(mockDB.insertedEntries.first.endTime, equals('12:00'));
      expect(mockDB.insertedEntries.first.projectName, equals('Örnek Proje'));

      expect(mockRef.invalidatedProviders, contains(clientsProvider));
      expect(mockRef.invalidatedProviders, contains(entriesProvider));
    });

    test('should reuse existing client when client names match (case insensitive)', () async {
      final existingClient = Client(id: 'existing-id', name: 'Mevcut Müşteri', color: '#123456');
      mockDB.mockClients.add(existingClient);

      final bytes = createExcelBytes([
        ['15.03.2026', 'mevcut müşteri', '09:00', '12:00', 'Yazılım', 'Örnek Proje', 'İkinci not'],
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(1));
      expect(mockDB.insertedClients.isEmpty, isTrue); // Reused, no new client inserted
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.clientId, equals('existing-id'));
      expect(mockDB.insertedEntries.first.clientName, equals('Mevcut Müşteri'));
      expect(mockRef.invalidatedProviders, isNot(contains(clientsProvider)));
      expect(mockRef.invalidatedProviders, contains(entriesProvider));
    });

    test('should skip rows with missing or empty required fields', () async {
      final bytes = createExcelBytes([
        ['', 'Müşteri', '09:00', '12:00', 'Yazılım', 'Proje'], // missing date
        ['15.03.2026', '', '09:00', '12:00', 'Yazılım', 'Proje'], // missing client name
        ['15.03.2026', 'Müşteri', '', '12:00', 'Yazılım', 'Proje'], // missing start time
        ['15.03.2026', 'Müşteri', '09:00', '', 'Yazılım', 'Proje'], // missing end time
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(0));
      expect(mockDB.insertedClients.isEmpty, isTrue);
      expect(mockDB.insertedEntries.isEmpty, isTrue);
      expect(mockRef.invalidatedProviders, isEmpty);
    });

    test('should import row even when work type is empty (optional field)', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Müşteri', '09:00', '12:00', '', 'Proje', 'Notlar'], // empty work type — should still import
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(1));
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.workType, equals('Diğer'));
    });

    test('should import pricing details (hourly and fixed billing types)', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Müşteri A', '09:00', '12:00', 'Yazılım', 'Proje A', 'Saatlik iş', 'Saatlik', '250'],
        ['16.03.2026', 'Müşteri B', '10:00', '11:00', 'Tasarım', 'Proje B', 'Sabit iş', 'Sabit', '1500'],
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(2));
      expect(mockDB.insertedEntries.length, equals(2));

      // First entry - Hourly (250 TL/hr * 3 hrs = 750 TL)
      final hourlyEntry = mockDB.insertedEntries.first;
      expect(hourlyEntry.billingType, equals('hourly'));
      expect(hourlyEntry.hourlyRate, equals(250.0));
      expect(hourlyEntry.totalPrice, equals(750.0));
      expect(hourlyEntry.durationHours, equals(3.0));

      // Second entry - Fixed (1500 TL total price)
      final fixedEntry = mockDB.insertedEntries[1];
      expect(fixedEntry.billingType, equals('fixed'));
      expect(fixedEntry.hourlyRate, equals(0.0));
      expect(fixedEntry.totalPrice, equals(1500.0));
    });

    test('should import rows that have fewer than 6 columns (defaulting to Genel project)', () async {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Müşteri'),
        TextCellValue('Başlangıç'),
        TextCellValue('Bitiş'),
        TextCellValue('İş Türü'),
      ]);
      // Sadece 5 sütun — Proje eksik
      sheet.appendRow([
        TextCellValue('15.03.2026'),
        TextCellValue('Müşteri'),
        TextCellValue('09:00'),
        TextCellValue('12:00'),
        TextCellValue('Yazılım'),
      ]);

      final bytes = excel.encode()!;
      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(1));
      expect(mockDB.insertedClients.length, equals(1));
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.projectName, equals('Genel'));
    });

    test('should handle malformed row values gracefully and continue with other valid rows', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Hatalı Zaman', '09:00', 'invalid-time', 'Yazılım', 'Proje'], // invalid end-time -> duration 0, still imported
        ['16.03.2026', 'Düzgün Müşteri', '10:00', '11:00', 'Tasarım', 'Proje'], // valid row
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      // Both rows are imported; the malformed-time row yields a 0-duration entry
      // instead of crashing, so it no longer falls into the catch block.
      expect(count, equals(2));
      expect(mockDB.insertedClients.length, equals(2));
      expect(mockDB.insertedClients[0].name, equals('Hatalı Zaman'));
      expect(mockDB.insertedClients[1].name, equals('Düzgün Müşteri'));
      expect(mockDB.insertedEntries.length, equals(2));
      // The valid row's entry is present
      expect(mockDB.insertedEntries.any((e) => e.clientName == 'Düzgün Müşteri' && e.date == '16.03.2026'), isTrue);
      // The malformed-time row is also present but with 0 duration
      expect(mockDB.insertedEntries.any((e) => e.clientName == 'Hatalı Zaman' && e.durationHours == 0.0), isTrue);
      expect(mockRef.invalidatedProviders, contains(entriesProvider));
    });

    test('should gracefully handle database exceptions (catch block triggered) and continue', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Müşteri 1', '09:00', '10:00', 'Yazılım', 'Proje'],
        ['16.03.2026', 'Müşteri 2', '11:00', '12:00', 'Tasarım', 'Proje'],
      ]);

      // Set DB to throw during processing of the first row
      mockDB.shouldThrowOnInsertEntry = true;

      final count = await ImportService.importBytes(bytes, mockRef);

      // Both rows will fail to insert into the entry DB, but the loop continues without crashing
      expect(count, equals(0));
      expect(mockDB.insertedEntries.isEmpty, isTrue);
      expect(mockRef.invalidatedProviders, isNot(contains(entriesProvider)));
    });
  });

  group('ImportService Integration & Benchmark', () {
    late ProviderContainer container;
    late MockWidgetRefIntegration mockRef;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(LocalDBService(dbName: ':memory:')),
        ],
      );
      mockRef = MockWidgetRefIntegration(container);

      // Clear database before each test
      final db = container.read(localDBServiceProvider);
      await db.clearClients();
      await db.clearEntries();
    });

    tearDown(() {
      container.dispose();
    });

    List<int> createMockExcelBytes(int rowCount) {
      final excel = Excel.createExcel();
      final sheet = excel.tables.values.first;

      // Header
      sheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Müşteri'),
        TextCellValue('Başlangıç'),
        TextCellValue('Bitiş'),
        TextCellValue('İş Tipi'),
        TextCellValue('Proje'),
        TextCellValue('Notlar'),
      ]);

      // We will use 5 distinct client names repeated in round-robin fashion
      for (int i = 0; i < rowCount; i++) {
        final clientNum = i % 5;
        sheet.appendRow([
          TextCellValue('15.03.2026'),
          TextCellValue('Client_$clientNum'),
          TextCellValue('09:00'),
          TextCellValue('17:00'),
          TextCellValue('Yazılım'),
          TextCellValue('Project_$clientNum'),
          TextCellValue('Note $i'),
        ]);
      }

      final bytes = excel.encode();
      return bytes ?? [];
    }

    test('should import Excel rows and measure performance', () async {
      final rowCount = 50; // Use 50 rows for testing
      final bytes = createMockExcelBytes(rowCount);
      expect(bytes.isNotEmpty, isTrue);

      final stopwatch = Stopwatch()..start();
      final result = await ImportService.importBytes(bytes, mockRef);
      stopwatch.stop();

      print(
          'Benchmark - Imported $result rows in ${stopwatch.elapsedMilliseconds} ms');
      expect(result, equals(rowCount));

      // Verify that 5 clients were actually created in database
      final db = container.read(localDBServiceProvider);
      final clients = await db.getAllClients();
      expect(clients.length, equals(5));

      // Verify work entries count
      final entries = await db.getAllEntries();
      expect(entries.length, equals(rowCount));
    });
  });
}
