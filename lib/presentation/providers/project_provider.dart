import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/project_entity.dart';
import 'repository_provider.dart';

/// Provider for list of all active projects
final projectsProvider = FutureProvider<List<ProjectEntity>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProjects();
});

/// Provider for getting a specific project by ID
final projectByIdProvider = FutureProvider.family<ProjectEntity?, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProjectById(projectId);
});

/// Provider for getting projects filtered by status
final projectsByStatusProvider =
    FutureProvider.family<List<ProjectEntity>, String>((ref, status) async {
      final allProjects = await ref.watch(projectsProvider.future);
      return allProjects.where((p) => p.status == status).toList();
    });

/// Provider for archived projects
final archivedProjectsProvider = FutureProvider<List<ProjectEntity>>((ref) {
  return ref.watch(projectsByStatusProvider('archived').future);
});

/// Provider for getting total hours tracked per project
final projectTotalHoursProvider = FutureProvider.family<double, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProjectTotalHours(projectId);
});

/// Provider for project today's hours
final projectTodayHoursProvider = FutureProvider.family<double, String>((
  ref,
  projectId,
) async {
  // TODO: Calculate today's hours from timer sessions
  // Currently, this would require querying timer sessions filtered by date
  // For now, return 0 as a placeholder
  return 0.0;
});

/// Provider for project this week's hours
final projectWeekHoursProvider = FutureProvider.family<double, String>((
  ref,
  projectId,
) async {
  // Similar to today's hours, we would filter timer sessions by week
  // For now, we can use the total as a placeholder
  return await ref.watch(projectTotalHoursProvider(projectId).future);
});

/// Provider for creating a new project
final createProjectProvider = FutureProvider.family<void, CreateProjectParams>((
  ref,
  params,
) async {
  final repository = ref.watch(projectRepositoryProvider);

  await repository.createProject(
    name: params.name,
    description: params.description,
    color: params.color,
  );

  // Invalidate the projects list to refresh it
  ref.invalidate(projectsProvider);
});

/// Provider for updating a project
final updateProjectProvider = FutureProvider.family<void, UpdateProjectParams>((
  ref,
  params,
) async {
  final repository = ref.watch(projectRepositoryProvider);

  final updatedProject = ProjectEntity(
    id: params.id,
    name: params.name,
    description: params.description,
    color: params.color,
    status: params.status,
    createdAt: params.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );

  await repository.updateProject(updatedProject);

  // Invalidate related providers
  ref.invalidate(projectsProvider);
  ref.invalidate(projectByIdProvider(params.id));
});

/// Provider for deleting a project
final deleteProjectProvider = FutureProvider.family<void, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(projectRepositoryProvider);
  await repository.deleteProject(projectId);

  // Invalidate related providers
  ref.invalidate(projectsProvider);
  ref.invalidate(projectByIdProvider(projectId));
});

/// Provider for archiving a project
final archiveProjectProvider = FutureProvider.family<void, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(projectRepositoryProvider);

  await repository.archiveProject(projectId);
  ref.invalidate(projectsProvider);
  ref.invalidate(projectByIdProvider(projectId));
});

/// Provider for unarchiving a project
final unarchiveProjectProvider = FutureProvider.family<void, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(projectRepositoryProvider);

  await repository.unarchiveProject(projectId);
  ref.invalidate(projectsProvider);
  ref.invalidate(projectByIdProvider(projectId));
});

/// Provider for project count
final projectCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProjectCount();
});

/// Parameters for creating a project
class CreateProjectParams {
  final String name;
  final String? description;
  final String color;

  CreateProjectParams({
    required this.name,
    this.description,
    required this.color,
  });
}

/// Parameters for updating a project
class UpdateProjectParams {
  final String id;
  final String name;
  final String? description;
  final String color;
  final String status;
  final DateTime createdAt;

  UpdateProjectParams({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.status,
    required this.createdAt,
  });
}
