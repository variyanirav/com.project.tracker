/// Timer session entity - Represents a single timer session
class TimerSessionEntity {
  final String id;
  final String taskId;
  final String projectId;
  final DateTime startTime;
  final DateTime? pauseTime;
  final DateTime? resumeTime;
  final DateTime? endTime;
  final int totalSeconds;
  final bool isCompleted;
  final String sessionDate;
  final DateTime createdAt;

  TimerSessionEntity({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.startTime,
    this.pauseTime,
    this.resumeTime,
    this.endTime,
    required this.totalSeconds,
    required this.isCompleted,
    required this.sessionDate,
    required this.createdAt,
  });

  TimerSessionEntity copyWith({
    String? id,
    String? taskId,
    String? projectId,
    DateTime? startTime,
    DateTime? pauseTime,
    DateTime? resumeTime,
    DateTime? endTime,
    int? totalSeconds,
    bool? isCompleted,
    String? sessionDate,
    DateTime? createdAt,
  }) {
    return TimerSessionEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      startTime: startTime ?? this.startTime,
      pauseTime: pauseTime ?? this.pauseTime,
      resumeTime: resumeTime ?? this.resumeTime,
      endTime: endTime ?? this.endTime,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      sessionDate: sessionDate ?? this.sessionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TimerSessionEntity(id: $id, taskId: $taskId, totalSeconds: $totalSeconds)';
  }
}
