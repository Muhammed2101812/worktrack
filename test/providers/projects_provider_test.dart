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
      test('adds a unique project successfully and triggers sync and backup', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        final returnedProject = await container.read(projectsProvider.notifier).addProject(newProject);

        expect(returnedProject, equals(newProject));
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
        expect(updatedProjects.length, equals(3));
      });

      test('database throws exception: exception propagates, state remains unchanged, and sync/backup/invalidation are not executed', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        when(() => mockLocalDB.insertProject(any())).thenThrow(Exception('DB insertion failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        // Fetch initial state first so we can verify it doesn't change
        final initialState = await container.read(projectsProvider.future);
        expect(initialState.length, equals(2));

        // Act & Assert exception propagates
        await expectLater(
          container.read(projectsProvider.notifier).addProject(newProject),
          throwsA(isA<Exception>()),
        );

        // Verify downstream methods are never called
        verifyNever(() => mockSync.syncPendingProjects());
        verifyNever(() => mockBackup.triggerBackup());

        // Verify state is NOT modified (projectsList still has only original projects)
        final finalState = await container.read(projectsProvider.future);
        expect(finalState, equals(initialState));
        expect(projectsList, equals([projectA, projectB]));
      });

      test('sync throws exception: exception is caught, local project is added, state is updated, and backup is triggered', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        // Fetch initial state
        final initialState = await container.read(projectsProvider.future);
        expect(initialState.length, equals(2));

        // Act - should not throw, as exception is caught
        final returnedProject = await container.read(projectsProvider.notifier).addProject(newProject);

        expect(returnedProject, equals(newProject));
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
        expect(updatedProjects.length, equals(3));
      });
    });

    group('updateProject', () {
      test('updates project successfully, marking unsynced, and triggers backup', () async {
        final container = createContainer();
        final updatedProject = projectA.copyWith(name: 'Project A Updated');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).updateProject(updatedProject);

        // Verify local DB update was called with synced = false
        verify(() => mockLocalDB.updateProject(any(that: isA<Project>().having((p) => p.name, 'name', 'Project A Updated').having((p) => p.synced, 'synced', false)))).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.name == 'Project A Updated'), isTrue);
      });

      test('handles Sync exception gracefully during updateProject', () async {
        final container = createContainer();
        final updatedProject = projectA.copyWith(name: 'Project A Updated');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).updateProject(updatedProject),
          completes,
        );

        verify(() => mockLocalDB.updateProject(any())).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);
      });
    });

    group('deleteProject', () {
      test('soft-deletes project successfully and triggers backup', () async {
        final container = createContainer();

        // Simulate DB soft-delete by updating getAllProjects stub
        when(() => mockLocalDB.softDeleteProject(any())).thenAnswer((inv) async {
          projectsList.removeWhere((p) => p.id == 'p1');
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

      test('handles Sync exception gracefully during deleteProject', () async {
        final container = createContainer();

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).deleteProject('p1'),
          completes,
        );

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);
      });
    });

    group('refresh', () {
      test('refresh triggers self-invalidation', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        // Fetch initial state first
        await container.read(projectsProvider.future);

        // Call refresh
        await container.read(projectsProvider.notifier).refresh();

        // Await the future to ensure the rebuild has finished
        await container.read(projectsProvider.future);

        // getAllProjects is called once for build, and again because of refresh invalidating state
        verify(() => mockLocalDB.getAllProjects()).called(2);
      });
    });
  });
}
