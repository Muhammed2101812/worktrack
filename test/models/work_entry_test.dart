import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/work_entry.dart';

void main() {
  group('WorkEntry Model Tests', () {
    test('should create WorkEntry with auto-generated id', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
      );

      expect(entry.id, isNotNull);
      expect(entry.clientId, 'client1');
      expect(entry.clientName, 'Test Client');
      expect(entry.clientColor, '#4A90D9');
      expect(entry.date, '15.03.2026');
      expect(entry.startTime, '09:00');
      expect(entry.endTime, '12:00');
      expect(entry.workType, 'Yazılım');
      expect(entry.notes, '');
      expect(entry.synced, false);
    });

    test('should create WorkEntry with custom id', () {
      final entry = WorkEntry(
        id: 'custom-id',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
      );

      expect(entry.id, 'custom-id');
    });

    test('should calculate duration correctly', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:30',
        workType: 'Yazılım',
      );

      expect(entry.durationHours, 3.5);
    });

    test('should return 0 for invalid time range', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '12:00',
        endTime: '09:00',
        workType: 'Yazılım',
      );

      expect(entry.durationHours, 0.0);
    });

    test('should calculate duration for exact hours', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '17:00',
        workType: 'Yazılım',
      );

      expect(entry.durationHours, 8.0);
    });

    test('should copy with updated values', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
      );

      final updated = entry.copyWith(
        notes: 'Updated notes',
        synced: true,
      );

      expect(updated.id, entry.id);
      expect(updated.notes, 'Updated notes');
      expect(updated.synced, true);
      expect(updated.clientName, entry.clientName);
    });

    test('should convert to map correctly', () {
      final entry = WorkEntry(
        id: 'test-id',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
        notes: 'Test notes',
      );

      final map = entry.toMap();

      expect(map['id'], 'test-id');
      expect(map['client_id'], 'client1');
      expect(map['client_name'], 'Test Client');
      expect(map['client_color'], '#4A90D9');
      expect(map['date'], '15.03.2026');
      expect(map['start_time'], '09:00');
      expect(map['end_time'], '12:00');
      expect(map['duration_hours'], 3.0);
      expect(map['work_type'], 'Yazılım');
      expect(map['notes'], 'Test notes');
    });

    test('should convert to local map with synced field', () {
      final entry = WorkEntry(
        id: 'test-id',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
        synced: true,
      );

      final map = entry.toLocalMap();

      expect(map['synced'], 1);
    });

    test('should create WorkEntry from map', () {
      final map = {
        'id': 'test-id',
        'client_id': 'client1',
        'client_name': 'Test Client',
        'client_color': '#4A90D9',
        'date': '15.03.2026',
        'start_time': '09:00',
        'end_time': '12:00',
        'work_type': 'Yazılım',
        'notes': 'Test notes',
        'synced': 1,
      };

      final entry = WorkEntry.fromMap(map);

      expect(entry.id, 'test-id');
      expect(entry.clientId, 'client1');
      expect(entry.clientName, 'Test Client');
      expect(entry.clientColor, '#4A90D9');
      expect(entry.date, '15.03.2026');
      expect(entry.startTime, '09:00');
      expect(entry.endTime, '12:00');
      expect(entry.workType, 'Yazılım');
      expect(entry.notes, 'Test notes');
      expect(entry.synced, true);
    });

    test('should create WorkEntry from map with default values', () {
      final map = {
        'id': 'test-id',
        'client_id': 'client1',
        'date': '15.03.2026',
        'start_time': '09:00',
        'end_time': '12:00',
        'work_type': 'Yazılım',
      };

      final entry = WorkEntry.fromMap(map);

      expect(entry.clientName, '');
      expect(entry.clientColor, '#4A90D9');
      expect(entry.notes, '');
      expect(entry.synced, false);
    });

    test('should parse synced as boolean', () {
      final mapWithBool = {
        'id': 'test-id',
        'client_id': 'client1',
        'client_name': 'Test Client',
        'client_color': '#4A90D9',
        'date': '15.03.2026',
        'start_time': '09:00',
        'end_time': '12:00',
        'work_type': 'Yazılım',
        'synced': true,
      };

      final entry = WorkEntry.fromMap(mapWithBool);
      expect(entry.synced, true);
    });
  });
}
