import 'package:project_tracker/domain/repositories/iproject_repository.dart';
import 'package:project_tracker/domain/entities/project_entity.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/time_aggregator.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:uuid/uuid.dart';

/// Concrete implementation of IProjectRepository
/// Handles all project data operations using AppDatabase
class ProjectRepositoryImpl implements IProjectRepository {
  final AppDatabase db;

  ProjectRepositoryImpl(this.db);

  @override
  Future<List<ProjectEntity>> getProjects({String? status}) async {
    final projects = await db.projectsDao.getAllProjects();
    if (status != null) {
      return projects.where((p) => p.status == status).map(_toEntity).toList();
    }
    return projects.map(_toEntity).toList();
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    final project = await db.projectsDao.getProjectById(id);
    return project != null ? _toEntity(project) : null;
  }

  @override
  Future<ProjectEntity> createProject({
    required String name,
    required String? description,
    required String? color,
  }) async {
    final id = const Uuid().v4();
    final now = TimezoneHelper.getCurrentUtc();

    final project = ProjectData(
      id: id,
      name: name,
      description: description ?? '',
      avatarEmoji: color ?? '📱',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    await db.projectsDao.createProject(project);
    return _toEntity(project);
  }

  @override
  Future<void> updateProject(ProjectEntity project) async {
    final data = ProjectData(
      id: project.id,
      name: project.name,
      description: project.description ?? '',
      avatarEmoji: project.color ?? '📱',
      status: project.status,
      createdAt: project.createdAt,
      updatedAt: TimezoneHelper.getCurrentUtc(),
    );

    await db.projectsDao.updateProject(data);
  }

  @override
  Future<void> deleteProject(String id) async {
    await db.projectsDao.deleteProject(id);
  }

  @override
  Future<List<ProjectEntity>> getProjectsByDate(DateTime date) async {
    final projects = await db.projectsDao.getAllProjects();
    return projects
        .where((p) => TimezoneHelper.isSameDay(p.createdAt, date))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<List<ProjectEntity>> getProjectsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final projects = await db.projectsDao.getAllProjects();
    return projects
        .where(
          (p) =>
              (p.createdAt.isAfter(startDate) &&
                  p.createdAt.isBefore(endDate)) ||
              TimezoneHelper.isSameDay(p.createdAt, startDate) ||
              TimezoneHelper.isSameDay(p.createdAt, endDate),
        )
        .map(_toEntity)
        .toList();
  }

  @override
  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    final project = await db.projectsDao.getProjectById(projectId);
    if (project == null) return;

    final updated = project.copyWith(
      status: newStatus,
      updatedAt: TimezoneHelper.getCurrentUtc(),
    );
    await db.projectsDao.updateProject(updated);
  }

  @override
  Future<double> getProjectTotalHours(String projectId) async {
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return TimeAggregator.sumSessionHours(sessions);
  }

  @override
  Future<int> getProjectTotalSeconds(String projectId) async {
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return TimeAggregator.sumSessionDurations(sessions);
  }

  @override
  Future<double> getProjectTodayHours(String projectId) async {
    final today = TimezoneHelper.getTodayStartUtc();
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return TimeAggregator.calculateDailyHours(sessions, today);
  }

  @override
  Future<double> getProjectWeekHours(String projectId) async {
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return TimeAggregator.calculateWeeklyHours(sessions);
  }

  @override
  Future<List<ProjectEntity>> getActiveProjects() async {
    return getProjects(status: 'active');
  }

  @override
  Future<List<ProjectEntity>> getCompletedProjects() async {
    return getProjects(status: 'complete');
  }

  @override
  Future<List<ProjectEntity>> getPausedProjects() async {
    return getProjects(status: 'paused');
  }

  @override
  Future<void> archiveProject(String id) async {
    await updateProjectStatus(id, 'archived');
  }

  @override
  Future<void> unarchiveProject(String id) async {
    await updateProjectStatus(id, 'active');
  }

  @override
  Future<List<ProjectEntity>> getArchivedProjects() async {
    return getProjects(status: 'archived');
  }

  @override
  Future<List<ProjectEntity>> searchProjectsByName(String query) async {
    final projects = await db.projectsDao.getAllProjects();
    final lowerQuery = query.toLowerCase();
    return projects
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<int> getProjectCount() async {
    final projects = await db.projectsDao.getAllProjects();
    return projects.length;
  }

  @override
  Future<List<ProjectEntity>> getTodayProjects() async {
    return getProjectsByDate(TimezoneHelper.getTodayStartUtc());
  }

  @override
  Future<List<ProjectEntity>> getWeekProjects() async {
    final weekStart = TimezoneHelper.getWeekStartUtc();
    final weekEnd = TimezoneHelper.getWeekEndUtc();
    return getProjectsByDateRange(weekStart, weekEnd);
  }

  @override
  Future<Map<String, dynamic>> exportProjectData(String projectId) async {
    final project = await getProjectById(projectId);
    if (project == null) return {};

    final totalHours = await getProjectTotalHours(projectId);
    final totalSeconds = await getProjectTotalSeconds(projectId);

    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'color': project.color,
      'status': project.status,
      'totalHours': totalHours,
      'totalSeconds': totalSeconds,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<bool> projectExists(String id) async {
    final project = await db.projectsDao.getProjectById(id);
    return project != null;
  }

  /// Helper: Convert database ProjectData to domain ProjectEntity
  ProjectEntity _toEntity(ProjectData data) {
    return ProjectEntity(
      id: data.id,
      name: data.name,
      description: (data.description?.isNotEmpty ?? false)
          ? data.description
          : null,
      color: data.avatarEmoji,
      status: data.status,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}
