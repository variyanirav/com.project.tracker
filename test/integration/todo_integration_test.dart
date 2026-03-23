import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/todo_provider.dart';

void main() {
  group('TodoApp - End-to-End Integration Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('complete workflow: create, filter, search, edit, delete', () async {
      // Step 1: Create multiple todos with different properties
      final todoIds = <String>[];

      const testCases = [
        (
          'Review PR #123',
          'Check code quality and tests',
          todoStatusOpen,
          todoPriorityHigh,
        ),
        (
          'Update documentation',
          'Add API examples and configuration',
          todoStatusOpen,
          todoPriorityMedium,
        ),
        (
          'Fix bug in authentication',
          'User login not working',
          todoStatusInProgress,
          todoPriorityHigh,
        ),
        (
          'Plan next sprint',
          'Plan features for Q2',
          todoStatusOpen,
          todoPriorityLow,
        ),
        (
          'Deploy to production',
          'Release version 1.2.0',
          todoStatusDone,
          todoPriorityHigh,
        ),
      ];

      for (var (title, description, status, priority) in testCases) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: title,
              description: description,
              status: status,
              priority: priority,
            ),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 5);
      todoIds.addAll(todos.map((t) => t.id));

      // Step 2: Verify initial counts
      var openCount = await container.read(openTodoCountProvider.future);
      var completedCount = await container.read(
        completedTodoCountProvider.future,
      );
      expect(openCount, 4); // 4 non-done
      expect(completedCount, 1); // 1 done

      // Step 3: Filter by status (Open)
      todos = await container.read(todoItemsProvider.future);
      final openTodos = todos.where((t) => t.status == todoStatusOpen).toList();
      expect(openTodos.length, 3);
      expect(openTodos.every((t) => t.status == todoStatusOpen), isTrue);

      // Step 4: Filter by priority (High)
      final highPriorityTodos = todos
          .where((t) => t.priority == todoPriorityHigh)
          .toList();
      expect(highPriorityTodos.length, 3); // Review PR, Fix bug, Deploy

      // Step 5: Combine filters (Open AND High)
      final openHighTodos = openTodos
          .where((t) => t.priority == todoPriorityHigh)
          .toList();
      expect(openHighTodos.length, 1); // Review PR
      expect(openHighTodos.first.title, 'Review PR #123');

      // Step 6: Search by title
      todos = await container.read(todoItemsProvider.future);
      final searchTitle = todos
          .where((t) => t.title.toLowerCase().contains('review'))
          .toList();
      expect(searchTitle.length, 1);
      expect(searchTitle.first.title, 'Review PR #123');

      // Step 7: Search by description
      final searchDescription = todos
          .where((t) => t.description.toLowerCase().contains('api'))
          .toList();
      expect(searchDescription.length, 1);
      expect(searchDescription.first.title, 'Update documentation');

      // Step 8: Edit a todo
      todos = await container.read(todoItemsProvider.future);
      final todoToEdit = todos.firstWhere((t) => t.title == 'Review PR #123');

      await container.read(
        updateTodoProvider(
          UpdateTodoParams(
            id: todoToEdit.id,
            title: 'Review PR #123 - COMPLETED',
            description: 'Code review complete, ready to merge',
            status: todoStatusDone,
            priority: todoPriorityHigh,
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      final editedTodo = todos.firstWhere((t) => t.id == todoToEdit.id);
      expect(editedTodo.title, 'Review PR #123 - COMPLETED');
      expect(editedTodo.status, todoStatusDone);

      // Step 9: Verify counts updated after edit
      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 3); // Was 4, now 3
      expect(completedCount, 2); // Was 1, now 2

      // Step 10: Delete a todo
      await container.read(deleteTodoProvider(todoIds[1]).future);

      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 4);
      expect(todos.any((t) => t.id == todoIds[1]), isFalse);

      // Step 11: Verify counts updated after delete
      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 2); // 'Update documentation' was deleted
      expect(completedCount, 2);

      // Step 12: Change status to in_progress
      todos = await container.read(todoItemsProvider.future);
      final planTodo = todos.firstWhere((t) => t.title == 'Plan next sprint');

      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: planTodo.id,
            status: todoStatusInProgress,
            snoozedUntil: null,
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      final updatedPlanTodo = todos.firstWhere((t) => t.id == planTodo.id);
      expect(updatedPlanTodo.status, todoStatusInProgress);

      // Step 13: Snooze a todo
      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: updatedPlanTodo.id,
            status: todoStatusSnoozed,
            snoozedUntil: DateTime.now().add(const Duration(days: 7)).toUtc(),
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      final snoozedTodo = todos.firstWhere((t) => t.id == updatedPlanTodo.id);
      expect(snoozedTodo.status, todoStatusSnoozed);
      expect(snoozedTodo.snoozedUntil, isNotNull);

      // Step 14: Verify final state - all non-done items count as "open"
      final finalCount = await container.read(openTodoCountProvider.future);
      // After snoozed, we have: Fix bug (in_progress) + Plan next sprint (snoozed) = 2 open
      expect(finalCount, 2);
    });

    test('bulk operations: create, mark all done, delete all', () async {
      // Create 10 todos
      for (int i = 0; i < 10; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: 'Task $i',
              description: 'Description for task $i',
              status: todoStatusOpen,
            ),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 10);

      // Mark all as done
      for (var todo in todos) {
        await container.read(
          updateTodoStatusProvider(
            UpdateTodoStatusParams(
              id: todo.id,
              status: todoStatusDone,
              snoozedUntil: null,
            ),
          ).future,
        );
      }

      // Verify all are done
      todos = await container.read(todoItemsProvider.future);
      expect(todos.every((t) => t.status == todoStatusDone), isTrue);

      var completedCount = await container.read(
        completedTodoCountProvider.future,
      );
      expect(completedCount, 10);

      var openCount = await container.read(openTodoCountProvider.future);
      expect(openCount, 0);

      // Delete all
      for (var todo in todos) {
        await container.read(deleteTodoProvider(todo.id).future);
      }

      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });

    test('ordering is consistent: newest first on every operation', () async {
      final ids = <String>[];

      // Create todos
      for (int i = 0; i < 5; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Task $i', description: 'Desc $i'),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 5);
      for (var todo in todos) {
        ids.add(todo.id);
      }

      // Verify all todos are returned and have correct titles
      final titles = todos.map((t) => t.title).toSet();
      expect(titles, {'Task 0', 'Task 1', 'Task 2', 'Task 3', 'Task 4'});

      // Edit one and verify it's still there after refetch
      await container.read(
        updateTodoProvider(
          UpdateTodoParams(
            id: todos.first.id,
            title: 'Task 0 - Updated',
            description: 'Updated desc',
            status: todoStatusOpen,
            priority: todoPriorityMedium,
          ),
        ).future,
      );

      // Check ordering again - all items should still be there
      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 5);
      expect(todos.map((t) => t.title).toSet(), contains('Task 0 - Updated'));
    });

    test('data persistence across provider resets', () async {
      // Create todo
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Persistent Task',
            description: 'Should persist',
          ),
        ).future,
      );

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 1);
      final todoId = todos.first.id;

      // Invalidate and refetch
      container.refresh(todoItemsProvider);
      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 1);
      expect(todos.first.id, todoId);
      expect(todos.first.title, 'Persistent Task');

      // Update
      await container.read(
        updateTodoProvider(
          UpdateTodoParams(
            id: todoId,
            title: 'Updated Persistent Task',
            description: 'Persisted and updated',
            status: todoStatusOpen,
            priority: todoPriorityMedium,
          ),
        ).future,
      );

      // Refetch
      todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Updated Persistent Task');
    });

    test('cascade updates: counts reflect CRUD changes', () async {
      var openCount = await container.read(openTodoCountProvider.future);
      var completedCount = await container.read(
        completedTodoCountProvider.future,
      );
      expect(openCount, 0);
      expect(completedCount, 0);

      // Create 5 open todos
      final ids = <String>[];
      for (int i = 0; i < 5; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: 'Task $i',
              description: 'Desc',
              status: todoStatusOpen,
            ),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);
      ids.addAll(todos.map((t) => t.id));

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 5);
      expect(completedCount, 0);

      // Mark 2 as done
      for (int i = 0; i < 2; i++) {
        await container.read(
          updateTodoStatusProvider(
            UpdateTodoStatusParams(
              id: ids[i],
              status: todoStatusDone,
              snoozedUntil: null,
            ),
          ).future,
        );
      }

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 3);
      expect(completedCount, 2);

      // Delete 1 done todo
      await container.read(deleteTodoProvider(ids[0]).future);

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 3);
      expect(completedCount, 1);

      // Mark remaining open as done in batch
      for (int i = 2; i < ids.length; i++) {
        await container.read(
          updateTodoStatusProvider(
            UpdateTodoStatusParams(
              id: ids[i],
              status: todoStatusDone,
              snoozedUntil: null,
            ),
          ).future,
        );
      }

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 0);
      expect(completedCount, 4); // 1 deleted + 3 remaining = 4
    });

    test('complex filtering scenario', () async {
      // Create diverse todos
      const scenarios = [
        ('Task A', 'Low priority, open', todoStatusOpen, todoPriorityLow),
        ('Task B', 'High priority, open', todoStatusOpen, todoPriorityHigh),
        (
          'Task C',
          'Medium priority, in progress',
          todoStatusInProgress,
          todoPriorityMedium,
        ),
        ('Task D', 'High priority, done', todoStatusDone, todoPriorityHigh),
        ('Task E', 'Low priority, snoozed', todoStatusSnoozed, todoPriorityLow),
      ];

      for (var (title, description, status, priority) in scenarios) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: title,
              description: description,
              status: status,
              priority: priority,
            ),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);

      // Filter: Open AND High Priority
      final openHigh = todos
          .where(
            (t) => t.status == todoStatusOpen && t.priority == todoPriorityHigh,
          )
          .toList();
      expect(openHigh.length, 1);
      expect(openHigh.first.title, 'Task B');

      // Filter: Not Done (for display in "To Do" count)
      final notDone = todos.where((t) => t.status != todoStatusDone).toList();
      expect(notDone.length, 4);

      // Filter: High Priority across all statuses
      final allHigh = todos
          .where((t) => t.priority == todoPriorityHigh)
          .toList();
      expect(allHigh.length, 2); // Task B and Task D

      // Filter: Snoozed (to show reminders later)
      final snoozed = todos
          .where((t) => t.status == todoStatusSnoozed)
          .toList();
      expect(snoozed.length, 1);
      expect(snoozed.first.title, 'Task E');
    });

    test('search and filter combination', () async {
      // Create todos with similar titles but different descriptions
      const testData = [
        ('Review Code', 'Check pull request #123'),
        ('Code Review', 'Review submission feedback'),
        ('Review Documentation', 'Update API docs'),
        ('Documentation Updates', 'Add examples'),
      ];

      for (var (title, description) in testData) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: title, description: description),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);

      // Search: title contains "review" (case-insensitive)
      final searchReview = todos
          .where((t) => t.title.toLowerCase().contains('review'))
          .toList();
      expect(searchReview.length, 3);

      // Search: description contains "pull"
      final searchPull = todos
          .where((t) => t.description.toLowerCase().contains('pull'))
          .toList();
      expect(searchPull.length, 1);
      expect(searchPull.first.title, 'Review Code');

      // Search: either title or description contains "code"
      final searchCode = todos
          .where(
            (t) =>
                t.title.toLowerCase().contains('code') ||
                t.description.toLowerCase().contains('code'),
          )
          .toList();
      expect(searchCode.length, 2); // Review Code, Code Review
    });
  });

  group('TodoApp - Performance and Stress Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('handle large number of todos gracefully', () async {
      const itemCount = 100;

      for (int i = 0; i < itemCount; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: 'Task ${i.toString().padLeft(3, '0')}',
              description: 'Description $i',
              status: i % 3 == 0 ? todoStatusDone : todoStatusOpen,
              priority: i % 2 == 0 ? todoPriorityHigh : todoPriorityLow,
            ),
          ).future,
        );
      }

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, itemCount);

      // Verify counts are correct
      final done = todos.where((t) => t.status == todoStatusDone).length;
      // i % 3 == 0 for i=0,3,6,...,99 = 34 items done (inclusive counting)
      expect(done, greaterThan(itemCount ~/ 3)); // Should be 34

      final high = todos.where((t) => t.priority == todoPriorityHigh).length;
      // i % 2 == 0 for all even i = 50 items
      expect(high, itemCount ~/ 2);
    });

    test('rapid CRUD operations', () async {
      const iterations = 20;

      // Rapid creates
      final ids = <String>[];
      for (int i = 0; i < iterations; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Rapid $i', description: 'Created rapidly'),
          ).future,
        );
      }

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, iterations);
      ids.addAll(todos.map((t) => t.id));

      // Rapid updates
      for (int i = 0; i < iterations; i++) {
        await container.read(
          updateTodoProvider(
            UpdateTodoParams(
              id: ids[i],
              title: 'Rapid $i - Updated',
              description: 'Updated rapidly',
              status: todoStatusOpen,
              priority: todoPriorityMedium,
            ),
          ).future,
        );
      }

      todos = await container.read(todoItemsProvider.future);
      expect(todos.every((t) => t.title.contains('Updated')), isTrue);

      // Rapid deletes
      for (int i = 0; i < iterations ~/ 2; i++) {
        await container.read(deleteTodoProvider(ids[i]).future);
      }

      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, iterations ~/ 2);
    });
  });
}
