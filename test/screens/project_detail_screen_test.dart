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
      expect(find.text('3h 30m'), findsOneWidget);
      // Today and week should include today's 5400 sec => 1h 30m.
      expect(find.text('1h 30m'), findsAtLeastNWidgets(2));
    });

    testWidgets(
      '2) Project tasks list shows start/stop, date and duration correctly',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Project Tasks'), findsOneWidget);
        expect(find.text('Today Task'), findsAtLeastNWidgets(2));
        expect(find.text('Old Task'), findsOneWidget);

        final todayMeta =
            '${_formatSeconds(5400)} · ${_formatDate(todayCreated)}';
        final oldMeta = '${_formatSeconds(1800)} · ${_formatDate(oldCreated)}';

        expect(find.text(todayMeta), findsOneWidget);
        expect(find.text(oldMeta), findsOneWidget);

        // Running task row should expose Stop action.
        expect(find.text('Stop'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '3) Info dialog shows correct title, status, timer status, description and date',
      (tester) async {
        await pumpScreen(tester);

        final viewDetailsButton = find.byTooltip('View task details').first;
        await tester.ensureVisible(viewDetailsButton);
        await tester.tap(viewDetailsButton);
        await tester.pumpAndSettle();

        expect(find.text('Task Details'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        final detailsDialog = find.byType(AlertDialog);
        expect(
          find.descendant(of: detailsDialog, matching: find.text('Today Task')),
          findsOneWidget,
        );
        expect(find.text('Progress Status'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Timer Status'), findsOneWidget);
        expect(find.text('⏱️ Currently Tracking'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
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
      '4) Edit button updates title, progress status and description visible via info and list',
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
        expect(find.text('Edited Task Title'), findsAtLeastNWidgets(2));
        expect(find.text('Complete'), findsAtLeastNWidgets(1));

        // Verify info dialog values were updated.
        await tester.tap(find.byTooltip('View task details').first);
        await tester.pumpAndSettle();

        final detailsDialog = find.byType(AlertDialog);
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

    testWidgets('5) Today tasks section shows only today tasks with basic info', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text("Today's Tasks"), findsOneWidget);

      // Today task appears in main list + today's list, old task only in main list.
      expect(find.text('Today Task'), findsAtLeastNWidgets(2));
      expect(find.text('Old Task'), findsOneWidget);

      // Basic info in today's card: duration + status.
      expect(find.text(_formatSeconds(5400)), findsWidgets);
      expect(find.text('inProgress'), findsAtLeastNWidgets(1));
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
