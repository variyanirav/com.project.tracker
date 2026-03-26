import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/core/utils/live_hours_overlay.dart';

void main() {
  group('LiveHoursOverlay', () {
    test('adds live hours for today scope when timer started today', () {
      final result = LiveHoursOverlay.withLiveOverlay(
        persistedHours: 2.0,
        isTimerRunning: true,
        elapsedSeconds: 1800,
        timerStartTime: DateTime.now(),
        timerProjectId: 'p1',
        scope: LiveHoursScope.today,
      );

      expect(result, closeTo(2.5, 0.0001));
    });

    test(
      'does not add hours for today scope when timer started earlier day',
      () {
        final result = LiveHoursOverlay.withLiveOverlay(
          persistedHours: 2.0,
          isTimerRunning: true,
          elapsedSeconds: 1800,
          timerStartTime: DateTime.now().subtract(const Duration(days: 1)),
          timerProjectId: 'p1',
          scope: LiveHoursScope.today,
        );

        expect(result, closeTo(2.0, 0.0001));
      },
    );

    test('adds live hours for matching project scope only', () {
      final matching = LiveHoursOverlay.withLiveOverlay(
        persistedHours: 1.0,
        isTimerRunning: true,
        elapsedSeconds: 3600,
        timerStartTime: DateTime.now(),
        timerProjectId: 'project-1',
        targetProjectId: 'project-1',
        scope: LiveHoursScope.project,
      );
      final nonMatching = LiveHoursOverlay.withLiveOverlay(
        persistedHours: 1.0,
        isTimerRunning: true,
        elapsedSeconds: 3600,
        timerStartTime: DateTime.now(),
        timerProjectId: 'project-1',
        targetProjectId: 'project-2',
        scope: LiveHoursScope.project,
      );

      expect(matching, closeTo(2.0, 0.0001));
      expect(nonMatching, closeTo(1.0, 0.0001));
    });

    test('does not add live hours when timer is not running', () {
      final result = LiveHoursOverlay.withLiveOverlay(
        persistedHours: 3.0,
        isTimerRunning: false,
        elapsedSeconds: 3600,
        timerStartTime: DateTime.now(),
        timerProjectId: 'p1',
        scope: LiveHoursScope.week,
      );

      expect(result, closeTo(3.0, 0.0001));
    });
  });
}
