import '../entities/task_entity.dart';

/// Abstract repository for task operations
/// Defines the contract that data repositories must implement for task management
abstract class ITaskRepository {
  /// Get all tasks for a specific project
  /// [projectId] - the project ID to fetch tasks for
  /// [status] - optional filter by task status
  Future<List<TaskEntity>> getTasksByProject(
    String projectId, {
    String? status,
  });

  /// Get all tasks across all projects
  Future<List<TaskEntity>> getAllTasks({String? status});

  /// Get single task by ID
  Future<TaskEntity?> getTaskById(String id);

  /// Get tasks for a specific day
  Future<List<TaskEntity>> getTasksByDate(DateTime date);

  /// Create new task
  Future<TaskEntity> createTask({
    required String projectId,
    required String taskName,
    required String? description,
  });

  /// Update existing task
  Future<void> updateTask(TaskEntity task);

  /// Delete task
  Future<void> deleteTask(String id);

  /// Update task status
  /// [taskId] - the task to update
  /// [newStatus] - the new status (todo, inProgress, inReview, onHold, complete)
  Future<void> updateTaskStatus(String taskId, String newStatus);

  /// Update task's total time spent
  /// [taskId] - the task to update
  /// [totalSeconds] - new cumulative seconds
  Future<void> updateTaskTotalSeconds(String taskId, int totalSeconds);

  /// Change task's running state
  /// [taskId] - the task to update
  /// [isRunning] - whether timer is currently running
  /// [lastSessionId] - if running, the current timer session ID
  Future<void> updateTaskRunningState(
    String taskId,
    bool isRunning, {
    String? lastSessionId,
  });

  /// Get all running tasks (isRunning = true)
  Future<List<TaskEntity>> getRunningTasks();

  /// Get all tasks in a specific status
  Future<List<TaskEntity>> getTasksByStatus(String status);

  /// Get today's tasks
  /// Tasks created/modified today
  Future<List<TaskEntity>> getTodayTasks();

  /// Get tasks by duration range
  /// [minSeconds] - minimum duration
  /// [maxSeconds] - maximum duration
  Future<List<TaskEntity>> getTasksByDurationRange(
    int minSeconds,
    int maxSeconds,
  );

  /// Get total hours spent on a task across all sessions
  Future<double> getTaskTotalHours(String taskId);

  /// Get total hours spent on a project (sum of all task hours)
  Future<double> getProjectTotalHours(String projectId);

  /// Get tasks created within a date range
  Future<List<TaskEntity>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Archive task (soft delete)
  Future<void> archiveTask(String id);

  /// Unarchive task
  Future<void> unarchiveTask(String id);

  /// Get archived tasks for a project
  Future<List<TaskEntity>> getArchivedTasksByProject(String projectId);
}
