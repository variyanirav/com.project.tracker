import 'package:project_tracker/data/database/app_database.dart';
import 'timezone_helper.dart';

/// Time aggregation and calculation utilities
/// Responsible for summing hours, calculating daily/weekly totals, etc.
class TimeAggregator {
  TimeAggregator._(); // Private constructor - static only

  /// Convert seconds to total hours (decimal)
  /// Example: 3600 seconds = 1.0 hours
  static double secondsToHours(int seconds) {
    return seconds / 3600.0;
  }

  /// Convert seconds to total minutes (decimal)
  /// Example: 3600 seconds = 60.0 minutes
  static double secondsToMinutes(int seconds) {
    return seconds / 60.0;
  }

  /// Sum all elapsed seconds from timer sessions
  /// Useful for calculating total task hours or project hours
  static int sumSessionDurations(List<TimerSessionData> sessions) {
    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.elapsedSeconds,
    );
  }

  /// Sum total hours from timer sessions as decimal
  /// Example: [session1 (3600s), session2 (1800s)] = 1.5 hours
  static double sumSessionHours(List<TimerSessionData> sessions) {
    final totalSeconds = sumSessionDurations(sessions);
    return secondsToHours(totalSeconds);
  }

  /// Calculate total hours spent on a specific day
  /// [sessions] - list of sessions to filter
  /// [dayUtc] - the day in UTC to compare against
  /// Returns total hours for that day
  static double calculateDailyHours(
    List<TimerSessionData> sessions,
    DateTime dayUtc,
  ) {
    final filtered = sessions.where((session) {
      return TimezoneHelper.isSameDay(session.startTime, dayUtc);
    }).toList();
    return sumSessionHours(filtered);
  }

  /// Calculate total hours for the current week (Mon-Sun)
  /// Returns hours from Monday through Sunday of current week
  static double calculateWeeklyHours(List<TimerSessionData> sessions) {
    final weekStart = TimezoneHelper.getWeekStartUtc();
    final weekEnd = TimezoneHelper.getWeekEndUtc();

    final filtered = sessions.where((session) {
      final sessionDay = session.startTime;
      return sessionDay.isAtSameMomentAs(weekStart) ||
          (sessionDay.isAfter(weekStart) && sessionDay.isBefore(weekEnd));
    }).toList();

    return sumSessionHours(filtered);
  }

  /// Calculate total hours for a specific month
  /// [year] and [month] specify which month to calculate
  static double calculateMonthlyHours(
    List<TimerSessionData> sessions,
    int year,
    int month,
  ) {
    final filtered = sessions.where((session) {
      return session.startTime.year == year && session.startTime.month == month;
    }).toList();
    return sumSessionHours(filtered);
  }

  /// Calculate total hours for the current day
  /// Convenient wrapper for calculateDailyHours with today's date
  static double calculateTodayHours(List<TimerSessionData> sessions) {
    final today = TimezoneHelper.getTodayStartUtc();
    return calculateDailyHours(sessions, today);
  }

  /// Calculate all-time total hours from sessions
  /// Sums every session in the list
  static double calculateTotalHours(List<TimerSessionData> sessions) {
    return sumSessionHours(sessions);
  }

  /// Group sessions by day
  /// Returns a map of date (YYYY-MM-DD) to list of sessions for that day
  static Map<String, List<TimerSessionData>> groupSessionsByDay(
    List<TimerSessionData> sessions,
  ) {
    final grouped = <String, List<TimerSessionData>>{};

    for (final session in sessions) {
      final dateKey =
          '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(session);
    }

    return grouped;
  }

  /// Group sessions by week
  /// Returns a map where key is week start date (YYYY-MM-DD)
  static Map<String, List<TimerSessionData>> groupSessionsByWeek(
    List<TimerSessionData> sessions,
  ) {
    final grouped = <String, List<TimerSessionData>>{};

    for (final session in sessions) {
      final weekStart = TimezoneHelper.getWeekStartUtc(
        referenceDate: session.startTime,
      );
      final dateKey =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(session);
    }

    return grouped;
  }

  /// Calculate average session duration in seconds
  /// Returns 0 if no sessions exist
  static int calculateAverageSessionDuration(List<TimerSessionData> sessions) {
    if (sessions.isEmpty) return 0;
    final totalSeconds = sumSessionDurations(sessions);
    return (totalSeconds / sessions.length).round();
  }

  /// Get the longest session duration in seconds
  /// Returns 0 if no sessions exist
  static int getLongestSessionDuration(List<TimerSessionData> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions
        .map((s) => s.elapsedSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get the shortest session duration in seconds
  /// Returns 0 if no sessions exist
  static int getShortestSessionDuration(List<TimerSessionData> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions
        .map((s) => s.elapsedSeconds)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Check if a session occurred today
  static bool isSessionToday(TimerSessionData session) {
    return TimezoneHelper.isToday(session.startTime);
  }

  /// Check if a session occurred this week
  static bool isSessionThisWeek(TimerSessionData session) {
    return TimezoneHelper.isThisWeek(session.startTime);
  }

  /// Filter sessions that occurred today
  static List<TimerSessionData> getTodaySessions(
    List<TimerSessionData> sessions,
  ) {
    return sessions.where(isSessionToday).toList();
  }

  /// Filter sessions that occurred this week
  static List<TimerSessionData> getThisWeekSessions(
    List<TimerSessionData> sessions,
  ) {
    return sessions.where(isSessionThisWeek).toList();
  }

  /// Sort sessions by start time (newest first)
  static List<TimerSessionData> sortByNewest(List<TimerSessionData> sessions) {
    final sorted = [...sessions];
    sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted;
  }

  /// Sort sessions by start time (oldest first)
  static List<TimerSessionData> sortByOldest(List<TimerSessionData> sessions) {
    final sorted = [...sessions];
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }
}
