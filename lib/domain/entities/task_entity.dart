/// Task entity - Business logic model (Domain layer)
class TaskEntity {
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
  final DateTime updatedAt;

  TaskEntity({
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
    required this.updatedAt,
  });

  TaskEntity copyWith({
    String? id,
    String? projectId,
    String? taskName,
    String? description,
    String? status,
    int? totalSeconds,
    bool? isRunning,
    DateTime? lastStartedAt,
    String? lastSessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TaskEntity(id: $id, projectId: $projectId, taskName: $taskName, status: $status)';
  }
}
