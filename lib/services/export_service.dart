import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/work_entry.dart';
import '../models/client.dart';

class ExportService {
  static Future<void> exportToExcel(
      List<WorkEntry> entries, List<Client> clients) async {
    final bytes = buildExcelBytes(entries, clients);
    final fileName =
        'WorkLog_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    try {
      await Share.shareXFiles([XFile(file.path)], subject: 'WorkLog Excel');
    } catch (e) {
      // Ignore or log error
    }
  }

  static Future<void> generateSampleExcel() async {
    final sample = <WorkEntry>[];
    final sampleClients = <Client>[];
    final bytes = buildExcelBytes(sample, sampleClients, isSample: true);
    final fileName = 'WorkLog_Ornek.xlsx';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    try {
      await Share.shareXFiles([XFile(file.path)], subject: 'WorkLog Örnek Excel');
    } catch (e) {
      // Ignore or log error
    }
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
      // Add sample rows for the work-entries sheet.
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
      sheet.appendRow([
        TextCellValue('20.03.2026'),
        TextCellValue('Örnek Müşteri'),
        TextCellValue('10:00'),
        TextCellValue('14:00'),
        TextCellValue('Yazılım'),
        TextCellValue('Web Sitesi'),
        TextCellValue('Sabit ücretli iş'),
        TextCellValue('Sabit'),
        TextCellValue('5000'),
      ]);

      // Second sheet: sample payments (so users know the payment format too).
      final paymentsSheet = excel['Ödemeler'];
      paymentsSheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Müşteri'),
        TextCellValue('Tutar'),
        TextCellValue('Not'),
      ]);
      paymentsSheet.appendRow([
        TextCellValue('16.03.2026'),
        TextCellValue('Örnek Müşteri'),
        TextCellValue('1500'),
        TextCellValue('Peşinat'),
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
