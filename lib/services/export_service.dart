import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../models/client.dart';

class ExportService {
  static Future<void> exportToCSV(List<WorkEntry> entries, List<Client> clients) async {
    List<List<dynamic>> rows = [];
    
    rows.add([
      'Tarih',
      'MüşteriAdı',
      'Saat',
      'Notlar'
    ]);

    for (var entry in entries) {
      final client = clients.firstWhere(
        (c) => c.id == entry.clientId,
        orElse: () => Client(name: 'Bilinmeyen', color: '#000000'),
      );
      
      rows.add([
        entry.date,
        client.name,
        entry.durationHours.toStringAsFixed(2),
        entry.notes,
      ]);
    }

    String csvString = const CsvEncoder().convert(rows);
    Uint8List bytes = Uint8List.fromList(csvString.codeUnits);
    
    String fileName = 'WorkLog_Records_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
    
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.csv,
    );
  }
}
