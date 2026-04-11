import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'project_provider.dart';
import 'task_provider.dart';
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

        state = state.copyWith(elapsedSeconds: elapsed);
      }
    });
  }

  int _currentElapsedSeconds() {
    if (!state.isRunning || state.isPaused) {
      return state.elapsedSeconds;
    }
    return _baselineElapsedSeconds +
        DateTime.now().difference(state.startTime).inSeconds;
  }

  /// Start a timer for a task
  Future<void> startTimer(
    String taskId,
    String projectId, {
    String? startNote,
  }) async {
    if (state.isRunning) {
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
      } catch (e) {
        // No paused session found, will create new one
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

    // If resuming, mark the session as not paused
    if (pausedSessionEntity != null) {
      await timerRepository.resumeSession(
        session.id,
        TimezoneHelper.getCurrentUtc(),
      );
    }

    final trimmedStartNote = startNote?.trim();
    if (trimmedStartNote != null && trimmedStartNote.isNotEmpty) {
      try {
        await timerRepository.updateSessionStartNote(
          session.id,
          trimmedStartNote,
        );
      } catch (e) {
        debugPrint('[TIMER] Failed to save start note: $e');
      }
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

    // Auto-transition task from "To Do" to "In Progress" when timer starts.
    final currentStatus = task?.status.trim().toLowerCase().replaceAll(' ', '');
    if (currentStatus == 'todo') {
      await taskRepository.updateTaskStatus(taskId, 'inProgress');
    }

    // Refresh task providers so status/running state updates immediately in UI.
    ref.invalidate(tasksProvider);
    ref.invalidate(activeTaskProvider);
    ref.invalidate(taskByIdProvider(taskId));
    ref.invalidate(tasksByProjectProvider(projectId));

    _startTickTimer();
  }

  /// Pause the current timer
  Future<void> pauseTimer() async {
    if (!state.isRunning || state.isPaused || state.sessionId == null) {
      return;
    }

    final elapsedAtPause = _currentElapsedSeconds();
    _baselineElapsedSeconds = elapsedAtPause;

    // Stop the tick timer when pausing
    _tickTimer?.cancel();

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.pauseSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    state = state.copyWith(isPaused: true, elapsedSeconds: elapsedAtPause);
  }

  /// Resume a paused timer
  Future<void> resumeTimer() async {
    if (!state.isRunning || !state.isPaused || state.sessionId == null) {
      return;
    }

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    await timerRepository.resumeSession(
      state.sessionId!,
      TimezoneHelper.getCurrentUtc(),
    );

    _baselineElapsedSeconds = state.elapsedSeconds;
    state = state.copyWith(isPaused: false, startTime: DateTime.now());
    _startTickTimer();
  }

  /// Stop the current timer
  Future<void> stopTimer({String? stopNote}) async {
    if (state.sessionId == null) {
      return;
    }

    final currentTaskId = state.taskId;
    final currentProjectId = state.projectId;

    // Cancel tick timer
    _tickTimer?.cancel();

    final timerRepository = ref.read(timerSessionRepositoryProvider);
    final endTime = TimezoneHelper.getCurrentUtc();
    final duration = _currentElapsedSeconds();

    await timerRepository.stopSession(
      state.sessionId!,
      endTime: endTime,
      totalSeconds: duration,
    );

    final trimmedStopNote = stopNote?.trim();
    if (trimmedStopNote != null && trimmedStopNote.isNotEmpty) {
      try {
        await timerRepository.updateSessionStopNote(
          state.sessionId!,
          trimmedStopNote,
        );
      } catch (e) {
        debugPrint('[TIMER] Failed to save stop note: $e');
      }
    }

    // Persist the latest task total seconds and running state.
    if (currentTaskId != null) {
      final taskRepository = ref.read(taskRepositoryProvider);
      final totalTaskSeconds = await timerRepository.getTaskTotalSeconds(
        currentTaskId,
      );
      await taskRepository.updateTaskTotalSeconds(
        currentTaskId,
        totalTaskSeconds,
      );
      await taskRepository.updateTaskRunningState(currentTaskId, false);
    }

    // Refresh dependent UI providers so project/task stats update immediately.
    ref.invalidate(tasksProvider);
    ref.invalidate(activeTaskProvider);
    if (currentTaskId != null) {
      ref.invalidate(taskByIdProvider(currentTaskId));
    }
    if (currentProjectId != null) {
      ref.invalidate(tasksByProjectProvider(currentProjectId));
      ref.invalidate(projectTotalHoursProvider(currentProjectId));
      ref.invalidate(projectTodayHoursProvider(currentProjectId));
      ref.invalidate(projectWeekHoursProvider(currentProjectId));
      ref.invalidate(projectMonthHoursProvider(currentProjectId));
    }

    // Dashboard aggregates
    ref.invalidate(todayTotalHoursProvider);
    ref.invalidate(weekTotalHoursProvider);
    ref.invalidate(dailyProgressProvider);

    state = TimerState.idle();
    _baselineElapsedSeconds = 0;
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

  // Create a stream that emits the current state periodically
  final controller = StreamController<TimerState>();

  // Emit initial state immediately
  controller.add(timerState);

  // Then emit every 100ms
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    final currentState = ref.read(timerProvider);
    controller.add(currentState);
  });

  // Cancel timer when stream is closed
  controller.onCancel = () {
    timer.cancel();
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

/// Params for updating timer session notes.
class UpdateTimerSessionNotesParams {
  final String sessionId;
  final String? notes;

  const UpdateTimerSessionNotesParams({required this.sessionId, this.notes});
}

/// Provider for updating notes on a timer session.
final updateTimerSessionNotesProvider =
    FutureProvider.family<void, UpdateTimerSessionNotesParams>((
      ref,
      params,
    ) async {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      await timerRepository.updateSessionNotes(params.sessionId, params.notes);

      ref.invalidate(timerSessionsProvider);
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

/// Params for updating a timer session start note.
class UpdateTimerSessionStartNoteParams {
  final String sessionId;
  final String? startNote;

  const UpdateTimerSessionStartNoteParams({
    required this.sessionId,
    this.startNote,
  });
}

/// Provider for updating the start note on a timer session.
final updateTimerSessionStartNoteProvider =
    FutureProvider.family<void, UpdateTimerSessionStartNoteParams>((
      ref,
      params,
    ) async {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      await timerRepository.updateSessionStartNote(
        params.sessionId,
        params.startNote,
      );
    });

/// Params for updating a timer session stop note.
class UpdateTimerSessionStopNoteParams {
  final String sessionId;
  final String? stopNote;

  const UpdateTimerSessionStopNoteParams({
    required this.sessionId,
    this.stopNote,
  });
}

/// Provider for updating the stop note on a timer session.
final updateTimerSessionStopNoteProvider =
    FutureProvider.family<void, UpdateTimerSessionStopNoteParams>((
      ref,
      params,
    ) async {
      final timerRepository = ref.watch(timerSessionRepositoryProvider);
      await timerRepository.updateSessionStopNote(
        params.sessionId,
        params.stopNote,
      );
    });
