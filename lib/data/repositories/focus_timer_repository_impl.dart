import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/focus_goal_entity.dart';
import '../../domain/entities/focus_run_record_entity.dart';
import '../../domain/entities/focus_run_state_entity.dart';
import '../../domain/repositories/ifocus_timer_repository.dart';
import '../database/app_database.dart';

class FocusTimerRepositoryImpl implements IFocusTimerRepository {
  FocusTimerRepositoryImpl(this.db);

  static const String _activeRunStateKey = 'focus_active_run_state_json';

  final AppDatabase db;

  @override
  Future<void> saveActiveRunState(FocusRunStateEntity state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRunStateKey, jsonEncode(_encodeState(state)));
  }

  @override
  Future<FocusRunStateEntity?> getActiveRunState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeRunStateKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return _decodeState(decoded);
  }

  @override
  Future<void> clearActiveRunState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRunStateKey);
  }

  @override
  Future<void> saveRunRecord(FocusRunRecordEntity record) async {
    if (record.endedAt == null) {
      await db.customStatement(
        '''
        INSERT INTO focus_runs (
          id,
          started_at,
          ended_at,
          target_focus_minutes,
          actual_focus_seconds,
          actual_break_seconds,
          focus_minutes,
          short_break_minutes,
          long_break_minutes,
          long_break_every_n_cycles,
          completed,
          created_at
        ) VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          record.id,
          record.startedAt.toUtc().millisecondsSinceEpoch,
          record.targetFocusMinutes,
          record.actualFocusSeconds,
          record.actualBreakSeconds,
          record.focusMinutes,
          record.shortBreakMinutes,
          record.longBreakMinutes,
          record.longBreakEveryNCycles,
          record.completed ? 1 : 0,
          DateTime.now().toUtc().millisecondsSinceEpoch,
        ],
      );
      return;
    }

    await db.customStatement(
      '''
      INSERT INTO focus_runs (
        id,
        started_at,
        ended_at,
        target_focus_minutes,
        actual_focus_seconds,
        actual_break_seconds,
        focus_minutes,
        short_break_minutes,
        long_break_minutes,
        long_break_every_n_cycles,
        completed,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        record.id,
        record.startedAt.toUtc().millisecondsSinceEpoch,
        record.endedAt!.toUtc().millisecondsSinceEpoch,
        record.targetFocusMinutes,
        record.actualFocusSeconds,
        record.actualBreakSeconds,
        record.focusMinutes,
        record.shortBreakMinutes,
        record.longBreakMinutes,
        record.longBreakEveryNCycles,
        record.completed ? 1 : 0,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<List<FocusRunRecordEntity>> getRecentRunRecords({
    int limit = 30,
  }) async {
    final rows = await db
        .customSelect(
          '''
      SELECT
        id,
        started_at,
        ended_at,
        target_focus_minutes,
        actual_focus_seconds,
        actual_break_seconds,
        focus_minutes,
        short_break_minutes,
        long_break_minutes,
        long_break_every_n_cycles,
        completed
      FROM focus_runs
      ORDER BY started_at DESC
      LIMIT ?
      ''',
          variables: [Variable.withInt(limit)],
        )
        .get();

    return rows.map(_rowToRecord).toList();
  }

  FocusRunRecordEntity _rowToRecord(QueryRow row) {
    final startedAtMs = row.read<int>('started_at');
    final endedAtMs = row.readNullable<int>('ended_at');

    return FocusRunRecordEntity(
      id: row.read<String>('id'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs, isUtc: true),
      endedAt: endedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endedAtMs, isUtc: true),
      targetFocusMinutes: row.read<int>('target_focus_minutes'),
      actualFocusSeconds: row.read<int>('actual_focus_seconds'),
      actualBreakSeconds: row.read<int>('actual_break_seconds'),
      focusMinutes: row.read<int>('focus_minutes'),
      shortBreakMinutes: row.read<int>('short_break_minutes'),
      longBreakMinutes: row.read<int>('long_break_minutes'),
      longBreakEveryNCycles: row.read<int>('long_break_every_n_cycles'),
      completed: row.read<int>('completed') == 1,
    );
  }

  Map<String, dynamic> _encodeState(FocusRunStateEntity state) {
    return {
      'phase': state.phase.name,
      'lastActivePhase': state.lastActivePhase?.name,
      'remainingSeconds': state.remainingSeconds,
      'currentPhaseTotalSeconds': state.currentPhaseTotalSeconds,
      'targetFocusSeconds': state.targetFocusSeconds,
      'accumulatedFocusSeconds': state.accumulatedFocusSeconds,
      'accumulatedBreakSeconds': state.accumulatedBreakSeconds,
      'completedFocusCycles': state.completedFocusCycles,
      'autoStartBreak': state.autoStartBreak,
      'autoStartFocus': state.autoStartFocus,
      'progressMode': state.progressMode.name,
    };
  }

  FocusRunStateEntity _decodeState(Map<String, dynamic> map) {
    return FocusRunStateEntity(
      phase: FocusRunPhase.values.firstWhere((e) => e.name == map['phase']),
      lastActivePhase: map['lastActivePhase'] == null
          ? null
          : FocusRunPhase.values.firstWhere(
              (e) => e.name == map['lastActivePhase'],
            ),
      remainingSeconds: map['remainingSeconds'] as int,
      currentPhaseTotalSeconds: map['currentPhaseTotalSeconds'] as int,
      targetFocusSeconds: map['targetFocusSeconds'] as int,
      accumulatedFocusSeconds: map['accumulatedFocusSeconds'] as int,
      accumulatedBreakSeconds: map['accumulatedBreakSeconds'] as int,
      completedFocusCycles: map['completedFocusCycles'] as int,
      autoStartBreak: map['autoStartBreak'] as bool,
      autoStartFocus: map['autoStartFocus'] as bool,
      progressMode: FocusProgressMode.values.firstWhere(
        (e) => e.name == map['progressMode'],
      ),
    );
  }
}
