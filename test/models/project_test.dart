import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('should create Project with auto-generated id and default values', () {
      final project = Project(
        clientId: 'client-123',
        name: 'Project Alpha',
      );

      expect(project.id, isNotEmpty);
      expect(project.clientId, 'client-123');
      expect(project.name, 'Project Alpha');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, isNotEmpty);
      expect(project.updatedAt, isNotEmpty);
      expect(project.synced, false);
      expect(project.isDeleted, false);
    });

    test('should create Project with custom properties in constructor', () {
      final customCreatedAt = '2026-05-15T10:00:00Z';
      final customUpdatedAt = '2026-05-15T12:00:00Z';

      final project = Project(
        id: 'custom-proj-id',
        clientId: 'client-456',
        name: 'Project Beta',
        description: 'A custom project',
        status: 'completed',
        createdAt: customCreatedAt,
        updatedAt: customUpdatedAt,
        synced: true,
        isDeleted: true,
      );

      expect(project.id, 'custom-proj-id');
      expect(project.clientId, 'client-456');
      expect(project.name, 'Project Beta');
      expect(project.description, 'A custom project');
      expect(project.status, 'completed');
      expect(project.createdAt, customCreatedAt);
      expect(project.updatedAt, customUpdatedAt);
      expect(project.synced, true);
      expect(project.isDeleted, true);
    });

    test('should copyWith updated values and preserve original id', () {
      final project = Project(
        id: 'proj-789',
        clientId: 'client-789',
        name: 'Project Gamma',
        description: 'Original description',
        status: 'active',
        synced: false,
        isDeleted: false,
      );

      final updated = project.copyWith(
        clientId: 'client-999',
        name: 'Project Gamma Updated',
        description: 'Updated description',
        status: 'archived',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
        synced: true,
        isDeleted: true,
      );

      // Verify ID is preserved and not updated
      expect(updated.id, 'proj-789');

      // Verify updated properties
      expect(updated.clientId, 'client-999');
      expect(updated.name, 'Project Gamma Updated');
      expect(updated.description, 'Updated description');
      expect(updated.status, 'archived');
      expect(updated.createdAt, '2026-01-01T00:00:00Z');
      expect(updated.updatedAt, '2026-01-02T00:00:00Z');
      expect(updated.synced, true);
      expect(updated.isDeleted, true);
    });

    test('should copyWith partial updates', () {
      final project = Project(
        clientId: 'client-111',
        name: 'Project Delta',
        description: 'Description',
      );

      final updated = project.copyWith(name: 'New Name');

      expect(updated.id, project.id);
      expect(updated.clientId, 'client-111');
      expect(updated.name, 'New Name');
      expect(updated.description, 'Description');
      expect(updated.status, project.status);
      expect(updated.createdAt, project.createdAt);
      expect(updated.updatedAt, project.updatedAt);
      expect(updated.synced, project.synced);
      expect(updated.isDeleted, project.isDeleted);
    });

    test('should serialize to Map correctly (toMap for Supabase)', () {
      final project = Project(
        id: 'proj-supabase',
        clientId: 'client-supabase',
        name: 'Supabase Project',
        description: 'Testing toMap',
        status: 'active',
        createdAt: '2026-05-15T10:00:00Z',
        updatedAt: '2026-05-15T12:00:00Z',
        synced: true, // synced should not be included in standard toMap
        isDeleted: false,
      );

      final map = project.toMap();

      expect(map['id'], 'proj-supabase');
      expect(map['client_id'], 'client-supabase');
      expect(map['name'], 'Supabase Project');
      expect(map['description'], 'Testing toMap');
      expect(map['status'], 'active');
      expect(map['created_at'], '2026-05-15T10:00:00Z');
      expect(map['updated_at'], '2026-05-15T12:00:00Z');
      expect(map['is_deleted'], false);
      expect(map.containsKey('synced'), false); // local-only sync fields omitted
    });

    test('should serialize to Local Map correctly (toLocalMap for SQLite)', () {
      final project = Project(
        id: 'proj-sqlite',
        clientId: 'client-sqlite',
        name: 'SQLite Project',
        description: 'Testing toLocalMap',
        status: 'active',
        createdAt: '2026-05-15T10:00:00Z',
        updatedAt: '2026-05-15T12:00:00Z',
        synced: true,
        isDeleted: true,
      );

      final localMap = project.toLocalMap();

      expect(localMap['id'], 'proj-sqlite');
      expect(localMap['client_id'], 'client-sqlite');
      expect(localMap['name'], 'SQLite Project');
      expect(localMap['description'], 'Testing toLocalMap');
      expect(localMap['status'], 'active');
      expect(localMap['created_at'], '2026-05-15T10:00:00Z');
      expect(localMap['updated_at'], '2026-05-15T12:00:00Z');
      expect(localMap['synced'], 1); // mapped to int
      expect(localMap['is_deleted'], 1); // mapped to int
    });

    test('should serialize to Local Map with falsy values correctly', () {
      final project = Project(
        clientId: 'client-sqlite',
        name: 'SQLite Project',
        synced: false,
        isDeleted: false,
      );

      final localMap = project.toLocalMap();

      expect(localMap['synced'], 0);
      expect(localMap['is_deleted'], 0);
    });

    test('should deserialize from Map correctly with boolean representations', () {
      final map = {
        'id': 'proj-map-bool',
        'client_id': 'client-map-bool',
        'name': 'Map Bool Project',
        'description': 'Testing fromMap with bools',
        'status': 'active',
        'created_at': '2026-05-15T10:00:00Z',
        'updated_at': '2026-05-15T12:00:00Z',
        'synced': true,
        'is_deleted': true,
      };

      final project = Project.fromMap(map);

      expect(project.id, 'proj-map-bool');
      expect(project.clientId, 'client-map-bool');
      expect(project.name, 'Map Bool Project');
      expect(project.description, 'Testing fromMap with bools');
      expect(project.status, 'active');
      expect(project.createdAt, '2026-05-15T10:00:00Z');
      expect(project.updatedAt, '2026-05-15T12:00:00Z');
      expect(project.synced, true);
      expect(project.isDeleted, true);
    });

    test('should deserialize from Map correctly with integer representations (SQLite)', () {
      final map = {
        'id': 'proj-map-int',
        'client_id': 'client-map-int',
        'name': 'Map Int Project',
        'description': 'Testing fromMap with ints',
        'status': 'active',
        'created_at': '2026-05-15T10:00:00Z',
        'updated_at': '2026-05-15T12:00:00Z',
        'synced': 1,
        'is_deleted': 1,
      };

      final project = Project.fromMap(map);

      expect(project.id, 'proj-map-int');
      expect(project.clientId, 'client-map-int');
      expect(project.name, 'Map Int Project');
      expect(project.description, 'Testing fromMap with ints');
      expect(project.status, 'active');
      expect(project.createdAt, '2026-05-15T10:00:00Z');
      expect(project.updatedAt, '2026-05-15T12:00:00Z');
      expect(project.synced, true);
      expect(project.isDeleted, true);
    });

    test('should decode HTML entities in name and description during deserialization', () {
      final map = {
        'id': 'proj-html',
        'client_id': 'client-html',
        'name': 'Project &amp; Son&#39;s &lt;App&gt;',
        'description': 'Testing &quot;HTML&quot; &amp; custom entities',
        'status': 'active',
        'created_at': '2026-05-15T10:00:00Z',
        'updated_at': '2026-05-15T12:00:00Z',
        'synced': 0,
        'is_deleted': 0,
      };

      final project = Project.fromMap(map);

      expect(project.name, "Project & Son's <App>");
      expect(project.description, 'Testing "HTML" & custom entities');
    });

    test('should apply default values during deserialization if fields are missing', () {
      final map = {
        'id': 'proj-defaults',
      };

      final project = Project.fromMap(map);

      expect(project.id, 'proj-defaults');
      expect(project.clientId, '');
      expect(project.name, '');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, '');
      expect(project.updatedAt, isNotEmpty);
      expect(project.synced, false);
      expect(project.isDeleted, false);
    });
  });
}
