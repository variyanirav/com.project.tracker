import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/project_repository_impl.dart';
import 'package:project_tracker/data/repositories/task_repository_impl.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/screens/project_detail_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

void main() {
  group('ProjectDetailScreen trash flow', () {
    late AppDatabase db;
    late ProjectRepositoryImpl projectRepo;
    late TaskRepositoryImpl taskRepo;
    late String projectId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      projectRepo = ProjectRepositoryImpl(db);
      taskRepo = TaskRepositoryImpl(db);

      final project = await projectRepo.createProject(
        name: 'Project A',
        description: 'Project A Description',
        color: 'A',
      );
      projectId = project.id;
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      TimerState? timerState,
    }) async {
      final state = timerState ?? TimerState.idle();

      await tester.binding.setSurfaceSize(const Size(1700, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedProjectIdProvider.overrideWith((ref) => projectId),
            timerProvider.overrideWith((ref) => _FakeTimerNotifier(ref, state)),
            timerTickProvider.overrideWith((ref) => Stream.value(state)),
          ],
          child: const MaterialApp(home: ProjectDetailScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> openTaskAction(WidgetTester tester, String actionLabel) async {
      final actionButton = find.byTooltip('More actions').first;
      await tester.ensureVisible(actionButton);
      await tester.tap(actionButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(actionLabel).last);
      await tester.pumpAndSettle();
    }

    testWidgets(
      '1) Moving a task to Trash stores it as deleted and restore brings back its original status',
      (tester) async {
        final task = await taskRepo.createTask(
          projectId: projectId,
          taskName: 'Trash Candidate',
          description: 'Task that should move to Trash',
        );
        final taskEntity = (await taskRepo.getTaskById(task.id))!;
        await taskRepo.updateTask(
          taskEntity.copyWith(
            status: 'inProgress',
            totalSeconds: 1800,
            isRunning: false,
          ),
        );

        await pumpScreen(tester);

        expect(find.text('Trash Candidate'), findsAtLeastNWidgets(1));

        await openTaskAction(tester, 'Move to Trash');
        expect(find.text('Move to Trash'), findsOneWidget);
        await tester.tap(find.text('Move'));
        await tester.pumpAndSettle();

        expect(await taskRepo.getTasksByProject(projectId), isEmpty);
        final trashedTasks = await taskRepo.getDeletedTasksByProject(projectId);
        expect(trashedTasks, hasLength(1));
        expect(trashedTasks.single.id, task.id);
        expect(trashedTasks.single.deletedStatus, 'inProgress');
        expect(trashedTasks.single.deletedAt, isNotNull);

        await tester.tap(find.widgetWithText(ChoiceChip, 'Trash'));
        await tester.pumpAndSettle();

        expect(find.text('Trash Candidate'), findsOneWidget);

        await openTaskAction(tester, 'Restore');
        expect(find.text('Restore Task'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        final restored = await taskRepo.getTaskById(task.id);
        expect(restored, isNotNull);
        expect(restored!.status, 'inProgress');
        expect(restored.deletedAt, isNull);
        expect(restored.deletedStatus, isNull);
        expect(await taskRepo.getDeletedTasksByProject(projectId), isEmpty);
      },
    );

    testWidgets('2) Archive tab remains separate from Trash', (tester) async {
      final completedTask = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Archive Candidate',
        description: 'Task that should be archived',
      );
      final completedTaskEntity = (await taskRepo.getTaskById(
        completedTask.id,
      ))!;
      await taskRepo.updateTask(
        completedTaskEntity.copyWith(
          status: 'complete',
          totalSeconds: 3600,
          isRunning: false,
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Archive Candidate'), findsAtLeastNWidgets(1));

      await openTaskAction(tester, 'Archive');
      expect(find.text('Archive Task'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Archive Candidate'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Archive Candidate'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Trash'));
      await tester.pumpAndSettle();
      expect(find.text('No records found'), findsOneWidget);
      expect(find.text('Archive Candidate'), findsNothing);
    });

    testWidgets(
      '3) Permanently deleting a trashed task removes it from the database',
      (tester) async {
        final task = await taskRepo.createTask(
          projectId: projectId,
          taskName: 'Delete Candidate',
          description: 'Task that should be removed permanently',
        );

        await pumpScreen(tester);

        await openTaskAction(tester, 'Move to Trash');
        await tester.tap(find.text('Move'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ChoiceChip, 'Trash'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Candidate'), findsOneWidget);

        await openTaskAction(tester, 'Delete Permanently');
        expect(find.text('Delete Permanently'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(await taskRepo.getTaskById(task.id), isNull);
        expect(await taskRepo.getDeletedTasksByProject(projectId), isEmpty);
        expect(find.text('Delete Candidate'), findsNothing);
      },
    );
  });
}
