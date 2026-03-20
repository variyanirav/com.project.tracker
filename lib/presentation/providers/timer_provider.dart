import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'repository_provider.dart';

/// State notifier for managing timer state
class TimerStateNotifier extends StateNotifier<TimerState> {
  final Ref ref;

  TimerStateNotifier(this.ref) : super(TimerState.idle());

  /// Start a timer for a task
  Future<void> startTimer(String taskId, String projectId) async {
    final timerRepository = ref.read(timerSessionRepositoryProvider);

    final session = await timerRepository.createSession(
      taskId: taskId,
      projectId: projectId,
      startTime: TimezoneHelper.getCurrentUtc(),
    );

    // Update UI state
    state = TimerState(
      sessionId: session.id,
      taskId: taskId,
      projectId: projectId,
      elapsedSeconds: 0,
      isRunning: true,
      isPaused: false,
      startTime: DateTime.now(),
    );

    // Update task running state
    final taskRepository = ref.read(taskRepositoryProvider);
    await taskRepository.updateTaskRunningState(
      taskId,
      true,
      lastSessionId: session.id,
    );
  }

  /// Pause the current timer
  Future<void> pauseTimer() async {
    if (!state.isRunning || state.isPaused || state.sessionId == null) return;

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.pauseSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    state = state.copyWith(isPaused: true);
  }

  /// Resume a paused timer
  Future<void> resumeTimer() async {
    if (!state.isRunning || !state.isPaused || state.sessionId == null) return;

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.resumeSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    state = state.copyWith(isPaused: false);
  }

  /// Stop the current timer
  Future<void> stopTimer() async {
    if (state.sessionId == null) return;

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    final endTime = TimezoneHelper.getCurrentUtc();

    final duration = endTime.difference(state.startTime).inSeconds;

    await timerRepository.stopSession(
      state.sessionId!,
      endTime: endTime,
      totalSeconds: duration,
    );

    // Update task running state to false
    if (state.taskId != null) {
      final taskRepository = ref.read(taskRepositoryProvider);
      await taskRepository.updateTaskRunningState(state.taskId!, false);
    }

    state = TimerState.idle();
  }

  /// Update elapsed time for UI display
  void updateElapsedTime(int seconds) {
    if (state.isRunning && !state.isPaused) {
      state = state.copyWith(elapsedSeconds: seconds);
    }
  }
}

/// Provider for timer state management
final timerProvider = StateNotifierProvider<TimerStateNotifier, TimerState>((
  ref,
) {
  return TimerStateNotifier(ref);
});

/// Provider for getting the current active timer session from database
final currentTimerSessionProvider = FutureProvider<TimerSessionEntity?>((ref) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  return timerRepository.getActiveSession();
});

/// Provider for all timer sessions
final timerSessionsProvider = FutureProvider<List<TimerSessionEntity>>((ref) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  // Get a week of sessions as a reasonable default
  final weekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  return timerRepository.getSessionsByDateRange(weekStart, DateTime.now());
});

/// Provider for timer sessions filtered by task
final timerSessionsByTaskProvider =
    FutureProvider.family<List<TimerSessionEntity>, String>((ref, taskId) {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      return timerRepository.getSessionsByTask(taskId);
    });

/// Provider for timer sessions filtered by project
final timerSessionsByProjectProvider =
    FutureProvider.family<List<TimerSessionEntity>, String>((ref, projectId) {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      return timerRepository.getSessionsByProject(projectId);
    });

/// Provider for timer sessions filtered by date
final timerSessionsByDateProvider =
    FutureProvider.family<List<TimerSessionEntity>, DateTime>((ref, date) {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      return timerRepository.getSessionsByDate(date);
    });

/// Provider for today's timer sessions
final todayTimerSessionsProvider = FutureProvider<List<TimerSessionEntity>>((
  ref,
) {
  final today = TimezoneHelper.getTodayStartUtc();
  return ref.watch(timerSessionsByDateProvider(today).future);
});

/// Provider for this week's timer sessions
final weekTimerSessionsProvider = FutureProvider<List<TimerSessionEntity>>((
  ref,
) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  return timerRepository.getWeekSessionsByProject(''); // Empty project gets all
});

/// Provider for total hours today
final todayTotalHoursProvider = FutureProvider<double>((ref) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  return timerRepository.getTodayTotalHours();
});

/// Provider for total hours this week
final weekTotalHoursProvider = FutureProvider<double>((ref) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  return timerRepository.getWeekTotalHours();
});

/// Provider for checking if there's an active timer
final hasActiveTimerProvider = FutureProvider<bool>((ref) {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  return timerRepository.hasActiveSession();
});

/// Provider for daily goal in hours
final dailyGoalProvider = FutureProvider<double>((ref) async {
  final dailyGoalRepository = ref.watch(dailyGoalRepositoryProvider);
  final minutes = await dailyGoalRepository.getDailyGoal();
  return minutes / 60.0; // Convert minutes to hours
});

/// Provider for daily progress percentage
final dailyProgressProvider = FutureProvider<double>((ref) async {
  final todayHours = await ref.watch(todayTotalHoursProvider.future);
  final dailyGoalHours = await ref.watch(dailyGoalProvider.future);

  if (dailyGoalHours == 0) return 0.0;

  final progress = (todayHours / dailyGoalHours).clamp(0.0, 1.0);
  return progress;
});

/// Provider for deleting a timer session
final deleteTimerSessionProvider = FutureProvider.family<void, String>((
  ref,
  sessionId,
) async {
  final timerRepository = ref.watch(timerSessionRepositoryProvider);
  await timerRepository.deleteSession(sessionId);

  // Invalidate related providers
  ref.invalidate(timerSessionsProvider);
  ref.invalidate(currentTimerSessionProvider);
  ref.invalidate(todayTimerSessionsProvider);
  ref.invalidate(weekTimerSessionsProvider);
});

/// Timer state model
class TimerState {
  final String? sessionId;
  final String? taskId;
  final String? projectId;
  final int elapsedSeconds;
  final bool isRunning;
  final bool isPaused;
  final DateTime startTime;

  TimerState({
    this.sessionId,
    this.taskId,
    this.projectId,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.isPaused = false,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  factory TimerState.idle() {
    return TimerState(
      sessionId: null,
      taskId: null,
      projectId: null,
      elapsedSeconds: 0,
      isRunning: false,
      isPaused: false,
      startTime: DateTime.now(),
    );
  }

  TimerState copyWith({
    String? sessionId,
    String? taskId,
    String? projectId,
    int? elapsedSeconds,
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
  }) {
    return TimerState(
      sessionId: sessionId ?? this.sessionId,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
    );
  }
}
