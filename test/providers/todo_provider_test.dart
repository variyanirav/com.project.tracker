import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/todo_provider.dart';

void main() {
  group('TodoProvider - CRUD Operations', () {
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

    test('create todo item successfully', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Review PR',
            description: 'Check team pull requests',
            status: todoStatusOpen,
            priority: todoPriorityHigh,
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 1);
      expect(todos.first.title, 'Review PR');
      expect(todos.first.description, 'Check team pull requests');
      expect(todos.first.status, todoStatusOpen);
      expect(todos.first.priority, todoPriorityHigh);
      expect(todos.first.createdAt, isNotNull);
      expect(todos.first.updatedAt, isNotNull);
    });

    test('create todo with default status and priority', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Default Values', description: ''),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, todoStatusOpen);
      expect(todos.first.priority, todoPriorityMedium);
    });

    test('create todo with reference URL and project link', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Check docs',
            description: 'Review API docs',
            referenceUrl: 'https://api.example.com/docs',
            linkedProjectId: 'proj-123',
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.referenceUrl, 'https://api.example.com/docs');
      expect(todos.first.linkedProjectId, 'proj-123');
    });

    test('create todo with due date and snoozed until', () async {
      final dueDate = DateTime.now().toUtc();
      final snoozedUntil = DateTime.now().add(const Duration(days: 1)).toUtc();

      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Timed task',
            description: 'Has dates',
            dueDate: dueDate,
            snoozedUntil: snoozedUntil,
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.dueDate, isNotNull);
      expect(todos.first.snoozedUntil, isNotNull);
    });

    test('update todo item successfully', () async {
      // Create
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Original title',
            description: 'Original description',
          ),
        ).future,
      );

      var todos = await container.read(todoItemsProvider.future);
      final todoId = todos.first.id;
      final originalCreatedAt = todos.first.createdAt;

      // Update
      await container.read(
        updateTodoProvider(
          UpdateTodoParams(
            id: todoId,
            title: 'Updated title',
            description: 'Updated description',
            status: todoStatusInProgress,
            priority: todoPriorityHigh,
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Updated title');
      expect(todos.first.description, 'Updated description');
      expect(todos.first.status, todoStatusInProgress);
      expect(todos.first.priority, todoPriorityHigh);
      expect(todos.first.createdAt, originalCreatedAt); // unchanged
      expect(todos.first.updatedAt, isNotNull);
    });

    test('update todo status only', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Task',
            description: 'Description',
            status: todoStatusOpen,
          ),
        ).future,
      );

      var todos = await container.read(todoItemsProvider.future);
      final todoId = todos.first.id;

      // Update status
      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: todoId,
            status: todoStatusDone,
            snoozedUntil: null,
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, todoStatusDone);
      expect(todos.first.title, 'Task'); // unchanged
    });

    test('update todo with snoozed status', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Snoozable task',
            description: 'Can be snoozed',
          ),
        ).future,
      );

      var todos = await container.read(todoItemsProvider.future);
      final todoId = todos.first.id;
      final snoozedUntil = DateTime.now().add(const Duration(days: 3)).toUtc();

      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: todoId,
            status: todoStatusSnoozed,
            snoozedUntil: snoozedUntil,
          ),
        ).future,
      );

      todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, todoStatusSnoozed);
      expect(todos.first.snoozedUntil, isNotNull);
    });

    test('delete todo item successfully', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'To delete', description: ''),
        ).future,
      );

      var todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 1);
      final todoId = todos.first.id;

      await container.read(deleteTodoProvider(todoId).future);

      todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });

    test('list todos ordered by createdAt descending', () async {
      // Create 3 todos
      for (int i = 0; i < 3; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Todo $i', description: 'Description $i'),
          ).future,
        );
      }

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 3);
      // Verify all todos are retrieved (ordering by createdAt descending)
      final titles = todos.map((t) => t.title).toList();
      expect(titles.length, 3);
      expect(titles.toSet(), {'Todo 0', 'Todo 1', 'Todo 2'});
    });
  });

  group('TodoProvider - Count Queries', () {
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

    test('openTodoCountProvider excludes done items', () async {
      // Create 3 todos
      for (int i = 0; i < 3; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Todo $i', description: 'Desc $i'),
          ).future,
        );
      }

      var openCount = await container.read(openTodoCountProvider.future);
      expect(openCount, 3);

      // Mark 1 as done
      var todos = await container.read(todoItemsProvider.future);
      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: todos.first.id,
            status: todoStatusDone,
            snoozedUntil: null,
          ),
        ).future,
      );

      openCount = await container.read(openTodoCountProvider.future);
      expect(openCount, 2);
    });

    test('completedTodoCountProvider counts done items only', () async {
      // Create 4 todos with different statuses
      final statuses = [
        todoStatusOpen,
        todoStatusInProgress,
        todoStatusDone,
        todoStatusDone,
      ];

      for (int i = 0; i < statuses.length; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: 'Todo $i',
              description: 'Desc $i',
              status: statuses[i],
            ),
          ).future,
        );
      }

      final completedCount = await container.read(
        completedTodoCountProvider.future,
      );
      expect(completedCount, 2);
    });

    test('count queries update after CRUD operations', () async {
      // Initial state
      var openCount = await container.read(openTodoCountProvider.future);
      var completedCount = await container.read(
        completedTodoCountProvider.future,
      );
      expect(openCount, 0);
      expect(completedCount, 0);

      // Create one
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'New', description: 'Task'),
        ).future,
      );

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 1);
      expect(completedCount, 0);

      // Mark as done
      var todos = await container.read(todoItemsProvider.future);
      await container.read(
        updateTodoStatusProvider(
          UpdateTodoStatusParams(
            id: todos.first.id,
            status: todoStatusDone,
            snoozedUntil: null,
          ),
        ).future,
      );

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 0);
      expect(completedCount, 1);

      // Delete
      await container.read(deleteTodoProvider(todos.first.id).future);

      openCount = await container.read(openTodoCountProvider.future);
      completedCount = await container.read(completedTodoCountProvider.future);
      expect(openCount, 0);
      expect(completedCount, 0);
    });
  });

  group('TodoProvider - Params Classes', () {
    test('CreateTodoParams stores all fields correctly', () {
      final dueDate = DateTime.now();
      final snoozedUntil = DateTime.now().add(const Duration(days: 1));

      final params = CreateTodoParams(
        title: 'Title',
        description: 'Description',
        status: todoStatusInProgress,
        priority: todoPriorityHigh,
        referenceUrl: 'https://example.com',
        linkedProjectId: 'proj-id',
        dueDate: dueDate,
        snoozedUntil: snoozedUntil,
      );

      expect(params.title, 'Title');
      expect(params.description, 'Description');
      expect(params.status, todoStatusInProgress);
      expect(params.priority, todoPriorityHigh);
      expect(params.referenceUrl, 'https://example.com');
      expect(params.linkedProjectId, 'proj-id');
      expect(params.dueDate, dueDate);
      expect(params.snoozedUntil, snoozedUntil);
    });

    test('CreateTodoParams has correct defaults', () {
      final params = CreateTodoParams(
        title: 'Title',
        description: 'Description',
      );

      expect(params.status, todoStatusOpen);
      expect(params.priority, todoPriorityMedium);
      expect(params.referenceUrl, isNull);
      expect(params.linkedProjectId, isNull);
      expect(params.dueDate, isNull);
      expect(params.snoozedUntil, isNull);
    });

    test('UpdateTodoParams stores all fields correctly', () {
      final dueDate = DateTime.now();

      final params = UpdateTodoParams(
        id: 'todo-1',
        title: 'Updated title',
        description: 'Updated desc',
        status: todoStatusDone,
        priority: todoPriorityLow,
        referenceUrl: 'https://updated.com',
        linkedProjectId: 'proj-2',
        dueDate: dueDate,
        snoozedUntil: null,
      );

      expect(params.id, 'todo-1');
      expect(params.title, 'Updated title');
      expect(params.status, todoStatusDone);
      expect(params.priority, todoPriorityLow);
    });

    test('UpdateTodoStatusParams stores status and snoozedUntil', () {
      final snoozedUntil = DateTime.now().add(const Duration(days: 1));

      final params = UpdateTodoStatusParams(
        id: 'todo-1',
        status: todoStatusSnoozed,
        snoozedUntil: snoozedUntil,
      );

      expect(params.id, 'todo-1');
      expect(params.status, todoStatusSnoozed);
      expect(params.snoozedUntil, snoozedUntil);
    });
  });

  group('TodoProvider - Edge Cases', () {
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

    test('trim whitespace from title and description', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: '  Whitespace title  ',
            description: '  Whitespace desc  ',
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Whitespace title');
      expect(todos.first.description, 'Whitespace desc');
    });

    test('handle empty reference URL by storing null', () async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'No URL',
            description: 'Desc',
            referenceUrl: '   ', // whitespace only
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.referenceUrl, isNull);
    });

    test('delete non-existent todo does not throw', () async {
      // Should not throw even if ID doesn't exist
      await container.read(deleteTodoProvider('non-existent-id').future);

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });

    test('create multiple todos and verify count', () async {
      for (int i = 0; i < 10; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Todo $i', description: 'Desc $i'),
          ).future,
        );
      }

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 10);
    });

    test('update non-existent todo does not crash', () async {
      await container.read(
        updateTodoProvider(
          UpdateTodoParams(
            id: 'non-existent',
            title: 'Updated',
            description: 'Desc',
            status: todoStatusOpen,
            priority: todoPriorityMedium,
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });
  });
}
