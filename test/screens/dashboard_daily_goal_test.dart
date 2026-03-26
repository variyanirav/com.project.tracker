import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/domain/repositories/idaily_goal_repository.dart';
import 'package:project_tracker/core/constants/app_constants.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';
import 'package:project_tracker/presentation/providers/task_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/screens/dashboard_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

class _FakeDailyGoalRepository implements IDailyGoalRepository {
  _FakeDailyGoalRepository(this._goalMinutes);

  int _goalMinutes;

  int get goalMinutes => _goalMinutes;

  @override
  Future<void> setDailyGoal(int minutes) async {
    _goalMinutes = minutes;
  }

  @override
  Future<int> getDailyGoal() async => _goalMinutes;

  @override
  Future<int> getDefaultDailyGoal() async => 480;

  @override
  Future<bool> isTodayGoalMet(double hoursWorked) async {
    return hoursWorked >= (_goalMinutes / 60.0);
  }

  @override
  Future<double> getTodayGoalProgress(double hoursWorked) async {
    final goalHours = _goalMinutes / 60.0;
    if (goalHours == 0) return 0.0;
    final progress = (hoursWorked / goalHours) * 100.0;
    return progress > 100.0 ? 100.0 : progress;
  }

  @override
  Future<void> saveActiveTimer({
    required String taskId,
    required int elapsedSeconds,
    required String startTime,
  }) async {}

  @override
  Future<Map<String, dynamic>> getActiveTimer() async => <String, dynamic>{};

  @override
  Future<String?> getActiveTimerTaskId() async => null;

  @override
  Future<bool> hasActiveTimer() async => false;

  @override
  Future<void> clearActiveTimer() async {}

  @override
  Future<void> updateActiveTimerElapsedSeconds(int elapsedSeconds) async {}

  @override
  Future<void> setThemePreference(String theme) async {}

  @override
  Future<String> getThemePreference() async => 'system';

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> clearAllPreferences() async {}

  @override
  Future<Set<String>> getAllPreferenceKeys() async => <String>{};

  @override
  Future<bool> hasPreference(String key) async => false;

  @override
  Future<void> removePreference(String key) async {}
}

void main() {
  testWidgets('dashboard updates and reopens daily goal with saved value', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeGoalRepository = _FakeDailyGoalRepository(480);
    final idleState = TimerState.idle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          tasksProvider.overrideWith((ref) async => []),
          timerProvider.overrideWith(
            (ref) => _FakeTimerNotifier(ref, idleState),
          ),
          timerTickProvider.overrideWith((ref) => Stream.value(idleState)),
          todayTotalHoursProvider.overrideWith((ref) async => 0.0),
          dailyGoalRepositoryProvider.overrideWithValue(fakeGoalRepository),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('8h 00m'), findsOneWidget);
    expect(find.text('Version ${AppConstants.appVersion}'), findsOneWidget);

    await tester.tap(find.byTooltip('Daily Goal Settings'));
    await tester.pumpAndSettle();

    final initialSlider = tester.widget<Slider>(find.byType(Slider));
    expect(initialSlider.value, 8.0);

    await tester.tap(find.text('6 hours').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();

    expect(fakeGoalRepository.goalMinutes, 360);
    expect(find.text('6h 00m'), findsOneWidget);

    await tester.tap(find.byTooltip('Daily Goal Settings'));
    await tester.pumpAndSettle();

    final reopenedSlider = tester.widget<Slider>(find.byType(Slider));
    expect(reopenedSlider.value, 6.0);
    expect(find.text('6 hours'), findsWidgets);
  });
}
