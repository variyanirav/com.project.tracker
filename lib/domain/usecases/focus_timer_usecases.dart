import '../entities/focus_cycle_template_entity.dart';
import '../entities/focus_goal_entity.dart';
import '../entities/focus_run_state_entity.dart';

class StartFocusRunUseCase {
  FocusRunStateEntity execute({
    required FocusGoalEntity goal,
    required FocusCycleTemplateEntity template,
  }) {
    final firstFocusSeconds = _nextFocusSlice(
      targetFocusSeconds: goal.targetFocusSeconds,
      accumulatedFocusSeconds: 0,
      focusSeconds: template.focusSeconds,
    );

    return FocusRunStateEntity(
      phase: FocusRunPhase.focus,
      remainingSeconds: firstFocusSeconds,
      currentPhaseTotalSeconds: firstFocusSeconds,
      targetFocusSeconds: goal.targetFocusSeconds,
      accumulatedFocusSeconds: 0,
      accumulatedBreakSeconds: 0,
      completedFocusCycles: 0,
      autoStartBreak: goal.autoStartBreak,
      autoStartFocus: goal.autoStartFocus,
      progressMode: goal.progressMode,
    );
  }
}

class PauseFocusRunUseCase {
  FocusRunStateEntity execute(FocusRunStateEntity state) {
    if (!state.isActive) {
      return state;
    }
    return state.copyWith(
      phase: FocusRunPhase.paused,
      lastActivePhase: state.phase,
    );
  }
}

class ResumeFocusRunUseCase {
  FocusRunStateEntity execute(FocusRunStateEntity state) {
    if (!state.isPaused || state.lastActivePhase == null) {
      return state;
    }

    return state.copyWith(
      phase: state.lastActivePhase,
      clearLastActivePhase: true,
    );
  }
}

class StopFocusRunUseCase {
  FocusRunStateEntity execute() => const FocusRunStateEntity.idle();
}

class TickFocusRunUseCase {
  FocusRunStateEntity execute({
    required FocusRunStateEntity state,
    required FocusCycleTemplateEntity template,
  }) {
    if (!state.isActive) {
      return state;
    }

    if (state.remainingSeconds > 1) {
      return state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    }

    return ComputeNextPhaseUseCase().execute(state: state, template: template);
  }
}

class ComputeNextPhaseUseCase {
  FocusRunStateEntity execute({
    required FocusRunStateEntity state,
    required FocusCycleTemplateEntity template,
  }) {
    if (!state.isActive) {
      return state;
    }

    if (state.phase == FocusRunPhase.focus) {
      final newAccumulatedFocus =
          state.accumulatedFocusSeconds + state.currentPhaseTotalSeconds;
      final newCompletedCycles = state.completedFocusCycles + 1;

      if (newAccumulatedFocus >= state.targetFocusSeconds) {
        return state.copyWith(
          phase: FocusRunPhase.completed,
          clearLastActivePhase: true,
          remainingSeconds: 0,
          currentPhaseTotalSeconds: 0,
          accumulatedFocusSeconds: newAccumulatedFocus,
          completedFocusCycles: newCompletedCycles,
        );
      }

      final isLongBreak =
          newCompletedCycles % template.longBreakEveryNCycles == 0;
      final nextBreakPhase = isLongBreak
          ? FocusRunPhase.longBreak
          : FocusRunPhase.shortBreak;
      final nextBreakSeconds = isLongBreak
          ? template.longBreakSeconds
          : template.shortBreakSeconds;

      if (!state.autoStartBreak) {
        return state.copyWith(
          phase: FocusRunPhase.paused,
          lastActivePhase: nextBreakPhase,
          remainingSeconds: nextBreakSeconds,
          currentPhaseTotalSeconds: nextBreakSeconds,
          accumulatedFocusSeconds: newAccumulatedFocus,
          completedFocusCycles: newCompletedCycles,
        );
      }

      return state.copyWith(
        phase: nextBreakPhase,
        clearLastActivePhase: true,
        remainingSeconds: nextBreakSeconds,
        currentPhaseTotalSeconds: nextBreakSeconds,
        accumulatedFocusSeconds: newAccumulatedFocus,
        completedFocusCycles: newCompletedCycles,
      );
    }

    final newAccumulatedBreak =
        state.accumulatedBreakSeconds + state.currentPhaseTotalSeconds;
    final nextFocusSeconds = _nextFocusSlice(
      targetFocusSeconds: state.targetFocusSeconds,
      accumulatedFocusSeconds: state.accumulatedFocusSeconds,
      focusSeconds: template.focusSeconds,
    );

    if (!state.autoStartFocus) {
      return state.copyWith(
        phase: FocusRunPhase.paused,
        lastActivePhase: FocusRunPhase.focus,
        remainingSeconds: nextFocusSeconds,
        currentPhaseTotalSeconds: nextFocusSeconds,
        accumulatedBreakSeconds: newAccumulatedBreak,
      );
    }

    return state.copyWith(
      phase: FocusRunPhase.focus,
      clearLastActivePhase: true,
      remainingSeconds: nextFocusSeconds,
      currentPhaseTotalSeconds: nextFocusSeconds,
      accumulatedBreakSeconds: newAccumulatedBreak,
    );
  }
}

class CalculateFocusProgressUseCase {
  double execute(FocusRunStateEntity state) {
    if (state.targetFocusSeconds <= 0) {
      return 0.0;
    }

    if (state.progressMode == FocusProgressMode.focusOnly) {
      return (state.accumulatedFocusSeconds / state.targetFocusSeconds).clamp(
        0.0,
        1.0,
      );
    }

    final tracked =
        state.accumulatedFocusSeconds + state.accumulatedBreakSeconds;
    final denominator =
        state.targetFocusSeconds + state.accumulatedBreakSeconds;

    if (denominator <= 0) {
      return 0.0;
    }

    return (tracked / denominator).clamp(0.0, 1.0);
  }
}

int _nextFocusSlice({
  required int targetFocusSeconds,
  required int accumulatedFocusSeconds,
  required int focusSeconds,
}) {
  final remainingGoal = targetFocusSeconds - accumulatedFocusSeconds;
  if (remainingGoal <= 0) {
    return 0;
  }

  return remainingGoal < focusSeconds ? remainingGoal : focusSeconds;
}
