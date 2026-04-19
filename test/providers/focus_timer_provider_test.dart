import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/focus_timer_provider.dart';
import 'package:project_tracker/domain/entities/focus_cycle_template_entity.dart';
import 'package:project_tracker/domain/entities/focus_goal_entity.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('focusTimerProvider', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('provider transition flow runs focus -> break -> focus', () async {
      final notifier = container.read(focusTimerProvider.notifier);
      const template = FocusCycleTemplateEntity(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 1,
        longBreakEveryNCycles: 4,
      );
      const goal = FocusGoalEntity(
        targetFocusMinutes: 2,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      await notifier.startRun(goal: goal, template: template);
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.focus);

      for (var i = 0; i < 60; i++) {
        await notifier.advanceOneSecond();
      }
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.shortBreak);

      for (var i = 0; i < 60; i++) {
        await notifier.advanceOneSecond();
      }
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.focus);

      await notifier.stopRun();
    });

    test('pause and resume keeps remaining time frozen while paused', () async {
      final notifier = container.read(focusTimerProvider.notifier);
      const template = FocusCycleTemplateEntity(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 1,
        longBreakEveryNCycles: 4,
      );
      const goal = FocusGoalEntity(
        targetFocusMinutes: 2,
        autoStartBreak: true,
        autoStartFocus: true,
        progressMode: FocusProgressMode.focusOnly,
      );

      await notifier.startRun(goal: goal, template: template);
      await notifier.advanceOneSecond();
      final beforePause = container.read(focusTimerProvider).remainingSeconds;

      await notifier.pauseRun();
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.paused);

      await notifier.advanceOneSecond();
      final whilePaused = container.read(focusTimerProvider).remainingSeconds;
      expect(whilePaused, beforePause);

      await notifier.resumeRun();
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.focus);

      await notifier.stopRun();
    });

    test('auto-start toggles are respected at phase boundaries', () async {
      final notifier = container.read(focusTimerProvider.notifier);
      const template = FocusCycleTemplateEntity(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 1,
        longBreakEveryNCycles: 4,
      );
      const goal = FocusGoalEntity(
        targetFocusMinutes: 3,
        autoStartBreak: false,
        autoStartFocus: false,
        progressMode: FocusProgressMode.focusOnly,
      );

      await notifier.startRun(goal: goal, template: template);
      for (var i = 0; i < 60; i++) {
        await notifier.advanceOneSecond();
      }

      final pausedAtBreak = container.read(focusTimerProvider);
      expect(pausedAtBreak.phase, FocusRunPhase.paused);
      expect(pausedAtBreak.lastActivePhase, FocusRunPhase.shortBreak);

      await notifier.resumeRun();
      expect(container.read(focusTimerProvider).phase, FocusRunPhase.shortBreak);

      for (var i = 0; i < 60; i++) {
        await notifier.advanceOneSecond();
      }

      final pausedAtFocus = container.read(focusTimerProvider);
      expect(pausedAtFocus.phase, FocusRunPhase.paused);
      expect(pausedAtFocus.lastActivePhase, FocusRunPhase.focus);

      await notifier.stopRun();
    });
  });
}
