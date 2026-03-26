import 'timezone_helper.dart';

/// Reusable live overlay for combining persisted hours with currently running timer.
///
/// This keeps writes infrequent (persist on stop/pause/resume) while allowing
/// real-time UI updates across screens.
enum LiveHoursScope { today, week, project }

class LiveHoursOverlay {
  LiveHoursOverlay._();

  static double withLiveOverlay({
    required double persistedHours,
    required bool isTimerRunning,
    required int elapsedSeconds,
    required DateTime timerStartTime,
    String? timerProjectId,
    required LiveHoursScope scope,
    String? targetProjectId,
  }) {
    final extraHours = _liveExtraHours(
      isTimerRunning: isTimerRunning,
      elapsedSeconds: elapsedSeconds,
      timerStartTime: timerStartTime,
      timerProjectId: timerProjectId,
      scope: scope,
      targetProjectId: targetProjectId,
    );

    return persistedHours + extraHours;
  }

  static double _liveExtraHours({
    required bool isTimerRunning,
    required int elapsedSeconds,
    required DateTime timerStartTime,
    String? timerProjectId,
    required LiveHoursScope scope,
    String? targetProjectId,
  }) {
    if (!isTimerRunning || elapsedSeconds <= 0) {
      return 0.0;
    }

    final now = DateTime.now();

    switch (scope) {
      case LiveHoursScope.today:
        if (!TimezoneHelper.isSameDay(timerStartTime, now)) {
          return 0.0;
        }
        return elapsedSeconds / 3600.0;
      case LiveHoursScope.week:
        if (!TimezoneHelper.isThisWeek(timerStartTime)) {
          return 0.0;
        }
        return elapsedSeconds / 3600.0;
      case LiveHoursScope.project:
        if (targetProjectId == null || timerProjectId != targetProjectId) {
          return 0.0;
        }
        return elapsedSeconds / 3600.0;
    }
  }
}
