/// Progress mode for representing focus completion.
enum FocusProgressMode { focusOnly, focusPlusBreak }

/// Goal settings for a focus run.
class FocusGoalEntity {
  final int targetFocusMinutes;
  final bool autoStartBreak;
  final bool autoStartFocus;
  final FocusProgressMode progressMode;

  const FocusGoalEntity({
    required this.targetFocusMinutes,
    this.autoStartBreak = true,
    this.autoStartFocus = true,
    this.progressMode = FocusProgressMode.focusOnly,
  });

  const FocusGoalEntity.defaultHour()
    : targetFocusMinutes = 60,
      autoStartBreak = true,
      autoStartFocus = true,
      progressMode = FocusProgressMode.focusOnly;

  int get targetFocusSeconds => targetFocusMinutes * 60;
}
