import 'focus_goal_entity.dart';

/// Runtime phase for focus cycle engine.
enum FocusRunPhase { idle, focus, shortBreak, longBreak, paused, completed }

/// Aggregate state for a standalone focus run.
class FocusRunStateEntity {
  final FocusRunPhase phase;
  final FocusRunPhase? lastActivePhase;
  final int remainingSeconds;
  final int currentPhaseTotalSeconds;
  final int targetFocusSeconds;
  final int accumulatedFocusSeconds;
  final int accumulatedBreakSeconds;
  final int completedFocusCycles;
  final bool autoStartBreak;
  final bool autoStartFocus;
  final FocusProgressMode progressMode;

  const FocusRunStateEntity({
    required this.phase,
    this.lastActivePhase,
    required this.remainingSeconds,
    required this.currentPhaseTotalSeconds,
    required this.targetFocusSeconds,
    required this.accumulatedFocusSeconds,
    required this.accumulatedBreakSeconds,
    required this.completedFocusCycles,
    required this.autoStartBreak,
    required this.autoStartFocus,
    required this.progressMode,
  });

  const FocusRunStateEntity.idle()
    : phase = FocusRunPhase.idle,
      lastActivePhase = null,
      remainingSeconds = 0,
      currentPhaseTotalSeconds = 0,
      targetFocusSeconds = 0,
      accumulatedFocusSeconds = 0,
      accumulatedBreakSeconds = 0,
      completedFocusCycles = 0,
      autoStartBreak = true,
      autoStartFocus = true,
      progressMode = FocusProgressMode.focusOnly;

  bool get isActive =>
      phase == FocusRunPhase.focus ||
      phase == FocusRunPhase.shortBreak ||
      phase == FocusRunPhase.longBreak;

  bool get isPaused => phase == FocusRunPhase.paused;
  bool get isCompleted => phase == FocusRunPhase.completed;

  FocusRunStateEntity copyWith({
    FocusRunPhase? phase,
    FocusRunPhase? lastActivePhase,
    bool clearLastActivePhase = false,
    int? remainingSeconds,
    int? currentPhaseTotalSeconds,
    int? targetFocusSeconds,
    int? accumulatedFocusSeconds,
    int? accumulatedBreakSeconds,
    int? completedFocusCycles,
    bool? autoStartBreak,
    bool? autoStartFocus,
    FocusProgressMode? progressMode,
  }) {
    return FocusRunStateEntity(
      phase: phase ?? this.phase,
      lastActivePhase: clearLastActivePhase
          ? null
          : (lastActivePhase ?? this.lastActivePhase),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentPhaseTotalSeconds:
          currentPhaseTotalSeconds ?? this.currentPhaseTotalSeconds,
      targetFocusSeconds: targetFocusSeconds ?? this.targetFocusSeconds,
      accumulatedFocusSeconds:
          accumulatedFocusSeconds ?? this.accumulatedFocusSeconds,
      accumulatedBreakSeconds:
          accumulatedBreakSeconds ?? this.accumulatedBreakSeconds,
      completedFocusCycles: completedFocusCycles ?? this.completedFocusCycles,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      progressMode: progressMode ?? this.progressMode,
    );
  }
}
