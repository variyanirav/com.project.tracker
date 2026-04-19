/// Focus cycle template for alternating focus and break durations.
class FocusCycleTemplateEntity {
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryNCycles;

  const FocusCycleTemplateEntity({
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakEveryNCycles,
  });

  const FocusCycleTemplateEntity.standard()
    : focusMinutes = 25,
      shortBreakMinutes = 5,
      longBreakMinutes = 15,
      longBreakEveryNCycles = 4;

  int get focusSeconds => focusMinutes * 60;
  int get shortBreakSeconds => shortBreakMinutes * 60;
  int get longBreakSeconds => longBreakMinutes * 60;

  FocusCycleTemplateEntity copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakEveryNCycles,
  }) {
    return FocusCycleTemplateEntity(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakEveryNCycles:
          longBreakEveryNCycles ?? this.longBreakEveryNCycles,
    );
  }
}
