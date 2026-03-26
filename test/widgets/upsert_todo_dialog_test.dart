import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/todo_provider.dart';
import 'package:project_tracker/presentation/widgets/dialogs/upsert_todo_dialog.dart';

void main() {
  group('UpsertTodoDialog - Create Mode', () {
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

    Future<void> renderCreateDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: Scaffold(
              body: UpsertTodoDialog(
                onCreate: (params) =>
                    container.read(createTodoProvider(params).future),
                onUpdate: (params) =>
                    container.read(updateTodoProvider(params).future),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays all form fields', (tester) async {
      await renderCreateDialog(tester);

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Title'), findsWidgets);
      expect(find.text('Description'), findsWidgets);
      expect(find.text('Reference URL'), findsWidgets);
      expect(find.text('Priority'), findsWidgets);
      expect(find.text('Status'), findsWidgets);
    });

    testWidgets('create todo with valid input', (tester) async {
      await renderCreateDialog(tester);

      // Fill title
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'New Task');

      // Fill description
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Task description',
      );

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify todo was created
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 1);
      expect(todos.first.title, 'New Task');
      expect(todos.first.description, 'Task description');
    });

    testWidgets('validate title is required', (tester) async {
      await renderCreateDialog(tester);

      // Try to save without title
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Title is required'), findsOneWidget);

      // Todos should not be created
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });

    testWidgets('validate title minimum length', (tester) async {
      await renderCreateDialog(tester);

      // Enter single character (too short)
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'A');

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Title must be at least 2 characters'), findsOneWidget);

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });

    testWidgets('set priority in dialog', (tester) async {
      await renderCreateDialog(tester);

      // Fill title
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'Task');

      // Click priority dropdown
      if (find.byType(DropdownButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(DropdownButton).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('High').last);
        await tester.pumpAndSettle();
      }

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.priority, 'high');
    });

    testWidgets('set status in dialog', (tester) async {
      await renderCreateDialog(tester);

      // Fill title
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'Task');

      // Click status dropdown and select "in_progress"
      final statusDropdown = find.byType(DropdownButtonFormField).last;
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, 'in_progress');
    });

    testWidgets('set due date in dialog', (tester) async {
      await renderCreateDialog(tester);

      // Fill title
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'Task');

      // Tap due date field
      await tester.tap(find.text('Due Date'));
      await tester.pumpAndSettle();

      // Select a date in date picker (tap first available day)
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.dueDate, isNotNull);
    });

    testWidgets('clear title shows error on save', (tester) async {
      await renderCreateDialog(tester);

      // Enter title
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'Task');

      // Clear it
      await tester.enterText(find.byType(TextFormField).at(0), '');

      // Try save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('trim whitespace from input', (tester) async {
      await renderCreateDialog(tester);

      // Enter title with whitespace
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '  Trimmed Task  ',
      );

      // Enter description with whitespace
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '  Trimmed desc  ',
      );

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Trimmed Task');
      expect(todos.first.description, 'Trimmed desc');
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await renderCreateDialog(tester);

      // Enter data
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), 'Task');

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed/disposed but todo not created
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.length, 0);
    });
  });

  group('UpsertTodoDialog - Edit Mode', () {
    late AppDatabase db;
    late ProviderContainer container;
    late TodoItemData existingTodo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      // Create a todo to edit
      await container.read(
        createTodoProvider(
          CreateTodoParams(
            title: 'Original Title',
            description: 'Original Description',
            status: todoStatusOpen,
            priority: todoPriorityMedium,
          ),
        ).future,
      );

      final todos = await container.read(todoItemsProvider.future);
      existingTodo = todos.first;
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> renderEditDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: Scaffold(
              body: UpsertTodoDialog(
                existingTodo: existingTodo,
                onCreate: (params) =>
                    container.read(createTodoProvider(params).future),
                onUpdate: (params) =>
                    container.read(updateTodoProvider(params).future),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('pre-fills form with existing todo data', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Verify fields are pre-filled
      expect(
        find.byWidgetPredicate((w) {
          if (w is TextFormField) {
            final controller = w.controller;
            if (controller != null) {
              return controller.text.contains('Original Title') ||
                  controller.text.contains('Original Description');
            }
          }
          return false;
        }),
        findsWidgets,
      );
    });

    testWidgets('update todo successfully', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Clear and update title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Updated Title');

      // Clear and update description
      final descField = find.byType(TextFormField).at(1);
      await tester.enterText(descField, 'Updated Description');

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify update
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Updated Title');
      expect(todos.first.description, 'Updated Description');
      expect(todos.first.id, existingTodo.id); // Same ID
    });

    testWidgets('change status on existing todo', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Change status to done
      final statusDropdown = find.byType(DropdownButtonFormField).last;
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify status changed
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, 'done');
    });

    testWidgets('change priority on existing todo', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Find and click priority dropdown
      final dropdowns = find.byType(DropdownButtonFormField);
      // Priority is usually the first dropdown
      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.priority, 'high');
    });

    testWidgets('edit title validation still applies', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Clear title to empty
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, '');

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Title is required'), findsOneWidget);

      // Original should be unchanged
      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, 'Original Title');
    });

    testWidgets('mark todo as snoozed when editing', (tester) async {
      await renderEditDialog(tester);
      await tester.pumpAndSettle();

      // Change status to snoozed
      final statusDropdown = find.byType(DropdownButtonFormField).last;
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Snoozed').last);
      await tester.pumpAndSettle();

      // Set snoozed until date
      await tester.tap(find.text('Snoozed Until'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.status, 'snoozed');
      expect(todos.first.snoozedUntil, isNotNull);
    });
  });

  group('UpsertTodoDialog - Edge Cases', () {
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

    testWidgets('handle very long input gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: Scaffold(
              body: UpsertTodoDialog(
                onCreate: (params) =>
                    container.read(createTodoProvider(params).future),
                onUpdate: (params) =>
                    container.read(updateTodoProvider(params).future),
              ),
            ),
          ),
        ),
      );

      const longText =
          'This is a very long text that might cause layout '
          'issues if not handled properly in the form fields';

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), longText);

      await tester.pumpAndSettle();

      // Should render without layout errors
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('handle special characters in input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: Scaffold(
              body: UpsertTodoDialog(
                onCreate: (params) =>
                    container.read(createTodoProvider(params).future),
                onUpdate: (params) =>
                    container.read(updateTodoProvider(params).future),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Task with @mention, #tags, & special chars!',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoItemsProvider.future);
      expect(todos.first.title, contains('@mention'));
      expect(todos.first.title, contains('#tags'));
    });

    testWidgets('prevent saving with whitespace-only title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: UncontrolledProviderScope(
            container: container,
            child: Scaffold(
              body: UpsertTodoDialog(
                onCreate: (params) =>
                    container.read(createTodoProvider(params).future),
                onUpdate: (params) =>
                    container.read(updateTodoProvider(params).future),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), '    ');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });
  });
}
