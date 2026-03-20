import 'package:drift/drift.dart';

/// Tasks Table
/// Stores all tasks for projects with time tracking
@DataClassName('TaskData')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get taskName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('todo'),
  )(); // todo, inProgress, inReview, onHold, complete
  IntColumn get totalSeconds => integer().withDefault(
    const Constant(0),
  )(); // Cumulative seconds for this task
  BoolColumn get isRunning => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastStartedAt => dateTime().nullable()();
  TextColumn get lastSessionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
