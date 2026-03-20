import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'repository_provider.dart';

/// Provider for list of all tasks
final tasksProvider = FutureProvider<List<TaskEntity>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getAllTasks();
});

/// Provider for tasks filtered by project
final tasksByProjectProvider = FutureProvider.family<List<TaskEntity>, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getTasksByProject(projectId);
});

/// Provider for tasks filtered by status
final tasksByStatusProvider = FutureProvider.family<List<TaskEntity>, String>((
  ref,
  status,
) async {
  final allTasks = await ref.watch(tasksProvider.future);
  return allTasks.where((t) => t.status == status).toList();
});

/// Provider for active/running task
final activeTaskProvider = FutureProvider<TaskEntity?>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final allTasks = await repository.getAllTasks();

  // Find the currently running task
  try {
    return allTasks.firstWhere((t) => t.isRunning);
  } catch (e) {
    return null;
  }
});

/// Provider for archived tasks
final archivedTasksProvider = FutureProvider<List<TaskEntity>>((ref) {
  return ref.watch(tasksByStatusProvider('archived').future);
});

/// Provider for completed tasks
final completedTasksProvider = FutureProvider<List<TaskEntity>>((ref) {
  return ref.watch(tasksByStatusProvider('complete').future);
});

/// Provider for in-progress tasks
final inProgressTasksProvider = FutureProvider<List<TaskEntity>>((ref) {
  return ref.watch(tasksByStatusProvider('inProgress').future);
});

/// Provider for getting a specific task by ID
final taskByIdProvider = FutureProvider.family<TaskEntity?, String>((
  ref,
  taskId,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getTaskById(taskId);
});

/// Provider for creating a new task
final createTaskProvider = FutureProvider.family<void, CreateTaskParams>((
  ref,
  params,
) async {
  final repository = ref.watch(taskRepositoryProvider);

  await repository.createTask(
    projectId: params.projectId,
    taskName: params.taskName,
    description: params.description,
  );

  // Invalidate related providers
  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
});

/// Provider for updating a task
final updateTaskProvider = FutureProvider.family<void, UpdateTaskParams>((
  ref,
  params,
) async {
  final repository = ref.watch(taskRepositoryProvider);

  final updatedTask = TaskEntity(
    id: params.id,
    projectId: params.projectId,
    taskName: params.taskName,
    description: params.description,
    status: params.status,
    totalSeconds: params.totalSeconds,
    isRunning: params.isRunning,
    lastStartedAt: params.lastStartedAt,
    lastSessionId: params.lastSessionId,
    createdAt: params.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );

  await repository.updateTask(updatedTask);

  // Invalidate related providers
  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
  ref.invalidate(taskByIdProvider(params.id));
});

/// Provider for deleting a task
final deleteTaskProvider = FutureProvider.family<void, DeleteTaskParams>((
  ref,
  params,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  await repository.deleteTask(params.taskId);

  // Invalidate related providers
  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
  ref.invalidate(taskByIdProvider(params.taskId));
});

/// Provider for updating task status
final updateTaskStatusProvider =
    FutureProvider.family<void, UpdateTaskStatusParams>((ref, params) async {
      final repository = ref.watch(taskRepositoryProvider);
      await repository.updateTaskStatus(params.taskId, params.status);

      // Invalidate related providers
      ref.invalidate(tasksProvider);
      ref.invalidate(taskByIdProvider(params.taskId));
    });

/// Provider for updating task running state
final updateTaskRunningStateProvider =
    FutureProvider.family<void, UpdateTaskRunningStateParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(taskRepositoryProvider);
      await repository.updateTaskRunningState(
        params.taskId,
        params.isRunning,
        lastSessionId: params.lastSessionId,
      );

      // Invalidate related providers
      ref.invalidate(tasksProvider);
      ref.invalidate(activeTaskProvider);
      ref.invalidate(taskByIdProvider(params.taskId));
    });

/// Provider for getting tasks by date range
final tasksByDateRangeProvider =
    FutureProvider.family<List<TaskEntity>, DateRangeParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(taskRepositoryProvider);
      return await repository.getTasksByDateRange(
        params.startDate,
        params.endDate,
      );
    });

/// Provider for task count (not available in interface - using list length)
final taskCountProvider = FutureProvider<int>((ref) async {
  final allTasks = await ref.watch(tasksProvider.future);
  return allTasks.length;
});

/// Parameters for creating a task
class CreateTaskParams {
  final String projectId;
  final String taskName;
  final String? description;

  CreateTaskParams({
    required this.projectId,
    required this.taskName,
    this.description,
  });
}

/// Parameters for updating a task
class UpdateTaskParams {
  final String id;
  final String projectId;
  final String taskName;
  final String? description;
  final String status;
  final int totalSeconds;
  final bool isRunning;
  final DateTime? lastStartedAt;
  final String? lastSessionId;
  final DateTime createdAt;

  UpdateTaskParams({
    required this.id,
    required this.projectId,
    required this.taskName,
    this.description,
    required this.status,
    required this.totalSeconds,
    required this.isRunning,
    this.lastStartedAt,
    this.lastSessionId,
    required this.createdAt,
  });
}

/// Parameters for deleting a task
class DeleteTaskParams {
  final String taskId;
  final String projectId;

  DeleteTaskParams({required this.taskId, required this.projectId});
}

/// Parameters for updating task status
class UpdateTaskStatusParams {
  final String taskId;
  final String status;

  UpdateTaskStatusParams({required this.taskId, required this.status});
}

/// Parameters for updating task running state
class UpdateTaskRunningStateParams {
  final String taskId;
  final bool isRunning;
  final String? lastSessionId;

  UpdateTaskRunningStateParams({
    required this.taskId,
    required this.isRunning,
    this.lastSessionId,
  });
}

/// Parameters for date range queries
class DateRangeParams {
  final DateTime startDate;
  final DateTime endDate;

  DateRangeParams({required this.startDate, required this.endDate});
}
