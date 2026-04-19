import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/focus_timer_repository_impl.dart';
import 'package:project_tracker/domain/entities/focus_goal_entity.dart';
import 'package:project_tracker/domain/entities/focus_run_record_entity.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FocusTimerRepositoryImpl', () {
    late AppDatabase db;
    late FocusTimerRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FocusTimerRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('migration creates focus_runs table', () async {
      final row = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'focus_runs'",
          )
          .getSingleOrNull();

      expect(row, isNotNull);
      expect(row!.read<String>('name'), 'focus_runs');
    });

    test('save and fetch recent run records works', () async {
      final now = DateTime.now().toUtc();

      await repository.saveRunRecord(
        FocusRunRecordEntity(
          id: 'run-1',
          startedAt: now.subtract(const Duration(minutes: 40)),
          endedAt: now,
          targetFocusMinutes: 60,
          actualFocusSeconds: 3600,
          actualBreakSeconds: 600,
          focusMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          longBreakEveryNCycles: 4,
          completed: true,
        ),
      );

      final records = await repository.getRecentRunRecords(limit: 5);

      expect(records.length, 1);
      expect(records.first.id, 'run-1');
      expect(records.first.targetFocusMinutes, 60);
      expect(records.first.actualFocusSeconds, 3600);
      expect(records.first.completed, isTrue);
    });

    test('active run state persists and restores from preferences', () async {
      const state = FocusRunStateEntity(
        phase: FocusRunPhase.focus,
        lastActivePhase: null,
        remainingSeconds: 1200,
        currentPhaseTotalSeconds: 1500,
        targetFocusSeconds: 3600,
        accumulatedFocusSeconds: 900,
        accumulatedBreakSeconds: 300,
        completedFocusCycles: 1,
        autoStartBreak: true,
        autoStartFocus: false,
        progressMode: FocusProgressMode.focusOnly,
      );

      await repository.saveActiveRunState(state);

      final restored = await repository.getActiveRunState();
      expect(restored, isNotNull);
      expect(restored!.phase, FocusRunPhase.focus);
      expect(restored.remainingSeconds, 1200);
      expect(restored.currentPhaseTotalSeconds, 1500);
      expect(restored.targetFocusSeconds, 3600);
      expect(restored.accumulatedFocusSeconds, 900);
      expect(restored.accumulatedBreakSeconds, 300);
      expect(restored.completedFocusCycles, 1);
      expect(restored.autoStartBreak, isTrue);
      expect(restored.autoStartFocus, isFalse);
      expect(restored.progressMode, FocusProgressMode.focusOnly);

      await repository.clearActiveRunState();
      final afterClear = await repository.getActiveRunState();
      expect(afterClear, isNull);
    });
  });
}
