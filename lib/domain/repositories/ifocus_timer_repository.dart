import '../entities/focus_run_record_entity.dart';
import '../entities/focus_run_state_entity.dart';

/// Repository contract for focus timer persistence.
abstract class IFocusTimerRepository {
  /// Save in-progress state for crash/restart recovery.
  Future<void> saveActiveRunState(FocusRunStateEntity state);

  /// Restore in-progress state if one exists.
  Future<FocusRunStateEntity?> getActiveRunState();

  /// Clear in-progress state.
  Future<void> clearActiveRunState();

  /// Save a run summary entry.
  Future<void> saveRunRecord(FocusRunRecordEntity record);

  /// Fetch latest runs (newest first).
  Future<List<FocusRunRecordEntity>> getRecentRunRecords({int limit = 30});
}
