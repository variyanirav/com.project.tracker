import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/timer_session_repository_impl.dart';

void main() {
  group('TimerSessionRepositoryImpl', () {
    late AppDatabase db;
    late TimerSessionRepositoryImpl repository;

    const projectId = 'project-1';
    const taskId = 'task-1';

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TimerSessionRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('create, pause, resume and stop session flow works', () async {
      final startTime = DateTime.now().toUtc().subtract(
        const Duration(minutes: 5),
      );
      final session = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: startTime,
      );

      await repository.pauseSession(session.id, DateTime.now().toUtc());
      final paused = await repository.getSessionById(session.id);
      expect(paused, isNotNull);
      expect(paused!.isPaused, isTrue);

      await repository.resumeSession(session.id, DateTime.now().toUtc());
      final resumed = await repository.getSessionById(session.id);
      expect(resumed, isNotNull);
      expect(resumed!.isPaused, isFalse);

      await repository.stopSession(
        session.id,
        endTime: DateTime.now().toUtc(),
        totalSeconds: 300,
      );
      final stopped = await repository.getSessionById(session.id);
      expect(stopped, isNotNull);
      expect(stopped!.endTime, isNotNull);
      expect(stopped.totalSeconds, 300);
      expect(stopped.isCompleted, isTrue);
    });

    test('hour aggregations include today and this week correctly', () async {
      final now = DateTime.now().toUtc();
      final old = now.subtract(const Duration(days: 10));

      final today = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(minutes: 30)),
      );
      await repository.stopSession(today.id, endTime: now, totalSeconds: 1800);

      final oldSession = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: old,
      );
      await repository.stopSession(
        oldSession.id,
        endTime: old.add(const Duration(hours: 1)),
        totalSeconds: 3600,
      );

      final projectSeconds = await repository.getProjectTotalSeconds(projectId);
      final projectHours = await repository.getProjectTotalHours(projectId);
      final todayHours = await repository.getTodayTotalHours();
      final weekHours = await repository.getWeekTotalHours();

      expect(projectSeconds, 5400);
      expect(projectHours, closeTo(1.5, 0.0001));
      expect(todayHours, closeTo(0.5, 0.0001));
      expect(weekHours, closeTo(0.5, 0.0001));
    });

    test('hasActiveSession reflects active session state', () async {
      expect(await repository.hasActiveSession(), isFalse);

      final session = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: DateTime.now().toUtc(),
      );
      expect(await repository.hasActiveSession(), isTrue);

      await repository.stopSession(
        session.id,
        endTime: DateTime.now().toUtc(),
        totalSeconds: 1,
      );
      expect(await repository.hasActiveSession(), isFalse);
    });

    test(
      'getSessionsByDateRange includes exact start and end boundaries',
      () async {
        final weekStart = TimezoneHelper.getWeekStartUtc();
        final weekEnd = TimezoneHelper.getWeekEndUtc();

        final startBoundary = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: weekStart,
        );
        await repository.stopSession(
          startBoundary.id,
          endTime: weekStart.add(const Duration(minutes: 5)),
          totalSeconds: 300,
        );

        final endBoundary = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: weekEnd,
        );
        await repository.stopSession(
          endBoundary.id,
          endTime: weekEnd.add(const Duration(minutes: 5)),
          totalSeconds: 300,
        );

        final outside = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: weekStart.subtract(const Duration(seconds: 1)),
        );
        await repository.stopSession(
          outside.id,
          endTime: weekStart,
          totalSeconds: 300,
        );

        final sessions = await repository.getSessionsByDateRange(
          weekStart,
          weekEnd,
        );
        final ids = sessions.map((s) => s.id).toSet();

        expect(ids.contains(startBoundary.id), isTrue);
        expect(ids.contains(endBoundary.id), isTrue);
        expect(ids.contains(outside.id), isFalse);
      },
    );

    test(
      'project totals aggregate across tasks in same project only',
      () async {
        final now = DateTime.now().toUtc();

        final task2Session = await repository.createSession(
          taskId: 'task-2',
          projectId: projectId,
          startTime: now.subtract(const Duration(minutes: 20)),
        );
        await repository.stopSession(
          task2Session.id,
          endTime: now,
          totalSeconds: 1200,
        );

        final otherProjectSession = await repository.createSession(
          taskId: 'task-x',
          projectId: 'project-2',
          startTime: now.subtract(const Duration(minutes: 10)),
        );
        await repository.stopSession(
          otherProjectSession.id,
          endTime: now,
          totalSeconds: 600,
        );

        final totalSeconds = await repository.getProjectTotalSeconds(projectId);
        final totalHours = await repository.getProjectTotalHours(projectId);

        expect(totalSeconds, 1200);
        expect(totalHours, closeTo(1200 / 3600, 0.0001));
      },
    );

    test(
      'task stats, sorting, pagination, counts and notes update work',
      () async {
        final now = DateTime.now().toUtc();

        final s1 = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now.subtract(const Duration(hours: 3)),
        );
        await repository.stopSession(
          s1.id,
          endTime: now.subtract(const Duration(hours: 2, minutes: 50)),
          totalSeconds: 600,
        );

        final s2 = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now.subtract(const Duration(hours: 2)),
        );
        await repository.stopSession(
          s2.id,
          endTime: now.subtract(const Duration(hours: 1, minutes: 40)),
          totalSeconds: 1200,
        );

        final s3 = await repository.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now.subtract(const Duration(hours: 1)),
        );
        await repository.stopSession(
          s3.id,
          endTime: now.subtract(const Duration(minutes: 30)),
          totalSeconds: 1800,
        );

        expect(await repository.getTaskTotalSeconds(taskId), 3600);
        expect(
          await repository.getTaskTotalHours(taskId),
          closeTo(1.0, 0.0001),
        );

        final todayTaskSessions = await repository.getTodaySessionsByTask(
          taskId,
        );
        final todayProjectSessions = await repository.getTodaySessionsByProject(
          projectId,
        );
        final weekProjectSessions = await repository.getWeekSessionsByProject(
          projectId,
        );
        expect(todayTaskSessions.length, greaterThanOrEqualTo(3));
        expect(todayProjectSessions.length, greaterThanOrEqualTo(3));
        expect(weekProjectSessions.length, greaterThanOrEqualTo(3));

        expect(await repository.getTaskAverageSessionDuration(taskId), 1200);
        expect(await repository.getTaskLongestSession(taskId), 1800);
        expect(await repository.getTaskShortestSession(taskId), 600);

        expect(await repository.getSessionCountByTask(taskId), 3);
        expect(await repository.getSessionCountByProject(projectId), 3);

        final newest = await repository.getSessionsByTaskNewest(taskId);
        final oldest = await repository.getSessionsByTaskOldest(taskId);
        expect(newest.first.startTime.isAfter(newest.last.startTime), isTrue);
        expect(oldest.first.startTime.isBefore(oldest.last.startTime), isTrue);

        final paginated = await repository.getSessionsByTaskPaginated(
          taskId,
          limit: 2,
          offset: 0,
        );
        expect(paginated.length, 2);

        await repository.updateSessionNotes(s2.id, 'deep focus');
        final noted = await repository.getSessionById(s2.id);
        expect(noted, isNotNull);
        expect(noted!.notes, 'deep focus');

        final monthHours = await repository.getMonthTotalHours(
          now.year,
          now.month,
        );
        expect(monthHours, greaterThanOrEqualTo(1.0));
      },
    );

    test('deleteSessionsByTask removes all task sessions', () async {
      final now = DateTime.now().toUtc();

      final s1 = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(minutes: 10)),
      );
      await repository.stopSession(s1.id, endTime: now, totalSeconds: 300);

      final s2 = await repository.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(minutes: 5)),
      );
      await repository.stopSession(s2.id, endTime: now, totalSeconds: 300);

      expect((await repository.getSessionsByTask(taskId)).length, 2);

      await repository.deleteSessionsByTask(taskId);

      expect(await repository.getSessionsByTask(taskId), isEmpty);
    });
  });
}
