import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../providers/core_providers.dart';
import '../providers/entries_provider.dart';
import '../providers/clients_provider.dart';

class ImportService {
  /// Returns number of imported rows, or -1 if cancelled.
  static Future<int> pickAndImport(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return -1;

    final bytes = result.files.first.bytes;
    if (bytes == null) return -1;

    return _importBytes(bytes, ref);
  }

  static Future<int> _importBytes(List<int> bytes, WidgetRef ref) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.length <= 1) return 0; // Only header or empty

    final db = ref.read(localDBServiceProvider);
    int count = 0;

    for (final row in rows.skip(1)) {
      try {
        if (row.length < 5) continue;
        final date = _cellStr(row[0]);
        final clientName = _cellStr(row[1]);
        final startTime = _cellStr(row[2]);
        final endTime = _cellStr(row[3]);
        final workType = _cellStr(row[4]);
        final notes = row.length > 5 ? _cellStr(row[5]) : '';

        if (date.isEmpty || clientName.isEmpty || startTime.isEmpty ||
            endTime.isEmpty || workType.isEmpty) continue;

        // Find or create client
        final existingClients = await db.getAllClients();
        Client client;
        final match = existingClients.where(
          (c) => c.name.toLowerCase() == clientName.toLowerCase(),
        );
        if (match.isNotEmpty) {
          client = match.first;
        } else {
          client = Client(name: clientName, color: '#4A90D9');
          await db.insertClient(client);
          ref.invalidate(clientsProvider);
        }

        final entry = WorkEntry(
          clientId: client.id,
          clientName: client.name,
          clientColor: client.color,
          date: date,
          startTime: startTime,
          endTime: endTime,
          workType: workType,
          notes: notes,
          synced: false,
        );
        await db.insertEntry(entry);
        count++;
      } catch (_) {
        continue;
      }
    }

    if (count > 0) {
      ref.invalidate(entriesProvider);
    }
    return count;
  }

  static String _cellStr(dynamic cell) {
    if (cell == null) return '';
    if (cell is Data) {
      return cell.value?.toString().trim() ?? '';
    }
    return cell.toString().trim();
  }
}
