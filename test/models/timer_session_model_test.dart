import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/models/timer_session_model.dart';

void main() {
  group('TimerSessionModel', () {
    test('maps from and to TimerSessionData correctly', () {
      final data = TimerSessionData(
        id: 's1',
        taskId: 't1',
        projectId: 'p1',
        startTime: DateTime.utc(2026, 3, 21, 10),
        endTime: DateTime.utc(2026, 3, 21, 11),
        elapsedSeconds: 3600,
        isPaused: false,
        notes: 'focus work',
        createdAt: DateTime.utc(2026, 3, 21, 10),
      );

      final model = TimerSessionModel.fromTimerSessionData(data);
      final converted = model.toTimerSessionData();

      expect(model.id, 's1');
      expect(model.formattedDuration, '01:00:00');
      expect(model.displaySessionState, 'Completed');
      expect(converted.id, data.id);
      expect(converted.elapsedSeconds, data.elapsedSeconds);
      expect(converted.endTime, data.endTime);
    });

    test('running and paused states are derived correctly', () {
      final running = TimerSessionModel(
        id: 's-running',
        taskId: 't1',
        projectId: 'p1',
        startTime: DateTime.now().toUtc(),
        endTime: null,
        elapsedSeconds: 75,
        isPaused: true,
        notes: null,
        createdAt: DateTime.now().toUtc(),
      );

      expect(running.isRunning, isTrue);
      expect(running.displaySessionState, 'Running');
      expect(running.displayDuration, '1m');
      expect(running.displayDurationVerbose, '1 minute 15 seconds');
    });
  });
}
