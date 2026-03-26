import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';

void main() {
  group('ProjectProvider coverage', () {
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

    test('CRUD and status providers work end-to-end', () async {
      final taskRepo = container.read(taskRepositoryProvider);
      final timerRepo = container.read(timerSessionRepositoryProvider);

      await container.read(
        createProjectProvider(
          CreateProjectParams(name: 'Alpha', description: 'A', color: 'A'),
        ).future,
      );
      await container.read(
        createProjectProvider(
          CreateProjectParams(name: 'Beta', description: 'B', color: 'B'),
        ).future,
      );

      final projects = await container.read(projectsProvider.future);
      expect(projects.length, 2);

      final activeProjects = await container.read(
        projectsByStatusProvider('active').future,
      );
      expect(activeProjects.length, 2);

      final first = projects.first;
      final firstById = await container.read(
        projectByIdProvider(first.id).future,
      );
      expect(firstById, isNotNull);
      expect(firstById!.id, first.id);

      await container.read(
        updateProjectProvider(
          UpdateProjectParams(
            id: first.id,
            name: 'Alpha Updated',
            description: 'Updated',
            color: 'U',
            status: 'active',
            createdAt: first.createdAt,
          ),
        ).future,
      );

      final updated = await container.read(
        projectByIdProvider(first.id).future,
      );
      expect(updated!.name, 'Alpha Updated');

      // Seed some timer data so hour providers execute real paths.
      final task = await taskRepo.createTask(
        projectId: first.id,
        taskName: 'Task for hours',
        description: 'desc',
      );
      final now = DateTime.now().toUtc();
      final session = await timerRepo.createSession(
        taskId: task.id,
        projectId: first.id,
        startTime: now.subtract(const Duration(minutes: 30)),
      );
      await timerRepo.stopSession(session.id, endTime: now, totalSeconds: 1800);

      final totalHours = await container.read(
        projectTotalHoursProvider(first.id).future,
      );
      final todayHours = await container.read(
        projectTodayHoursProvider(first.id).future,
      );
      final weekHours = await container.read(
        projectWeekHoursProvider(first.id).future,
      );

      expect(totalHours, closeTo(0.5, 0.0001));
      expect(todayHours, greaterThanOrEqualTo(0.5));
      expect(weekHours, greaterThanOrEqualTo(0.5));

      await container.read(archiveProjectProvider(first.id).future);
      final archived = await container.read(archivedProjectsProvider.future);
      expect(archived.any((p) => p.id == first.id), isTrue);

      await container.read(unarchiveProjectProvider(first.id).future);
      final unarchived = await container.read(
        projectByIdProvider(first.id).future,
      );
      expect(unarchived!.status, 'active');

      final count = await container.read(projectCountProvider.future);
      expect(count, 2);

      await container.read(deleteProjectProvider(first.id).future);
      final afterDelete = await container.read(projectsProvider.future);
      expect(afterDelete.length, 1);
    });

    test(
      'recentWorkedProjectsProvider prioritizes recently worked projects',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);
        final taskRepo = container.read(taskRepositoryProvider);
        final timerRepo = container.read(timerSessionRepositoryProvider);

        final alpha = await projectRepo.createProject(
          name: 'Alpha',
          description: 'A',
          color: 'A',
        );
        final beta = await projectRepo.createProject(
          name: 'Beta',
          description: 'B',
          color: 'B',
        );
        final gamma = await projectRepo.createProject(
          name: 'Gamma',
          description: 'C',
          color: 'C',
        );

        final taskBeta = await taskRepo.createTask(
          projectId: beta.id,
          taskName: 'Task Beta',
          description: 'desc',
        );
        final taskGamma = await taskRepo.createTask(
          projectId: gamma.id,
          taskName: 'Task Gamma',
          description: 'desc',
        );

        final now = DateTime.now().toUtc();

        final betaSession = await timerRepo.createSession(
          taskId: taskBeta.id,
          projectId: beta.id,
          startTime: now.subtract(const Duration(hours: 2)),
        );
        await timerRepo.stopSession(
          betaSession.id,
          endTime: now.subtract(const Duration(hours: 1, minutes: 30)),
          totalSeconds: 1800,
        );

        final gammaSession = await timerRepo.createSession(
          taskId: taskGamma.id,
          projectId: gamma.id,
          startTime: now.subtract(const Duration(minutes: 30)),
        );
        await timerRepo.stopSession(
          gammaSession.id,
          endTime: now.subtract(const Duration(minutes: 10)),
          totalSeconds: 1200,
        );

        final recent = await container.read(
          recentWorkedProjectsProvider(3).future,
        );

        expect(recent.length, 3);
        expect(recent[0].id, gamma.id);
        expect(recent[1].id, beta.id);
        expect(recent.map((p) => p.id), contains(alpha.id));
      },
    );

    test(
      'recentWorkedProjectsProvider falls back to newest created when no work exists',
      () async {
        final projectRepo = container.read(projectRepositoryProvider);

        await projectRepo.createProject(
          name: 'One',
          description: '1',
          color: '1',
        );
        await projectRepo.createProject(
          name: 'Two',
          description: '2',
          color: '2',
        );
        await projectRepo.createProject(
          name: 'Three',
          description: '3',
          color: '3',
        );

        final allProjects = await container.read(projectsProvider.future);
        final recent = await container.read(
          recentWorkedProjectsProvider(2).future,
        );

        expect(recent.length, 2);

        final expected = [...allProjects]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        expect(recent[0].id, expected[0].id);
        expect(recent[1].id, expected[1].id);
      },
    );
  });
}
