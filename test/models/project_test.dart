import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('should create Project with auto-generated id, default status, and createdAt', () {
      final project = Project(
        clientId: 'client-123',
        name: 'Website Redesign',
      );

      expect(project.id, isNotNull);
      expect(project.id, isNotEmpty);
      expect(project.clientId, 'client-123');
      expect(project.name, 'Website Redesign');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, isNotNull);
      expect(project.createdAt, isNotEmpty);
      expect(project.synced, false);
    });

    test('should create Project with custom id and specific parameters', () {
      final project = Project(
        id: 'project-456',
        clientId: 'client-123',
        name: 'Mobile App',
        description: 'Building a Flutter app',
        status: 'completed',
        createdAt: '2026-03-15T10:00:00Z',
        synced: true,
      );

      expect(project.id, 'project-456');
      expect(project.clientId, 'client-123');
      expect(project.name, 'Mobile App');
      expect(project.description, 'Building a Flutter app');
      expect(project.status, 'completed');
      expect(project.createdAt, '2026-03-15T10:00:00Z');
      expect(project.synced, true);
    });

    test('should copy with updated values while preserving id', () {
      final project = Project(
        id: 'proj-1',
        clientId: 'client-1',
        name: 'Project Alpha',
        description: 'First phase',
        status: 'active',
        createdAt: '2026-01-01T12:00:00Z',
        synced: false,
      );

      final updated = project.copyWith(
        name: 'Project Alpha - Updated',
        description: 'Updated description',
        status: 'on-hold',
        synced: true,
      );

      expect(updated.id, 'proj-1');
      expect(updated.clientId, 'client-1');
      expect(updated.name, 'Project Alpha - Updated');
      expect(updated.description, 'Updated description');
      expect(updated.status, 'on-hold');
      expect(updated.createdAt, '2026-01-01T12:00:00Z');
      expect(updated.synced, true);
    });

    test('should copy with partial updates', () {
      final project = Project(
        id: 'proj-1',
        clientId: 'client-1',
        name: 'Project Alpha',
      );

      final updated = project.copyWith(clientId: 'client-2');

      expect(updated.id, 'proj-1');
      expect(updated.clientId, 'client-2');
      expect(updated.name, 'Project Alpha');
      expect(updated.description, '');
    });

    test('should convert to map correctly', () {
      final project = Project(
        id: 'proj-1',
        clientId: 'client-1',
        name: 'Project Alpha',
        description: 'Desc',
        status: 'active',
        createdAt: '2026-01-01T12:00:00Z',
      );

      final map = project.toMap();

      expect(map['id'], 'proj-1');
      expect(map['client_id'], 'client-1');
      expect(map['name'], 'Project Alpha');
      expect(map['description'], 'Desc');
      expect(map['status'], 'active');
      expect(map['created_at'], '2026-01-01T12:00:00Z');
      expect(map.containsKey('synced'), false);
    });

    test('should convert to local map with synced integer value', () {
      final projectSynced = Project(
        id: 'proj-1',
        clientId: 'client-1',
        name: 'Project Alpha',
        synced: true,
      );

      final mapSynced = projectSynced.toLocalMap();
      expect(mapSynced['synced'], 1);

      final projectUnsynced = Project(
        id: 'proj-2',
        clientId: 'client-1',
        name: 'Project Beta',
        synced: false,
      );

      final mapUnsynced = projectUnsynced.toLocalMap();
      expect(mapUnsynced['synced'], 0);
    });

    test('should create Project from map with all fields', () {
      final map = {
        'id': 'proj-1',
        'client_id': 'client-1',
        'name': 'Project Alpha',
        'description': 'Desc',
        'status': 'active',
        'created_at': '2026-01-01T12:00:00Z',
        'synced': 1,
      };

      final project = Project.fromMap(map);

      expect(project.id, 'proj-1');
      expect(project.clientId, 'client-1');
      expect(project.name, 'Project Alpha');
      expect(project.description, 'Desc');
      expect(project.status, 'active');
      expect(project.createdAt, '2026-01-01T12:00:00Z');
      expect(project.synced, true);
    });

    test('should handle boolean and integer types for synced in fromMap', () {
      final mapWithInt = {
        'id': 'proj-1',
        'synced': 1,
      };
      final projectWithInt = Project.fromMap(mapWithInt);
      expect(projectWithInt.synced, true);

      final mapWithBool = {
        'id': 'proj-2',
        'synced': true,
      };
      final projectWithBool = Project.fromMap(mapWithBool);
      expect(projectWithBool.synced, true);

      final mapWithFalse = {
        'id': 'proj-3',
        'synced': false,
      };
      final projectWithFalse = Project.fromMap(mapWithFalse);
      expect(projectWithFalse.synced, false);
    });

    test('should fallback to default values in fromMap when key is missing or null', () {
      final map = {
        'id': 'proj-1',
      };

      final project = Project.fromMap(map);

      expect(project.clientId, '');
      expect(project.name, '');
      expect(project.description, '');
      expect(project.status, 'active');
      expect(project.createdAt, '');
      expect(project.synced, false);
    });
  });
}
