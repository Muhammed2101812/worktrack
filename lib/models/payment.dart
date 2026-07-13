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
  final String updatedAt;
  final bool isDeleted;

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
    String? updatedAt,
    this.isDeleted = false,
  })  : assert(amount >= 0, 'amount cannot be negative'),
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

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
    String? updatedAt,
    bool? isDeleted,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Minimal map sent to Supabase (no local-only sync/conflict fields).
  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'client_color': clientColor,
        'amount': amount,
        'date': date,
        'notes': notes,
        'created_at': createdAt,
        'is_deleted': isDeleted,
        'updated_at': updatedAt,
      };

  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'updated_at': updatedAt,
        'synced': synced ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
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
        updatedAt: m['updated_at'],
        isDeleted: (m['is_deleted'] == 1) || (m['is_deleted'] == true),
      );
}
