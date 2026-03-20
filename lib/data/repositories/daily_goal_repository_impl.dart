import 'package:project_tracker/domain/repositories/idaily_goal_repository.dart';
import 'package:project_tracker/core/utils/shared_preferences_helper.dart';

/// Concrete implementation of IDailyGoalRepository
/// Handles all app settings and preferences using SharedPreferences
class DailyGoalRepositoryImpl implements IDailyGoalRepository {
  DailyGoalRepositoryImpl();

  @override
  Future<void> setDailyGoal(int minutes) async {
    await SharedPreferencesHelper.saveDailyGoal(minutes);
  }

  @override
  Future<int> getDailyGoal() async {
    return await SharedPreferencesHelper.getDailyGoal();
  }

  @override
  Future<int> getDefaultDailyGoal() async => 480;

  @override
  Future<bool> isTodayGoalMet(double hoursWorked) async {
    final goal = await getDailyGoal();
    final goalHours = goal / 60.0;
    return hoursWorked >= goalHours;
  }

  @override
  Future<double> getTodayGoalProgress(double hoursWorked) async {
    final goal = await getDailyGoal();
    final goalHours = goal / 60.0;

    if (goalHours == 0) return 0.0;

    final progress = (hoursWorked / goalHours) * 100;
    // Cap at 100% even if exceeded
    return progress > 100 ? 100.0 : progress;
  }

  @override
  Future<void> saveActiveTimer({
    required String taskId,
    required int elapsedSeconds,
    required String startTime,
  }) async {
    await SharedPreferencesHelper.saveActiveTimer(
      taskId: taskId,
      elapsedSeconds: elapsedSeconds,
      startTime: startTime,
    );
  }

  @override
  Future<Map<String, dynamic>> getActiveTimer() async {
    return await SharedPreferencesHelper.getActiveTimer();
  }

  @override
  Future<String?> getActiveTimerTaskId() async {
    return await SharedPreferencesHelper.getActiveTimerTaskId();
  }

  @override
  Future<bool> hasActiveTimer() async {
    return await SharedPreferencesHelper.hasActiveTimer();
  }

  @override
  Future<void> clearActiveTimer() async {
    await SharedPreferencesHelper.clearActiveTimer();
  }

  @override
  Future<void> updateActiveTimerElapsedSeconds(int elapsedSeconds) async {
    await SharedPreferencesHelper.updateActiveTimerElapsedSeconds(
      elapsedSeconds,
    );
  }

  @override
  Future<void> setThemePreference(String theme) async {
    await SharedPreferencesHelper.saveTheme(theme);
  }

  @override
  Future<String> getThemePreference() async {
    return await SharedPreferencesHelper.getTheme();
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await SharedPreferencesHelper.setNotificationsEnabled(enabled);
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return await SharedPreferencesHelper.areNotificationsEnabled();
  }

  @override
  Future<void> clearAllPreferences() async {
    await SharedPreferencesHelper.clearAllPreferences();
  }

  @override
  Future<Set<String>> getAllPreferenceKeys() async {
    return await SharedPreferencesHelper.getAllKeys();
  }

  @override
  Future<bool> hasPreference(String key) async {
    return await SharedPreferencesHelper.hasPreference(key);
  }

  @override
  Future<void> removePreference(String key) async {
    await SharedPreferencesHelper.removePreference(key);
  }
}
