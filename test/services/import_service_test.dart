import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:excel/excel.dart';
import 'package:worklog/services/import_service.dart';
import 'package:worklog/providers/core_providers.dart';

class MockWidgetRef implements WidgetRef {
  final ProviderContainer container;
  MockWidgetRef(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ImportService Tests & Benchmark', () {
    late ProviderContainer container;
    late MockWidgetRef mockRef;

    setUp(() async {
      container = ProviderContainer();
      mockRef = MockWidgetRef(container);

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
