import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/todo_provider.dart';
import 'package:project_tracker/presentation/screens/todo_list_screen.dart';

void main() {
  group('TodoListScreen - Widget Tests', () {
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

    Future<void> renderTodoListScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: const Scaffold(body: TodoListScreen()),
          ),
        ),
      );
    }

    testWidgets('displays empty state when no todos', (tester) async {
      await renderTodoListScreen(tester);

      expect(find.text('To-Do List'), findsOneWidget);
      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Create your first to-do item'), findsWidgets);
    });

    testWidgets('displays todo item in list', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Test Todo', description: 'Test description'),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('displays stat cards with correct counts', (tester) async {
      // Create 3 todos: 2 open, 1 done
      for (int i = 0; i < 2; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Open Todo $i', description: 'Open'),
          ).future,
        );
      }

      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Done Todo',
            description: 'Done',
            status: todoStatusDone,
          ),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 open todos
      expect(find.text('1'), findsOneWidget); // 1 completed
    });

    testWidgets('filter todos by status', (tester) async {
      // Create todos with different statuses
      final statuses = [
        (todoStatusOpen, 'Open Task'),
        (todoStatusInProgress, 'In Progress Task'),
        (todoStatusDone, 'Done Task'),
      ];

      for (var (status, title) in statuses) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: title, description: 'Desc', status: status),
          ).future,
        );
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Verify all are shown initially
      expect(find.text('Open Task'), findsOneWidget);
      expect(find.text('In Progress Task'), findsOneWidget);
      expect(find.text('Done Task'), findsOneWidget);

      // Click on "Open" filter chip
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify only open todos are shown
      expect(find.text('Open Task'), findsOneWidget);
      expect(find.text('In Progress Task'), findsNothing);
      expect(find.text('Done Task'), findsNothing);
    });

    testWidgets('filter todos by priority', (tester) async {
      // Create todos with different priorities
      const priorities = [
        (todoPriorityHigh, 'High Priority'),
        (todoPriorityMedium, 'Medium Priority'),
        (todoPriorityLow, 'Low Priority'),
      ];

      for (var (priority, title) in priorities) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: title,
              description: 'Desc',
              priority: priority,
            ),
          ).future,
        );
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Click on priority dropdown
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpAndSettle();

      // Click on "High"
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      // Verify only high priority shown
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Medium Priority'), findsNothing);
      expect(find.text('Low Priority'), findsNothing);
    });

    testWidgets('search todos by title', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Review code', description: 'Check PRs'),
        ).future,
      );

      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Buy groceries',
            description: 'Milk, eggs, bread',
          ),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Verify both are shown
      expect(find.text('Review code'), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);

      // Search for "review"
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'review');
      await tester.pumpAndSettle();

      // Verify only matching todo is shown
      expect(find.text('Review code'), findsOneWidget);
      expect(find.text('Buy groceries'), findsNothing);
    });

    testWidgets('search todos by description', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Task 1',
            description: 'Important meeting tomorrow',
          ),
        ).future,
      );

      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Task 2', description: 'Regular work'),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Search for "meeting"
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'meeting');
      await tester.pumpAndSettle();

      // Verify filtered by description
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);
    });

    testWidgets('clear search resets pagination', (tester) async {
      for (int i = 0; i < 15; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Todo $i', description: 'Desc'),
          ).future,
        );
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Search to filter
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'Todo 1');
      await tester.pumpAndSettle();

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Verify all todos are shown again
      expect(find.text('Todo 0'), findsOneWidget);
    });

    testWidgets('pagination loads more items', (tester) async {
      // Create 15 todos
      for (int i = 0; i < 15; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: 'Todo ${i.toString().padLeft(2, '0')}',
              description: 'Desc',
            ),
          ).future,
        );
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Initially should show 10 items
      expect(find.text('Load More'), findsOneWidget);
      expect(find.text('Todo 09'), findsOneWidget); // First item (newest first)
      expect(find.text('Todo 00'), findsNothing); // Should be off-screen

      // Tap Load More
      await tester.tap(find.text('Load More'));
      await tester.pumpAndSettle();

      // Now should show 15 items total
      expect(find.text('Todo 00'), findsOneWidget);
      expect(find.text('Load More'), findsNothing); // No more items to load
    });

    testWidgets('toggle todo completion with checkbox', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Complete me', description: 'Mark as done'),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Find and tap checkbox
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify todo is in done state
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, todoStatusDone);
    });

    testWidgets('list is ordered newest first', (tester) async {
      for (int i = 0; i < 3; i++) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(title: 'Todo $i', description: 'Desc'),
          ).future,
        );
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Newest first means Todo 2 should appear above Todo 0 in the list.
      final todo2Y = tester.getTopLeft(find.text('Todo 2')).dy;
      final todo0Y = tester.getTopLeft(find.text('Todo 0')).dy;
      expect(todo2Y < todo0Y, isTrue);
    });

    testWidgets('display todo with linked project', (tester) async {
      // Create a project first
      await container.read(
        createProjectProvider(
          CreateProjectParams(
            name: 'My Project',
            description: 'Test',
            color: 'blue',
          ),
        ).future,
      );

      final projects = await container.read(projectsProvider.future);
      final projectId = projects.first.id;

      // Create todo with linked project
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Linked Task',
            description: 'Connected to project',
            linkedProjectId: projectId,
          ),
        ).future,
      );

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Linked Task'), findsOneWidget);
      expect(find.text('My Project'), findsOneWidget); // Project name displayed
    });

    testWidgets('combine status and priority filters', (tester) async {
      // Create todos with different combinations
      const testCases = [
        (todoStatusOpen, todoPriorityHigh, 'High Open'),
        (todoStatusOpen, todoPriorityLow, 'Low Open'),
        (todoStatusDone, todoPriorityHigh, 'High Done'),
      ];

      for (var (status, priority, title) in testCases) {
        await container.read(
          createTodoProvider(
            CreateTodoParams(
              title: title,
              description: 'Desc',
              status: status,
              priority: priority,
            ),
          ).future,
        );
      }

      await renderTodoListScreen(tester);
      await tester.pumpAndSettle();

      // Filter by Open status
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Then filter by High priority
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      // Should only show High Open
      expect(find.text('High Open'), findsOneWidget);
      expect(find.text('Low Open'), findsNothing);
      expect(find.text('High Done'), findsNothing);
    });
  });

  group('TodoListScreen - Edge Cases', () {
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

    testWidgets('handle very long title gracefully', (tester) async {
      const longTitle =
          'This is a very long todo item title that should wrap '
          'to multiple lines without breaking the layout';

      await container.read(
        createTodoProvider(
          CreateTodoParams(title: longTitle, description: 'Short'),
        ).future,
      );

      final MaterialApp app = MaterialApp(
        theme: ThemeData.dark(),
        home: UncontrolledProviderScope(
          container: container,
          child: const Scaffold(body: TodoListScreen()),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Should render without layout errors
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('work with special characters in title', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'TODO: @mention, #hashtag, 50% complete!',
            description: 'Special chars',
          ),
        ).future,
      );

      final MaterialApp app = MaterialApp(
        theme: ThemeData.dark(),
        home: UncontrolledProviderScope(
          container: container,
          child: const Scaffold(body: TodoListScreen()),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(
        find.text('TODO: @mention, #hashtag, 50% complete!'),
        findsOneWidget,
      );
    });

    testWidgets('case-insensitive search', (tester) async {
      await container.read(
        createTodoProvider(
          CreateTodoParams(title: 'Review CODE', description: 'Desc'),
        ).future,
      );

      final MaterialApp app = MaterialApp(
        theme: ThemeData.dark(),
        home: UncontrolledProviderScope(
          container: container,
          child: const Scaffold(body: TodoListScreen()),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Search with lowercase
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'review code');
      await tester.pumpAndSettle();

      expect(find.text('Review CODE'), findsOneWidget);
    });
  });
}
