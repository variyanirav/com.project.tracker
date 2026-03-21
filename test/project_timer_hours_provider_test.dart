import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';

void main() {
  group('Project hour providers', () {
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
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Hours Project',
        description: 'Provider tests',
        color: 'H',
      );
      projectId = project.id;

      final task = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Hours Task',
        description: 'Task for provider tests',
      );
      taskId = task.id;

      final now = TimezoneHelper.getCurrentUtc();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final tenDaysAgo = now.subtract(const Duration(days: 10));

      final todaySession = await timerRepo.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: oneHourAgo,
      );
      await timerRepo.stopSession(
        todaySession.id,
        endTime: now,
        totalSeconds: 1800,
      );

      final oldSession = await timerRepo.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: tenDaysAgo,
      );
      await timerRepo.stopSession(
        oldSession.id,
        endTime: tenDaysAgo.add(const Duration(hours: 1)),
        totalSeconds: 3600,
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('projectTotalHoursProvider returns all-time total', () async {
      final total = await container.read(
        projectTotalHoursProvider(projectId).future,
      );

      expect(total, closeTo(1.5, 0.0001));
    });

    test('projectTodayHoursProvider returns only today sessions', () async {
      final today = await container.read(
        projectTodayHoursProvider(projectId).future,
      );

      expect(today, closeTo(0.5, 0.0001));
    });

    test('projectWeekHoursProvider excludes older sessions', () async {
      final week = await container.read(
        projectWeekHoursProvider(projectId).future,
      );

      expect(week, closeTo(0.5, 0.0001));
    });

    test(
      'projectTodayHoursProvider includes midnight boundary session',
      () async {
        final timerRepo = container.read(timerSessionRepositoryProvider);
        final todayStart = TimezoneHelper.getTodayStartUtc();

        final midnightSession = await timerRepo.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: todayStart,
        );
        await timerRepo.stopSession(
          midnightSession.id,
          endTime: todayStart.add(const Duration(minutes: 10)),
          totalSeconds: 600,
        );

        final today = await container.read(
          projectTodayHoursProvider(projectId).future,
        );

        // Existing 1800s + boundary 600s = 2400s = 0.6667h
        expect(today, closeTo(2400 / 3600, 0.0001));
      },
    );

    test('projectTodayHoursProvider excludes previous day session', () async {
      final timerRepo = container.read(timerSessionRepositoryProvider);
      final todayStart = TimezoneHelper.getTodayStartUtc();
      final baselineToday = await container.read(
        projectTodayHoursProvider(projectId).future,
      );

      final yesterdayLateSession = await timerRepo.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: todayStart.subtract(const Duration(seconds: 1)),
      );
      await timerRepo.stopSession(
        yesterdayLateSession.id,
        endTime: todayStart,
        totalSeconds: 600,
      );

      final today = await container.read(
        projectTodayHoursProvider(projectId).future,
      );

      // Should remain unchanged because session started before today boundary.
      expect(today, closeTo(baselineToday, 0.0001));
    });

    test(
      'projectTotalHoursProvider aggregates multiple tasks in project only',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);
        final timerRepo = container.read(timerSessionRepositoryProvider);

        final secondTask = await taskRepo.createTask(
          projectId: projectId,
          taskName: 'Second Task',
          description: 'Same project',
        );

        final anotherProject = await projectRepo.createProject(
          name: 'Other Project',
          description: 'Should not affect this project total',
          color: 'O',
        );
        final anotherTask = await taskRepo.createTask(
          projectId: anotherProject.id,
          taskName: 'Other Task',
          description: 'Different project',
        );

        final now = TimezoneHelper.getCurrentUtc();
        final secondTaskSession = await timerRepo.createSession(
          taskId: secondTask.id,
          projectId: projectId,
          startTime: now.subtract(const Duration(minutes: 15)),
        );
        await timerRepo.stopSession(
          secondTaskSession.id,
          endTime: now,
          totalSeconds: 900,
        );

        final otherProjectSession = await timerRepo.createSession(
          taskId: anotherTask.id,
          projectId: anotherProject.id,
          startTime: now.subtract(const Duration(minutes: 20)),
        );
        await timerRepo.stopSession(
          otherProjectSession.id,
          endTime: now,
          totalSeconds: 1200,
        );

        final total = await container.read(
          projectTotalHoursProvider(projectId).future,
        );

        // Base setup 5400s + same-project extra 900s = 6300s (other project excluded)
        expect(total, closeTo(6300 / 3600, 0.0001));
      },
    );
  });
}
