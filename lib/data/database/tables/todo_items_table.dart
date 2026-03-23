import 'package:drift/drift.dart';

/// To-Do items table
/// Stores reminder-like future tasks independent of tracked project tasks.
@DataClassName('TodoItemData')
class TodoItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get referenceUrl => text().nullable()();
  TextColumn get linkedProjectId => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
