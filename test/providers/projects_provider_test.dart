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

    final projectA = Project(id: 'p1', clientId: 'c1', name: 'Project A', updatedAt: '2023-01-01T00:00:00.000Z');
    final projectB = Project(id: 'p2', clientId: 'c2', name: 'Project B', updatedAt: '2023-01-01T00:00:00.000Z');

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

    test('build handles database fetch failure and transitions to AsyncError state', () async {
      when(() => mockLocalDB.getAllProjects()).thenThrow(Exception('DB Fetch Error'));

      final container = createContainer();

      try {
        await container.read(projectsProvider.future);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      final stateWithError = container.read(projectsProvider);
      expect(stateWithError.hasError, isTrue);
      expect(stateWithError.error, isA<Exception>());
    });

    group('addProject', () {
      test('adds project successfully and triggers sync and backup', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c3', name: 'Project C');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        final result = await container.read(projectsProvider.notifier).addProject(newProject);

        expect(result, equals(newProject));
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify notifier state is updated
        final updatedProjects = await container.read(projectsProvider.future);
        expect(updatedProjects, contains(newProject));
        expect(updatedProjects.length, equals(3));
      });

      test('handles database insertion failure gracefully (rethrows, no backup/sync)', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c3', name: 'Project C');

        when(() => mockLocalDB.insertProject(any())).thenThrow(Exception('DB Write Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).addProject(newProject),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verifyNever(() => mockSync.syncPendingProjects());
        verifyNever(() => mockBackup.triggerBackup());
      });

      test('handles sync failure gracefully and still updates state/triggers backup', () async {
        final container = createContainer();
        final newProject = Project(id: 'p3', clientId: 'c3', name: 'Project C');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync Network Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        final result = await container.read(projectsProvider.notifier).addProject(newProject);

        expect(result, equals(newProject));
        verify(() => mockLocalDB.insertProject(newProject)).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify local state gets updated
        final list = await container.read(projectsProvider.future);
        expect(list, contains(newProject));
      });
    });

    group('updateProject', () {
      test('updates project locally with synced=false and updated timestamp, then triggers sync/backup', () async {
        final container = createContainer();
        final updatedProjectInput = projectA.copyWith(name: 'Project A Updated');

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).updateProject(updatedProjectInput);

        final captured = verify(() => mockLocalDB.updateProject(captureAny())).captured.first as Project;
        expect(captured.id, equals(projectA.id));
        expect(captured.name, equals('Project A Updated'));
        expect(captured.synced, isFalse);
        expect(captured.updatedAt, isNot(equals(projectA.updatedAt)));

        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify state is updated
        final list = await container.read(projectsProvider.future);
        expect(list.any((p) => p.name == 'Project A Updated'), isTrue);
      });

      test('handles local DB failure by throwing (no sync/backup)', () async {
        final container = createContainer();
        final updatedProjectInput = projectA.copyWith(name: 'Project A Updated');

        when(() => mockLocalDB.updateProject(any())).thenThrow(Exception('DB Write Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).updateProject(updatedProjectInput),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.updateProject(any())).called(1);
        verifyNever(() => mockSync.syncPendingProjects());
        verifyNever(() => mockBackup.triggerBackup());
      });

      test('handles sync failure gracefully and still updates state/triggers backup', () async {
        final container = createContainer();
        final updatedProjectInput = projectA.copyWith(name: 'Project A Updated');

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync Network Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).updateProject(updatedProjectInput);

        verify(() => mockLocalDB.updateProject(any())).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify state is updated
        final list = await container.read(projectsProvider.future);
        expect(list.any((p) => p.name == 'Project A Updated'), isTrue);
      });
    });

    group('deleteProject', () {
      test('soft-deletes project in local DB, then triggers sync/backup', () async {
        final container = createContainer();

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).deleteProject('p1');

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify list is updated
        final list = await container.read(projectsProvider.future);
        expect(list.any((p) => p.id == 'p1'), isFalse);
      });

      test('handles local DB soft-delete failure by throwing (no sync/backup)', () async {
        final container = createContainer();

        when(() => mockLocalDB.softDeleteProject(any())).thenThrow(Exception('DB Write Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await expectLater(
          container.read(projectsProvider.notifier).deleteProject('p1'),
          throwsA(isA<Exception>()),
        );

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verifyNever(() => mockSync.syncPendingProjects());
        verifyNever(() => mockBackup.triggerBackup());
      });

      test('handles sync failure gracefully and still updates state/triggers backup', () async {
        final container = createContainer();

        when(() => mockSync.syncPendingProjects()).thenThrow(Exception('Sync Network Error'));

        container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

        await container.read(projectsProvider.notifier).deleteProject('p1');

        verify(() => mockLocalDB.softDeleteProject('p1')).called(1);
        verify(() => mockSync.syncPendingProjects()).called(1);
        verify(() => mockBackup.triggerBackup()).called(1);

        // Verify list is updated
        final list = await container.read(projectsProvider.future);
        expect(list.any((p) => p.id == 'p1'), isFalse);
      });
    });

    test('refresh invalidates the provider self-state', () async {
      final container = createContainer();

      container.listen<AsyncValue<List<Project>>>(projectsProvider, (_, __) {});

      // Initial read of future
      await container.read(projectsProvider.future);

      // Call refresh
      await container.read(projectsProvider.notifier).refresh();

      // Read again to await the new evaluation
      await container.read(projectsProvider.future);

      // Verify mockLocalDB.getAllProjects was called again (at least 2 times: once on initial load, once on refresh)
      verify(() => mockLocalDB.getAllProjects()).called(greaterThan(1));
    });
  });
}
