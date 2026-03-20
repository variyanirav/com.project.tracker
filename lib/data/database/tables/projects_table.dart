import 'package:drift/drift.dart';

/// Projects Table
/// Stores all projects with basic metadata
@DataClassName('ProjectData')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarEmoji => text().withDefault(const Constant('📱'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
