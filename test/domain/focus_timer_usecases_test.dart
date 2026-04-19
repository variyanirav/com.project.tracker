import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/domain/entities/focus_cycle_template_entity.dart';
import 'package:project_tracker/domain/entities/focus_goal_entity.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:project_tracker/domain/usecases/focus_timer_usecases.dart';

void main() {
  group('Focus timer domain use cases', () {
    test('next phase from focus goes to short break', () {
      const template = FocusCycleTemplateEntity.standard();
      const state = FocusRunStateEntity(
        phase: FocusRunPhase.focus,
        remainingSeconds: 1,
        currentPhaseTotalSeconds: 1500,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 0,
        accumulatedBreakSeconds: 0,
        completedFocusCycles: 0,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      final result = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );

      expect(result.phase, FocusRunPhase.shortBreak);
      expect(result.remainingSeconds, template.shortBreakSeconds);
      expect(result.accumulatedFocusSeconds, 1500);
      expect(result.completedFocusCycles, 1);
    });

    test('next phase from short break returns to focus', () {
      const template = FocusCycleTemplateEntity.standard();
      const state = FocusRunStateEntity(
        phase: FocusRunPhase.shortBreak,
        remainingSeconds: 1,
        currentPhaseTotalSeconds: 300,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 1500,
        accumulatedBreakSeconds: 0,
        completedFocusCycles: 1,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      final result = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );

      expect(result.phase, FocusRunPhase.focus);
      expect(result.remainingSeconds, template.focusSeconds);
      expect(result.accumulatedBreakSeconds, 300);
      expect(result.completedFocusCycles, 1);
    });

    test('long break is selected on configured cycle boundary', () {
      const template = FocusCycleTemplateEntity.standard();
      const state = FocusRunStateEntity(
        phase: FocusRunPhase.focus,
        remainingSeconds: 1,
        currentPhaseTotalSeconds: 1500,
        targetFocusSeconds: 10000,
        accumulatedFocusSeconds: 4500,
        accumulatedBreakSeconds: 0,
        completedFocusCycles: 3,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      final result = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );

      expect(result.phase, FocusRunPhase.longBreak);
      expect(result.remainingSeconds, template.longBreakSeconds);
      expect(result.completedFocusCycles, 4);
    });

    test('goal completion triggers completed phase', () {
      const template = FocusCycleTemplateEntity.standard();
      const state = FocusRunStateEntity(
        phase: FocusRunPhase.focus,
        remainingSeconds: 1,
        currentPhaseTotalSeconds: 600,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 3000,
        accumulatedBreakSeconds: 600,
        completedFocusCycles: 2,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      final result = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );

      expect(result.phase, FocusRunPhase.completed);
      expect(result.accumulatedFocusSeconds, 3600);
      expect(result.remainingSeconds, 0);
    });

    test('progress math supports both modes', () {
      const focusOnlyState = FocusRunStateEntity(
        phase: FocusRunPhase.focus,
        remainingSeconds: 900,
        currentPhaseTotalSeconds: 1500,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 1800,
        accumulatedBreakSeconds: 600,
        completedFocusCycles: 1,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      const focusPlusBreakState = FocusRunStateEntity(
        phase: FocusRunPhase.shortBreak,
        remainingSeconds: 120,
        currentPhaseTotalSeconds: 300,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 1800,
        accumulatedBreakSeconds: 600,
        completedFocusCycles: 1,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusPlusBreak,
      );

      final useCase = CalculateFocusProgressUseCase();

      final focusOnly = useCase.execute(focusOnlyState);
      final focusPlusBreak = useCase.execute(focusPlusBreakState);

      expect(focusOnly, closeTo(0.5, 0.0001));
      expect(focusPlusBreak, closeTo(0.5714, 0.001));
    });

    test('start use case slices first focus block to remaining goal', () {
      const template = FocusCycleTemplateEntity.standard();
      const goal = FocusGoalEntity(
        targetFocusMinutes: 10,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      final state = StartFocusRunUseCase().execute(
        goal: goal,
        template: template,
      );

      expect(state.phase, FocusRunPhase.focus);
      expect(state.remainingSeconds, 600);
      expect(state.currentPhaseTotalSeconds, 600);
      expect(state.targetFocusSeconds, 600);
    });
  });
}
