import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for list of all tasks
/// TODO: Implement with database queries
final tasksProvider = Provider<List<dynamic>>((ref) {
  // TODO: Fetch from database
  return [];
});

/// Provider for tasks filtered by project
final tasksByProjectProvider = Provider.family<List<dynamic>, String>((
  ref,
  projectId,
) {
  // TODO: Fetch from database with project filter
  return [];
});

/// Provider for active/running task
final activeTaskProvider = StateProvider<dynamic>((ref) {
  // TODO: Fetch currently running task
  return null;
});

/// Provider for creating a new task
final createTaskProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  // TODO: Implement task creation
});

/// Provider for updating a task
final updateTaskProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  // TODO: Implement task update
});

/// Provider for deleting a task
final deleteTaskProvider = FutureProvider.family<void, String>((
  ref,
  taskId,
) async {
  // TODO: Implement task deletion
});
