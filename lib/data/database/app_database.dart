import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/projects_table.dart';
import 'tables/tasks_table.dart';
import 'tables/timer_sessions_table.dart';
import 'tables/app_settings_table.dart';

part 'app_database.g.dart';

/// App Database
/// Main Drift database class that manages all tables and migrations
@DriftDatabase(tables: [Projects, Tasks, TimerSessions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // Getters for DAOs (optional, for convenience)
  late final projectsDao = ProjectsDao(this);
  late final tasksDao = TasksDao(this);
  late final timerSessionsDao = TimerSessionsDao(this);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here as schema evolves
        // Currently at version 1, so no migrations needed
      },
    );
  }
}

/// Simple DAOs for common operations (optional, can expand as needed)

class ProjectsDao {
  final AppDatabase db;
  ProjectsDao(this.db);

  /// Get all projects ordered by creation date (newest first)
  Future<List<ProjectData>> getAllProjects() {
    return (db.select(db.projects)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Get single project by ID
  Future<ProjectData?> getProjectById(String id) async {
    final result = await (db.select(
      db.projects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return result;
  }

  /// Create project
  Future<void> createProject(ProjectData project) {
    return db.into(db.projects).insert(project);
  }

  /// Update project
  Future<bool> updateProject(ProjectData project) {
    return db.update(db.projects).replace(project);
  }

  /// Delete project (cascade deletes tasks and sessions)
  Future<int> deleteProject(String id) {
    return (db.delete(db.projects)..where((t) => t.id.equals(id))).go();
  }
}

class TasksDao {
  final AppDatabase db;
  TasksDao(this.db);

  /// Get all tasks for a project (paginated)
  Future<List<TaskData>> getTasksByProject(
    String projectId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (db.select(db.tasks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get single task by ID
  Future<TaskData?> getTaskById(String id) async {
    return (db.select(
      db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Create task
  Future<void> createTask(TaskData task) {
    return db.into(db.tasks).insert(task);
  }

  /// Update task
  Future<bool> updateTask(TaskData task) {
    return db.update(db.tasks).replace(task);
  }

  /// Delete task
  Future<int> deleteTask(String id) {
    return (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Get tasks for today by project
  Future<List<TaskData>> getTasksForToday(String projectId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(Duration(days: 1));

    return (db.select(db.tasks)..where(
          (t) =>
              t.projectId.equals(projectId) &
              t.createdAt.isBetweenValues(todayStart, tomorrowStart),
        ))
        .get();
  }

  /// Update task status
  Future<int> updateTaskStatus(String taskId, String status) {
    return (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
    );
  }

  /// Update task total seconds
  Future<int> updateTaskTotalSeconds(String taskId, int totalSeconds) {
    return (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        totalSeconds: Value(totalSeconds),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class TimerSessionsDao {
  final AppDatabase db;
  TimerSessionsDao(this.db);

  /// Create timer session
  Future<void> createSession(TimerSessionData session) {
    return db.into(db.timerSessions).insert(session);
  }

  /// Get active timer (only 1 should exist)
  Future<TimerSessionData?> getActiveTimer() async {
    return (db.select(
      db.timerSessions,
    )..where((t) => t.endTime.isNull())).getSingleOrNull();
  }

  /// Stop timer session
  Future<int> stopSession(
    String sessionId,
    DateTime endTime,
    int elapsedSeconds,
  ) {
    return (db.update(
      db.timerSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      TimerSessionsCompanion(
        endTime: Value(endTime),
        elapsedSeconds: Value(elapsedSeconds),
      ),
    );
  }

  /// Get all sessions for a task
  Future<List<TimerSessionData>> getSessionsByTask(String taskId) {
    return (db.select(db.timerSessions)
          ..where((t) => t.taskId.equals(taskId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get all sessions for a project
  Future<List<TimerSessionData>> getSessionsByProject(String projectId) {
    return (db.select(db.timerSessions)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get sessions for a specific day
  Future<List<TimerSessionData>> getSessionsForDay(
    String projectId,
    DateTime dayStart,
  ) {
    final dayEnd = dayStart.add(Duration(days: 1));
    return (db.select(db.timerSessions)..where(
          (t) =>
              t.projectId.equals(projectId) &
              t.startTime.isBetweenValues(dayStart, dayEnd),
        ))
        .get();
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'time_tracker.db'));
    return NativeDatabase(file);
  });
}
