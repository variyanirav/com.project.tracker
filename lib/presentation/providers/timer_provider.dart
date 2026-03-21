import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'repository_provider.dart';

/// State notifier for managing timer state
class TimerStateNotifier extends StateNotifier<TimerState> {
  final Ref ref;
  Timer? _tickTimer;
  int _baselineElapsedSeconds = 0;

  TimerStateNotifier(this.ref) : super(TimerState.idle());

  /// Cleanup timer when notifier is disposed
  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && !state.isPaused) {
        final elapsed =
            _baselineElapsedSeconds +
            DateTime.now().difference(state.startTime).inSeconds;
        debugPrint(
          '[TIMER] 🔄 Tick - Elapsed: ${elapsed}s (${(elapsed ~/ 3600)}h ${((elapsed % 3600) ~/ 60)}m ${(elapsed % 60)}s)',
        );
        state = state.copyWith(elapsedSeconds: elapsed);
      }
    });

    debugPrint('[TIMER] ⏱️  Tick timer started');
  }

  int _currentElapsedSeconds() {
    if (!state.isRunning || state.isPaused) {
      return state.elapsedSeconds;
    }
    return _baselineElapsedSeconds +
        DateTime.now().difference(state.startTime).inSeconds;
  }

  /// Start a timer for a task
  Future<void> startTimer(String taskId, String projectId) async {
    if (state.isRunning) {
      debugPrint('[TIMER] Timer already running for task: ${state.taskId}');
      return;
    }

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    final taskRepository = ref.read(taskRepositoryProvider);

    // Check if there's a paused session to resume
    final task = await taskRepository.getTaskById(taskId);
    TimerSessionEntity? pausedSessionEntity;
    int previousElapsedSeconds = 0;

    if (task != null &&
        task.lastSessionId != null &&
        task.lastSessionId!.isNotEmpty) {
      // Try to get the paused session
      final allSessions = await timerRepository.getSessionsByTask(taskId);
      try {
        pausedSessionEntity = allSessions.firstWhere(
          (s) => s.id == task.lastSessionId && s.isPaused && s.endTime == null,
        );
        previousElapsedSeconds = pausedSessionEntity.totalSeconds;

        debugPrint(
          '[TIMER] 📋 Resuming paused session - SessionID: ${pausedSessionEntity.id}, Previous elapsed: ${previousElapsedSeconds}s',
        );
      } catch (e) {
        // No paused session found, will create new one
        debugPrint('[TIMER] ℹ️  No paused session found, creating new one');
      }
    }

    // If no paused session, create a new one
    final session =
        pausedSessionEntity ??
        await timerRepository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: TimezoneHelper.getCurrentUtc(),
        );

    debugPrint(
      '[TIMER] ✅ Timer started - SessionID: ${session.id}, TaskID: $taskId, ProjectID: $projectId, Previous elapsed: ${previousElapsedSeconds}s',
    );

    // If resuming, mark the session as not paused
    if (pausedSessionEntity != null) {
      await timerRepository.resumeSession(
        session.id,
        TimezoneHelper.getCurrentUtc(),
      );
      debugPrint(
        '[TIMER] ▶️  Resumed paused session - SessionID: ${session.id}',
      );
    }

    // Update UI state with actual start time
    final startTime = DateTime.now();
    _baselineElapsedSeconds = previousElapsedSeconds;
    state = TimerState(
      sessionId: session.id,
      taskId: taskId,
      projectId: projectId,
      elapsedSeconds: previousElapsedSeconds,
      isRunning: true,
      isPaused: false,
      startTime: startTime,
    );

    // Update task running state in database
    await taskRepository.updateTaskRunningState(
      taskId,
      true,
      lastSessionId: session.id,
    );

    _startTickTimer();
  }

  /// Pause the current timer
  Future<void> pauseTimer() async {
    if (!state.isRunning || state.isPaused || state.sessionId == null) {
      debugPrint(
        '[TIMER] ⚠️  Cannot pause: isRunning=${state.isRunning}, isPaused=${state.isPaused}',
      );
      return;
    }

    final elapsedAtPause = _currentElapsedSeconds();
    _baselineElapsedSeconds = elapsedAtPause;

    // Stop the tick timer when pausing
    _tickTimer?.cancel();
    debugPrint('[TIMER] ⏱️  Tick timer cancelled for pause');

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.pauseSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    debugPrint('[TIMER] ⏸️  Timer paused - Elapsed: ${elapsedAtPause}s');
    state = state.copyWith(isPaused: true, elapsedSeconds: elapsedAtPause);
  }

  /// Resume a paused timer
  Future<void> resumeTimer() async {
    if (!state.isRunning || !state.isPaused || state.sessionId == null) {
      debugPrint(
        '[TIMER] ⚠️  Cannot resume: isRunning=${state.isRunning}, isPaused=${state.isPaused}',
      );
      return;
    }

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.resumeSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    debugPrint(
      '[TIMER] ▶️  Timer resumed - Continuing from ${state.elapsedSeconds}s',
    );
    _baselineElapsedSeconds = state.elapsedSeconds;
    state = state.copyWith(isPaused: false, startTime: DateTime.now());
    _startTickTimer();
  }

  /// Stop the current timer
  Future<void> stopTimer() async {
    if (state.sessionId == null) {
      debugPrint('[TIMER] ⚠️  No active session to stop');
      return;
    }

    // Cancel tick timer
    _tickTimer?.cancel();
    debugPrint('[TIMER] ⏱️  Tick timer cancelled');

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    final endTime = TimezoneHelper.getCurrentUtc();
    final duration = _currentElapsedSeconds();
    debugPrint(
      '[TIMER] 🛑 Timer stopped - SessionID: ${state.sessionId}, Final elapsed: ${duration}s (${(duration ~/ 3600)}h ${((duration % 3600) ~/ 60)}m ${(duration % 60)}s)',
    );

    await timerRepository.stopSession(
      state.sessionId!,
      endTime: endTime,
      totalSeconds: duration,
    );

    // Update task running state to false
    if (state.taskId != null) {
      final taskRepository = ref.read(taskRepositoryProvider);
      await taskRepository.updateTaskRunningState(state.taskId!, false);
      debugPrint('[TIMER] ✅ Updated task ${state.taskId} to not running');
    }

    state = TimerState.idle();
    _baselineElapsedSeconds = 0;
    debugPrint('[TIMER] 🔄 Timer state reset to idle');
  }

  /// Update elapsed time for UI display (called by tick mechanism)
  void updateElapsedTime(int seconds) {
    if (state.isRunning && !state.isPaused) {
      state = state.copyWith(elapsedSeconds: seconds);
    }
  }
}

/// Provider for timer state that triggers UI rebuilds on every tick
/// This watches the timerProvider and also emits when the timer is running
final timerTickProvider = StreamProvider<TimerState>((ref) {
  final timerState = ref.watch(timerProvider);

  if (!timerState.isRunning) {
    // Not running, just emit current state once
    return Stream.value(timerState);
  }

  // Running: emit state every 100ms for smooth UI updates
  debugPrint('[TIMER_TICK] Stream started for active timer');

  // Create a stream that emits the current state periodically
  final controller = StreamController<TimerState>();

  // Emit initial state immediately
  controller.add(timerState);

  // Then emit every 100ms
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    final currentState = ref.read(timerProvider);
    debugPrint('[TIMER_TICK] Emitting tick: ${currentState.elapsedSeconds}s');
    controller.add(currentState);
  });

  // Cancel timer when stream is closed
  controller.onCancel = () {
    timer.cancel();
    debugPrint('[TIMER_TICK] Stream cancelled');
  };

  return controller.stream;
});

/// Provider for timer state management
final timerProvider = StateNotifierProvider<TimerStateNotifier, TimerState>((
  ref,
) {
  return TimerStateNotifier(ref);
});

/// Provider for getting detailed timer debug info
/// Useful for tracking timer state in console logs
final timerDebugInfoProvider = Provider<String>((ref) {
  final state = ref.watch(timerProvider);
  final info =
      '[TIMER_DEBUG] '
      'isRunning=${state.isRunning}, '
      'isPaused=${state.isPaused}, '
      'sessionId=${state.sessionId}, '
      'taskId=${state.taskId}, '
      'projectId=${state.projectId}, '
      'elapsedSeconds=${state.elapsedSeconds}';
  debugPrint(info);
  return info;
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
