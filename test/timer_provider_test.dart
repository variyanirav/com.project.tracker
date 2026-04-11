import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';

void main() {
  group('TimerStateNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;
    late String projectId;
    late String taskId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Timer Project',
        description: 'Project for timer tests',
        color: 'T',
      );
      projectId = project.id;

      final task = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Timer Task',
        description: 'Task for timer tests',
      );
      taskId = task.id;
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'startTimer starts a session and updates task running state',
      () async {
        final notifier = container.read(timerProvider.notifier);
        final timerRepo = container.read(timerSessionRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);

        await notifier.startTimer(taskId, projectId);

        final state = container.read(timerProvider);
        final active = await timerRepo.getActiveSession();
        final task = await taskRepo.getTaskById(taskId);

        expect(state.isRunning, isTrue);
        expect(state.isPaused, isFalse);
        expect(state.taskId, taskId);
        expect(state.projectId, projectId);
        expect(active, isNotNull);
        expect(active!.taskId, taskId);
        expect(task!.isRunning, isTrue);
        expect(task.status, 'inProgress');
        expect(task.lastSessionId, isNotEmpty);
      },
    );

    test('startTimer does not change non-To Do statuses', () async {
      final notifier = container.read(timerProvider.notifier);
      final taskRepo = container.read(taskRepositoryProvider);

      for (final status in ['complete', 'onHold']) {
        await taskRepo.updateTaskStatus(taskId, status);

        await notifier.startTimer(taskId, projectId);
        final runningTask = await taskRepo.getTaskById(taskId);

        expect(runningTask, isNotNull);
        expect(runningTask!.status, status);
        expect(runningTask.isRunning, isTrue);

        await notifier.stopTimer();
      }
    });

    test(
      'pause then resume continues elapsed time and does not reset to zero',
      () async {
        final notifier = container.read(timerProvider.notifier);

        await notifier.startTimer(taskId, projectId);
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        await notifier.pauseTimer();
        final pausedState = container.read(timerProvider);
        final pausedElapsed = pausedState.elapsedSeconds;

        expect(pausedState.isPaused, isTrue);
        expect(pausedElapsed, greaterThanOrEqualTo(1));

        await Future<void>.delayed(const Duration(milliseconds: 1200));
        final stillPausedState = container.read(timerProvider);
        expect(stillPausedState.elapsedSeconds, pausedElapsed);

        await notifier.resumeTimer();
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        final resumedState = container.read(timerProvider);

        expect(resumedState.isPaused, isFalse);
        expect(
          resumedState.elapsedSeconds,
          greaterThanOrEqualTo(pausedElapsed + 1),
        );
      },
    );

    test('stop after resume persists full elapsed duration', () async {
      final notifier = container.read(timerProvider.notifier);
      final timerRepo = container.read(timerSessionRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);

      await notifier.startTimer(taskId, projectId);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await notifier.pauseTimer();
      final pausedElapsed = container.read(timerProvider).elapsedSeconds;

      await notifier.resumeTimer();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final beforeStop = container.read(timerProvider).elapsedSeconds;

      await notifier.stopTimer();

      final state = container.read(timerProvider);
      final sessions = await timerRepo.getSessionsByTask(taskId);
      final stoppedSession = sessions.firstWhere((s) => s.endTime != null);
      final task = await taskRepo.getTaskById(taskId);

      expect(state.isRunning, isFalse);
      expect(state.sessionId, isNull);
      expect(
        stoppedSession.totalSeconds,
        greaterThanOrEqualTo(pausedElapsed + 1),
      );
      expect(stoppedSession.totalSeconds, greaterThanOrEqualTo(beforeStop - 1));
      expect(task!.isRunning, isFalse);
    });

    test('pause/resume/stop when idle are safe no-ops', () async {
      final notifier = container.read(timerProvider.notifier);

      await notifier.pauseTimer();
      await notifier.resumeTimer();
      await notifier.stopTimer();

      final state = container.read(timerProvider);
      expect(state.isRunning, isFalse);
      expect(state.isPaused, isFalse);
      expect(state.sessionId, isNull);
      expect(state.elapsedSeconds, 0);
    });

    test('start and stop notes are persisted in timer session', () async {
      final notifier = container.read(timerProvider.notifier);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      await notifier.startTimer(
        taskId,
        projectId,
        startNote: 'Review clean architecture chapter',
      );

      final runningState = container.read(timerProvider);
      expect(runningState.sessionId, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await notifier.stopTimer(stopNote: 'Summarized key points');

      final stoppedSession = await timerRepo.getSessionById(
        runningState.sessionId!,
      );
      expect(stoppedSession, isNotNull);
      expect(stoppedSession!.startNote, 'Review clean architecture chapter');
      expect(stoppedSession.stopNote, 'Summarized key points');
      expect(
        stoppedSession.notes,
        contains('START: Review clean architecture chapter'),
      );
      expect(stoppedSession.notes, contains('STOP: Summarized key points'));
    });
  });
}
