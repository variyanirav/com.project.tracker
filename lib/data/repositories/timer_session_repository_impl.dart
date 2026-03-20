import 'package:project_tracker/domain/repositories/itimer_session_repository.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/time_aggregator.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:uuid/uuid.dart';

/// Concrete implementation of ITimerSessionRepository
/// Handles all timer session data operations using AppDatabase
class TimerSessionRepositoryImpl implements ITimerSessionRepository {
  final AppDatabase db;

  TimerSessionRepositoryImpl(this.db);

  @override
  Future<TimerSessionEntity> createSession({
    required String taskId,
    required String projectId,
    required DateTime startTime,
  }) async {
    final id = const Uuid().v4();
    final now = TimezoneHelper.getCurrentUtc();

    final session = TimerSessionData(
      id: id,
      taskId: taskId,
      projectId: projectId,
      startTime: startTime,
      endTime: null,
      elapsedSeconds: 0,
      isPaused: false,
      notes: null,
      createdAt: now,
    );

    await db.timerSessionsDao.createSession(session);
    return _toEntity(session);
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByTask(String taskId) async {
    final sessions = await db.timerSessionsDao.getSessionsByTask(taskId);
    return sessions.map(_toEntity).toList();
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByProject(
    String projectId,
  ) async {
    final sessions = await db.timerSessionsDao.getSessionsByProject(projectId);
    return sessions.map(_toEntity).toList();
  }

  @override
  Future<TimerSessionEntity?> getSessionById(String id) async {
    final sessions = await (db.select(
      db.timerSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return sessions != null ? _toEntity(sessions) : null;
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByDate(DateTime date) async {
    final sessions = await (db.select(db.timerSessions)).get();
    return sessions
        .where((s) => TimezoneHelper.isSameDay(s.startTime, date))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessions = await (db.select(db.timerSessions)).get();
    return sessions
        .where(
          (s) =>
              (s.startTime.isAfter(startDate) &&
                  s.startTime.isBefore(endDate)) ||
              TimezoneHelper.isSameDay(s.startTime, startDate) ||
              TimezoneHelper.isSameDay(s.startTime, endDate),
        )
        .map(_toEntity)
        .toList();
  }

  @override
  Future<TimerSessionEntity?> getActiveSession() async {
    final data = await db.timerSessionsDao.getActiveTimer();
    return data != null ? _toEntity(data) : null;
  }

  @override
  Future<void> stopSession(
    String sessionId, {
    required DateTime endTime,
    required int totalSeconds,
  }) async {
    await db.timerSessionsDao.stopSession(sessionId, endTime, totalSeconds);
  }

  @override
  Future<void> pauseSession(String sessionId, DateTime pauseTime) async {
    final session = await (db.select(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (session == null) return;

    final updated = session.copyWith(isPaused: true);
    await (db.update(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).write(updated);
  }

  @override
  Future<void> resumeSession(String sessionId, DateTime resumeTime) async {
    final session = await (db.select(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (session == null) return;

    final updated = session.copyWith(isPaused: false);
    await (db.update(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).write(updated);
  }

  @override
  Future<int> getTaskTotalSeconds(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.sumSessionDurations(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<int> getProjectTotalSeconds(String projectId) async {
    final sessions = await getSessionsByProject(projectId);
    return TimeAggregator.sumSessionDurations(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<double> getTaskTotalHours(String taskId) async {
    final seconds = await getTaskTotalSeconds(taskId);
    return TimeAggregator.secondsToHours(seconds);
  }

  @override
  Future<double> getProjectTotalHours(String projectId) async {
    final seconds = await getProjectTotalSeconds(projectId);
    return TimeAggregator.secondsToHours(seconds);
  }

  @override
  Future<List<TimerSessionEntity>> getTodaySessionsByTask(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return sessions.where((s) => s.isToday).toList();
  }

  @override
  Future<List<TimerSessionEntity>> getTodaySessionsByProject(
    String projectId,
  ) async {
    final sessions = await getSessionsByProject(projectId);
    return sessions.where((s) => s.isToday).toList();
  }

  @override
  Future<List<TimerSessionEntity>> getWeekSessionsByProject(
    String projectId,
  ) async {
    final sessions = await getSessionsByProject(projectId);
    return sessions.where((s) => s.isThisWeek).toList();
  }

  @override
  Future<double> getTodayTotalHours() async {
    final today = TimezoneHelper.getTodayStartUtc();
    final sessions = await getSessionsByDate(today);
    return TimeAggregator.sumSessionHours(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<double> getWeekTotalHours() async {
    final weekStart = TimezoneHelper.getWeekStartUtc();
    final weekEnd = TimezoneHelper.getWeekEndUtc();
    final sessions = await getSessionsByDateRange(weekStart, weekEnd);
    return TimeAggregator.sumSessionHours(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<double> getMonthTotalHours(int year, int month) async {
    final sessions = await (db.select(db.timerSessions)).get();
    final filtered = sessions
        .where((s) => s.startTime.year == year && s.startTime.month == month)
        .toList();
    return TimeAggregator.sumSessionHours(filtered);
  }

  @override
  Future<int> getTaskAverageSessionDuration(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.calculateAverageSessionDuration(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<int> getTaskLongestSession(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.getLongestSessionDuration(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<int> getTaskShortestSession(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.getShortestSessionDuration(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    );
  }

  @override
  Future<void> deleteSession(String id) async {
    await (db.delete(db.timerSessions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteSessionsByTask(String taskId) async {
    await (db.delete(
      db.timerSessions,
    )..where((t) => t.taskId.equals(taskId))).go();
  }

  @override
  Future<void> updateSessionNotes(String sessionId, String? notes) async {
    final session = await getSessionById(sessionId);
    if (session == null) return;

    final updated = TimerSessionData(
      id: session.id,
      taskId: session.taskId,
      projectId: session.projectId,
      startTime: session.startTime,
      endTime: session.endTime,
      elapsedSeconds: session.totalSeconds,
      isPaused: session.isPaused,
      notes: notes,
      createdAt: session.createdAt,
    );

    await (db.update(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).write(updated);
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByTaskPaginated(
    String taskId, {
    required int limit,
    required int offset,
  }) async {
    final sessions = await db.timerSessionsDao.getSessionsByTask(taskId);
    final paginated = sessions.skip(offset).take(limit);
    return paginated.map(_toEntity).toList();
  }

  @override
  Future<bool> hasActiveSession() async {
    final active = await getActiveSession();
    return active != null;
  }

  @override
  Future<int> getSessionCountByTask(String taskId) async {
    final sessions = await getSessionsByTask(taskId);
    return sessions.length;
  }

  @override
  Future<int> getSessionCountByProject(String projectId) async {
    final sessions = await getSessionsByProject(projectId);
    return sessions.length;
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByTaskNewest(
    String taskId,
  ) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.sortByNewest(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    ).map(_toEntity).toList();
  }

  @override
  Future<List<TimerSessionEntity>> getSessionsByTaskOldest(
    String taskId,
  ) async {
    final sessions = await getSessionsByTask(taskId);
    return TimeAggregator.sortByOldest(
      sessions.map((e) => _entityToDbModel(e)).toList(),
    ).map(_toEntity).toList();
  }

  /// Helper: Convert database TimerSessionData to domain TimerSessionEntity
  TimerSessionEntity _toEntity(TimerSessionData data) {
    return TimerSessionEntity(
      id: data.id,
      taskId: data.taskId,
      projectId: data.projectId,
      startTime: data.startTime,
      pauseTime: data.isPaused ? data.startTime : null,
      resumeTime: null,
      endTime: data.endTime,
      totalSeconds: data.elapsedSeconds,
      isCompleted: data.endTime != null,
      sessionDate:
          '${data.startTime.year}-${data.startTime.month.toString().padLeft(2, '0')}-${data.startTime.day.toString().padLeft(2, '0')}',
      notes: data.notes,
      createdAt: data.createdAt,
    );
  }

  /// Helper: Convert domain TimerSessionEntity to database TimerSessionData
  TimerSessionData _entityToDbModel(TimerSessionEntity entity) {
    return TimerSessionData(
      id: entity.id,
      taskId: entity.taskId,
      projectId: entity.projectId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      elapsedSeconds: entity.totalSeconds,
      isPaused: false,
      notes: null,
      createdAt: entity.createdAt,
    );
  }
}
