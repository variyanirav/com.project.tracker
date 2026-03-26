import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/core/widgets/custom_scaffold.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/categories_screen.dart';

void main() {
  group('CategoriesScreen', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('supports add, edit, and delete category flows', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            dailyGoalProvider.overrideWith((ref) async => 8.0),
            dailyProgressProvider.overrideWith((ref) async => 0.0),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Add
      await tester.enterText(find.byType(TextField).first, 'Focus');
      await tester.tap(find.text('Add'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Focus'), findsOneWidget);

      // Edit
      final focusTile = find.ancestor(
        of: find.text('Focus'),
        matching: find.byType(ListTile),
      );
      expect(focusTile, findsOneWidget);

      await tester.tap(
        find.descendant(of: focusTile, matching: find.byTooltip('Edit')),
      );
      await tester.pumpAndSettle();

      final editDialog = find.byType(AlertDialog);
      await tester.enterText(
        find.descendant(of: editDialog, matching: find.byType(TextField)),
        'Deep Work',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('Focus'), findsNothing);

      // Delete with fallback reassignment
      final deepWorkTile = find.ancestor(
        of: find.text('Deep Work'),
        matching: find.byType(ListTile),
      );
      expect(deepWorkTile, findsOneWidget);

      await tester.tap(
        find.descendant(of: deepWorkTile, matching: find.byTooltip('Delete')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Category'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deep Work'), findsNothing);
    });

    testWidgets('sidebar category navigation updates current route', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CustomScaffold(
              activeRoute: AppRouter.dashboard,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Categories'));
      await tester.pumpAndSettle();

      expect(container.read(currentScreenProvider), AppRouter.categories);
    });
  });
}
