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

    final projectA = Project(id: 'p1', clientId: 'c1', name: 'Project A', description: 'Desc A');
    final projectB = Project(id: 'p2', clientId: 'c1', name: 'Project B', description: 'Desc B');

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

    group('Fetch Projects (build)', () {
      test('build fetches and returns projects from local DB (happy path)', () async {
        final container = createContainer();

        final result = await container.read(projectsProvider.future);

        expect(result, equals([projectA, projectB]));
        verify(() => mockLocalDB.getAllProjects()).called(1);
      });

      test('build handles error from local DB during fetch (error path)', () async {
        final container = createContainer();
        final databaseError = Exception('Database connection failed');
        when(() => mockLocalDB.getAllProjects()).thenThrow(databaseError);

        // Expect that reading the future throws the exception
        await expectLater(
          container.read(projectsProvider.future),
          throwsA(equals(databaseError)),
        );

        // Expect the provider state is AsyncError
        final state = container.read(projectsProvider);
        expect(state, isA<AsyncError>());
        expect(state.asError!.error, equals(databaseError));
        verify(() => mockLocalDB.getAllProjects()).called(1);
      });
    });

    group('addProject', () {
      test('adds a project successfully, triggers sync, backup, and invalidates self', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        final added = await container.read(projectsProvider.notifier).addProject(newProject);

        expect(added, equals(newProject));
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verification of invalidation (getAllProjects should be called twice in total)
        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
        expect(updatedProjects.length, equals(3));
        verify(() => mockLocalDB.getAllProjects()).called(2);
      });

      test('handles sync exception gracefully during addProject', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c1', name: 'Project C');
        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).addProject(newProject),
          completes,
        );

        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
      });
    });

    group('updateProject', () {
      test('updates a project successfully (sets synced=false), syncs, backups, and invalidates self', () async {
        final container = createContainer();
        final updatedProject = projectA.copyWith(name: 'Project A Updated');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).updateProject(updatedProject);

        // Captured updated project should have synced=false
        final captured = verify(() => mockLocalDB.updateProject(captureAny())).captured.single as Project;
        expect(captured.id, equals(projectA.id));
        expect(captured.name, equals('Project A Updated'));
        expect(captured.synced, isFalse);

        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.name == 'Project A Updated'), isTrue);
        expect(updatedProjects.length, equals(2));
      });

      test('handles sync exception gracefully during updateProject', () async {
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

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.name == 'Project A Updated'), isTrue);
      });
    });

    group('deleteProject', () {
      test('soft-deletes a project, syncs, backups, and invalidates self', () async {
        final container = createContainer();

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
        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync failed'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).deleteProject('p1'),
          completes,
        );

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects.any((p) => p.id == 'p1'), isFalse);
      });
    });

    group('refresh', () {
      test('refresh triggers invalidateSelf and rebuilds provider', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        // Initial fetch
        await container.read(projectsProvider.future);
        verify(() => mockLocalDB.getAllProjects()).called(1);

        // Call refresh
        await container.read(projectsProvider.notifier).refresh();

        // Second fetch
        await container.read(projectsProvider.future);
        verify(() => mockLocalDB.getAllProjects()).called(1);
      });
    });
  });
}
