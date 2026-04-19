import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/focus_cycle_template_entity.dart';
import '../../domain/entities/focus_goal_entity.dart';
import '../../domain/entities/focus_run_record_entity.dart';
import '../../domain/entities/focus_run_state_entity.dart';
import '../../domain/usecases/focus_timer_usecases.dart';
import 'repository_provider.dart';

class FocusTimerNotifier extends StateNotifier<FocusRunStateEntity> {
  FocusTimerNotifier(this.ref) : super(const FocusRunStateEntity.idle()) {
    _initialization = _restoreIfAvailable();
  }

  final Ref ref;
  Timer? _tickTimer;
  DateTime? _runStartedAtUtc;
  FocusCycleTemplateEntity _template =
      const FocusCycleTemplateEntity.standard();
  late final Future<void> _initialization;

  Future<void> get ready => _initialization;

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreIfAvailable() async {
    final repo = ref.read(focusTimerRepositoryProvider);
    final restored = await repo.getActiveRunState();
    if (restored == null) {
      return;
    }

    state = restored;
    if (state.isActive) {
      _startTicker();
    }
  }

  Future<void> startRun({
    required FocusGoalEntity goal,
    FocusCycleTemplateEntity template =
        const FocusCycleTemplateEntity.standard(),
  }) async {
    _tickTimer?.cancel();
    _template = template;
    _runStartedAtUtc = DateTime.now().toUtc();

    state = StartFocusRunUseCase().execute(goal: goal, template: template);
    await _persistActiveState();
    _startTicker();
  }

  Future<void> pauseRun() async {
    state = PauseFocusRunUseCase().execute(state);
    _tickTimer?.cancel();
    await _persistActiveState();
  }

  Future<void> resumeRun() async {
    state = ResumeFocusRunUseCase().execute(state);
    await _persistActiveState();
    if (state.isActive) {
      _startTicker();
    }
  }

  Future<void> stopRun() async {
    final previous = state;
    _tickTimer?.cancel();

    if (previous.accumulatedFocusSeconds > 0 ||
        previous.accumulatedBreakSeconds > 0) {
      await _saveRunRecord(previous, completed: previous.isCompleted);
      ref.invalidate(focusTimerHistoryProvider);
    }

    state = StopFocusRunUseCase().execute();
    await ref.read(focusTimerRepositoryProvider).clearActiveRunState();
  }

  Future<void> advanceOneSecond() async {
    final previousPhase = state.phase;
    state = TickFocusRunUseCase().execute(state: state, template: _template);

    if (state.isCompleted && previousPhase != FocusRunPhase.completed) {
      _tickTimer?.cancel();
      await _saveRunRecord(state, completed: true);
      ref.invalidate(focusTimerHistoryProvider);
      await ref.read(focusTimerRepositoryProvider).clearActiveRunState();
      return;
    }

    await _persistActiveState();
  }

  double progress() => CalculateFocusProgressUseCase().execute(state);

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(advanceOneSecond());
    });
  }

  Future<void> _persistActiveState() async {
    if (state.isActive || state.isPaused) {
      await ref.read(focusTimerRepositoryProvider).saveActiveRunState(state);
      return;
    }

    await ref.read(focusTimerRepositoryProvider).clearActiveRunState();
  }

  Future<void> _saveRunRecord(
    FocusRunStateEntity runState, {
    required bool completed,
  }) async {
    final startedAt = _runStartedAtUtc ?? DateTime.now().toUtc();
    final record = FocusRunRecordEntity(
      id: const Uuid().v4(),
      startedAt: startedAt,
      endedAt: DateTime.now().toUtc(),
      targetFocusMinutes: (runState.targetFocusSeconds / 60).round(),
      actualFocusSeconds: runState.accumulatedFocusSeconds,
      actualBreakSeconds: runState.accumulatedBreakSeconds,
      focusMinutes: _template.focusMinutes,
      shortBreakMinutes: _template.shortBreakMinutes,
      longBreakMinutes: _template.longBreakMinutes,
      longBreakEveryNCycles: _template.longBreakEveryNCycles,
      completed: completed,
    );

    await ref.read(focusTimerRepositoryProvider).saveRunRecord(record);
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusRunStateEntity>((ref) {
      return FocusTimerNotifier(ref);
    });

final focusTimerHistoryProvider = FutureProvider<List<FocusRunRecordEntity>>((
  ref,
) {
  final repo = ref.watch(focusTimerRepositoryProvider);
  return repo.getRecentRunRecords(limit: 12);
});
