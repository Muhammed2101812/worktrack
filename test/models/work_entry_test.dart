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

    test('should calculate duration for overnight wrap-around shift', () {
      final entry = WorkEntry(
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '12:00',
        endTime: '09:00',
        workType: 'Yazılım',
      );

      expect(entry.durationHours, 21.0);
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

    group('effectivePrice', () {
      test('hourly entry uses durationHours * hourlyRate', () {
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '17:00', // 8 hours
          workType: 'Yazılım',
          billingType: 'hourly',
          hourlyRate: 150.0,
        );
        // 8h * 150 = 1200
        expect(entry.effectivePrice, 1200.0);
      });

      test('fixed entry uses totalPrice when > 0', () {
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Yazılım',
          billingType: 'fixed',
          totalPrice: 5000.0,
        );
        expect(entry.effectivePrice, 5000.0);
      });

      test('hourly entry with zero rate returns 0', () {
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
          billingType: 'hourly',
          hourlyRate: 0.0,
        );
        expect(entry.effectivePrice, 0.0);
      });

      test('fixed entry without totalPrice returns 0', () {
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
          billingType: 'fixed',
        );
        expect(entry.effectivePrice, 0.0);
      });
    });

    group('break (mola) duration', () {
      test('subtracts break time from gross duration', () {
        // 09:00→17:00 = 8h, break 12:00→13:00 = 1h → net 7h
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Yazılım',
          breakStart: '12:00',
          breakEnd: '13:00',
        );
        expect(entry.durationHours, 7.0);
      });

      test('null break means no deduction', () {
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Yazılım',
        );
        expect(entry.durationHours, 8.0);
      });

      test('effectivePrice reflects break deduction for hourly', () {
        // 8h - 0.5h break = 7.5h, rate 100 → 750
        final entry = WorkEntry(
          clientId: 'c1',
          clientName: 'Client',
          clientColor: '#000000',
          date: '01.01.2026',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Yazılım',
          billingType: 'hourly',
          hourlyRate: 100.0,
          breakStart: '12:00',
          breakEnd: '12:30',
        );
        expect(entry.effectivePrice, 750.0);
      });
    });
  });
}
