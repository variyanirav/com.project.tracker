import '../entities/project_entity.dart';

/// Abstract repository for project operations
/// Defines the contract that data repositories must implement
abstract class IProjectRepository {
  /// Get all projects
  Future<List<ProjectEntity>> getProjects();

  /// Get single project by ID
  Future<ProjectEntity?> getProjectById(String id);

  /// Create new project
  Future<ProjectEntity> createProject({
    required String name,
    required String? description,
    required String? color,
  });

  /// Update existing project
  Future<void> updateProject(ProjectEntity project);

  /// Delete project
  Future<void> deleteProject(String id);

  /// Get projects for specific date
  Future<List<ProjectEntity>> getProjectsByDate(DateTime date);

  /// Archive project
  Future<void> archiveProject(String id);

  /// Unarchive project
  Future<void> unarchiveProject(String id);
}
