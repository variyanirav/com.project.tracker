import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/category_repository_impl.dart';
import 'package:project_tracker/data/repositories/task_repository_impl.dart';

void main() {
  group('Category and task category integration', () {
    late AppDatabase db;
    late CategoryRepositoryImpl categoryRepository;
    late TaskRepositoryImpl taskRepository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categoryRepository = CategoryRepositoryImpl(db);
      taskRepository = TaskRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> createProject() async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.projects)
          .insert(
            ProjectData(
              id: 'p1',
              name: 'Project 1',
              description: null,
              avatarEmoji: 'P',
              status: 'active',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    test('default categories are seeded on database creation', () async {
      final categories = await categoryRepository.getAllCategories();
      final names = categories.map((c) => c.name).toSet();

      expect(names.contains('Uncategorized'), isTrue);
      expect(names.contains('Learning'), isTrue);
      expect(names.contains('Development'), isTrue);
      expect(names.contains('Research'), isTrue);
    });

    test(
      'createTask defaults to Uncategorized when no category is provided',
      () async {
        await createProject();

        final task = await taskRepository.createTask(
          projectId: 'p1',
          taskName: 'Read docs',
          description: 'API docs',
        );

        expect(task.categoryId, AppDatabase.uncategorizedCategoryId);
      },
    );

    test('createTask preserves explicitly selected category', () async {
      await createProject();

      final task = await taskRepository.createTask(
        projectId: 'p1',
        categoryId: AppDatabase.learningCategoryId,
        taskName: 'Learn clean architecture',
        description: null,
      );

      expect(task.categoryId, AppDatabase.learningCategoryId);
    });

    test('deleting category reassigns tasks to fallback category', () async {
      await createProject();

      final customCategory = await categoryRepository.createCategory(
        name: 'Deep Work',
        colorHex: '#123456',
      );

      final created = await taskRepository.createTask(
        projectId: 'p1',
        categoryId: customCategory.id,
        taskName: 'Design API',
        description: null,
      );
      expect(created.categoryId, customCategory.id);

      await categoryRepository.deleteCategory(
        customCategory.id,
        fallbackCategoryId: AppDatabase.uncategorizedCategoryId,
      );

      final updated = await taskRepository.getTaskById(created.id);
      expect(updated, isNotNull);
      expect(updated!.categoryId, AppDatabase.uncategorizedCategoryId);
    });
  });
}
