import 'package:uuid/uuid.dart';

class Client {
  final String id;
  final String name;
  final String color;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  Client({
    String? id,
    required this.name,
    required this.color,
    String? createdAt,
    String? updatedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Client copyWith({
    String? name,
    String? color,
    String? createdAt,
    String? updatedAt,
    bool? isDeleted,
  }) =>
      Client(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  /// Minimal map sent to Supabase. Soft-delete/conflict fields are only used
  /// locally; remote schema is kept simple to avoid breaking existing tables.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
      };

  // SQLite için: tüm senkronizasyon alanlarını içerir
  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Client.fromMap(Map<String, dynamic> m) => Client(
        id: m['id'],
        name: m['name'] ?? '',
        color: m['color'] ?? '#4A90D9',
        createdAt: m['created_at'],
        updatedAt: m['updated_at'],
        isDeleted: (m['is_deleted'] == 1) || (m['is_deleted'] == true),
      );
}
