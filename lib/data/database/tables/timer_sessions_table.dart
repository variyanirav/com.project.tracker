import 'package:drift/drift.dart';

/// Timer Sessions Table
/// Stores individual timer session records for time tracking
@DataClassName('TimerSessionData')
class TimerSessions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get startTime =>
      dateTime()(); // UTC timestamp when timer started
  DateTimeColumn get endTime => dateTime()
      .nullable()(); // UTC timestamp when timer stopped (null if still running)
  IntColumn get elapsedSeconds => integer()(); // Total seconds for this session
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime()(); // When this session record was created

  @override
  Set<Column> get primaryKey => {id};
}
