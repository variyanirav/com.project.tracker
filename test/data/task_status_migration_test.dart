import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';

void main() {
  group('Task status normalization migration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('normalizes legacy task labels into canonical status codes', () async {
      final now = DateTime.now().toUtc();

      await db
          .into(db.projects)
          .insert(
            ProjectData(
              id: 'p1',
              name: 'Project',
              description: 'desc',
              avatarEmoji: 'B',
              status: 'active',
              createdAt: now,
              updatedAt: now,
            ),
          );

      Future<void> insertTask(String id, String status) async {
        await db
            .into(db.tasks)
            .insert(
              TaskData(
                id: id,
                projectId: 'p1',
                categoryId: AppDatabase.uncategorizedCategoryId,
                taskName: 'Task $id',
                description: 'd',
                status: status,
                totalSeconds: 0,
                isRunning: false,
                lastStartedAt: null,
                lastSessionId: null,
                createdAt: now,
                updatedAt: now,
                isBillable: true,
              ),
            );
      }

      await insertTask('t1', 'To Do');
      await insertTask('t2', 'IN PROGRESS');
      await insertTask('t3', 'in review');
      await insertTask('t4', 'on_hold');
      await insertTask('t5', 'Complete');
      await insertTask('t6', 'archived');

      await db.normalizeLegacyTaskStatuses();

      final tasks = await (db.select(db.tasks)).get();
      final statusById = {for (final task in tasks) task.id: task.status};

      expect(statusById['t1'], 'todo');
      expect(statusById['t2'], 'inProgress');
      expect(statusById['t3'], 'inReview');
      expect(statusById['t4'], 'onHold');
      expect(statusById['t5'], 'complete');
      expect(statusById['t6'], 'archived');
    });
  });
}
