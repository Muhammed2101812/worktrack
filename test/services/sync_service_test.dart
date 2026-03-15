import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/services/sync_service.dart';

void main() {
  group('SyncService Tests', () {
    test('should have SyncService class', () {
      expect(() => SyncService, returnsNormally);
    });
  });
}
