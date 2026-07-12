import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/client.dart';

void main() {
  test('Benchmark - Stats Screen List Lookup vs Map Lookup', () {
    // We will generate 1000 clients and look up 5000 client IDs to measure the speedup of Map-based lookup vs List-based (.firstWhere) lookup.
    final numClients = 1000;
    final numLookups = 5000;

    final clients = List.generate(
      numClients,
      (i) => Client(id: 'client_$i', name: 'Client $i', color: '#123456'),
    );

    final lookupIds = List.generate(
      numLookups,
      (i) => 'client_${i % numClients}',
    );

    // 1. Baseline: List lookup using firstWhere
    final listStopwatch = Stopwatch()..start();
    var listFoundCount = 0;
    for (final id in lookupIds) {
      final client = clients.firstWhere(
        (c) => c.id == id,
        orElse: () => Client(id: id, name: 'Bilinmeyen', color: '#9CA3AF'),
      );
      if (client.name != 'Bilinmeyen') {
        listFoundCount++;
      }
    }
    listStopwatch.stop();
    final listTime = listStopwatch.elapsedMicroseconds;

    // 2. Optimized: Map creation and map lookup
    final mapStopwatch = Stopwatch()..start();
    final clientMap = {for (var c in clients) c.id: c};
    var mapFoundCount = 0;
    for (final id in lookupIds) {
      final client = clientMap[id] ?? Client(id: id, name: 'Bilinmeyen', color: '#9CA3AF');
      if (client.name != 'Bilinmeyen') {
        mapFoundCount++;
      }
    }
    mapStopwatch.stop();
    final mapTime = mapStopwatch.elapsedMicroseconds;

    expect(listFoundCount, equals(numLookups));
    expect(mapFoundCount, equals(numLookups));

    print('Benchmark (1000 clients, 5000 lookups):');
    print('  List Lookup (.firstWhere): ${listTime / 1000.0} ms');
    print('  Map Lookup (Map + lookup): ${mapTime / 1000.0} ms');
    if (mapTime > 0) {
      final speedup = listTime / mapTime;
      print('  Speedup: ${speedup.toStringAsFixed(2)}x');
    }
  });
}
