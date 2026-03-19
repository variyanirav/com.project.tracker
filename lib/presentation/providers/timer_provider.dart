import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for current timer session
final currentTimerProvider = StateProvider<TimerState>((ref) {
  return TimerState.idle();
});

/// Provider for starting a timer
final startTimerProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  // TODO: Implement timer start
});

/// Provider for pausing a timer
final pauseTimerProvider = FutureProvider<void>((ref) async {
  // TODO: Implement timer pause
});

/// Provider for resuming a timer
final resumeTimerProvider = FutureProvider<void>((ref) async {
  // TODO: Implement timer resume
});

/// Provider for stopping a timer
final stopTimerProvider = FutureProvider<void>((ref) async {
  // TODO: Implement timer stop
});

/// Timer state model
class TimerState {
  final String? taskId;
  final String? projectId;
  final int elapsedSeconds;
  final bool isRunning;
  final bool isPaused;

  TimerState({
    required this.taskId,
    required this.projectId,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.isPaused,
  });

  factory TimerState.idle() {
    return TimerState(
      taskId: null,
      projectId: null,
      elapsedSeconds: 0,
      isRunning: false,
      isPaused: false,
    );
  }

  TimerState copyWith({
    String? taskId,
    String? projectId,
    int? elapsedSeconds,
    bool? isRunning,
    bool? isPaused,
  }) {
    return TimerState(
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
