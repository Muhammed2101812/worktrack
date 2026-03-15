import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../models/client.dart';

class ExportService {
  static Future<void> exportToExcel(
      List<WorkEntry> entries, List<Client> clients) async {
    final bytes = _buildExcelBytes(entries, clients);
    final fileName =
        'WorkLog_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<void> generateSampleExcel() async {
    final sample = <WorkEntry>[];
    final sampleClients = <Client>[];
    final bytes = _buildExcelBytes(sample, sampleClients, isSample: true);
    await FileSaver.instance.saveFile(
      name: 'WorkLog_Ornek',
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Uint8List _buildExcelBytes(
    List<WorkEntry> entries,
    List<Client> clients, {
    bool isSample = false,
  }) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'İş Kayıtları');
    final sheet = excel['İş Kayıtları'];

    // Header row
    final headers = [
      'Tarih',
      'Müşteri',
      'Başlangıç',
      'Bitiş',
      'İş Türü',
      'Notlar',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    if (isSample) {
      // Add one sample row
      sheet.appendRow([
        TextCellValue('15.03.2026'),
        TextCellValue('Örnek Müşteri'),
        TextCellValue('09:00'),
        TextCellValue('17:00'),
        TextCellValue('Arayüz tasarımı'),
        TextCellValue('Örnek not'),
      ]);
    } else {
      for (final entry in entries) {
        final client = clients.firstWhere(
          (c) => c.id == entry.clientId,
          orElse: () =>
              Client(id: entry.clientId, name: 'Bilinmeyen', color: '#000000'),
        );
        sheet.appendRow([
          TextCellValue(entry.date),
          TextCellValue(client.name),
          TextCellValue(entry.startTime),
          TextCellValue(entry.endTime),
          TextCellValue(entry.workType),
          TextCellValue(entry.notes),
        ]);
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }
}
