import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'core_providers.dart';

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    return ref.watch(localDBServiceProvider).getAllProjects();
  }

  /// Adds a new project: saves locally and pushes to remote sync.
  Future<Project> addProject(Project project) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    await db.insertProject(project);
    try {
      await sync.syncPendingProjects();
    } catch (_) {}
    ref.invalidateSelf();
    await ref.read(backupServiceProvider).triggerBackup();
    return project;
  }

  /// Updates an existing project (e.g. rename) and syncs.
  Future<void> updateProject(Project project) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    // Mark as needing sync by bumping updatedAt and clearing synced flag.
    final updated = project.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
      synced: false,
    );
    await db.updateProject(updated);
    try {
      await sync.syncPendingProjects();
    } catch (_) {}
    ref.invalidateSelf();
    await ref.read(backupServiceProvider).triggerBackup();
  }

  /// Soft-deletes a project so the deletion propagates to remote on sync.
  Future<void> deleteProject(String id) async {
    final db = ref.read(localDBServiceProvider);
    final sync = ref.read(syncServiceProvider);
    await db.softDeleteProject(id);
    try {
      await sync.syncPendingProjects();
    } catch (_) {}
    ref.invalidateSelf();
    await ref.read(backupServiceProvider).triggerBackup();
  }

  Future<void> refresh() => Future(() => ref.invalidateSelf());
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(ProjectsNotifier.new);
