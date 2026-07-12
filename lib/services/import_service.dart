import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
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

    return importBytes(bytes, ref);
  }

  @visibleForTesting
  static Future<int> importBytes(List<int> bytes, WidgetRef ref) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.length <= 1) return 0; // Only header or empty

    final db = ref.read(localDBServiceProvider);
    int count = 0;

    // Fetch existing clients once before the loop to prevent N+1 DB queries
    final existingClients = await db.getAllClients();
    final Map<String, Client> clientMap = {
      for (final client in existingClients) client.name.toLowerCase(): client,
    };

    for (final row in rows.skip(1)) {
      try {
        if (row.length < 5) continue;
        final date = _cellStr(row[0]);
        final clientName = _cellStr(row[1]);
        final startTime = _cellStr(row[2]);
        final endTime = _cellStr(row[3]);
        final workType = _cellStr(row[4]);
        final notes = row.length > 5 ? _cellStr(row[5]) : '';

        if (date.isEmpty ||
            clientName.isEmpty ||
            startTime.isEmpty ||
            endTime.isEmpty ||
            workType.isEmpty) continue;

        // Find or create client using local Map
        final lowercaseClientName = clientName.toLowerCase();
        Client client;
        if (clientMap.containsKey(lowercaseClientName)) {
          client = clientMap[lowercaseClientName]!;
        } else {
          client = Client(name: clientName, color: '#4A90D9');
          await db.insertClient(client);
          ref.invalidate(clientsProvider);
          clientMap[lowercaseClientName] = client;
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
      await ref.read(backupServiceProvider).triggerBackup();
    }
    return count;
  }

  static String _cellStr(Data? cell) {
    if (cell == null) return '';
    return cell.value?.toString().trim() ?? '';
  }
}
