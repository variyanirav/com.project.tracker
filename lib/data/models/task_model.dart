import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/formatters.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';

/// TaskModel represents a Task entity in the application
/// Extends database TaskData with computed properties, formatting, and status management
class TaskModel {
  final String id;
  final String projectId;
  final String taskName;
  final String description;
  final String status;
  final int totalSeconds;
  final bool isRunning;
  final DateTime? lastStartedAt;
  final String? lastSessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.taskName,
    required this.description,
    required this.status,
    required this.totalSeconds,
    required this.isRunning,
    this.lastStartedAt,
    this.lastSessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create TaskModel from database TaskData
  factory TaskModel.fromTaskData(TaskData data) {
    return TaskModel(
      id: data.id,
      projectId: data.projectId,
      taskName: data.taskName,
      description: data.description ?? '',
      status: data.status,
      totalSeconds: data.totalSeconds,
      isRunning: data.isRunning,
      lastStartedAt: data.lastStartedAt,
      lastSessionId: data.lastSessionId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Convert TaskModel back to database TaskData
  TaskData toTaskData() {
    return TaskData(
      id: id,
      projectId: projectId,
      taskName: taskName,
      description: description,
      status: status,
      totalSeconds: totalSeconds,
      isRunning: isRunning,
      lastStartedAt: lastStartedAt,
      lastSessionId: lastSessionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get total hours as decimal
  /// Example: 3661 seconds = 1.01 hours
  double get totalHours => totalSeconds / 3600.0;

  /// Get total minutes as decimal
  /// Example: 3661 seconds = 61.02 minutes
  double get totalMinutes => totalSeconds / 60.0;

  /// Get formatted time HH:MM:SS (e.g., "01:01:01")
  String get formattedTime => TimeFormatter.secondsToTime(totalSeconds);

  /// Get display-ready time format (e.g., "1h 1m")
  String get displayTime => TimeFormatter.secondsToShortForm(totalSeconds);

  /// Get display-ready total hours format (e.g., "2.5 hours" or "30 minutes")
  String get displayTotalHours {
    if (totalSeconds == 0) return '0 minutes';
    if (totalSeconds < 60) return '${totalSeconds}s';
    if (totalSeconds < 3600) {
      final minutes = totalSeconds ~/ 60;
      return '$minutes minutes';
    }
    final rounded = totalHours.toStringAsFixed(1);
    return '$rounded hours';
  }

  /// Get formatted creation date for display
  String get formattedCreatedAt => TimezoneHelper.formatForDisplay(createdAt);

  /// Get formatted last update date for display
  String get formattedUpdatedAt => TimezoneHelper.formatForDisplay(updatedAt);

  /// Get formatted last started time (if applicable)
  String get formattedLastStartedAt {
    if (lastStartedAt == null) return 'Never';
    return TimezoneHelper.formatForDisplay(lastStartedAt!);
  }

  /// Get human-readable status
  String get displayStatus {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'inProgress':
        return 'In Progress';
      case 'inReview':
        return 'In Review';
      case 'onHold':
        return 'On Hold';
      case 'complete':
        return 'Complete';
      default:
        return status;
    }
  }

  /// Get status badge color (for UI display)
  /// Returns color code (e.g., 'red', 'yellow', 'green')
  String get statusBadgeColor {
    switch (status) {
      case 'todo':
        return 'grey';
      case 'inProgress':
        return 'blue';
      case 'inReview':
        return 'orange';
      case 'onHold':
        return 'red';
      case 'complete':
        return 'green';
      default:
        return 'grey';
    }
  }

  /// Check if task is not started
  bool get isTodo => status == 'todo';

  /// Check if task is in progress
  bool get isInProgress => status == 'inProgress';

  /// Check if task is in review
  bool get isInReview => status == 'inReview';

  /// Check if task is on hold
  bool get isOnHold => status == 'onHold';

  /// Check if task is completed
  bool get isCompleted => status == 'complete';

  /// Check if task can be started (not running and not completed)
  bool get canStart => !isRunning && !isCompleted;

  /// Check if task can be resumed (is running or has been started before)
  bool get canResume => isRunning || lastStartedAt != null;

  /// Check if task was created today
  bool get wasCreatedToday => TimezoneHelper.isToday(createdAt);

  /// Check if task was updated today
  bool get wasUpdatedToday => TimezoneHelper.isToday(updatedAt);

  /// Get task duration category (useful for UI filtering/sorting)
  String get durationCategory {
    if (totalSeconds < 600) return 'quick'; // < 10 mins
    if (totalSeconds < 1800) return 'short'; // < 30 mins
    if (totalSeconds < 3600) return 'medium'; // < 1 hour
    if (totalSeconds < 14400) return 'long'; // < 4 hours
    return 'veryLong'; // 4+ hours
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          projectId == other.projectId &&
          status == other.status &&
          totalSeconds == other.totalSeconds;

  @override
  int get hashCode =>
      id.hashCode ^
      projectId.hashCode ^
      status.hashCode ^
      totalSeconds.hashCode;

  @override
  String toString() =>
      'TaskModel(id: $id, taskName: $taskName, status: $status, totalSeconds: $totalSeconds, isRunning: $isRunning)';
}
