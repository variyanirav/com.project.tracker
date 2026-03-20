import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';

/// Provides singleton instance of AppDatabase
/// This is the root provider that all repository providers depend on
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
