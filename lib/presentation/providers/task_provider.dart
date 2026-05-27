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

/// Provider for active tasks filtered by project
final activeTasksByProjectProvider =
    FutureProvider.family<List<TaskEntity>, String>((ref, projectId) async {
      final repository = ref.watch(taskRepositoryProvider);
      final tasks = await repository.getTasksByProject(projectId);
      return tasks.where((task) => task.status != 'archived').toList();
    });

/// Provider for archived tasks filtered by project
final archivedTasksByProjectProvider =
    FutureProvider.family<List<TaskEntity>, String>((ref, projectId) async {
      final repository = ref.watch(taskRepositoryProvider);
      return await repository.getArchivedTasksByProject(projectId);
    });

/// Provider for deleted tasks filtered by project
final deletedTasksByProjectProvider =
    FutureProvider.family<List<TaskEntity>, String>((ref, projectId) async {
      final repository = ref.watch(taskRepositoryProvider);
      return await repository.getDeletedTasksByProject(projectId);
    });

/// Search mode for project detail task queries
enum ProjectTaskViewMode { active, archived, trash }

/// Search parameters for project detail task queries
class ProjectTaskSearchParams {
  final String projectId;
  final ProjectTaskViewMode viewMode;
  final String query;

  const ProjectTaskSearchParams({
    required this.projectId,
    required this.viewMode,
    required this.query,
  });

  @override
  bool operator ==(Object other) {
    return other is ProjectTaskSearchParams &&
        other.projectId == projectId &&
        other.viewMode == viewMode &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(projectId, viewMode, query);
}

/// Provider for DB-backed project task search
final searchedTasksByProjectProvider =
    FutureProvider.family<List<TaskEntity>, ProjectTaskSearchParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(taskRepositoryProvider);
      final query = params.query.trim();

      if (query.isEmpty) {
        switch (params.viewMode) {
          case ProjectTaskViewMode.active:
            return repository
                .getTasksByProject(params.projectId)
                .then(
                  (tasks) =>
                      tasks.where((task) => task.status != 'archived').toList(),
                );
          case ProjectTaskViewMode.archived:
            return repository.getArchivedTasksByProject(params.projectId);
          case ProjectTaskViewMode.trash:
            return repository.getDeletedTasksByProject(params.projectId);
        }
      }

      switch (params.viewMode) {
        case ProjectTaskViewMode.active:
          return repository.searchActiveTasksByProject(params.projectId, query);
        case ProjectTaskViewMode.archived:
          return repository.searchArchivedTasksByProject(
            params.projectId,
            query,
          );
        case ProjectTaskViewMode.trash:
          return repository.searchDeletedTasksByProject(
            params.projectId,
            query,
          );
      }
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
    categoryId: params.categoryId,
    taskName: params.taskName,
    description: params.description,
    estimatedHours: params.estimatedHours,
    isBillable: params.isBillable,
  );

  // Invalidate related providers
  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
  ref.invalidate(activeTasksByProjectProvider(params.projectId));
  ref.invalidate(archivedTasksByProjectProvider(params.projectId));
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
    categoryId: params.categoryId,
    taskName: params.taskName,
    description: params.description,
    estimatedHours: params.estimatedHours,
    status: params.status,
    isBillable: params.isBillable,
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
  ref.invalidate(deletedTasksByProjectProvider(params.projectId));
});

/// Provider for permanently deleting a task
final permanentlyDeleteTaskProvider =
    FutureProvider.family<void, DeleteTaskParams>((ref, params) async {
      final repository = ref.watch(taskRepositoryProvider);
      await repository.permanentlyDeleteTask(params.taskId);

      ref.invalidate(tasksProvider);
      ref.invalidate(tasksByProjectProvider(params.projectId));
      ref.invalidate(archivedTasksByProjectProvider(params.projectId));
      ref.invalidate(deletedTasksByProjectProvider(params.projectId));
      ref.invalidate(taskByIdProvider(params.taskId));
    });

/// Provider for archiving a task
final archiveTaskProvider = FutureProvider.family<void, ArchiveTaskParams>((
  ref,
  params,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  await repository.archiveTask(params.taskId);

  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
  ref.invalidate(activeTasksByProjectProvider(params.projectId));
  ref.invalidate(archivedTasksByProjectProvider(params.projectId));
  ref.invalidate(taskByIdProvider(params.taskId));
});

/// Provider for restoring an archived task
final unarchiveTaskProvider = FutureProvider.family<void, ArchiveTaskParams>((
  ref,
  params,
) async {
  final repository = ref.watch(taskRepositoryProvider);
  await repository.unarchiveTask(params.taskId);

  ref.invalidate(tasksProvider);
  ref.invalidate(tasksByProjectProvider(params.projectId));
  ref.invalidate(activeTasksByProjectProvider(params.projectId));
  ref.invalidate(archivedTasksByProjectProvider(params.projectId));
  ref.invalidate(taskByIdProvider(params.taskId));
});

/// Provider for restoring a deleted task from Trash
final restoreDeletedTaskProvider =
    FutureProvider.family<void, DeleteTaskParams>((ref, params) async {
      final repository = ref.watch(taskRepositoryProvider);
      await repository.restoreDeletedTask(params.taskId);

      ref.invalidate(tasksProvider);
      ref.invalidate(tasksByProjectProvider(params.projectId));
      ref.invalidate(activeTasksByProjectProvider(params.projectId));
      ref.invalidate(archivedTasksByProjectProvider(params.projectId));
      ref.invalidate(deletedTasksByProjectProvider(params.projectId));
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
  final String? categoryId;
  final String taskName;
  final String? description;
  final double? estimatedHours;
  final bool isBillable;

  CreateTaskParams({
    required this.projectId,
    this.categoryId,
    required this.taskName,
    this.description,
    this.estimatedHours,
    this.isBillable = true,
  });
}

/// Parameters for updating a task
class UpdateTaskParams {
  final String id;
  final String projectId;
  final String? categoryId;
  final String taskName;
  final String? description;
  final double? estimatedHours;
  final String status;
  final bool isBillable;
  final int totalSeconds;
  final bool isRunning;
  final DateTime? lastStartedAt;
  final String? lastSessionId;
  final DateTime createdAt;

  UpdateTaskParams({
    required this.id,
    required this.projectId,
    this.categoryId,
    required this.taskName,
    this.description,
    this.estimatedHours,
    required this.status,
    required this.isBillable,
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

/// Parameters for archive/restore operations
class ArchiveTaskParams {
  final String taskId;
  final String projectId;

  ArchiveTaskParams({required this.taskId, required this.projectId});
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
