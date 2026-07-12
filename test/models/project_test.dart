import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('should create Project with default parameters', () {
      final project = Project(
        clientId: 'client-123',
        name: 'New Website Design',
      );

      expect(project.id, isNotEmpty);
      expect(project.clientId, 'client-123');
      expect(project.name, 'New Website Design');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, isNotEmpty);
      expect(project.updatedAt, isNotEmpty);
      expect(project.synced, isFalse);
      expect(project.isDeleted, isFalse);
    });

    test('should create Project with custom id and optional parameters', () {
      final project = Project(
        id: 'custom-project-id',
        clientId: 'client-123',
        name: 'New Website Design',
        description: 'Creating a custom website design',
        status: 'completed',
        createdAt: '2026-03-24T12:00:00Z',
        updatedAt: '2026-03-24T12:10:00Z',
        synced: true,
        isDeleted: true,
      );

      expect(project.id, 'custom-project-id');
      expect(project.clientId, 'client-123');
      expect(project.name, 'New Website Design');
      expect(project.description, 'Creating a custom website design');
      expect(project.status, 'completed');
      expect(project.createdAt, '2026-03-24T12:00:00Z');
      expect(project.updatedAt, '2026-03-24T12:10:00Z');
      expect(project.synced, isTrue);
      expect(project.isDeleted, isTrue);
    });

    test('should copyWith updated values', () {
      final project = Project(
        clientId: 'client-123',
        name: 'New Website Design',
        description: 'Initial desc',
        status: 'active',
        createdAt: '2026-03-24T12:00:00Z',
        updatedAt: '2026-03-24T12:10:00Z',
        synced: false,
        isDeleted: false,
      );

      final updated = project.copyWith(
        clientId: 'client-456',
        name: 'Updated Website Design',
        description: 'Updated desc',
        status: 'on-hold',
        createdAt: '2026-03-24T13:00:00Z',
        updatedAt: '2026-03-24T13:10:00Z',
        synced: true,
        isDeleted: true,
      );

      // ID should remain the same
      expect(updated.id, project.id);
      expect(updated.clientId, 'client-456');
      expect(updated.name, 'Updated Website Design');
      expect(updated.description, 'Updated desc');
      expect(updated.status, 'on-hold');
      expect(updated.createdAt, '2026-03-24T13:00:00Z');
      expect(updated.updatedAt, '2026-03-24T13:10:00Z');
      expect(updated.synced, isTrue);
      expect(updated.isDeleted, isTrue);
    });

    test('should convert to map correctly (toMap)', () {
      final project = Project(
        id: 'project-789',
        clientId: 'client-123',
        name: 'Test Project',
        description: 'A test project description',
        status: 'active',
        createdAt: '2026-03-24T12:00:00Z',
        updatedAt: '2026-03-24T12:10:00Z',
        synced: true,
        isDeleted: false,
      );

      final map = project.toMap();

      expect(map, {
        'id': 'project-789',
        'client_id': 'client-123',
        'name': 'Test Project',
        'description': 'A test project description',
        'status': 'active',
        'created_at': '2026-03-24T12:00:00Z',
      });
      // toMap shouldn't contain local-only sync/conflict fields (synced, is_deleted, updated_at), since it is used for Remote DB
    });

    test('should convert to local map correctly (toLocalMap)', () {
      final project = Project(
        id: 'project-789',
        clientId: 'client-123',
        name: 'Test Project',
        description: 'A test project description',
        status: 'active',
        createdAt: '2026-03-24T12:00:00Z',
        updatedAt: '2026-03-24T12:10:00Z',
        synced: true,
        isDeleted: true,
      );

      final localMap = project.toLocalMap();

      expect(localMap, {
        'id': 'project-789',
        'client_id': 'client-123',
        'name': 'Test Project',
        'description': 'A test project description',
        'status': 'active',
        'created_at': '2026-03-24T12:00:00Z',
        'updated_at': '2026-03-24T12:10:00Z',
        'synced': 1,
        'is_deleted': 1,
      });
    });

    test('should create Project fromMap correctly', () {
      final map = {
        'id': 'project-789',
        'client_id': 'client-123',
        'name': 'Test Project',
        'description': 'A test project description',
        'status': 'active',
        'created_at': '2026-03-24T12:00:00Z',
        'updated_at': '2026-03-24T12:10:00Z',
        'synced': 1,
        'is_deleted': 1,
      };

      final project = Project.fromMap(map);

      expect(project.id, 'project-789');
      expect(project.clientId, 'client-123');
      expect(project.name, 'Test Project');
      expect(project.description, 'A test project description');
      expect(project.status, 'active');
      expect(project.createdAt, '2026-03-24T12:00:00Z');
      expect(project.updatedAt, '2026-03-24T12:10:00Z');
      expect(project.synced, isTrue);
      expect(project.isDeleted, isTrue);
    });

    test('should create Project fromMap with default/missing values', () {
      final map = <String, dynamic>{
        'id': 'project-789',
      };

      final project = Project.fromMap(map);

      expect(project.id, 'project-789');
      expect(project.clientId, '');
      expect(project.name, '');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, '');
      expect(project.updatedAt, isNotEmpty); // falls back to DateTime.now().toIso8601String() in constructor
      expect(project.synced, isFalse);
      expect(project.isDeleted, isFalse);
    });
  });
}
