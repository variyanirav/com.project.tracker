import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/projects_table.dart';
import 'tables/tasks_table.dart';
import 'tables/categories_table.dart';
import 'tables/timer_sessions_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/todo_items_table.dart';

part 'app_database.g.dart';

/// App Database
/// Main Drift database class that manages all tables and migrations
@DriftDatabase(
  tables: [Projects, Categories, Tasks, TimerSessions, AppSettings, TodoItems],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  // Getters for DAOs (optional, for convenience)
  late final projectsDao = ProjectsDao(this);
  late final categoriesDao = CategoriesDao(this);
  late final tasksDao = TasksDao(this);
  late final timerSessionsDao = TimerSessionsDao(this);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultCategories();
        await _backfillTaskCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(todoItems);
        }
        if (from < 3) {
          await normalizeLegacyTaskStatuses();
        }
        if (from < 4) {
          await m.createTable(categories);
          await m.addColumn(tasks, tasks.categoryId);
          await _seedDefaultCategories();
          await _backfillTaskCategories();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tasks_category_id ON tasks(category_id)',
          );
        }
        if (from < 5) {
          if (!await _columnExists('timer_sessions', 'start_note')) {
            await m.addColumn(timerSessions, timerSessions.startNote);
          }
          if (!await _columnExists('timer_sessions', 'stop_note')) {
            await m.addColumn(timerSessions, timerSessions.stopNote);
          }
        }
        if (from < 6) {
          if (!await _columnExists('tasks', 'is_billable')) {
            await m.addColumn(tasks, tasks.isBillable);
          }
        }
      },
    );
  }

  static const String uncategorizedCategoryId = 'cat_uncategorized';
  static const String learningCategoryId = 'cat_learning';
  static const String developmentCategoryId = 'cat_development';
  static const String researchCategoryId = 'cat_research';

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now().toUtc();

    final defaults = <CategoryData>[
      CategoryData(
        id: uncategorizedCategoryId,
        name: 'Uncategorized',
        colorHex: '#9E9E9E',
        createdAt: now,
        updatedAt: now,
      ),
      CategoryData(
        id: learningCategoryId,
        name: 'Learning',
        colorHex: '#3B82F6',
        createdAt: now,
        updatedAt: now,
      ),
      CategoryData(
        id: developmentCategoryId,
        name: 'Development',
        colorHex: '#10B981',
        createdAt: now,
        updatedAt: now,
      ),
      CategoryData(
        id: researchCategoryId,
        name: 'Research',
        colorHex: '#F59E0B',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final category in defaults) {
      await into(categories).insertOnConflictUpdate(category);
    }
  }

  Future<void> _backfillTaskCategories() async {
    await customStatement(
      "UPDATE tasks SET category_id = '$learningCategoryId' WHERE category_id IS NULL AND lower(trim(task_name)) LIKE 'learning%';",
    );
    await customStatement(
      "UPDATE tasks SET category_id = '$developmentCategoryId' WHERE category_id IS NULL AND lower(trim(task_name)) LIKE 'development%';",
    );
    await customStatement(
      "UPDATE tasks SET category_id = '$researchCategoryId' WHERE category_id IS NULL AND lower(trim(task_name)) LIKE 'research%';",
    );
    await customStatement(
      "UPDATE tasks SET category_id = '$uncategorizedCategoryId' WHERE category_id IS NULL;",
    );
  }

  /// Normalize legacy task status labels/casing to canonical stored codes.
  ///
  /// Stored canonical values are: todo, inProgress, inReview, onHold, complete.
  Future<void> normalizeLegacyTaskStatuses() async {
    const normalizedExpression =
        "lower(replace(replace(replace(trim(status), '_', ''), '-', ''), ' ', ''))";

    await customStatement(
      "UPDATE tasks SET status = 'todo' WHERE $normalizedExpression = 'todo' AND status <> 'todo'",
    );
    await customStatement(
      "UPDATE tasks SET status = 'inProgress' WHERE $normalizedExpression = 'inprogress' AND status <> 'inProgress'",
    );
    await customStatement(
      "UPDATE tasks SET status = 'inReview' WHERE $normalizedExpression = 'inreview' AND status <> 'inReview'",
    );
    await customStatement(
      "UPDATE tasks SET status = 'onHold' WHERE $normalizedExpression = 'onhold' AND status <> 'onHold'",
    );
    await customStatement(
      "UPDATE tasks SET status = 'complete' WHERE $normalizedExpression = 'complete' AND status <> 'complete'",
    );
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
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

class CategoriesDao {
  final AppDatabase db;
  CategoriesDao(this.db);

  Future<List<CategoryData>> getAllCategories() {
    return (db.select(
      db.categories,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<CategoryData?> getCategoryById(String id) {
    return (db.select(
      db.categories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> createCategory(CategoryData category) {
    return db.into(db.categories).insert(category);
  }

  Future<bool> updateCategory(CategoryData category) {
    return db.update(db.categories).replace(category);
  }

  Future<int> deleteCategory(String id) {
    return (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
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
    final file = File(p.join(dbFolder.path, _databaseFileName()));
    return NativeDatabase(file);
  });
}

String _databaseFileName() {
  const override = String.fromEnvironment('APP_DB_FILENAME');
  if (override.isNotEmpty) {
    return override;
  }

  const isProduction = bool.fromEnvironment('dart.vm.product');
  return isProduction ? 'time_tracker.db' : 'time_tracker_dev.db';
}
