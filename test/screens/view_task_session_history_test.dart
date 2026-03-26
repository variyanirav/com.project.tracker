import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/project_repository_impl.dart';
import 'package:project_tracker/data/repositories/task_repository_impl.dart';
import 'package:project_tracker/data/repositories/timer_session_repository_impl.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/project_detail_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

void main() {
  testWidgets(
    'task details shows session notes and supports edit/delete session actions',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => db.close());

      final projectRepo = ProjectRepositoryImpl(db);
      final taskRepo = TaskRepositoryImpl(db);
      final sessionRepo = TimerSessionRepositoryImpl(db);

      final project = await projectRepo.createProject(
        name: 'Session Notes Project',
        description: 'Project for session notes test',
        color: 'S',
      );

      final task = await taskRepo.createTask(
        projectId: project.id,
        taskName: 'Session Notes Task',
        description: 'Task with session notes',
      );

      final start = DateTime.utc(2026, 3, 26, 11, 0);
      final end = DateTime.utc(2026, 3, 26, 12, 0);
      final session = await sessionRepo.createSession(
        taskId: task.id,
        projectId: project.id,
        startTime: start,
      );
      await sessionRepo.stopSession(
        session.id,
        endTime: end,
        totalSeconds: 3600,
      );
      await sessionRepo.updateSessionNotes(
        session.id,
        'START: Initial planning\nSTOP: Completed first draft',
      );

      final idle = TimerState.idle();

      await tester.binding.setSurfaceSize(const Size(1700, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedProjectIdProvider.overrideWith((ref) => project.id),
            timerProvider.overrideWith((ref) => _FakeTimerNotifier(ref, idle)),
            timerTickProvider.overrideWith((ref) => Stream.value(idle)),
          ],
          child: const MaterialApp(home: ProjectDetailScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byTooltip('View task details').first);
      await tester.pumpAndSettle();

      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Session History'), findsOneWidget);
      expect(find.textContaining('START: Initial planning'), findsOneWidget);
      expect(
        find.textContaining('STOP: Completed first draft'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Edit Session Notes').first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Session Notes'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        'START: Updated plan\nSTOP: Updated outcome',
      );
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('START: Updated plan'), findsOneWidget);
      expect(find.textContaining('STOP: Updated outcome'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete Session').first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Session'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No sessions logged yet'), findsOneWidget);
    },
  );
}
