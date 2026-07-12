import 'package:uuid/uuid.dart';
import '../core/utils.dart';

class Project {
  final String id;
  final String clientId;
  final String name;
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool synced;
  final bool isDeleted;

  Project({
    String? id,
    required this.clientId,
    required this.name,
    this.description = '',
    this.status = 'active',
    String? createdAt,
    String? updatedAt,
    this.synced = false,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Project copyWith({
    String? clientId,
    String? name,
    String? description,
    String? status,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    bool? isDeleted,
  }) =>
      Project(
        id: id,
        clientId: clientId ?? this.clientId,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  /// Minimal map sent to Supabase (no local-only sync/conflict fields).
  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'name': name,
        'description': description,
        'status': status,
        'created_at': createdAt,
      };

  // SQLite için (synced + is_deleted sütunları var)
  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'updated_at': updatedAt,
        'synced': synced ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'],
        clientId: m['client_id'] ?? '',
        name: decodeHtmlEntities(m['name'] ?? ''),
        description: decodeHtmlEntities(m['description'] ?? ''),
        status: m['status'] ?? 'active',
        createdAt: m['created_at'] ?? '',
        updatedAt: m['updated_at'],
        synced: m['synced'] == 1 || m['synced'] == true,
        isDeleted: (m['is_deleted'] == 1) || (m['is_deleted'] == true),
      );
}
