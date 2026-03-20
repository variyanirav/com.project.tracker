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
  Future<List<TaskEntity>> getAllTasks({String? status}) async {
    final tasks = await (db.select(db.tasks)).get();
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
    final tasks = await (db.select(db.tasks)).get();
    return tasks
        .where((t) => TimezoneHelper.isSameDay(t.createdAt, date))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<TaskEntity> createTask({
    required String projectId,
    required String taskName,
    required String? description,
  }) async {
    final id = const Uuid().v4();
    final now = TimezoneHelper.getCurrentUtc();

    final task = TaskData(
      id: id,
      projectId: projectId,
      taskName: taskName,
      description: description ?? '',
      status: 'todo',
      totalSeconds: 0,
      isRunning: false,
      lastStartedAt: null,
      lastSessionId: null,
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
      taskName: task.taskName,
      description: task.description ?? '',
      status: task.status,
      totalSeconds: task.totalSeconds,
      isRunning: task.isRunning,
      lastStartedAt: task.lastStartedAt,
      lastSessionId: task.lastSessionId,
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
    )..where((t) => t.isRunning.equals(true))).get();
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
    final tasks = await (db.select(db.tasks)).get();
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
    final tasks = await (db.select(db.tasks)).get();
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
    await updateTaskStatus(id, 'todo');
  }

  @override
  Future<List<TaskEntity>> getArchivedTasksByProject(String projectId) async {
    final tasks = await getTasksByProject(projectId, status: 'archived');
    return tasks;
  }

  /// Helper: Convert database TaskData to domain TaskEntity
  TaskEntity _toEntity(TaskData data) {
    return TaskEntity(
      id: data.id,
      projectId: data.projectId,
      taskName: data.taskName,
      description: (data.description?.isNotEmpty ?? false)
          ? data.description
          : null,
      status: data.status,
      totalSeconds: data.totalSeconds,
      isRunning: data.isRunning,
      lastStartedAt: data.lastStartedAt,
      lastSessionId: data.lastSessionId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}
