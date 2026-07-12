import 'package:uuid/uuid.dart';
import '../core/utils.dart';

class Payment {
  final String id;
  final String clientId;
  final String clientName;
  final String clientColor;
  final double amount;
  final String date;
  final String notes;
  final bool synced;
  final String createdAt;

  Payment({
    String? id,
    required this.clientId,
    required this.clientName,
    required this.clientColor,
    required this.amount,
    required this.date,
    this.notes = '',
    this.synced = false,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Payment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientColor,
    double? amount,
    String? date,
    String? notes,
    bool? synced,
    String? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientColor: clientColor ?? this.clientColor,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'client_color': clientColor,
        'amount': amount,
        'date': date,
        'notes': notes,
        'created_at': createdAt,
      };

  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'synced': synced ? 1 : 0,
      };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'],
        clientId: m['client_id'] ?? '',
        clientName: decodeHtmlEntities(m['client_name'] ?? ''),
        clientColor: m['client_color'] ?? '#4A90D9',
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        date: m['date'] ?? '',
        notes: decodeHtmlEntities(m['notes'] ?? ''),
        synced: m['synced'] == 1 || m['synced'] == true,
        createdAt: m['created_at'],
      );
}
