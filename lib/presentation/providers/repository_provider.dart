import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/repositories/repositories.dart';
import 'package:project_tracker/domain/repositories/iproject_repository.dart';
import 'package:project_tracker/domain/repositories/itask_repository.dart';
import 'package:project_tracker/domain/repositories/itimer_session_repository.dart';
import 'package:project_tracker/domain/repositories/idaily_goal_repository.dart';
import 'database_provider.dart';

/// Provides the project repository implementation
final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepositoryImpl(db);
});

/// Provides the task repository implementation
final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepositoryImpl(db);
});

/// Provides the timer session repository implementation
final timerSessionRepositoryProvider = Provider<ITimerSessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TimerSessionRepositoryImpl(db);
});

/// Provides the daily goal repository implementation
final dailyGoalRepositoryProvider = Provider<IDailyGoalRepository>((ref) {
  return DailyGoalRepositoryImpl();
});
