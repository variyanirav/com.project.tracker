import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/reports_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/providers/todo_provider.dart';
import 'package:project_tracker/presentation/screens/project_list_screen.dart';
import 'package:project_tracker/presentation/screens/reports_screen.dart';
import 'package:project_tracker/presentation/screens/todo_list_screen.dart';

void main() {
  Future<void> _pumpProjectList(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.0),
        ],
        child: const MaterialApp(home: ProjectListScreen()),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> _pumpTodoList(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          todoItemsProvider.overrideWith((ref) async => []),
          openTodoCountProvider.overrideWith((ref) async => 0),
          completedTodoCountProvider.overrideWith((ref) async => 0),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.0),
        ],
        child: const MaterialApp(home: TodoListScreen()),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> _pumpReports(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          weekProjectSummaryProvider.overrideWith((ref) async => []),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          dailyProgressProvider.overrideWith((ref) async => 0.0),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('project list settings opens daily goal dialog', (tester) async {
    await _pumpProjectList(tester);

    await tester.ensureVisible(find.byTooltip('Daily Goal Settings'));
    await tester.tap(find.byTooltip('Daily Goal Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Goal Settings'), findsOneWidget);
  });

  testWidgets(
    'todo list settings and theme buttons are visible and clickable',
    (tester) async {
      await _pumpTodoList(tester);

      await tester.ensureVisible(find.byTooltip('Daily Goal Settings'));
      await tester.tap(find.byTooltip('Daily Goal Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Goal Settings'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('Light Mode'));
      await tester.tap(find.byTooltip('Light Mode'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dark Mode'), findsOneWidget);
    },
  );

  testWidgets('reports settings and theme buttons are visible and clickable', (
    tester,
  ) async {
    await _pumpReports(tester);

    await tester.ensureVisible(find.byTooltip('Daily Goal Settings'));
    await tester.tap(find.byTooltip('Daily Goal Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Goal Settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Light Mode'));
    await tester.tap(find.byTooltip('Light Mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dark Mode'), findsOneWidget);
  });
}
