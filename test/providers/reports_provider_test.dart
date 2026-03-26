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
          contains('Project,Task,Category,Task Status,Session Count'),
        );
        expect(csv, contains('"TaskA"'));
        expect(csv, contains('"TaskB"'));
        expect(csv, contains('"TaskA","Uncategorized","To Do",1,'));
        expect(csv, contains('"TaskB","Uncategorized","To Do",0,'));
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
        contains('"TaskThisWeek","Uncategorized","To Do",1,'),
      );
      expect(
        thisWeekCsv,
        contains('"TaskLastWeek","Uncategorized","To Do",0,'),
      );

      expect(
        lastWeekCsv,
        contains('"TaskThisWeek","Uncategorized","To Do",0,'),
      );
      expect(
        lastWeekCsv,
        contains('"TaskLastWeek","Uncategorized","To Do",1,'),
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

    test('detailed export uses human-readable date format', () async {
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

      final csv = await container.read(detailedCsvExportProvider.future);

      expect(csv, isNot(contains(RegExp(r'\d{4}-\d{2}-\d{2}T'))));
      expect(
        csv,
        contains(RegExp(r'\b\d{1,2}(st|nd|rd|th)\s+[A-Za-z]+\s+\d{4}\b')),
      );
    });

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

        final start = DateTime.utc(2026, 3, 26, 14, 45);
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
  });
}
