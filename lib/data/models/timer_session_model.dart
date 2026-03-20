import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/formatters.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';

/// TimerSessionModel represents a single timer session record
/// Stores individual work session data for tracking and reporting
class TimerSessionModel {
  final String id;
  final String taskId;
  final String projectId;
  final DateTime startTime; // UTC
  final DateTime? endTime; // UTC, null while running
  final int elapsedSeconds;
  final bool isPaused;
  final String? notes;
  final DateTime createdAt; // UTC

  TimerSessionModel({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.startTime,
    this.endTime,
    required this.elapsedSeconds,
    required this.isPaused,
    this.notes,
    required this.createdAt,
  });

  /// Create TimerSessionModel from database TimerSessionData
  factory TimerSessionModel.fromTimerSessionData(TimerSessionData data) {
    return TimerSessionModel(
      id: data.id,
      taskId: data.taskId,
      projectId: data.projectId,
      startTime: data.startTime,
      endTime: data.endTime,
      elapsedSeconds: data.elapsedSeconds,
      isPaused: data.isPaused,
      notes: data.notes,
      createdAt: data.createdAt,
    );
  }

  /// Convert TimerSessionModel back to database TimerSessionData
  TimerSessionData toTimerSessionData() {
    return TimerSessionData(
      id: id,
      taskId: taskId,
      projectId: projectId,
      startTime: startTime,
      endTime: endTime,
      elapsedSeconds: elapsedSeconds,
      isPaused: isPaused,
      notes: notes,
      createdAt: createdAt,
    );
  }

  /// Check if session is currently running (no end time set)
  bool get isRunning => endTime == null;

  /// Get session duration in hours (as decimal)
  /// Example: 3661 seconds = 1.01 hours
  double get durationHours => elapsedSeconds / 3600.0;

  /// Get session duration in minutes (as decimal)
  /// Example: 3661 seconds = 61.02 minutes
  double get durationMinutes => elapsedSeconds / 60.0;

  /// Get formatted duration HH:MM:SS (e.g., "01:01:01")
  String get formattedDuration => TimeFormatter.secondsToTime(elapsedSeconds);

  /// Get display-ready duration format (e.g., "1h 1m")
  String get displayDuration =>
      TimeFormatter.secondsToShortForm(elapsedSeconds);

  /// Get human-readable session state
  String get displaySessionState {
    if (isRunning) return 'Running';
    if (isPaused) return 'Paused';
    return 'Completed';
  }

  /// Get start time in local timezone (for display)
  DateTime get startTimeLocal => startTime.toLocal();

  /// Get end time in local timezone (for display, null if running)
  DateTime? get endTimeLocal => endTime?.toLocal();

  /// Get formatted start date (e.g., "Mar 20, 2026")
  String get formattedStartDate => TimezoneHelper.formatDateOnly(startTime);

  /// Get formatted start time (e.g., "2:30 PM")
  String get formattedStartTime => TimezoneHelper.formatTimeOnly(startTime);

  /// Get formatted start date and time together (e.g., "Mar 20, 2026 2:30 PM")
  String get formattedStartDateTime =>
      TimezoneHelper.formatForDisplay(startTime);

  /// Get formatted end date if session is complete
  String get formattedEndDate {
    if (endTime == null) return 'Running';
    return TimezoneHelper.formatDateOnly(endTime!);
  }

  /// Get formatted end time if session is complete
  String get formattedEndTime {
    if (endTime == null) return 'N/A';
    return TimezoneHelper.formatTimeOnly(endTime!);
  }

  /// Get formatted end date and time if session is complete
  String get formattedEndDateTime {
    if (endTime == null) return 'Still Running';
    return TimezoneHelper.formatForDisplay(endTime!);
  }

  /// Get formatted creation timestamp
  String get formattedCreatedAt => TimezoneHelper.formatForDisplay(createdAt);

  /// Get session duration as string with both hours and minutes
  /// Example: "1 hour 1 minute"
  String get displayDurationVerbose {
    final duration = Duration(seconds: elapsedSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours hour${hours > 1 ? 's' : ''}');
    }
    if (minutes > 0) {
      parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
    }
    if (seconds > 0) {
      parts.add('$seconds second${seconds > 1 ? 's' : ''}');
    }

    if (parts.isEmpty) return '0 seconds';
    if (parts.length == 1) return parts[0];
    if (parts.length == 2) return '${parts[0]} ${parts[1]}';
    return '${parts[0]} ${parts[1]} ${parts[2]}';
  }

  /// Check if session occurred today
  bool get isToday => TimezoneHelper.isToday(startTime);

  /// Check if session occurred this week
  bool get isThisWeek => TimezoneHelper.isThisWeek(startTime);

  /// Get time of day category (useful for UI display)
  String get timeOfDay {
    final hour = startTimeLocal.hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  /// Get session summary for display in lists
  /// Example: "Mar 20 2:30 PM - 3:45 PM (1h 15m)"
  String get sessionSummary {
    final startDate = TimezoneHelper.formatDateOnly(startTime);
    final startTimeStr = TimezoneHelper.formatTimeOnly(startTime);
    final endTimeStr = this.endTime != null
        ? TimezoneHelper.formatTimeOnly(this.endTime!)
        : 'Still running';
    return '$startDate $startTimeStr - $endTimeStr ($displayDuration)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          taskId == other.taskId &&
          elapsedSeconds == other.elapsedSeconds;

  @override
  int get hashCode => id.hashCode ^ taskId.hashCode ^ elapsedSeconds.hashCode;

  @override
  String toString() =>
      'TimerSessionModel(id: $id, taskId: $taskId, duration: $displayDuration, isRunning: $isRunning)';
}
