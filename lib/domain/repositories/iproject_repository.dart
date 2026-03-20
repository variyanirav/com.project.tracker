import '../entities/project_entity.dart';

/// Abstract repository for project operations
/// Defines the contract that data repositories must implement for project management
abstract class IProjectRepository {
  /// Get all projects
  /// [status] - optional filter by project status (active, complete, paused)
  Future<List<ProjectEntity>> getProjects({String? status});

  /// Get single project by ID
  Future<ProjectEntity?> getProjectById(String id);

  /// Create new project
  /// [name] - project name
  /// [description] - optional project description
  /// [color] - optional color/emoji for the project
  Future<ProjectEntity> createProject({
    required String name,
    required String? description,
    required String? color,
  });

  /// Update existing project
  Future<void> updateProject(ProjectEntity project);

  /// Delete project (also deletes all tasks and sessions)
  Future<void> deleteProject(String id);

  /// Get projects created on a specific date
  Future<List<ProjectEntity>> getProjectsByDate(DateTime date);

  /// Get projects created within a date range
  Future<List<ProjectEntity>> getProjectsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Update project status
  /// [projectId] - the project to update
  /// [newStatus] - the new status (active, complete, paused)
  Future<void> updateProjectStatus(String projectId, String newStatus);

  /// Get total hours spent on a project (sum of all task hours)
  Future<double> getProjectTotalHours(String projectId);

  /// Get total seconds spent on a project
  Future<int> getProjectTotalSeconds(String projectId);

  /// Get today's total hours for a project
  Future<double> getProjectTodayHours(String projectId);

  /// Get this week's total hours for a project
  Future<double> getProjectWeekHours(String projectId);

  /// Get all active projects (status = 'active')
  Future<List<ProjectEntity>> getActiveProjects();

  /// Get all completed projects (status = 'complete')
  Future<List<ProjectEntity>> getCompletedProjects();

  /// Get all paused projects (status = 'paused')
  Future<List<ProjectEntity>> getPausedProjects();

  /// Archive project (soft delete)
  Future<void> archiveProject(String id);

  /// Unarchive project
  Future<void> unarchiveProject(String id);

  /// Get archived projects
  Future<List<ProjectEntity>> getArchivedProjects();

  /// Search projects by name
  Future<List<ProjectEntity>> searchProjectsByName(String query);

  /// Get project count
  Future<int> getProjectCount();

  /// Get only today's projects (created or modified today)
  Future<List<ProjectEntity>> getTodayProjects();

  /// Get only this week's projects (created or modified this week)
  Future<List<ProjectEntity>> getWeekProjects();

  /// Export project data for backup
  /// Returns a JSON-serializable map
  Future<Map<String, dynamic>> exportProjectData(String projectId);

  /// Check if project exists
  Future<bool> projectExists(String id);
}
