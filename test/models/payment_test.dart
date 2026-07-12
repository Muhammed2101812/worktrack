import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/payment.dart';

void main() {
  group('Payment Model Tests', () {
    test('should create Payment with auto-generated id and default values', () {
      final payment = Payment(
        clientId: 'client-1',
        clientName: 'Client 1',
        clientColor: '#FF5733',
        amount: 1500.0,
        date: '11.07.2026',
      );

      expect(payment.id, isNotNull);
      expect(payment.clientId, 'client-1');
      expect(payment.clientName, 'Client 1');
      expect(payment.clientColor, '#FF5733');
      expect(payment.amount, 1500.0);
      expect(payment.date, '11.07.2026');
      expect(payment.notes, '');
      expect(payment.synced, false);
    });

    test('should copyWith updated values', () {
      final payment = Payment(
        clientId: 'client-1',
        clientName: 'Client 1',
        clientColor: '#FF5733',
        amount: 1500.0,
        date: '11.07.2026',
      );

      final updated = payment.copyWith(
        amount: 2000.0,
        notes: 'Updated note',
        synced: true,
      );

      expect(updated.id, payment.id);
      expect(updated.amount, 2000.0);
      expect(updated.notes, 'Updated note');
      expect(updated.synced, true);
    });

    test('should serialize to map correctly', () {
      final payment = Payment(
        id: 'pay-123',
        clientId: 'client-1',
        clientName: 'Client 1',
        clientColor: '#FF5733',
        amount: 1500.0,
        date: '11.07.2026',
        notes: 'Some notes',
        synced: true,
      );

      final map = payment.toMap();
      expect(map['id'], 'pay-123');
      expect(map['client_id'], 'client-1');
      expect(map['client_name'], 'Client 1');
      expect(map['client_color'], '#FF5733');
      expect(map['amount'], 1500.0);
      expect(map['date'], '11.07.2026');
      expect(map['notes'], 'Some notes');
    });

    test('should serialize to local map with integer synced representation', () {
      final payment = Payment(
        id: 'pay-123',
        clientId: 'client-1',
        clientName: 'Client 1',
        clientColor: '#FF5733',
        amount: 1500.0,
        date: '11.07.2026',
        notes: 'Some notes',
        synced: true,
      );

      final map = payment.toLocalMap();
      expect(map['synced'], 1);
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'pay-456',
        'client_id': 'client-2',
        'client_name': 'Client 2',
        'client_color': '#33FF57',
        'amount': 2500.5,
        'date': '12.07.2026',
        'notes': 'More notes',
        'synced': 1,
      };

      final payment = Payment.fromMap(map);
      expect(payment.id, 'pay-456');
      expect(payment.clientId, 'client-2');
      expect(payment.clientName, 'Client 2');
      expect(payment.clientColor, '#33FF57');
      expect(payment.amount, 2500.5);
      expect(payment.date, '12.07.2026');
      expect(payment.notes, 'More notes');
      expect(payment.synced, true);
    });
  });
}
