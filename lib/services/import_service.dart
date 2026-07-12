import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_entry.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../providers/core_providers.dart';
import '../providers/entries_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/projects_provider.dart';
import '../core/utils.dart';

class ImportService {
  /// Returns number of imported rows, or -1 if cancelled.
  static Future<int> pickAndImport(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return -1;

    final file = result.files.first;
    List<int>? bytes = file.bytes;
    // Web'de bazen bytes null dönebilir; path üzerinden dosya oku (mobil/masaüstü)
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return -1;

    return importBytes(bytes, ref);
  }

  @visibleForTesting
  static Future<int> importBytes(List<int> bytes, WidgetRef ref) async {
    // Önce standart excel paketi ile decode etmeyi dene
    List<List<String>> grid;
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return 0;
      }
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.length <= 1) {
        return 0;
      }
      grid = rows
          .map((row) => row.map((cell) {
                if (cell == null) return '';
                final v = cell.value;
                return v?.toString().trim() ?? '';
              }).toList())
          .toList();
    } catch (e, s) {
      debugPrint('ImportService: Standard excel parser failed: $e\n$s');
      // excel paketi dosyayı çözemedi (örn. inlineStr + boş hücreler).
      // Raw XML fallback parser ile deneyelim.
      grid = _parseXlsxRaw(bytes);
      if (grid.length <= 1) return 0;
    }

    final db = ref.read(localDBServiceProvider);
    int count = 0;

    // Fetch existing clients once before the loop to prevent N+1 DB queries
    final existingClients = await db.getAllClients();
    final Map<String, Client> clientMap = {
      for (final client in existingClients) client.name.toLowerCase(): client,
    };
    // Fetch existing projects once before the loop (clientId|name key)
    final existingProjects = await db.getAllProjects();
    final Map<String, Project> projectMap = {
      for (final p in existingProjects) '${p.clientId}|${p.name.toLowerCase()}': p,
    };

    for (final row in grid.skip(1)) {
      try {
        if (row.length < 5) {
          continue;
        }
        final date = row[0];
        final clientName = row[1];
        final startTime = row[2];
        final endTime = row[3];
        final rawWorkType = row[4];
        final workType = rawWorkType.isEmpty ? 'Diğer' : rawWorkType;

        final rawProjectName = row.length > 5 ? row[5] : '';
        final projectName = rawProjectName.isEmpty ? 'Genel' : rawProjectName;

        final notes = row.length > 6 ? row[6] : '';

        // Tarih, müşteri ve saatler zorunlu; iş türü ve proje varsayılan değer alabilir
        if (date.isEmpty ||
            clientName.isEmpty ||
            startTime.isEmpty ||
            endTime.isEmpty) {
          continue;
        }

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

        // Varsa proje bul/oluştur
        String? projectId;
        String? projectResolvedName;
        if (projectName.isNotEmpty) {
          final key = '${client.id}|${projectName.toLowerCase()}';
          if (projectMap.containsKey(key)) {
            final existing = projectMap[key]!;
            projectId = existing.id;
            projectResolvedName = existing.name;
          } else {
            final project = Project(clientId: client.id, name: projectName);
            await db.insertProject(project);
            ref.invalidate(projectsProvider);
            projectMap[key] = project;
            projectId = project.id;
            projectResolvedName = project.name;
          }
        }

        String billingType = 'hourly';
        if (row.length > 7 && row[7].isNotEmpty) {
          final type = row[7].toLowerCase();
          if (type.contains('sabit') || type == 'fixed') {
            billingType = 'fixed';
          }
        }

        double hourlyRate = 0.0;
        double? totalPrice;
        if (row.length > 8 && row[8].isNotEmpty) {
          final rateVal = double.tryParse(row[8].replaceAll(',', '.')) ?? 0.0;
          if (billingType == 'hourly') {
            hourlyRate = rateVal;
          } else {
            totalPrice = rateVal;
          }
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
          projectId: projectId,
          projectName: projectResolvedName,
          synced: false,
          billingType: billingType,
          hourlyRate: hourlyRate,
          totalPrice: totalPrice,
        );
        await db.insertEntry(entry);
        count++;
      } catch (e, s) {
        debugPrint('ImportService: Exception importing row: $e\n$s');
        continue;
      }
    }

    if (count > 0) {
      ref.invalidate(entriesProvider);
      ref.invalidate(projectsProvider);
      await ref.read(backupServiceProvider).triggerBackup();
    }
    return count;
  }

  /// Excel paketinin çözemediği xlsx dosyaları için raw XML fallback parser.
  /// Özellikle Google Sheets gibi araçların ürettiği inlineStr + boş hücreli
  /// dosyaları çözmek için kullanılır.
  static List<List<String>> _parseXlsxRaw(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      // sheet1.xml (veya ilk sheet) içeriğini bul
      String? sheetXml;
      for (final file in archive) {
        if (file.name.contains('worksheets/sheet1.xml') ||
            file.name.contains('worksheets/sheet')) {
          sheetXml = utf8.decode(file.content as List<int>);
          break;
        }
      }
      if (sheetXml == null) return [];

      // sharedStrings.xml varsa yükle (bu dosyada yok ama genel destek için)
      final sharedStrings = <String>[];
      for (final file in archive) {
        if (file.name.contains('sharedStrings.xml')) {
          final ssXml = utf8.decode(file.content as List<int>);
          final siRegex = RegExp(r'<si>(.*?)</si>', dotAll: true);
          final tRegex = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true);
          for (final siMatch in siRegex.allMatches(ssXml)) {
            final tMatch = tRegex.firstMatch(siMatch.group(1)!);
            sharedStrings.add(_decodeXmlEntities(tMatch?.group(1) ?? ''));
          }
          break;
        }
      }

      // Satırları parse et
      final grid = <List<String>>[];
      final rowRegex = RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true);
      final cellRegex = RegExp(r'<c\b[^>]*>(.*?)</c>', dotAll: true);
      final refRegex = RegExp(r'r="([A-Z]+)(\d+)"');
      final typeRegex = RegExp(r't="([^"]*)"');
      final valueRegex = RegExp(r'<v>(.*?)</v>', dotAll: true);
      final inlineRegex = RegExp(r'<is><t[^>]*>(.*?)</t></is>', dotAll: true);

      for (final rowMatch in rowRegex.allMatches(sheetXml)) {
        final rowContent = rowMatch.group(1)!;
        // Hücreleri kolon harfine göre sırala
        final cells = <int, String>{};
        for (final cellMatch in cellRegex.allMatches(rowContent)) {
          final cellFull = cellMatch.group(0)!;
          final cellContent = cellMatch.group(1) ?? '';
          final refMatch = refRegex.firstMatch(cellFull);
          if (refMatch == null) continue;
          final colLetter = refMatch.group(1)!;
          final colIdx = _colLetterToIndex(colLetter);
          final typeMatch = typeRegex.firstMatch(cellFull);
          final type = typeMatch?.group(1);

          String value = '';
          if (type == 'inlineStr') {
            final m = inlineRegex.firstMatch(cellContent);
            value = _decodeXmlEntities(m?.group(1) ?? '');
          } else if (type == 's') {
            final m = valueRegex.firstMatch(cellContent);
            final idx = int.tryParse(m?.group(1) ?? '');
            value = (idx != null && idx < sharedStrings.length)
                ? sharedStrings[idx]
                : '';
          } else if (type == 'str') {
            final m = valueRegex.firstMatch(cellContent);
            value = _decodeXmlEntities(m?.group(1) ?? '');
          } else {
            // sayısal veya boş hücre
            final m = valueRegex.firstMatch(cellContent);
            value = m?.group(1)?.trim() ?? '';
          }
          cells[colIdx] = value.trim();
        }
        if (cells.isEmpty) continue;
        // En büyük kolon indexine kadar dizi oluştur
        final maxCol = cells.keys.reduce((a, b) => a > b ? a : b);
        final rowList = List<String>.filled(maxCol + 1, '');
        cells.forEach((k, v) => rowList[k] = v);
        grid.add(rowList);
      }
      return grid;
    } catch (_) {
      return [];
    }
  }

  static int _colLetterToIndex(String letters) {
    int result = 0;
    for (final char in letters.codeUnits) {
      result = result * 26 + (char - 0x41); // 'A' = 0
    }
    return result;
  }

  static String _decodeXmlEntities(String s) {
    return decodeHtmlEntities(s);
  }
}
