import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import '../models/work_entry.dart';
import '../models/client.dart';

class ExportService {
  static Future<void> exportToExcel(
      List<WorkEntry> entries, List<Client> clients) async {
    final bytes = buildExcelBytes(entries, clients);
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
    final bytes = buildExcelBytes(sample, sampleClients, isSample: true);
    await FileSaver.instance.saveFile(
      name: 'WorkLog_Ornek',
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  @visibleForTesting
  static Uint8List buildExcelBytes(
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
      'Proje',
      'Notlar',
      'Ücret Tipi',
      'Ücret',
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
        TextCellValue('Kartvizit Tasarımı'),
        TextCellValue('Örnek not'),
        TextCellValue('Saatlik'),
        TextCellValue('150'),
      ]);
    } else {
      final clientMap = {for (final client in clients) client.id: client};
      for (final entry in entries) {
        final client = clientMap[entry.clientId] ??
              Client(id: entry.clientId, name: 'Bilinmeyen', color: '#000000');
        sheet.appendRow([
          TextCellValue(entry.date),
          TextCellValue(client.name),
          TextCellValue(entry.startTime),
          TextCellValue(entry.endTime),
          TextCellValue(entry.workType),
          TextCellValue(entry.projectName ?? ''),
          TextCellValue(entry.notes),
          TextCellValue(entry.billingType == 'fixed' ? 'Sabit' : 'Saatlik'),
          TextCellValue(entry.billingType == 'fixed'
              ? entry.totalPrice.toStringAsFixed(1)
              : entry.hourlyRate.toStringAsFixed(1)),
        ]);
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }
}
