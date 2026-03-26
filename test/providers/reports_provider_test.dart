import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/reports_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';

void main() {
  group('ReportsProvider CSV export', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'task breakdown export includes all tasks for selected project',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);
        final timerRepo = container.read(timerSessionRepositoryProvider);

        final project = await projectRepo.createProject(
          name: 'Alpha',
          description: 'A',
          color: 'A',
        );

        final taskA = await taskRepo.createTask(
          projectId: project.id,
          taskName: 'TaskA',
          description: 'desc',
        );
        await taskRepo.createTask(
          projectId: project.id,
          taskName: 'TaskB',
          description: 'desc',
        );

        final now = DateTime.now().toUtc();
        final session = await timerRepo.createSession(
          taskId: taskA.id,
          projectId: project.id,
          startTime: now.subtract(const Duration(hours: 1)),
        );
        await timerRepo.stopSession(
          session.id,
          endTime: now,
          totalSeconds: 1800,
        );

        final csv = await container.read(
          taskBreakdownCsvExportProvider(
            CsvExportParams(
              period: ReportPeriod.thisWeek,
              projectId: project.id,
            ),
          ).future,
        );

        expect(csv, contains('Project,Task,Task Status,Session Count'));
        expect(csv, contains('"TaskA"'));
        expect(csv, contains('"TaskB"'));
        expect(csv, contains('"TaskA","To Do",1,'));
        expect(csv, contains('"TaskB","To Do",0,'));
      },
    );

    test('task breakdown export respects selected period', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Beta',
        description: 'B',
        color: 'B',
      );

      final taskThisWeek = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'TaskThisWeek',
        description: 'desc',
      );
      final taskLastWeek = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'TaskLastWeek',
        description: 'desc',
      );

      final thisWeekStart = TimezoneHelper.getWeekStartUtc();
      final thisWeekTime = thisWeekStart.add(const Duration(days: 1, hours: 2));
      final lastWeekTime = thisWeekStart.subtract(
        const Duration(days: 3, hours: 1),
      );

      final session1 = await timerRepo.createSession(
        taskId: taskThisWeek.id,
        projectId: project.id,
        startTime: thisWeekTime,
      );
      await timerRepo.stopSession(
        session1.id,
        endTime: thisWeekTime.add(const Duration(minutes: 20)),
        totalSeconds: 1200,
      );

      final session2 = await timerRepo.createSession(
        taskId: taskLastWeek.id,
        projectId: project.id,
        startTime: lastWeekTime,
      );
      await timerRepo.stopSession(
        session2.id,
        endTime: lastWeekTime.add(const Duration(minutes: 15)),
        totalSeconds: 900,
      );

      final thisWeekCsv = await container.read(
        taskBreakdownCsvExportProvider(
          CsvExportParams(period: ReportPeriod.thisWeek, projectId: project.id),
        ).future,
      );
      final lastWeekCsv = await container.read(
        taskBreakdownCsvExportProvider(
          CsvExportParams(period: ReportPeriod.lastWeek, projectId: project.id),
        ).future,
      );

      expect(thisWeekCsv, contains('"TaskThisWeek","To Do",1,'));
      expect(thisWeekCsv, contains('"TaskLastWeek","To Do",0,'));

      expect(lastWeekCsv, contains('"TaskThisWeek","To Do",0,'));
      expect(lastWeekCsv, contains('"TaskLastWeek","To Do",1,'));
    });
  });
}
