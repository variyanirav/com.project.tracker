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
  });
}
