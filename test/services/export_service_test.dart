import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:worklog/services/export_service.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/models/client.dart';

void main() {
  group('ExportService Tests', () {
    String getCellValue(Data? cell) {
      if (cell == null || cell.value == null) return '';
      return cell.value.toString();
    }

    test('buildExcelBytes - should generate excel with empty list and headers', () {
      final bytes = ExportService.buildExcelBytes([], []);
      final excel = Excel.decodeBytes(bytes);

      // Verify sheet exists
      expect(excel.tables.containsKey('İş Kayıtları'), isTrue);
      final sheet = excel.tables['İş Kayıtları']!;

      // Should have exactly 1 row (the header)
      expect(sheet.rows.length, equals(1));

      final headers = sheet.rows[0].map(getCellValue).toList();
      expect(headers, equals([
        'Tarih',
        'Müşteri',
        'Başlangıç',
        'Bitiş',
        'İş Türü',
        'Notlar',
      ]));
    });

    test('buildExcelBytes - should generate sample sheet when isSample is true', () {
      final bytes = ExportService.buildExcelBytes([], [], isSample: true);
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables['İş Kayıtları']!;
      expect(sheet.rows.length, equals(2)); // header + 1 sample row

      final sampleRow = sheet.rows[1].map(getCellValue).toList();
      expect(sampleRow, equals([
        '15.03.2026',
        'Örnek Müşteri',
        '09:00',
        '17:00',
        'Arayüz tasarımı',
        'Örnek not',
      ]));
    });

    test('buildExcelBytes - should map work entries with clients correctly', () {
      final clients = [
        Client(id: 'client-1', name: 'Acme Corp', color: '#112233'),
        Client(id: 'client-2', name: 'Beta LLC', color: '#445566'),
      ];

      final entries = [
        WorkEntry(
          id: 'entry-1',
          clientId: 'client-1',
          clientName: 'Acme Corp',
          clientColor: '#112233',
          date: '10.10.2025',
          startTime: '08:00',
          endTime: '12:00',
          workType: 'Software Development',
          notes: 'Writing unit tests',
        ),
        WorkEntry(
          id: 'entry-2',
          clientId: 'client-2',
          clientName: 'Beta LLC',
          clientColor: '#445566',
          date: '11.10.2025',
          startTime: '13:00',
          endTime: '17:00',
          workType: 'Meeting',
          notes: 'Sprint planning',
        ),
      ];

      final bytes = ExportService.buildExcelBytes(entries, clients);
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables['İş Kayıtları']!;
      expect(sheet.rows.length, equals(3)); // header + 2 entries

      final row1 = sheet.rows[1].map(getCellValue).toList();
      expect(row1, equals([
        '10.10.2025',
        'Acme Corp',
        '08:00',
        '12:00',
        'Software Development',
        'Writing unit tests',
      ]));

      final row2 = sheet.rows[2].map(getCellValue).toList();
      expect(row2, equals([
        '11.10.2025',
        'Beta LLC',
        '13:00',
        '17:00',
        'Meeting',
        'Sprint planning',
      ]));
    });

    test('buildExcelBytes - edge case: missing client fallback to Bilinmeyen', () {
      final clients = [
        Client(id: 'client-1', name: 'Acme Corp', color: '#112233'),
      ];

      final entries = [
        WorkEntry(
          id: 'entry-1',
          clientId: 'unknown-client-id',
          clientName: 'Some Client',
          clientColor: '#123456',
          date: '12.10.2025',
          startTime: '10:00',
          endTime: '11:00',
          workType: 'Support',
          notes: 'Solving bugs',
        ),
      ];

      final bytes = ExportService.buildExcelBytes(entries, clients);
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables['İş Kayıtları']!;
      expect(sheet.rows.length, equals(2)); // header + 1 entry

      final row1 = sheet.rows[1].map(getCellValue).toList();
      expect(row1, equals([
        '12.10.2025',
        'Bilinmeyen', // verified fallback name
        '10:00',
        '11:00',
        'Support',
        'Solving bugs',
      ]));
    });

    test('buildExcelBytes performance benchmark', () {
      final clients = List.generate(1000, (i) => Client(id: 'client-$i', name: 'Client $i', color: '#112233'));
      final entries = List.generate(5000, (i) {
        final clientId = 'client-${i % 1000}';
        return WorkEntry(
          id: 'entry-$i',
          clientId: clientId,
          clientName: 'Client ${i % 1000}',
          clientColor: '#112233',
          date: '10.10.2025',
          startTime: '08:00',
          endTime: '12:00',
          workType: 'Software Development',
          notes: 'Writing unit tests',
        );
      });

      final stopwatch = Stopwatch()..start();
      final bytes = ExportService.buildExcelBytes(entries, clients);
      stopwatch.stop();

      print('Export benchmark: built Excel bytes for ${entries.length} entries and ${clients.length} clients in ${stopwatch.elapsedMilliseconds} ms');
      expect(bytes, isNotEmpty);
    });
  });
}
