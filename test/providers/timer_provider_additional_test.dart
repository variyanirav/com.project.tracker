import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/repositories/idaily_goal_repository.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/repository_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';

class _FakeDailyGoalRepository implements IDailyGoalRepository {
  int _goalMinutes;
  Map<String, dynamic> _active = {};
  String _theme = 'system';
  bool _notifications = true;
  final Map<String, Object?> _prefs = {};

  _FakeDailyGoalRepository(this._goalMinutes);

  @override
  Future<void> clearActiveTimer() async {
    _active = {};
  }

  @override
  Future<void> clearAllPreferences() async {
    _prefs.clear();
    _active = {};
  }

  @override
  Future<bool> areNotificationsEnabled() async => _notifications;

  @override
  Future<Map<String, dynamic>> getActiveTimer() async => _active;

  @override
  Future<Set<String>> getAllPreferenceKeys() async => _prefs.keys.toSet();

  @override
  Future<String?> getActiveTimerTaskId() async => _active['taskId'] as String?;

  @override
  Future<int> getDailyGoal() async => _goalMinutes;

  @override
  Future<int> getDefaultDailyGoal() async => 480;

  @override
  Future<String> getThemePreference() async => _theme;

  @override
  Future<bool> hasActiveTimer() async => _active.isNotEmpty;

  @override
  Future<bool> hasPreference(String key) async => _prefs.containsKey(key);

  @override
  Future<bool> isTodayGoalMet(double hoursWorked) async {
    return hoursWorked >= (_goalMinutes / 60.0);
  }

  @override
  Future<void> removePreference(String key) async {
    _prefs.remove(key);
  }

  @override
  Future<void> saveActiveTimer({
    required String taskId,
    required int elapsedSeconds,
    required String startTime,
  }) async {
    _active = {
      'taskId': taskId,
      'elapsedSeconds': elapsedSeconds,
      'startTime': startTime,
    };
  }

  @override
  Future<void> setDailyGoal(int minutes) async {
    _goalMinutes = minutes;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notifications = enabled;
  }

  @override
  Future<void> setThemePreference(String theme) async {
    _theme = theme;
  }

  @override
  Future<double> getTodayGoalProgress(double hoursWorked) async {
    final goal = _goalMinutes / 60.0;
    if (goal == 0) return 0.0;
    return (hoursWorked / goal).clamp(0.0, 1.0);
  }

  @override
  Future<void> updateActiveTimerElapsedSeconds(int elapsedSeconds) async {
    if (_active.isNotEmpty) {
      _active['elapsedSeconds'] = elapsedSeconds;
    }
  }
}

void main() {
  group('TimerProvider additional coverage', () {
    late AppDatabase db;
    late ProviderContainer container;
    late String projectId;
    late String taskId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          dailyGoalRepositoryProvider.overrideWithValue(
            _FakeDailyGoalRepository(120),
          ),
        ],
      );

      final projectRepo = container.read(projectRepositoryProvider);
      final taskRepo = container.read(taskRepositoryProvider);

      final project = await projectRepo.createProject(
        name: 'Timer P',
        description: 'desc',
        color: 'T',
      );
      projectId = project.id;

      final task = await taskRepo.createTask(
        projectId: projectId,
        taskName: 'Timer Task',
        description: 'desc',
      );
      taskId = task.id;
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'timer providers for sessions and totals resolve with db data',
      () async {
        final timerRepo = container.read(timerSessionRepositoryProvider);
        final now = DateTime.now().toUtc();

        final stopped = await timerRepo.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now.subtract(const Duration(minutes: 20)),
        );
        await timerRepo.stopSession(
          stopped.id,
          endTime: now,
          totalSeconds: 1200,
        );

        final active = await timerRepo.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now,
        );

        final current = await container.read(
          currentTimerSessionProvider.future,
        );
        expect(current, isNotNull);
        expect(current!.id, active.id);

        final all = await container.read(timerSessionsProvider.future);
        expect(all.length, greaterThanOrEqualTo(2));

        final byTask = await container.read(
          timerSessionsByTaskProvider(taskId).future,
        );
        expect(byTask.length, greaterThanOrEqualTo(2));

        final byProject = await container.read(
          timerSessionsByProjectProvider(projectId).future,
        );
        expect(byProject.length, greaterThanOrEqualTo(2));

        final byDate = await container.read(
          timerSessionsByDateProvider(now).future,
        );
        expect(byDate.isNotEmpty, isTrue);

        final todaySessions = await container.read(
          todayTimerSessionsProvider.future,
        );
        expect(todaySessions.isNotEmpty, isTrue);

        // Current implementation asks week sessions with empty project id.
        final weekSessions = await container.read(
          weekTimerSessionsProvider.future,
        );
        expect(weekSessions, isA<List>());

        final todayHours = await container.read(todayTotalHoursProvider.future);
        final weekHours = await container.read(weekTotalHoursProvider.future);
        final hasActive = await container.read(hasActiveTimerProvider.future);

        expect(todayHours, greaterThanOrEqualTo(1200 / 3600));
        expect(weekHours, greaterThanOrEqualTo(1200 / 3600));
        expect(hasActive, isTrue);
      },
    );

    test('daily goal and progress providers compute expected values', () async {
      final timerRepo = container.read(timerSessionRepositoryProvider);
      final now = DateTime.now().toUtc();

      final s = await timerRepo.createSession(
        taskId: taskId,
        projectId: projectId,
        startTime: now.subtract(const Duration(hours: 1)),
      );
      await timerRepo.stopSession(s.id, endTime: now, totalSeconds: 3600);

      final goalHours = await container.read(dailyGoalProvider.future);
      final progress = await container.read(dailyProgressProvider.future);

      expect(goalHours, 2.0);
      expect(progress, closeTo(0.5, 0.1));

      final zeroGoalContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          dailyGoalRepositoryProvider.overrideWithValue(
            _FakeDailyGoalRepository(0),
          ),
        ],
      );
      addTearDown(zeroGoalContainer.dispose);

      final zeroProgress = await zeroGoalContainer.read(
        dailyProgressProvider.future,
      );
      expect(zeroProgress, 0.0);
    });

    test(
      'timerDebugInfoProvider and deleteTimerSessionProvider work',
      () async {
        final timerRepo = container.read(timerSessionRepositoryProvider);
        final now = DateTime.now().toUtc();

        final session = await timerRepo.createSession(
          taskId: taskId,
          projectId: projectId,
          startTime: now,
        );

        final info = container.read(timerDebugInfoProvider);
        expect(info.contains('isRunning='), isTrue);
        expect(info.contains('elapsedSeconds='), isTrue);

        await container.read(deleteTimerSessionProvider(session.id).future);
        final deleted = await timerRepo.getSessionById(session.id);
        expect(deleted, isNull);
      },
    );

    test('timerTickProvider emits for idle and running states', () async {
      final idleState = await container.read(timerTickProvider.future);
      expect(idleState.isRunning, isFalse);

      final notifier = container.read(timerProvider.notifier);
      await notifier.startTimer(taskId, projectId);

      final emitted = <TimerState>[];
      final sub = container.listen(timerTickProvider, (_, next) {
        next.whenData(emitted.add);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(emitted.length, greaterThanOrEqualTo(1));
      expect(emitted.first.isRunning, isTrue);

      await notifier.stopTimer();
    });

    test('TimerState and updateElapsedTime behavior', () async {
      final notifier = container.read(timerProvider.notifier);

      final idle = TimerState.idle();
      expect(idle.isRunning, isFalse);
      expect(idle.elapsedSeconds, 0);

      final updated = idle.copyWith(isRunning: true, elapsedSeconds: 42);
      expect(updated.isRunning, isTrue);
      expect(updated.elapsedSeconds, 42);

      notifier.updateElapsedTime(10);
      expect(container.read(timerProvider).elapsedSeconds, 0);

      await notifier.startTimer(taskId, projectId);
      notifier.updateElapsedTime(99);
      expect(container.read(timerProvider).elapsedSeconds, 99);

      await notifier.stopTimer();
    });

    test(
      'stopTimer persists task totalSeconds and updates project hours providers',
      () async {
        final notifier = container.read(timerProvider.notifier);
        final taskRepo = container.read(taskRepositoryProvider);

        await notifier.startTimer(taskId, projectId);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        await notifier.stopTimer();

        final task = await taskRepo.getTaskById(taskId);
        expect(task, isNotNull);
        expect(task!.totalSeconds, greaterThan(0));

        final totalHours = await container.read(
          projectTotalHoursProvider(projectId).future,
        );
        final todayHours = await container.read(
          projectTodayHoursProvider(projectId).future,
        );
        final weekHours = await container.read(
          projectWeekHoursProvider(projectId).future,
        );

        expect(totalHours, greaterThan(0));
        expect(todayHours, greaterThan(0));
        expect(weekHours, greaterThan(0));
      },
    );
  });
}
