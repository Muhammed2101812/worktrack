import 'package:uuid/uuid.dart';

class Project {
  final String id;
  final String clientId;
  final String name;
  final String description;
  final String status;
  final String createdAt;
  final bool synced;

  Project({
    String? id,
    required this.clientId,
    required this.name,
    this.description = '',
    this.status = 'active',
    String? createdAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Project copyWith({
    String? clientId,
    String? name,
    String? description,
    String? status,
    String? createdAt,
    bool? synced,
  }) =>
      Project(
        id: id,
        clientId: clientId ?? this.clientId,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'name': name,
        'description': description,
        'status': status,
        'created_at': createdAt,
      };

  // SQLite için (synced sütunu var)
  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'synced': synced ? 1 : 0,
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'],
        clientId: m['client_id'] ?? '',
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        status: m['status'] ?? 'active',
        createdAt: m['created_at'] ?? '',
        synced: m['synced'] == 1 || m['synced'] == true,
      );
}
