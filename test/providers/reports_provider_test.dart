import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
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

        expect(
          csv,
          contains(
            'Project,Task,Billing Type,Category,Estimated (Hours),Task Status,Session Count',
          ),
        );
        expect(csv, contains('"TaskA"'));
        expect(csv, contains('"TaskB"'));
        expect(
          csv,
          contains('"Alpha","TaskA","Billable","Uncategorized","","To Do",1,'),
        );
        expect(
          csv,
          contains('"Alpha","TaskB","Billable","Uncategorized","","To Do",0,'),
        );
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

      expect(
        thisWeekCsv,
        contains(
          '"Beta","TaskThisWeek","Billable","Uncategorized","","To Do",1,',
        ),
      );
      expect(
        thisWeekCsv,
        contains(
          '"Beta","TaskLastWeek","Billable","Uncategorized","","To Do",0,',
        ),
      );

      expect(
        lastWeekCsv,
        contains(
          '"Beta","TaskThisWeek","Billable","Uncategorized","","To Do",0,',
        ),
      );
      expect(
        lastWeekCsv,
        contains(
          '"Beta","TaskLastWeek","Billable","Uncategorized","","To Do",1,',
        ),
      );
    });

    test('task breakdown export respects selected category filter', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Gamma',
        description: 'G',
        color: 'G',
      );

      final learningTask = await taskRepo.createTask(
        projectId: project.id,
        categoryId: AppDatabase.learningCategoryId,
        taskName: 'Learn Dart',
        description: 'study',
      );
      final devTask = await taskRepo.createTask(
        projectId: project.id,
        categoryId: AppDatabase.developmentCategoryId,
        taskName: 'Build UI',
        description: 'build',
      );

      final now = DateTime.now().toUtc();
      final learningSession = await timerRepo.createSession(
        taskId: learningTask.id,
        projectId: project.id,
        startTime: now.subtract(const Duration(minutes: 30)),
      );
      await timerRepo.stopSession(
        learningSession.id,
        endTime: now,
        totalSeconds: 1800,
      );

      final devSession = await timerRepo.createSession(
        taskId: devTask.id,
        projectId: project.id,
        startTime: now.subtract(const Duration(minutes: 20)),
      );
      await timerRepo.stopSession(
        devSession.id,
        endTime: now,
        totalSeconds: 1200,
      );

      final learningCsv = await container.read(
        taskBreakdownCsvExportProvider(
          CsvExportParams(
            period: ReportPeriod.thisWeek,
            projectId: project.id,
            categoryId: AppDatabase.learningCategoryId,
          ),
        ).future,
      );

      expect(learningCsv, contains('"Learn Dart"'));
      expect(learningCsv, isNot(contains('"Build UI"')));
    });

    test('category summary provider aggregates hours and counts', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Delta',
        description: 'D',
        color: 'D',
      );

      final tasks = <TaskEntity>[
        await taskRepo.createTask(
          projectId: project.id,
          categoryId: AppDatabase.learningCategoryId,
          taskName: 'Learn architecture',
          description: null,
        ),
        await taskRepo.createTask(
          projectId: project.id,
          categoryId: AppDatabase.developmentCategoryId,
          taskName: 'Implement feature',
          description: null,
        ),
      ];

      final now = DateTime.now().toUtc();
      final s1 = await timerRepo.createSession(
        taskId: tasks[0].id,
        projectId: project.id,
        startTime: now.subtract(const Duration(minutes: 50)),
      );
      await timerRepo.stopSession(s1.id, endTime: now, totalSeconds: 3000);

      final s2 = await timerRepo.createSession(
        taskId: tasks[1].id,
        projectId: project.id,
        startTime: now.subtract(const Duration(minutes: 30)),
      );
      await timerRepo.stopSession(s2.id, endTime: now, totalSeconds: 1800);

      final summary = await container.read(
        categorySummaryProvider(
          const CsvExportParams(period: ReportPeriod.thisWeek),
        ).future,
      );

      final learning = summary.firstWhere(
        (item) => item.categoryId == AppDatabase.learningCategoryId,
      );
      final development = summary.firstWhere(
        (item) => item.categoryId == AppDatabase.developmentCategoryId,
      );

      expect(learning.sessionCount, 1);
      expect(learning.taskCount, 1);
      expect(learning.totalHours, closeTo(3000 / 3600, 0.01));

      expect(development.sessionCount, 1);
      expect(development.taskCount, 1);
      expect(development.totalHours, closeTo(1800 / 3600, 0.01));
    });

    test('task detail export uses human-readable date format', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Readable Date Project',
        description: 'R',
        color: 'R',
      );

      final task = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'Readable Task',
        description: null,
      );

      final start = DateTime.utc(2026, 3, 26, 10, 30);
      final session = await timerRepo.createSession(
        taskId: task.id,
        projectId: project.id,
        startTime: start,
      );

      await timerRepo.stopSession(
        session.id,
        endTime: start.add(const Duration(minutes: 30)),
        totalSeconds: 1800,
      );

      final csv = await container.read(
        sessionDetailCsvExportProvider(
          CsvExportParams(
            period: ReportPeriod.thisWeek,
            projectId: project.id,
            customStartUtc: DateTime.utc(2026, 3, 1),
            customEndUtcExclusive: DateTime.utc(2026, 4, 1),
          ),
        ).future,
      );

      expect(csv, contains('Project,Task,Billing Type,Category,Status'));
      expect(csv, isNot(contains(RegExp(r'\d{4}-\d{2}-\d{2}T'))));
      expect(
        csv,
        contains(RegExp(r'\b\d{1,2}(st|nd|rd|th)\s+[A-Za-z]+\s+\d{4}\b')),
      );
    });

    test(
      'task detail export includes empty tasks, excludes archived and deleted tasks, and totals estimation and actual hours',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);
        final timerRepo = container.read(timerSessionRepositoryProvider);

        final project = await projectRepo.createProject(
          name: 'Task Detail Export',
          description: 'TDE',
          color: 'TDE',
        );

        final activeTask = await taskRepo.createTask(
          projectId: project.id,
          categoryId: AppDatabase.learningCategoryId,
          taskName: 'Active With Session',
          description: 'active task',
          estimatedHours: 2,
        );
        await taskRepo.createTask(
          projectId: project.id,
          categoryId: AppDatabase.developmentCategoryId,
          taskName: 'No Session Task',
          description: 'empty task',
          estimatedHours: 1,
        );
        final archivedTask = await taskRepo.createTask(
          projectId: project.id,
          taskName: 'Archived Task',
          description: 'should not export',
          estimatedHours: 4,
        );
        final deletedTask = await taskRepo.createTask(
          projectId: project.id,
          taskName: 'Deleted Task',
          description: 'should not export',
          estimatedHours: 5,
        );

        final activeTaskEntity = (await taskRepo.getTaskById(activeTask.id))!;
        await taskRepo.updateTask(
          activeTaskEntity.copyWith(
            status: 'complete',
            totalSeconds: 5400,
            isRunning: false,
          ),
        );

        final start = DateTime.utc(2026, 3, 26, 9, 0);
        final session = await timerRepo.createSession(
          taskId: activeTask.id,
          projectId: project.id,
          startTime: start,
        );
        await timerRepo.updateSessionStartNote(
          session.id,
          'Session start note',
        );
        await timerRepo.stopSession(
          session.id,
          endTime: start.add(const Duration(minutes: 45)),
          totalSeconds: 2700,
        );
        await timerRepo.updateSessionStopNote(session.id, 'Session end note');

        final archivedTaskEntity = (await taskRepo.getTaskById(
          archivedTask.id,
        ))!;
        await taskRepo.updateTask(
          archivedTaskEntity.copyWith(status: 'archived'),
        );

        await taskRepo.deleteTask(deletedTask.id);

        final csv = await container.read(
          sessionDetailCsvExportProvider(
            CsvExportParams(
              period: ReportPeriod.thisWeek,
              projectId: project.id,
              customStartUtc: DateTime.utc(2026, 3, 1),
              customEndUtcExclusive: DateTime.utc(2026, 4, 1),
            ),
          ).future,
        );

        expect(
          csv,
          contains(
            'Project,Task,Billing Type,Category,Status,Estimation (Hours),Actual (Hours),Session Start,End Date,Start Note,End Note',
          ),
        );
        expect(csv, contains('Active With Session'));
        expect(csv, contains('No Session Task'));
        expect(csv, isNot(contains('Archived Task')));
        expect(csv, isNot(contains('Deleted Task')));
        expect(csv, contains('Session start note'));
        expect(csv, contains('Session end note'));
        expect(csv, contains('Grand Total'));
        expect(csv, contains('3.00'));
        expect(csv, contains('0.75'));
      },
    );

    test(
      'task breakdown latest session uses human-readable date format',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);
        final timerRepo = container.read(timerSessionRepositoryProvider);

        final project = await projectRepo.createProject(
          name: 'Readable Breakdown',
          description: 'RB',
          color: 'RB',
        );

        final task = await taskRepo.createTask(
          projectId: project.id,
          taskName: 'Breakdown Task',
          description: null,
        );

        final start = TimezoneHelper.getWeekStartUtc().add(
          const Duration(days: 1, hours: 14),
        );
        final session = await timerRepo.createSession(
          taskId: task.id,
          projectId: project.id,
          startTime: start,
        );

        await timerRepo.stopSession(
          session.id,
          endTime: start.add(const Duration(minutes: 10)),
          totalSeconds: 600,
        );

        final csv = await container.read(
          taskBreakdownCsvExportProvider(
            CsvExportParams(
              period: ReportPeriod.thisWeek,
              projectId: project.id,
            ),
          ).future,
        );

        expect(csv, isNot(contains(RegExp(r'\d{4}-\d{2}-\d{2}T'))));
        expect(
          csv,
          contains(RegExp(r'\b\d{1,2}(st|nd|rd|th)\s+[A-Za-z]+\s+\d{4}\b')),
        );
      },
    );

    test('project summary provider uses period and category scope', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Scoped Summary',
        description: 'S',
        color: 'S',
      );

      final learningTask = await taskRepo.createTask(
        projectId: project.id,
        categoryId: AppDatabase.learningCategoryId,
        taskName: 'Learning Task',
        description: null,
      );

      final devTask = await taskRepo.createTask(
        projectId: project.id,
        categoryId: AppDatabase.developmentCategoryId,
        taskName: 'Dev Task',
        description: null,
      );

      final weekStart = TimezoneHelper.getWeekStartUtc();
      final inRangeTime = weekStart.add(const Duration(days: 1, hours: 2));
      final outOfRangeTime = weekStart.subtract(const Duration(days: 2));

      final learningInRange = await timerRepo.createSession(
        taskId: learningTask.id,
        projectId: project.id,
        startTime: inRangeTime,
      );
      await timerRepo.stopSession(
        learningInRange.id,
        endTime: inRangeTime.add(const Duration(minutes: 30)),
        totalSeconds: 1800,
      );

      final devInRange = await timerRepo.createSession(
        taskId: devTask.id,
        projectId: project.id,
        startTime: inRangeTime.add(const Duration(hours: 1)),
      );
      await timerRepo.stopSession(
        devInRange.id,
        endTime: inRangeTime.add(const Duration(hours: 1, minutes: 45)),
        totalSeconds: 2700,
      );

      final learningOutOfRange = await timerRepo.createSession(
        taskId: learningTask.id,
        projectId: project.id,
        startTime: outOfRangeTime,
      );
      await timerRepo.stopSession(
        learningOutOfRange.id,
        endTime: outOfRangeTime.add(const Duration(minutes: 20)),
        totalSeconds: 1200,
      );

      final summary = await container.read(
        projectSummaryProvider(
          CsvExportParams(
            period: ReportPeriod.thisWeek,
            projectId: project.id,
            categoryId: AppDatabase.learningCategoryId,
          ),
        ).future,
      );

      expect(summary.length, 1);
      expect(summary.first.taskCount, 1);
      expect(summary.first.sessionCount, 1);
      expect(summary.first.totalHours, closeTo(0.5, 0.01));
    });

    test('task breakdown export supports custom date range', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Custom Range',
        description: 'CR',
        color: 'CR',
      );

      final task = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'Custom Task',
        description: null,
      );

      final inRangeTime = DateTime.utc(2026, 3, 10, 12, 0);
      final outOfRangeTime = DateTime.utc(2026, 2, 20, 10, 0);

      final inRangeSession = await timerRepo.createSession(
        taskId: task.id,
        projectId: project.id,
        startTime: inRangeTime,
      );
      await timerRepo.stopSession(
        inRangeSession.id,
        endTime: inRangeTime.add(const Duration(minutes: 40)),
        totalSeconds: 2400,
      );

      final outRangeSession = await timerRepo.createSession(
        taskId: task.id,
        projectId: project.id,
        startTime: outOfRangeTime,
      );
      await timerRepo.stopSession(
        outRangeSession.id,
        endTime: outOfRangeTime.add(const Duration(minutes: 10)),
        totalSeconds: 600,
      );

      final csv = await container.read(
        taskBreakdownCsvExportProvider(
          CsvExportParams(
            period: ReportPeriod.thisWeek,
            projectId: project.id,
            customStartUtc: DateTime.utc(2026, 3, 1),
            customEndUtcExclusive: DateTime.utc(2026, 4, 1),
          ),
        ).future,
      );

      expect(csv, contains('Report Range'));
      expect(csv, contains('"Custom Task"'));
      expect(csv, contains(',1,0.67,'));
    });

    test('session detail export includes start and stop notes', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Detail Export',
        description: 'DE',
        color: 'DE',
      );

      final task = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'Detail Task',
        description: null,
      );

      final start = DateTime.utc(2026, 3, 10, 9, 0);
      final session = await timerRepo.createSession(
        taskId: task.id,
        projectId: project.id,
        startTime: start,
      );
      await timerRepo.updateSessionStartNote(session.id, 'Define scope');
      await timerRepo.stopSession(
        session.id,
        endTime: start.add(const Duration(minutes: 25)),
        totalSeconds: 1500,
      );
      await timerRepo.updateSessionStopNote(session.id, 'Delivered outline');

      final csv = await container.read(
        sessionDetailCsvExportProvider(
          CsvExportParams(
            period: ReportPeriod.thisWeek,
            projectId: project.id,
            customStartUtc: DateTime.utc(2026, 3, 1),
            customEndUtcExclusive: DateTime.utc(2026, 4, 1),
          ),
        ).future,
      );

      expect(csv, contains('Start Note'));
      expect(csv, contains('End Note'));
      expect(csv, contains('Define scope'));
      expect(csv, contains('Delivered outline'));
    });
  });
}
