import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for list of all projects
/// TODO: Implement with database queries
final projectsProvider = Provider<List<dynamic>>((ref) {
  // TODO: Fetch from database
  return [];
});

/// Provider for creating a new project
final createProjectProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, data) async {
    // TODO: Implement project creation
  },
);

/// Provider for deleting a project
final deleteProjectProvider = FutureProvider.family<void, String>((
  ref,
  projectId,
) async {
  // TODO: Implement project deletion
});

/// Provider for updating a project
final updateProjectProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, data) async {
    // TODO: Implement project update
  },
);
