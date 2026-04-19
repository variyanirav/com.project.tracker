import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/focus_cycle_template_entity.dart';
import 'package:project_tracker/domain/entities/focus_goal_entity.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:project_tracker/domain/usecases/focus_timer_usecases.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/focus_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Focus timer integration', () {
    test('60 minute target path completes for 25/5 cycle pattern', () {
      const template = FocusCycleTemplateEntity.standard();
      const goal = FocusGoalEntity(
        targetFocusMinutes: 60,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      var state = StartFocusRunUseCase().execute(
        goal: goal,
        template: template,
      );

      expect(state.phase, FocusRunPhase.focus);
      expect(state.currentPhaseTotalSeconds, 1500);

      state = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );
      expect(state.phase, FocusRunPhase.shortBreak);

      state = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );
      expect(state.phase, FocusRunPhase.focus);
      expect(state.currentPhaseTotalSeconds, 1500);

      state = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );
      expect(state.phase, FocusRunPhase.shortBreak);

      state = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );
      expect(state.phase, FocusRunPhase.focus);
      expect(state.currentPhaseTotalSeconds, 600);

      state = ComputeNextPhaseUseCase().execute(
        state: state,
        template: template,
      );
      expect(state.phase, FocusRunPhase.completed);
      expect(state.accumulatedFocusSeconds, 3600);
    });

    test('provider restores active state after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      final container1 = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final notifier1 = container1.read(focusTimerProvider.notifier);
      await notifier1.startRun(
        goal: const FocusGoalEntity(targetFocusMinutes: 10),
        template: const FocusCycleTemplateEntity.standard(),
      );
      await notifier1.advanceOneSecond();

      final runningState = container1.read(focusTimerProvider);
      expect(runningState.phase, FocusRunPhase.focus);
      expect(runningState.remainingSeconds, lessThan(600));

      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container2.dispose);
      addTearDown(() async => db.close());

      final restoredNotifier = container2.read(focusTimerProvider.notifier);
      await restoredNotifier.ready;

      FocusRunStateEntity restored = container2.read(focusTimerProvider);
      for (
        var attempt = 0;
        attempt < 20 && restored.phase == FocusRunPhase.idle;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        restored = container2.read(focusTimerProvider);
      }

      expect(restored.phase, FocusRunPhase.focus);
      expect(restored.remainingSeconds, runningState.remainingSeconds);

      await container2.read(focusTimerProvider.notifier).stopRun();
    });
  });
}
