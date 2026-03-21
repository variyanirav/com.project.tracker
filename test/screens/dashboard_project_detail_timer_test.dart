import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/domain/entities/project_entity.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/task_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/dashboard_screen.dart';
import 'package:project_tracker/presentation/screens/project_detail_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(Ref ref, TimerState initial) : super(ref) {
    state = initial;
  }
}

void main() {
  final project = ProjectEntity(
    id: 'project-1',
    name: 'Client Work',
    description: 'Main project',
    color: 'C',
    status: 'active',
    createdAt: DateTime.utc(2026, 3, 21),
    updatedAt: DateTime.utc(2026, 3, 21),
  );

  final task = TaskEntity(
    id: 'task-1',
    projectId: 'project-1',
    taskName: 'Build Timer',
    description: 'Implement timer',
    status: 'inProgress',
    totalSeconds: 0,
    isRunning: true,
    createdAt: DateTime.utc(2026, 3, 21),
    updatedAt: DateTime.utc(2026, 3, 21),
  );

  testWidgets('Dashboard shows running timer card when timer is active', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final timerState = TimerState(
      sessionId: 'session-1',
      taskId: task.id,
      projectId: project.id,
      elapsedSeconds: 75,
      isRunning: true,
      isPaused: false,
      startTime: DateTime.now().subtract(const Duration(seconds: 75)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          tasksProvider.overrideWith((ref) async => []),
          timerProvider.overrideWith(
            (ref) => _FakeTimerNotifier(ref, timerState),
          ),
          timerTickProvider.overrideWith((ref) => Stream.value(timerState)),
          todayTotalHoursProvider.overrideWith((ref) async => 1.25),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.15625),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Currently Working On'), findsOneWidget);
    expect(find.text('Unknown Project'), findsOneWidget);
    expect(find.text('Unknown Task'), findsOneWidget);
    expect(find.text('00:01:15'), findsOneWidget);
  });

  testWidgets('Dashboard hides running timer card when timer is idle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final idleState = TimerState.idle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          tasksProvider.overrideWith((ref) async => []),
          timerProvider.overrideWith(
            (ref) => _FakeTimerNotifier(ref, idleState),
          ),
          timerTickProvider.overrideWith((ref) => Stream.value(idleState)),
          todayTotalHoursProvider.overrideWith((ref) async => 0.0),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.0),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Currently Working On'), findsNothing);
  });

  testWidgets('Dashboard shows Start label when timer is paused', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pausedState = TimerState(
      sessionId: 'session-1',
      taskId: task.id,
      projectId: project.id,
      elapsedSeconds: 75,
      isRunning: true,
      isPaused: true,
      startTime: DateTime.now().subtract(const Duration(seconds: 75)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          tasksProvider.overrideWith((ref) async => []),
          timerProvider.overrideWith(
            (ref) => _FakeTimerNotifier(ref, pausedState),
          ),
          timerTickProvider.overrideWith((ref) => Stream.value(pausedState)),
          todayTotalHoursProvider.overrideWith((ref) async => 0.0),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.0),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets(
    'Project detail shows total, today and week hours from providers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final idleState = TimerState.idle();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedProjectIdProvider.overrideWith((ref) => project.id),
            projectsProvider.overrideWith((ref) async => [project]),
            tasksByProjectProvider.overrideWith((ref, id) async => []),
            projectTotalHoursProvider.overrideWith((ref, id) async => 2.5),
            projectTodayHoursProvider.overrideWith((ref, id) async => 1.0),
            projectWeekHoursProvider.overrideWith((ref, id) async => 1.75),
            timerProvider.overrideWith(
              (ref) => _FakeTimerNotifier(ref, idleState),
            ),
            timerTickProvider.overrideWith((ref) => Stream.value(idleState)),
          ],
          child: const MaterialApp(home: ProjectDetailScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Project Details'), findsOneWidget);
      expect(find.text('Total Hours'), findsOneWidget);
      expect(find.text("Today's Hours"), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      expect(find.text('2h 30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('1h 45m'), findsOneWidget);
    },
  );

  testWidgets('Project detail shows Start label when timer is paused', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pausedState = TimerState(
      sessionId: 'session-1',
      taskId: task.id,
      projectId: project.id,
      elapsedSeconds: 75,
      isRunning: true,
      isPaused: true,
      startTime: DateTime.now().subtract(const Duration(seconds: 75)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectIdProvider.overrideWith((ref) => project.id),
          projectsProvider.overrideWith((ref) async => [project]),
          tasksByProjectProvider.overrideWith((ref, id) async => []),
          activeTaskProvider.overrideWith((ref) async => task),
          projectTotalHoursProvider.overrideWith((ref, id) async => 2.5),
          projectTodayHoursProvider.overrideWith((ref, id) async => 1.0),
          projectWeekHoursProvider.overrideWith((ref, id) async => 1.75),
          timerProvider.overrideWith(
            (ref) => _FakeTimerNotifier(ref, pausedState),
          ),
          timerTickProvider.overrideWith((ref) => Stream.value(pausedState)),
        ],
        child: const MaterialApp(home: ProjectDetailScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Currently Tracking'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
