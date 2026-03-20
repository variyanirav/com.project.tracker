import '../entities/timer_session_entity.dart';

/// Abstract repository for timer session operations
/// Manages individual timer session records for tracking and reporting
abstract class ITimerSessionRepository {
  /// Create a new timer session
  Future<TimerSessionEntity> createSession({
    required String taskId,
    required String projectId,
    required DateTime startTime,
  });

  /// Get all sessions for a specific task
  Future<List<TimerSessionEntity>> getSessionsByTask(String taskId);

  /// Get all sessions for a specific project
  Future<List<TimerSessionEntity>> getSessionsByProject(String projectId);

  /// Get single session by ID
  Future<TimerSessionEntity?> getSessionById(String id);

  /// Get all sessions created on a specific date
  Future<List<TimerSessionEntity>> getSessionsByDate(DateTime date);

  /// Get sessions within a date range
  Future<List<TimerSessionEntity>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get currently active/running session (if any)
  /// Returns null if no session is currently running
  Future<TimerSessionEntity?> getActiveSession();

  /// Stop an active session
  /// [sessionId] - the session to stop
  /// [endTime] - when the session ended
  /// [totalSeconds] - total elapsed seconds for this session
  Future<void> stopSession(
    String sessionId, {
    required DateTime endTime,
    required int totalSeconds,
  });

  /// Pause current session
  /// [sessionId] - the session to pause
  /// [pauseTime] - when it was paused
  Future<void> pauseSession(String sessionId, DateTime pauseTime);

  /// Resume a paused session
  /// [sessionId] - the session to resume
  /// [resumeTime] - when it was resumed
  Future<void> resumeSession(String sessionId, DateTime resumeTime);

  /// Get total seconds from all sessions for a task
  Future<int> getTaskTotalSeconds(String taskId);

  /// Get total seconds from all sessions for a project
  Future<int> getProjectTotalSeconds(String projectId);

  /// Get total hours (as decimal) for a task
  Future<double> getTaskTotalHours(String taskId);

  /// Get total hours (as decimal) for a project
  Future<double> getProjectTotalHours(String projectId);

  /// Get today's sessions for a task
  Future<List<TimerSessionEntity>> getTodaySessionsByTask(String taskId);

  /// Get today's sessions for a project
  Future<List<TimerSessionEntity>> getTodaySessionsByProject(String projectId);

  /// Get this week's sessions for a project (Mon-Sun)
  Future<List<TimerSessionEntity>> getWeekSessionsByProject(String projectId);

  /// Get today's total hours (all projects/tasks)
  Future<double> getTodayTotalHours();

  /// Get this week's total hours (Mon-Sun, all projects/tasks)
  Future<double> getWeekTotalHours();

  /// Get monthly total hours
  Future<double> getMonthTotalHours(int year, int month);

  /// Get average session duration for a task (in seconds)
  Future<int> getTaskAverageSessionDuration(String taskId);

  /// Get longest session duration for a task
  Future<int> getTaskLongestSession(String taskId);

  /// Get shortest session duration for a task
  Future<int> getTaskShortestSession(String taskId);

  /// Delete a session
  Future<void> deleteSession(String id);

  /// Delete all sessions for a task
  Future<void> deleteSessionsByTask(String taskId);

  /// Update session notes
  Future<void> updateSessionNotes(String sessionId, String? notes);

  /// Get sessions by task with pagination
  /// [taskId] - task to fetch sessions for
  /// [limit] - number of sessions per page
  /// [offset] - pagination offset
  Future<List<TimerSessionEntity>> getSessionsByTaskPaginated(
    String taskId, {
    required int limit,
    required int offset,
  });

  /// Check if there's currently an active session
  Future<bool> hasActiveSession();

  /// Get the number of sessions for a task
  Future<int> getSessionCountByTask(String taskId);

  /// Get the number of sessions for a project
  Future<int> getSessionCountByProject(String projectId);

  /// Get sessions sorted by start time (newest first)
  Future<List<TimerSessionEntity>> getSessionsByTaskNewest(String taskId);

  /// Get sessions sorted by start time (oldest first)
  Future<List<TimerSessionEntity>> getSessionsByTaskOldest(String taskId);
}
