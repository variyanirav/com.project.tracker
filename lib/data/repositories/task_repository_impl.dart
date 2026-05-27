import 'package:project_tracker/domain/repositories/itask_repository.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/time_aggregator.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Concrete implementation of ITaskRepository
/// Handles all task data operations using AppDatabase
class TaskRepositoryImpl implements ITaskRepository {
  final AppDatabase db;

  TaskRepositoryImpl(this.db);

  @override
  Future<List<TaskEntity>> getTasksByProject(
    String projectId, {
    String? status,
  }) async {
    final tasks = await db.tasksDao.getTasksByProject(projectId);
    if (status != null) {
      return tasks.where((t) => t.status == status).map(_toEntity).toList();
    }
    return tasks.map(_toEntity).toList();
  }

  @override
  Future<List<TaskEntity>> getDeletedTasksByProject(String projectId) async {
    final tasks = await db.tasksDao.getDeletedTasksByProject(projectId);
    return tasks.map(_toEntity).toList();
  }

  @override
  Future<List<TaskEntity>> getAllTasks({String? status}) async {
    final tasks = await (db.select(
      db.tasks,
    )..where((t) => t.deletedAt.isNull())).get();
    if (status != null) {
      return tasks.where((t) => t.status == status).map(_toEntity).toList();
    }
    return tasks.map(_toEntity).toList();
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    final task = await db.tasksDao.getTaskById(id);
    return task != null ? _toEntity(task) : null;
  }

  @override
  Future<List<TaskEntity>> getTasksByDate(DateTime date) async {
    final tasks = await (db.select(
      db.tasks,
    )..where((t) => t.deletedAt.isNull())).get();
    return tasks
        .where((t) => TimezoneHelper.isSameDay(t.createdAt, date))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<TaskEntity> createTask({
    required String projectId,
    String? categoryId,
    required String taskName,
    required String? description,
    double? estimatedHours,
    bool isBillable = true,
  }) async {
    final id = const Uuid().v4();
    final now = TimezoneHelper.getCurrentUtc();

    final task = TaskData(
      id: id,
      projectId: projectId,
      categoryId: categoryId ?? AppDatabase.uncategorizedCategoryId,
      taskName: taskName,
      description: description ?? '',
      estimatedHours: estimatedHours,
      status: 'todo',
      isBillable: isBillable,
      totalSeconds: 0,
      isRunning: false,
      lastStartedAt: null,
      lastSessionId: null,
      deletedAt: null,
      deletedStatus: null,
      createdAt: now,
      updatedAt: now,
    );

    await db.tasksDao.createTask(task);
    return _toEntity(task);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final data = TaskData(
      id: task.id,
      projectId: task.projectId,
      categoryId: task.categoryId ?? AppDatabase.uncategorizedCategoryId,
      taskName: task.taskName,
      description: task.description ?? '',
      estimatedHours: task.estimatedHours,
      status: task.status,
      isBillable: task.isBillable,
      totalSeconds: task.totalSeconds,
      isRunning: task.isRunning,
      lastStartedAt: task.lastStartedAt,
      lastSessionId: task.lastSessionId,
      deletedAt: task.deletedAt,
      deletedStatus: task.deletedStatus,
      createdAt: task.createdAt,
      updatedAt: TimezoneHelper.getCurrentUtc(),
    );

    await db.tasksDao.updateTask(data);
  }

  @override
  Future<void> deleteTask(String id) async {
    await db.tasksDao.deleteTask(id);
  }

  @override
  Future<void> permanentlyDeleteTask(String id) async {
    await db.tasksDao.permanentlyDeleteTask(id);
  }

  @override
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await db.tasksDao.updateTaskStatus(taskId, newStatus);
  }

  @override
  Future<void> updateTaskTotalSeconds(String taskId, int totalSeconds) async {
    await db.tasksDao.updateTaskTotalSeconds(taskId, totalSeconds);
  }

  @override
  Future<void> updateTaskRunningState(
    String taskId,
    bool isRunning, {
    String? lastSessionId,
  }) async {
    final task = await db.tasksDao.getTaskById(taskId);
    if (task == null) return;

    await db.tasksDao.updateTask(
      task.copyWith(
        isRunning: isRunning,
        lastStartedAt: Value(isRunning ? TimezoneHelper.getCurrentUtc() : null),
        lastSessionId: Value(lastSessionId),
        updatedAt: TimezoneHelper.getCurrentUtc(),
      ),
    );
  }

  @override
  Future<List<TaskEntity>> getRunningTasks() async {
    final tasks = await (db.select(
      db.tasks,
    )..where((t) => t.isRunning.equals(true) & t.deletedAt.isNull())).get();
    return tasks.map(_toEntity).toList();
  }

  @override
  Future<List<TaskEntity>> getTasksByStatus(String status) async {
    // Filter all tasks by status
    final allTasks = await getAllTasks(status: status);
    return allTasks;
  }

  @override
  Future<List<TaskEntity>> getTodayTasks() async {
    final today = TimezoneHelper.getTodayStartUtc();
    return getTasksByDate(today);
  }

  @override
  Future<List<TaskEntity>> getTasksByDurationRange(
    int minSeconds,
    int maxSeconds,
  ) async {
    final tasks = await (db.select(
      db.tasks,
    )..where((t) => t.deletedAt.isNull())).get();
    return tasks
        .where(
          (t) => t.totalSeconds >= minSeconds && t.totalSeconds <= maxSeconds,
        )
        .map(_toEntity)
        .toList();
  }

  @override
  Future<double> getTaskTotalHours(String taskId) async {
    final sessions = await db.timerSessionsDao.getSessionsByTask(taskId);
    return TimeAggregator.sumSessionHours(sessions);
  }

  @override
  Future<double> getProjectTotalHours(String projectId) async {
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return TimeAggregator.sumSessionHours(sessions);
  }

  @override
  Future<List<TaskEntity>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final tasks = await (db.select(
      db.tasks,
    )..where((t) => t.deletedAt.isNull())).get();
    return tasks
        .where(
          (t) =>
              (t.createdAt.isAfter(startDate) &&
                  t.createdAt.isBefore(endDate)) ||
              TimezoneHelper.isSameDay(t.createdAt, startDate) ||
              TimezoneHelper.isSameDay(t.createdAt, endDate),
        )
        .map(_toEntity)
        .toList();
  }

  @override
  Future<void> archiveTask(String id) async {
    await updateTaskStatus(id, 'archived');
  }

  @override
  Future<void> unarchiveTask(String id) async {
    await updateTaskStatus(id, 'complete');
  }

  @override
  Future<void> restoreDeletedTask(String id) async {
    await db.tasksDao.restoreDeletedTask(id);
  }

  @override
  Future<List<TaskEntity>> getArchivedTasksByProject(String projectId) async {
    final tasks = await getTasksByProject(projectId, status: 'archived');
    return tasks;
  }

  @override
  Future<List<TaskEntity>> searchActiveTasksByProject(
    String projectId,
    String query,
  ) async {
    return _searchTasksByProject(
      projectId: projectId,
      query: query,
      deletedOnly: false,
      statusFilter: 'archived',
      excludeStatus: true,
    );
  }

  @override
  Future<List<TaskEntity>> searchArchivedTasksByProject(
    String projectId,
    String query,
  ) async {
    return _searchTasksByProject(
      projectId: projectId,
      query: query,
      deletedOnly: false,
      statusFilter: 'archived',
    );
  }

  @override
  Future<List<TaskEntity>> searchDeletedTasksByProject(
    String projectId,
    String query,
  ) async {
    return _searchTasksByProject(
      projectId: projectId,
      query: query,
      deletedOnly: true,
    );
  }

  /// Helper: Convert database TaskData to domain TaskEntity
  TaskEntity _toEntity(TaskData data) {
    return TaskEntity(
      id: data.id,
      projectId: data.projectId,
      categoryId: data.categoryId,
      taskName: data.taskName,
      description: (data.description?.isNotEmpty ?? false)
          ? data.description
          : null,
      estimatedHours: data.estimatedHours,
      status: data.status,
      isBillable: data.isBillable,
      totalSeconds: data.totalSeconds,
      isRunning: data.isRunning,
      lastStartedAt: data.lastStartedAt,
      lastSessionId: data.lastSessionId,
      deletedAt: data.deletedAt,
      deletedStatus: data.deletedStatus,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  Future<List<TaskEntity>> _searchTasksByProject({
    required String projectId,
    required String query,
    required bool deletedOnly,
    String? statusFilter,
    bool excludeStatus = false,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final likeQuery = '%$normalizedQuery%';

    final rows = await db
        .customSelect(
          '''
      SELECT
        id,
        project_id,
        category_id,
        task_name,
        description,
        estimated_hours,
        status,
        is_billable,
        total_seconds,
        is_running,
        last_started_at,
        last_session_id,
        deleted_at,
        deleted_status,
        created_at,
        updated_at
      FROM tasks
      WHERE project_id = ?
        AND ${deletedOnly ? 'deleted_at IS NOT NULL' : 'deleted_at IS NULL'}
        ${statusFilter != null ? (excludeStatus ? 'AND status != ?' : 'AND status = ?') : ''}
        AND (
          lower(task_name) LIKE ? OR
          lower(COALESCE(description, '')) LIKE ? OR
          lower(status) LIKE ? OR
          lower(COALESCE(deleted_status, '')) LIKE ?
        )
      ORDER BY created_at DESC
      ''',
          variables: [
            Variable.withString(projectId),
            if (statusFilter != null) Variable.withString(statusFilter),
            Variable.withString(likeQuery),
            Variable.withString(likeQuery),
            Variable.withString(likeQuery),
            Variable.withString(likeQuery),
          ],
        )
        .get();

    return rows.map(_taskFromRow).toList();
  }

  TaskEntity _taskFromRow(QueryRow row) {
    return TaskEntity(
      id: row.read<String>('id'),
      projectId: row.read<String>('project_id'),
      categoryId: row.readNullable<String>('category_id'),
      taskName: row.read<String>('task_name'),
      description:
          row.readNullable<String>('description')?.trim().isNotEmpty == true
          ? row.readNullable<String>('description')
          : null,
      estimatedHours: row.readNullable<double>('estimated_hours'),
      status: row.read<String>('status'),
      isBillable: row.read<bool>('is_billable'),
      totalSeconds: row.read<int>('total_seconds'),
      isRunning: row.read<bool>('is_running'),
      lastStartedAt: row.readNullable<DateTime>('last_started_at'),
      lastSessionId: row.readNullable<String>('last_session_id'),
      deletedAt: row.readNullable<DateTime>('deleted_at'),
      deletedStatus: row.readNullable<String>('deleted_status'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}
