import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worklog/models/project.dart';
import 'package:worklog/providers/core_providers.dart';
import 'package:worklog/providers/projects_provider.dart';
import 'package:worklog/services/local_db_service.dart';
import 'package:worklog/services/sync_service.dart';
import 'package:worklog/services/backup_service.dart';

class MockLocalDBService extends Mock implements LocalDBService {}
class MockSyncService extends Mock implements SyncService {}
class MockBackupService extends Mock implements BackupService {}

class FakeProject extends Fake implements Project {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProject());
  });

  group('ProjectsNotifier Tests', () {
    late MockLocalDBService mockLocalDBService;
    late MockSyncService mockSyncService;
    late MockBackupService mockBackupService;

    setUp(() {
      mockLocalDBService = MockLocalDBService();
      mockSyncService = MockSyncService();
      mockBackupService = MockBackupService();
    });

    test('should fetch projects from DB on build', () async {
      final projects = [
        Project(id: '1', clientId: 'c1', name: 'P1'),
        Project(id: '2', clientId: 'c1', name: 'P2'),
      ];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => projects);

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(projectsProvider.future);
      expect(result, projects);
      verify(() => mockLocalDBService.getAllProjects()).called(1);
    });

    test('addProject should save locally, sync, trigger backup and return the project', () async {
      final project = Project(id: 'new-id', clientId: 'c1', name: 'New Project');
      final initialProjects = <Project>[];
      final updatedProjects = [project];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => initialProjects);
      when(() => mockLocalDBService.insertProject(any()))
          .thenAnswer((_) async => {});
      when(() => mockSyncService.syncPendingProjects())
          .thenAnswer((_) async => {});
      when(() => mockBackupService.triggerBackup())
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
          syncServiceProvider.overrideWithValue(mockSyncService),
          backupServiceProvider.overrideWithValue(mockBackupService),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial load
      await container.read(projectsProvider.future);

      // Prepare updated DB response for reload
      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => updatedProjects);

      final result = await container.read(projectsProvider.notifier).addProject(project);

      expect(result, project);

      verify(() => mockLocalDBService.insertProject(project)).called(1);
      verify(() => mockSyncService.syncPendingProjects()).called(1);
      verify(() => mockBackupService.triggerBackup()).called(1);

      // Verify re-evaluation fetched the updated projects list
      final finalProjects = await container.read(projectsProvider.future);
      expect(finalProjects, updatedProjects);
      verify(() => mockLocalDBService.getAllProjects()).called(2);
    });

    test('addProject should gracefully handle sync service exceptions and still complete the backup', () async {
      final project = Project(id: 'new-id', clientId: 'c1', name: 'New Project');
      final initialProjects = <Project>[];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => initialProjects);
      when(() => mockLocalDBService.insertProject(any()))
          .thenAnswer((_) async => {});
      when(() => mockSyncService.syncPendingProjects())
          .thenThrow(Exception('Network Error during sync'));
      when(() => mockBackupService.triggerBackup())
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
          syncServiceProvider.overrideWithValue(mockSyncService),
          backupServiceProvider.overrideWithValue(mockBackupService),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial load
      await container.read(projectsProvider.future);

      // We should prepare return for invalidation
      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => [project]);

      final result = await container.read(projectsProvider.notifier).addProject(project);

      expect(result, project);

      verify(() => mockLocalDBService.insertProject(project)).called(1);
      verify(() => mockSyncService.syncPendingProjects()).called(1);
      verify(() => mockBackupService.triggerBackup()).called(1);

      // State is still successfully updated/loaded
      final finalProjects = await container.read(projectsProvider.future);
      expect(finalProjects, [project]);
    });

    test('updateProject should save changes with updated timestamp, sync, and trigger backup', () async {
      final originalProject = Project(id: 'p-1', clientId: 'c1', name: 'Original Name');
      final initialProjects = [originalProject];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => initialProjects);
      when(() => mockLocalDBService.updateProject(any()))
          .thenAnswer((_) async => {});
      when(() => mockSyncService.syncPendingProjects())
          .thenAnswer((_) async => {});
      when(() => mockBackupService.triggerBackup())
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
          syncServiceProvider.overrideWithValue(mockSyncService),
          backupServiceProvider.overrideWithValue(mockBackupService),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial load
      await container.read(projectsProvider.future);

      // Prepare updated DB response for reload after updating
      final updatedProjectFromDB = originalProject.copyWith(name: 'Updated Name', synced: false);
      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => [updatedProjectFromDB]);

      await container.read(projectsProvider.notifier).updateProject(originalProject.copyWith(name: 'Updated Name'));

      // Verify that updateProject was called on the database with a non-synced project
      final capturedProject = verify(() => mockLocalDBService.updateProject(captureAny())).captured.single as Project;
      expect(capturedProject.id, originalProject.id);
      expect(capturedProject.name, 'Updated Name');
      expect(capturedProject.synced, isFalse);

      verify(() => mockSyncService.syncPendingProjects()).called(1);
      verify(() => mockBackupService.triggerBackup()).called(1);

      // Verify re-evaluation fetched the updated projects list
      final finalProjects = await container.read(projectsProvider.future);
      expect(finalProjects, [updatedProjectFromDB]);
    });

    test('deleteProject should soft delete locally, sync, and trigger backup', () async {
      final project = Project(id: 'p-delete', clientId: 'c1', name: 'To Delete');
      final initialProjects = [project];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => initialProjects);
      when(() => mockLocalDBService.softDeleteProject(any()))
          .thenAnswer((_) async => {});
      when(() => mockSyncService.syncPendingProjects())
          .thenAnswer((_) async => {});
      when(() => mockBackupService.triggerBackup())
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
          syncServiceProvider.overrideWithValue(mockSyncService),
          backupServiceProvider.overrideWithValue(mockBackupService),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial load
      await container.read(projectsProvider.future);

      // Prepare updated DB response for reload (empty list since project is deleted)
      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => <Project>[]);

      await container.read(projectsProvider.notifier).deleteProject('p-delete');

      verify(() => mockLocalDBService.softDeleteProject('p-delete')).called(1);
      verify(() => mockSyncService.syncPendingProjects()).called(1);
      verify(() => mockBackupService.triggerBackup()).called(1);

      // Verify re-evaluation fetched the updated projects list
      final finalProjects = await container.read(projectsProvider.future);
      expect(finalProjects, isEmpty);
    });

    test('refresh should invalidate the provider and reload data from DB', () async {
      final initialProjects = <Project>[];
      final refreshedProjects = [Project(id: 'refreshed-id', clientId: 'c1', name: 'Refreshed')];

      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => initialProjects);

      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWithValue(mockLocalDBService),
        ],
      );
      addTearDown(container.dispose);

      // Initial read
      await container.read(projectsProvider.future);

      // Change mocked DB response for the reload
      when(() => mockLocalDBService.getAllProjects())
          .thenAnswer((_) async => refreshedProjects);

      // Call refresh
      await container.read(projectsProvider.notifier).refresh();

      // Read resolved future again
      final result = await container.read(projectsProvider.future);
      expect(result, refreshedProjects);

      verify(() => mockLocalDBService.getAllProjects()).called(2);
    });
  });
}
