import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog/models/project.dart';
import 'package:worklog/providers/projects_provider.dart';
import 'package:worklog/providers/core_providers.dart';
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
    late MockLocalDBService mockLocalDB;
    late MockSyncService mockSync;
    late MockBackupService mockBackup;
    late List<Project> projectsList;

    final projectA = Project(id: 'p1', clientId: 'c1', name: 'Project A');
    final projectB = Project(id: 'p2', clientId: 'c1', name: 'Project B');

    setUp(() {
      mockLocalDB = MockLocalDBService();
      mockSync = MockSyncService();
      mockBackup = MockBackupService();

      projectsList = [projectA, projectB];

      // Setup default mock answers
      when(() => mockLocalDB.getAllProjects()).thenAnswer((_) async => List.from(projectsList));
      when(() => mockLocalDB.insertProject(any())).thenAnswer((invocation) async {
        final project = invocation.positionalArguments[0] as Project;
        projectsList.add(project);
      });
      when(() => mockLocalDB.updateProject(any())).thenAnswer((invocation) async {
        final project = invocation.positionalArguments[0] as Project;
        final index = projectsList.indexWhere((p) => p.id == project.id);
        if (index != -1) {
          projectsList[index] = project;
        }
      });
      when(() => mockLocalDB.softDeleteProject(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        projectsList.removeWhere((p) => p.id == id);
      });

      when(() => mockSync.syncPendingProjects()).thenAnswer((_) async {});
      when(() => mockBackup.triggerBackup()).thenAnswer((_) async {});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          localDBServiceProvider.overrideWith((ref) => mockLocalDB),
          syncServiceProvider.overrideWith((ref) => mockSync),
          backupServiceProvider.overrideWith((ref) => mockBackup),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build fetches and returns projects from local DB', () async {
      final container = createContainer();

      final result = await container.read(projectsProvider.future);

      expect(result, equals([projectA, projectB]));
      verify(() => mockLocalDB.getAllProjects()).called(1);
    });

    group('addProject', () {
      test('adds a project successfully, triggers sync and backup', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).addProject(newProject);

        // Verify local DB, sync and backup operations are called
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify notifier state is updated
        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
        expect(updatedProjects.length, equals(3));
      });

      test('handles sync exception gracefully during addProject', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).addProject(newProject),
          completes,
        );

        // Verify local DB is inserted and backup is triggered even if sync fails
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // State is still updated locally
        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
      });
    });

    group('updateProject', () {
      test('updates project successfully, triggers sync and backup', () async {
        final container = createContainer();
        final updatedProject = projectA.copyWith(name: 'Project A Updated');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).updateProject(updatedProject);

        verify(() => mockLocalDB.updateProject(any())).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.name == 'Project A Updated'), isTrue);
        expect(updatedProjects.length, equals(2));
      });

      test('handles sync exception gracefully during updateProject', () async {
        final container = createContainer();
        final updatedProject = projectA.copyWith(name: 'Project A Updated');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).updateProject(updatedProject),
          completes,
        );

        // Verify local DB is updated and backup is triggered even if sync fails
        verify(() => mockLocalDB.updateProject(any())).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.name == 'Project A Updated'), isTrue);
      });
    });

    group('deleteProject', () {
      test('soft-deletes project successfully, triggers sync and backup', () async {
        final container = createContainer();

        // After soft-delete, getAllProjects should no longer return the project
        when(() => mockLocalDB.softDeleteProject(any()))
            .thenAnswer((inv) async {
          when(() => mockLocalDB.getAllProjects()).thenAnswer((_) async =>
              [Project(id: 'p2', clientId: 'c1', name: 'Project B')]);
        });

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).deleteProject('p1');

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.id == 'p1'), isFalse);
        expect(updatedProjects.length, equals(1));
      });

      test('handles sync exception gracefully during deleteProject', () async {
        final container = createContainer();

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync error'));
        when(() => mockLocalDB.softDeleteProject(any()))
            .thenAnswer((inv) async {
          when(() => mockLocalDB.getAllProjects()).thenAnswer((_) async =>
              [Project(id: 'p2', clientId: 'c1', name: 'Project B')]);
        });

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).deleteProject('p1'),
          completes,
        );

        // Verify local DB is soft-deleted and backup is triggered even if sync fails
        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.id == 'p1'), isFalse);
      });

      test('propagates exception when localDB softDeleteProject fails', () async {
        final container = createContainer();

        when(() => mockLocalDB.softDeleteProject(any()))
            .thenThrow(Exception('DB delete error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).deleteProject('p1'),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        // Verify sync and backup are never triggered because delete failed early
        verifyNever(() => mockSync.syncPendingProjects());
        verifyNever(() => mockBackup.triggerBackup());
      });
    });
  });
}
