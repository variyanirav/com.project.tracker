import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/task_repository_impl.dart';

void main() {
  group('TaskRepositoryImpl trash flow', () {
    late AppDatabase db;
    late TaskRepositoryImpl repository;

    const projectId = 'project-1';
    const categoryId = AppDatabase.uncategorizedCategoryId;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TaskRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'soft delete moves task to trash and restore brings back original status',
      () async {
        final created = await repository.createTask(
          projectId: projectId,
          categoryId: categoryId,
          taskName: 'Trash me',
          description: 'Temporary task',
          estimatedHours: 1.5,
        );

        await repository.updateTaskStatus(created.id, 'inProgress');
        await repository.deleteTask(created.id);

        expect(await repository.getTasksByProject(projectId), isEmpty);
        expect(await repository.getTaskById(created.id), isNull);

        final trashed = await repository.getDeletedTasksByProject(projectId);
        expect(trashed, hasLength(1));
        expect(trashed.single.id, created.id);
        expect(trashed.single.deletedStatus, 'inProgress');
        expect(trashed.single.deletedAt, isNotNull);

        await repository.restoreDeletedTask(created.id);

        final restored = await repository.getTasksByProject(projectId);
        expect(restored, hasLength(1));
        expect(restored.single.id, created.id);
        expect(restored.single.status, 'inProgress');
        expect(restored.single.deletedAt, isNull);
        expect(restored.single.deletedStatus, isNull);
        expect(await repository.getDeletedTasksByProject(projectId), isEmpty);
      },
    );

    test('permanent delete removes a trashed task completely', () async {
      final created = await repository.createTask(
        projectId: projectId,
        categoryId: categoryId,
        taskName: 'Remove me',
        description: 'Task to be removed permanently',
        estimatedHours: 2,
      );

      await repository.deleteTask(created.id);
      await repository.permanentlyDeleteTask(created.id);

      expect(await repository.getTasksByProject(projectId), isEmpty);
      expect(await repository.getDeletedTasksByProject(projectId), isEmpty);
      expect(await repository.getTaskById(created.id), isNull);
    });
  });
}
