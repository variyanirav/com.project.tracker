/// Persisted summary of a completed or interrupted focus run.
class FocusRunRecordEntity {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetFocusMinutes;
  final int actualFocusSeconds;
  final int actualBreakSeconds;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryNCycles;
  final bool completed;

  const FocusRunRecordEntity({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.targetFocusMinutes,
    required this.actualFocusSeconds,
    required this.actualBreakSeconds,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakEveryNCycles,
    required this.completed,
  });
}
