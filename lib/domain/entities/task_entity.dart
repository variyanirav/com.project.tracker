/// Task entity - Business logic model (Domain layer)
class TaskEntity {
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
  final DateTime? deletedAt;
  final String? deletedStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskEntity({
    required this.id,
    required this.projectId,
    this.categoryId,
    required this.taskName,
    this.description,
    this.estimatedHours,
    required this.status,
    this.isBillable = true,
    required this.totalSeconds,
    required this.isRunning,
    this.lastStartedAt,
    this.lastSessionId,
    this.deletedAt,
    this.deletedStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskEntity copyWith({
    String? id,
    String? projectId,
    String? categoryId,
    String? taskName,
    String? description,
    double? estimatedHours,
    String? status,
    bool? isBillable,
    int? totalSeconds,
    bool? isRunning,
    DateTime? lastStartedAt,
    String? lastSessionId,
    DateTime? deletedAt,
    String? deletedStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      categoryId: categoryId ?? this.categoryId,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      status: status ?? this.status,
      isBillable: isBillable ?? this.isBillable,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedStatus: deletedStatus ?? this.deletedStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TaskEntity(id: $id, projectId: $projectId, taskName: $taskName, status: $status, isBillable: $isBillable)';
  }
}
