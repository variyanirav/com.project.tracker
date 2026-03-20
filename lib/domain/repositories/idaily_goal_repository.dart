/// Daily goal entity (simple value object)
class DailyGoal {
  final int minutes;
  final DateTime lastUpdated;

  DailyGoal({required this.minutes, required this.lastUpdated});

  @override
  String toString() => 'DailyGoal(minutes: $minutes)';
}

/// Abstract repository for daily goal and app settings
/// Manages user preferences stored in SharedPreferences
abstract class IDailyGoalRepository {
  /// Set the user's daily goal in minutes
  /// [minutes] - the daily goal (e.g., 480 for 8 hours)
  Future<void> setDailyGoal(int minutes);

  /// Get the user's daily goal
  /// Returns the previously set goal, or default 480 minutes (8 hours) if not set
  Future<int> getDailyGoal();

  /// Check if today's goal has been met
  /// [hoursWorked] - total hours worked today
  /// Returns true if hoursWorked >= dailyGoalHours
  Future<bool> isTodayGoalMet(double hoursWorked);

  /// Get today's progress towards the goal
  /// Returns a percentage (0-100)
  /// [hoursWorked] - total hours worked today
  Future<double> getTodayGoalProgress(double hoursWorked);

  /// Get the default daily goal (8 hours = 480 minutes)
  Future<int> getDefaultDailyGoal() async => 480;

  /// Save temporary active timer information
  /// [taskId] - the task being timed
  /// [elapsedSeconds] - seconds accumulated so far
  /// [startTime] - ISO 8601 string of when timer started
  Future<void> saveActiveTimer({
    required String taskId,
    required int elapsedSeconds,
    required String startTime,
  });

  /// Get temporary active timer information
  /// Returns map with 'taskId', 'elapsedSeconds', 'startTime' if timer exists
  /// Returns empty map if no active timer
  Future<Map<String, dynamic>> getActiveTimer();

  /// Get the task ID of the currently active timer
  /// Returns null if no timer is running
  Future<String?> getActiveTimerTaskId();

  /// Check if there's currently an active timer
  Future<bool> hasActiveTimer();

  /// Clear the active timer (call when timer is stopped)
  Future<void> clearActiveTimer();

  /// Update the elapsed seconds for the active timer
  /// Called to persist timer progress while running
  Future<void> updateActiveTimerElapsedSeconds(int elapsedSeconds);

  /// Save app theme preference
  /// [theme] - 'light', 'dark', or 'system'
  Future<void> setThemePreference(String theme);

  /// Get app theme preference
  /// Returns 'system' by default
  Future<String> getThemePreference();

  /// Set notifications enabled state
  Future<void> setNotificationsEnabled(bool enabled);

  /// Get notifications enabled state
  /// Returns true by default
  Future<bool> areNotificationsEnabled();

  /// Clear all preferences (useful for testing or hard reset)
  Future<void> clearAllPreferences();

  /// Get all stored preference keys (for debugging)
  Future<Set<String>> getAllPreferenceKeys();

  /// Check if a specific preference exists
  Future<bool> hasPreference(String key);

  /// Remove a specific preference
  Future<void> removePreference(String key);
}
