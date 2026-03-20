import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences helper for app-level settings and temporary state
/// Stores settings that don't need database persistence (e.g., daily goals, UI preferences)
/// Also stores temporary timer state while timer is running
class SharedPreferencesHelper {
  SharedPreferencesHelper._(); // Private constructor - static only

  // Keys for SharedPreferences
  static const String _dailyGoalKey = 'daily_goal_minutes';
  static const String _activeTimerTaskIdKey = 'active_timer_task_id';
  static const String _activeTimerElapsedSecondsKey =
      'active_timer_elapsed_seconds';
  static const String _activeTimerStartTimeKey = 'active_timer_start_time';
  static const String _themeKey = 'app_theme';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Default values
  static const int _defaultDailyGoal = 480; // 8 hours in minutes

  /// Save daily goal in minutes
  /// [minutes] - daily goal in minutes (default 480 = 8 hours)
  static Future<bool> saveDailyGoal(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_dailyGoalKey, minutes);
  }

  /// Get saved daily goal in minutes
  /// Returns default 480 minutes (8 hours) if not set
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? _defaultDailyGoal;
  }

  /// Save the currently active timer information
  /// [taskId] - the task ID of the running timer
  /// [elapsedSeconds] - seconds accumulated so far
  /// [startTime] - ISO 8601 string of when timer started
  static Future<bool> saveActiveTimer({
    required String taskId,
    required int elapsedSeconds,
    required String startTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_activeTimerTaskIdKey, taskId);
    await prefs.setInt(_activeTimerElapsedSecondsKey, elapsedSeconds);
    final success = await prefs.setString(_activeTimerStartTimeKey, startTime);

    return success;
  }

  /// Get the currently active timer information
  /// Returns a map with 'taskId', 'elapsedSeconds', 'startTime' if timer exists
  /// Returns empty map if no active timer
  static Future<Map<String, dynamic>> getActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();

    final taskId = prefs.getString(_activeTimerTaskIdKey);
    final elapsedSeconds = prefs.getInt(_activeTimerElapsedSecondsKey);
    final startTime = prefs.getString(_activeTimerStartTimeKey);

    if (taskId == null || elapsedSeconds == null || startTime == null) {
      return {};
    }

    return {
      'taskId': taskId,
      'elapsedSeconds': elapsedSeconds,
      'startTime': startTime,
    };
  }

  /// Get task ID if there's an active timer, null otherwise
  static Future<String?> getActiveTimerTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeTimerTaskIdKey);
  }

  /// Check if there's an active timer
  static Future<bool> hasActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_activeTimerTaskIdKey);
  }

  /// Clear active timer information
  /// Called when timer is stopped and saved to database
  static Future<bool> clearActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_activeTimerTaskIdKey);
    await prefs.remove(_activeTimerElapsedSecondsKey);
    final success = await prefs.remove(_activeTimerStartTimeKey);

    return success;
  }

  /// Update elapsed seconds for active timer
  /// Used to persist timer progress while running
  static Future<bool> updateActiveTimerElapsedSeconds(
    int elapsedSeconds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_activeTimerElapsedSecondsKey, elapsedSeconds);
  }

  /// Save app theme preference (light/dark/system)
  /// [theme] - 'light', 'dark', or 'system'
  static Future<bool> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_themeKey, theme);
  }

  /// Get saved app theme preference
  /// Returns 'system' by default
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  /// Save notifications enabled state
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Get notifications enabled state
  /// Returns true by default
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Clear all preferences (useful for testing or hard reset)
  static Future<bool> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  /// Get all keys stored in SharedPreferences
  /// Useful for debugging
  static Future<Set<String>> getAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  /// Remove a specific preference by key
  static Future<bool> removePreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  /// Check if a preference exists
  static Future<bool> hasPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}
