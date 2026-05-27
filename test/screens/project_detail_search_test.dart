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
  group('ProjectDetailScreen search', () {
    late AppDatabase db;
    late ProjectRepositoryImpl projectRepo;
    late TaskRepositoryImpl taskRepo;
    late String projectId;
    late String activeTaskId;
    late String followUpTaskId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      projectRepo = ProjectRepositoryImpl(db);
      taskRepo = TaskRepositoryImpl(db);

      final project = await projectRepo.createProject(
        name: 'Project Search',
        description: 'Project Search Description',
        color: 'A',
      );
      projectId = project.id;

      final activeTask = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Alpha Task',
        description: 'Focus note for alpha work',
      );
      final followUpTask = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Beta Task',
        description: 'Follow-up and review details',
      );

      activeTaskId = activeTask.id;
      followUpTaskId = followUpTask.id;

      final activeTaskEntity = (await taskRepo.getTaskById(activeTaskId))!;
      await taskRepo.updateTask(
        activeTaskEntity.copyWith(
          status: 'inProgress',
          totalSeconds: 1200,
          isRunning: true,
        ),
      );

      final followUpTaskEntity = (await taskRepo.getTaskById(followUpTaskId))!;
      await taskRepo.updateTask(
        followUpTaskEntity.copyWith(
          status: 'todo',
          totalSeconds: 600,
          isRunning: false,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      TimerState? timerState,
    }) async {
      final state =
          timerState ??
          TimerState(
            sessionId: 'session-running',
            taskId: activeTaskId,
            projectId: projectId,
            elapsedSeconds: 120,
            isRunning: true,
            isPaused: false,
            startTime: DateTime.now().subtract(const Duration(seconds: 120)),
          );

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

    testWidgets('search by task name keeps matching task visible', (
      tester,
    ) async {
      await pumpScreen(tester, timerState: TimerState.idle());

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Task'), findsAtLeastNWidgets(1));
      expect(find.text('Beta Task'), findsNothing);
    });

    testWidgets('whitespace search behaves like no search', (tester) async {
      await pumpScreen(tester, timerState: TimerState.idle());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Task'), findsAtLeastNWidgets(1));
      expect(find.text('Beta Task'), findsAtLeastNWidgets(1));
      expect(find.text('No tasks match your search'), findsNothing);
    });

    testWidgets('no matching search shows centered empty-state copy', (
      tester,
    ) async {
      await pumpScreen(tester, timerState: TimerState.idle());

      await tester.enterText(find.byType(TextField), 'zz-top-level-no-match');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No tasks match your search'), findsOneWidget);
      expect(
        find.text(
          'Try a different keyword or clear the search to see every task.',
        ),
        findsOneWidget,
      );
      expect(find.text('No records found'), findsNothing);
    });

    testWidgets('search also filters archive and trash views', (tester) async {
      final archived = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Archive Search Match',
        description: 'Archived search details',
      );
      final archivedEntity = (await taskRepo.getTaskById(archived.id))!;
      await taskRepo.updateTask(
        archivedEntity.copyWith(
          status: 'complete',
          totalSeconds: 900,
          isRunning: false,
        ),
      );
      await taskRepo.archiveTask(archived.id);

      final trashed = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Trash Search Match',
        description: 'Trashed search details',
      );
      await taskRepo.deleteTask(trashed.id);

      await pumpScreen(tester, timerState: TimerState.idle());

      await tester.tap(find.widgetWithText(ChoiceChip, 'Archive'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Archive Search');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Archive Search Match'), findsAtLeastNWidgets(1));
      expect(find.text('Trash Search Match'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Trash'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Trash Search');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Trash Search Match'), findsAtLeastNWidgets(1));
      expect(find.text('Archive Search Match'), findsNothing);
    });
  });
}
