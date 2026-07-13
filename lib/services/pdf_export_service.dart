import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show visibleForTesting, debugPrint;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/client.dart';
import '../models/work_entry.dart';

/// Generates a monthly work/earnings report as a PDF document.
///
/// The report summarises hours and earnings per client (and project) for the
/// given month, including the average hourly rate. Mirrors the on-screen
/// stats view so the exported file matches what the user sees.
class PdfExportService {
  /// Builds and saves a monthly report PDF. Returns true on success.
  static Future<bool> exportMonthlyReport({
    required List<WorkEntry> entries,
    required List<Client> clients,
    required DateTime month,
    String currency = 'TL',
  }) async {
    final bytes = await buildReportBytes(entries: entries, clients: clients, month: month, currency: currency);
    final monthLabel = DateFormat('MMMM_yyyy', 'tr').format(month);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'WorkTrack_Rapor_${monthLabel}_$timestamp.pdf';
    
    try {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'PDF Raporunu Kaydet',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (path != null) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          final file = File(path);
          await file.writeAsBytes(bytes);
        }
        return true;
      }
    } catch (e) {
      debugPrint('PDF export error: $e');
    }
    return false;
  }

  @visibleForTesting
  static Future<Uint8List> buildReportBytes({
    required List<WorkEntry> entries,
    required List<Client> clients,
    required DateTime month,
    String currency = 'TL',
  }) async {
    // Load Roboto TTF (bundled in assets) so Turkish characters (ç ğ ı ö ş ü)
    // render correctly. The pdf package's default Type1 font lacks them.
    final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    final monthTitle = DateFormat('MMMM yyyy', 'tr').format(month);

    // Filter entries to the selected month.
    final monthEntries = entries.where((e) {
      try {
        final d = DateFormat('dd.MM.yyyy').parse(e.date);
        return d.year == month.year && d.month == month.month;
      } catch (_) {
        return false;
      }
    }).toList();

    final totalHours =
        monthEntries.fold<double>(0, (s, e) => s + e.durationHours);
    final totalEarnings =
        monthEntries.fold<double>(0, (s, e) => s + e.effectivePrice);

    // Per-client aggregation.
    final clientData = <String, _ClientAgg>{};
    for (final e in monthEntries) {
      final agg = clientData.putIfAbsent(e.clientId, () => _ClientAgg(name: e.clientName));
      agg.hours += e.durationHours;
      agg.earnings += e.effectivePrice;
    }
    final clientRows = clientData.values.toList()
      ..sort((a, b) => b.earnings.compareTo(a.earnings));

    // Per-project aggregation.
    final projectData = <String, _ClientAgg>{};
    for (final e in monthEntries) {
      final pName = e.projectName;
      if (pName == null || pName.isEmpty) continue;
      final agg = projectData.putIfAbsent(e.projectId!, () => _ClientAgg(name: pName));
      agg.hours += e.durationHours;
      agg.earnings += e.effectivePrice;
    }
    final projectRows = projectData.values.toList()
      ..sort((a, b) => b.earnings.compareTo(a.earnings));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('WorkTrack Aylık Rapor',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(monthTitle,
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          // Summary box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryBlock('TOPLAM SAAT', '${totalHours.toStringAsFixed(1)} sa'),
                _summaryBlock('TOPLAM GELİR', '${totalEarnings.toStringAsFixed(0)} $currency'),
                _summaryBlock('KAYIT SAYISI', '${monthEntries.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Client table
          pw.Text('MÜŞTERİ BAZLI ÖZET',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildTable(
            headers: ['Müşteri', 'Saat', 'Gelir ($currency)', 'Ort. Saatlik ($currency)'],
            rows: clientRows
                .map((c) => [
                      c.name,
                      c.hours.toStringAsFixed(1),
                      c.earnings.toStringAsFixed(0),
                      c.hours > 0
                          ? (c.earnings / c.hours).toStringAsFixed(0)
                          : '-',
                    ])
                .toList(),
          ),
          if (projectRows.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('PROJE BAZLI ÖZET',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildTable(
              headers: ['Proje', 'Saat', 'Gelir ($currency)'],
              rows: projectRows
                  .map((p) => [
                        p.name,
                        p.hours.toStringAsFixed(1),
                        p.earnings.toStringAsFixed(0),
                      ])
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 32),
          pw.Center(
            child: pw.Text(
              'Bu rapor WorkTrack ile oluşturulmuştur • ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 16)),
      ],
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }
}

class _ClientAgg {
  final String name;
  double hours = 0;
  double earnings = 0;
  _ClientAgg({required this.name});
}
