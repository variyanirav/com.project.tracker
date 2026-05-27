import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/core/constants/task_status.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/project_repository_impl.dart';
import 'package:project_tracker/data/repositories/task_repository_impl.dart';
import 'package:project_tracker/data/repositories/timer_session_repository_impl.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/project_detail_screen.dart';
import 'package:project_tracker/presentation/widgets/project_detail/task_list_view.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

void main() {
  group('ProjectDetailScreen thorough test cases', () {
    late AppDatabase db;
    late ProjectRepositoryImpl projectRepo;
    late TaskRepositoryImpl taskRepo;
    late TimerSessionRepositoryImpl timerRepo;

    late String projectId;
    late String todayTaskId;
    late String oldTaskId;
    late DateTime todayCreated;
    late DateTime oldCreated;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      projectRepo = ProjectRepositoryImpl(db);
      taskRepo = TaskRepositoryImpl(db);
      timerRepo = TimerSessionRepositoryImpl(db);

      final project = await projectRepo.createProject(
        name: 'Project A',
        description: 'Project A Description',
        color: 'A',
      );
      projectId = project.id;

      final todayTask = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Today Task',
        description: 'Today task description',
      );
      final oldTask = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Old Task',
        description: 'Old task description',
      );

      todayTaskId = todayTask.id;
      oldTaskId = oldTask.id;
      todayCreated = DateTime.now().toUtc();
      oldCreated = DateTime.now().toUtc().subtract(const Duration(days: 1));

      final todayTaskEntity = (await taskRepo.getTaskById(todayTaskId))!;
      await taskRepo.updateTask(
        todayTaskEntity.copyWith(
          status: 'inProgress',
          totalSeconds: 5400,
          isRunning: true,
          createdAt: todayCreated,
        ),
      );

      final oldTaskEntity = (await taskRepo.getTaskById(oldTaskId))!;
      await taskRepo.updateTask(
        oldTaskEntity.copyWith(
          status: 'todo',
          totalSeconds: 1800,
          isRunning: false,
          createdAt: oldCreated,
        ),
      );

      final now = DateTime.now().toUtc();

      final todaySession = await timerRepo.createSession(
        taskId: todayTaskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(hours: 1, minutes: 30)),
      );
      await timerRepo.stopSession(
        todaySession.id,
        endTime: now,
        totalSeconds: 5400,
      );

      final oldSession = await timerRepo.createSession(
        taskId: oldTaskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(days: 10, hours: 2)),
      );
      await timerRepo.stopSession(
        oldSession.id,
        endTime: now.subtract(const Duration(days: 10)),
        totalSeconds: 7200,
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
            taskId: todayTaskId,
            projectId: projectId,
            elapsedSeconds: 75,
            isRunning: true,
            isPaused: false,
            startTime: DateTime.now().subtract(const Duration(seconds: 75)),
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

    testWidgets('1) Total/Today/Week cards show updated and correct values', (
      tester,
    ) async {
      await pumpScreen(tester, timerState: TimerState.idle());

      expect(find.text('Total Hours'), findsOneWidget);
      expect(find.text("Today's Hours"), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      // Total = 5400 + 7200 = 12600 sec = 3h 30m.
      expect(find.text('3h 30m'), findsAtLeastNWidgets(1));
      // Today and week should include today's 5400 sec => 1h 30m.
      expect(find.text('1h 30m'), findsAtLeastNWidgets(2));
    });

    testWidgets(
      '2) Project tasks list shows start/stop, date and duration correctly',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Project Tasks'), findsOneWidget);
        expect(find.text('Today Task'), findsAtLeastNWidgets(1));
        expect(find.text('Old Task'), findsOneWidget);

        // Duration values are rendered in dedicated table cells.
        expect(find.text(_formatSeconds(5400)), findsAtLeastNWidgets(1));
        expect(find.text(_formatSeconds(1800)), findsAtLeastNWidgets(1));

        // Running task row should expose timer stop control.
        expect(find.byTooltip('Stop'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('3) Task search filters the project list by name and details', (
      tester,
    ) async {
      await pumpScreen(tester);

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Old');
      await tester.pumpAndSettle();

      final taskList = find.byType(TaskListView);
      expect(
        find.descendant(of: taskList, matching: find.text('Old Task')),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.descendant(of: taskList, matching: find.text('Today Task')),
        findsNothing,
      );
    });

    testWidgets(
      '4) Whitespace search behaves like an empty search and keeps all tasks visible',
      (tester) async {
        await pumpScreen(tester);

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, '   ');
        await tester.pumpAndSettle();

        expect(find.text('Today Task'), findsAtLeastNWidgets(1));
        expect(find.text('Old Task'), findsOneWidget);
        expect(find.text('No tasks match your search'), findsNothing);
      },
    );

    testWidgets(
      '5) No matching search shows the centered empty state message',
      (tester) async {
        await pumpScreen(tester);

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'zzzz-not-found');
        await tester.pumpAndSettle();

        expect(find.text('No tasks match your search'), findsOneWidget);
        expect(
          find.text(
            'Try a different keyword or clear the search to see every task.',
          ),
          findsOneWidget,
        );
        expect(find.text('No records found'), findsNothing);
      },
    );

    testWidgets(
      '6) Completed task can be archived and restored from Archive tab',
      (tester) async {
        final completedTask = await taskRepo.createTask(
          projectId: projectId,
          taskName: 'Archive Me',
          description: 'Task ready for archive',
        );

        final completedTaskEntity = (await taskRepo.getTaskById(
          completedTask.id,
        ))!;
        await taskRepo.updateTask(
          completedTaskEntity.copyWith(
            status: 'complete',
            totalSeconds: 3600,
            isRunning: false,
            createdAt: DateTime.now().toUtc(),
          ),
        );

        final archiveSession = await timerRepo.createSession(
          taskId: completedTask.id,
          projectId: projectId,
          startTime: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        );
        await timerRepo.stopSession(
          archiveSession.id,
          endTime: DateTime.now().toUtc(),
          totalSeconds: 3600,
        );
        await timerRepo.updateSessionNotes(
          archiveSession.id,
          'START: Archive setup\nSTOP: Ready to archive',
        );

        await pumpScreen(tester, timerState: TimerState.idle());

        expect(find.text('Archive Me'), findsAtLeastNWidgets(1));
        final archiveButton = find.byTooltip('Archive Task').first;
        await tester.ensureVisible(archiveButton);
        await tester.tap(archiveButton);
        await tester.pumpAndSettle();

        expect(find.text('Archive Task'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Archive Me'), findsNothing);

        await tester.tap(find.text('Archive'));
        await tester.pumpAndSettle();

        expect(find.text('Archive Me'), findsOneWidget);
        expect(find.byTooltip('Edit task'), findsNothing);
        expect(find.byTooltip('Start'), findsNothing);
        expect(find.byTooltip('Stop'), findsNothing);

        final archivedViewButton = find.byTooltip('View task details').first;
        await tester.ensureVisible(archivedViewButton);
        await tester.tap(archivedViewButton);
        await tester.pumpAndSettle();

        final sessionActionsButton = find.byTooltip('Actions').first;
        await tester.ensureVisible(sessionActionsButton);
        await tester.tap(sessionActionsButton);
        await tester.pumpAndSettle();

        expect(find.text('Copy Stop Note'), findsOneWidget);
        expect(find.text('Edit Start Note'), findsNothing);
        expect(find.text('Edit Stop Note'), findsNothing);
        expect(find.text('Delete Session'), findsNothing);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Close').last);
        await tester.pumpAndSettle();

        final restoreButton = find.byTooltip('Restore Task').first;
        await tester.ensureVisible(restoreButton);
        await tester.tap(restoreButton);
        await tester.pumpAndSettle();

        expect(find.text('Restore Task'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();

        expect(find.text('Archive Me'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '7) Info dialog shows correct title, status, timer status, description and date',
      (tester) async {
        await pumpScreen(tester);

        final viewDetailsButton = find.byTooltip('View task details').first;
        await tester.ensureVisible(viewDetailsButton);
        await tester.tap(viewDetailsButton);
        await tester.pumpAndSettle();

        expect(find.text('Task Details'), findsAtLeastNWidgets(1));
        expect(find.text('Title'), findsOneWidget);
        final detailsDialog = find.byType(Dialog);
        expect(
          find.descendant(of: detailsDialog, matching: find.text('Today Task')),
          findsOneWidget,
        );
        expect(find.text('Progress Status'), findsOneWidget);
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text('In Progress'),
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('Timer Status'), findsOneWidget);
        expect(find.text('⏱️ Currently Tracking'), findsOneWidget);
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text('Description'),
          ),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text('Today task description'),
          ),
          findsOneWidget,
        );
        expect(find.text('Created On'), findsOneWidget);
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text(_formatDate(todayCreated)),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '8) Edit button updates title, progress status and description visible via info and list',
      (tester) async {
        await pumpScreen(tester);

        final editButton = find.byTooltip('Edit task').first;
        await tester.ensureVisible(editButton);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        expect(find.text('Edit Task'), findsOneWidget);

        final dialog = find.byType(Dialog);
        final textFields = find.descendant(
          of: dialog,
          matching: find.byType(TextField),
        );
        expect(textFields, findsNWidgets(2));

        await tester.enterText(textFields.at(0), 'Edited Task Title');
        await tester.enterText(textFields.at(1), 'Edited Task Description');

        await tester.tap(
          find.descendant(
            of: dialog,
            matching: find.byType(DropdownButton<TaskStatus>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Complete').last);
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(of: dialog, matching: find.text('Save Changes')),
        );
        await tester.pumpAndSettle();

        // Screen should remain open and show updated task row.
        expect(find.text('Edited Task Title'), findsAtLeastNWidgets(1));
        expect(find.text('Complete'), findsAtLeastNWidgets(1));

        // Verify info dialog values were updated.
        await tester.tap(find.byTooltip('View task details').first);
        await tester.pumpAndSettle();

        final detailsDialog = find.byType(Dialog);
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text('Edited Task Title'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: detailsDialog,
            matching: find.text('Edited Task Description'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: detailsDialog, matching: find.text('Complete')),
          findsOneWidget,
        );
      },
    );

    testWidgets('5) Tasks table replaces today tasks section', (tester) async {
      await pumpScreen(tester);

      expect(find.text("Today's Tasks"), findsNothing);

      // Table headers should be visible.
      expect(find.text('Task ID'), findsAtLeastNWidgets(1));
      expect(find.text('Name'), findsAtLeastNWidgets(1));
      expect(find.text('Timer'), findsAtLeastNWidgets(1));
      expect(find.text('Actions'), findsAtLeastNWidgets(1));

      // Both tasks should appear in the project tasks table.
      expect(find.text('Today Task'), findsAtLeastNWidgets(1));
      expect(find.text('Old Task'), findsOneWidget);
    });

    testWidgets('9) Filter with no matching records shows no-records message', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Complete').first);
      await tester.pumpAndSettle();

      expect(find.text('No records found'), findsOneWidget);
      expect(find.text('Task ID'), findsNothing);
    });

    testWidgets('10) Empty task dataset shows no-records message', (
      tester,
    ) async {
      await taskRepo.deleteTask(todayTaskId);
      await taskRepo.deleteTask(oldTaskId);

      await pumpScreen(tester);

      expect(find.text('No records found'), findsOneWidget);
      expect(find.text('Create your first task above'), findsOneWidget);
    });
  });
}

String _formatSeconds(int seconds) {
  if (seconds == 0) return '0m';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) {
    return '${minutes}m';
  } else if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

String _formatDate(DateTime date) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day;
  final monthName = months[date.month];
  final year = date.year;
  final suffix = _daySuffix(day);
  return '$day$suffix $monthName $year';
}

String _daySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
