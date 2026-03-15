import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/client.dart';

void main() {
  group('Client Model Tests', () {
    test('should create Client with auto-generated id', () {
      final client = Client(
        name: 'Test Client',
        color: '#4A90D9',
      );

      expect(client.id, isNotNull);
      expect(client.name, 'Test Client');
      expect(client.color, '#4A90D9');
    });

    test('should create Client with custom id', () {
      final client = Client(
        id: 'custom-id',
        name: 'Test Client',
        color: '#4A90D9',
      );

      expect(client.id, 'custom-id');
    });

    test('should copy with updated values', () {
      final client = Client(
        name: 'Test Client',
        color: '#4A90D9',
      );

      final updated = client.copyWith(
        name: 'Updated Client',
        color: '#FF6B6B',
      );

      expect(updated.id, client.id);
      expect(updated.name, 'Updated Client');
      expect(updated.color, '#FF6B6B');
    });

    test('should copy with partial updates', () {
      final client = Client(
        name: 'Test Client',
        color: '#4A90D9',
      );

      final updated = client.copyWith(name: 'New Name');

      expect(updated.id, client.id);
      expect(updated.name, 'New Name');
      expect(updated.color, client.color);
    });

    test('should convert to map correctly', () {
      final client = Client(
        id: 'test-id',
        name: 'Test Client',
        color: '#4A90D9',
      );

      final map = client.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Client');
      expect(map['color'], '#4A90D9');
    });

    test('should create Client from map', () {
      final map = {
        'id': 'test-id',
        'name': 'Test Client',
        'color': '#4A90D9',
      };

      final client = Client.fromMap(map);

      expect(client.id, 'test-id');
      expect(client.name, 'Test Client');
      expect(client.color, '#4A90D9');
    });
  });
}
