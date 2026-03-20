import 'package:project_tracker/core/utils/timezone_helper.dart';

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
  final String? notes;
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
    this.notes,
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
    String? notes,
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
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if session is currently paused
  bool get isPaused => pauseTime != null;

  /// Check if session started today
  bool get isToday {
    final today = TimezoneHelper.getTodayStartUtc();
    return startTime.isAfter(today) &&
        startTime.isBefore(today.add(const Duration(days: 1)));
  }

  /// Check if session started this week
  bool get isThisWeek {
    final now = DateTime.now().toUtc();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return startTime.isAfter(weekStart) && startTime.isBefore(weekEnd);
  }

  @override
  String toString() {
    return 'TimerSessionEntity(id: $id, taskId: $taskId, totalSeconds: $totalSeconds)';
  }
}
