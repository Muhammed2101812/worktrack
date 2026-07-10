import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/providers/clients_provider.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/entries_provider.dart';
import 'package:worklog/services/import_service.dart';
import 'package:worklog/services/local_db_service.dart';

class MockLocalDBService implements LocalDBService {
  final List<Client> mockClients = [];
  final List<WorkEntry> insertedEntries = [];
  final List<Client> insertedClients = [];
  bool shouldThrowOnClients = false;
  bool shouldThrowOnInsertEntry = false;

  @override
  Future<List<Client>> getAllClients() async {
    if (shouldThrowOnClients) {
      throw Exception('Database Error getting clients');
    }
    return mockClients;
  }

  @override
  Future<void> insertClient(Client client) async {
    if (shouldThrowOnClients) {
      throw Exception('Database Error inserting client');
    }
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWidgetRef implements WidgetRef {
  final Map<ProviderListenable<dynamic>, dynamic> _providerValues;
  final List<ProviderOrFamily> invalidatedProviders = [];

  MockWidgetRef(this._providerValues);

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_providerValues.containsKey(provider)) {
      return _providerValues[provider] as T;
    }
    throw UnimplementedError('Provider not mocked');
  }

  @override
  void invalidate(ProviderOrFamily provider) {
    invalidatedProviders.add(provider);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ImportService Tests', () {
    late MockLocalDBService mockDB;
    late MockWidgetRef mockRef;

    setUp(() {
      mockDB = MockLocalDBService();
      mockRef = MockWidgetRef({
        localDBServiceProvider: mockDB,
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
        TextCellValue('Notlar'),
      ]);

      // Data rows
      for (final r in rows) {
        sheet.appendRow(r.map((val) => TextCellValue(val)).toList());
      }

      return excel.encode()!;
    }

    test('should successfully import valid rows and create new client', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Yeni Müşteri', '09:00', '12:00', 'Yazılım', 'İlk not'],
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(1));
      expect(mockDB.insertedClients.length, equals(1));
      expect(mockDB.insertedClients.first.name, equals('Yeni Müşteri'));
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.clientName, equals('Yeni Müşteri'));
      expect(mockDB.insertedEntries.first.startTime, equals('09:00'));
      expect(mockDB.insertedEntries.first.endTime, equals('12:00'));

      expect(mockRef.invalidatedProviders, contains(clientsProvider));
      expect(mockRef.invalidatedProviders, contains(entriesProvider));
    });

    test('should reuse existing client when client names match (case insensitive)', () async {
      final existingClient = Client(id: 'existing-id', name: 'Mevcut Müşteri', color: '#123456');
      mockDB.mockClients.add(existingClient);

      final bytes = createExcelBytes([
        ['15.03.2026', 'mevcut müşteri', '09:00', '12:00', 'Yazılım', 'İkinci not'],
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
        ['', 'Müşteri', '09:00', '12:00', 'Yazılım'], // missing date
        ['15.03.2026', '', '09:00', '12:00', 'Yazılım'], // missing client name
        ['15.03.2026', 'Müşteri', '', '12:00', 'Yazılım'], // missing start time
        ['15.03.2026', 'Müşteri', '09:00', '', 'Yazılım'], // missing end time
        ['15.03.2026', 'Müşteri', '09:00', '12:00', ''], // missing work type
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(0));
      expect(mockDB.insertedClients.isEmpty, isTrue);
      expect(mockDB.insertedEntries.isEmpty, isTrue);
      expect(mockRef.invalidatedProviders, isEmpty);
    });

    test('should skip rows that have fewer than 5 columns', () async {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Müşteri'),
        TextCellValue('Başlangıç'),
        TextCellValue('Bitiş'),
        TextCellValue('İş Türü'),
      ]);
      // Appending only 4 columns
      sheet.appendRow([
        TextCellValue('15.03.2026'),
        TextCellValue('Müşteri'),
        TextCellValue('09:00'),
        TextCellValue('12:00'),
      ]);

      final bytes = excel.encode()!;
      final count = await ImportService.importBytes(bytes, mockRef);

      expect(count, equals(0));
      expect(mockDB.insertedClients.isEmpty, isTrue);
      expect(mockDB.insertedEntries.isEmpty, isTrue);
    });

    test('should handle malformed row values (catch block triggered) and continue with other valid rows', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Hatalı Zaman', '09:00', 'invalid-time', 'Yazılım'], // triggers FormatException in duration calc
        ['16.03.2026', 'Düzgün Müşteri', '10:00', '11:00', 'Tasarım'], // valid row
      ]);

      final count = await ImportService.importBytes(bytes, mockRef);

      // The first malformed row triggers the catch block, but the second row should be successfully parsed
      expect(count, equals(1));
      expect(mockDB.insertedClients.length, equals(2));
      expect(mockDB.insertedClients[0].name, equals('Hatalı Zaman'));
      expect(mockDB.insertedClients[1].name, equals('Düzgün Müşteri'));
      expect(mockDB.insertedEntries.length, equals(1));
      expect(mockDB.insertedEntries.first.clientName, equals('Düzgün Müşteri'));
      expect(mockDB.insertedEntries.first.date, equals('16.03.2026'));
      expect(mockRef.invalidatedProviders, contains(entriesProvider));
    });

    test('should gracefully handle database exceptions (catch block triggered) and continue', () async {
      final bytes = createExcelBytes([
        ['15.03.2026', 'Müşteri 1', '09:00', '10:00', 'Yazılım'],
        ['16.03.2026', 'Müşteri 2', '11:00', '12:00', 'Tasarım'],
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
}
