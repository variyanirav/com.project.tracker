import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/data/repositories/project_repository_impl.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/project_detail_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

void main() {
  testWidgets(
    'project detail category dropdown includes user-created categories',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => db.close());

      final projectRepo = ProjectRepositoryImpl(db);
      final project = await projectRepo.createProject(
        name: 'Category Project',
        description: 'Category test project',
        color: 'C',
      );

      final now = DateTime.now().toUtc();
      await db.categoriesDao.createCategory(
        CategoryData(
          id: 'cat_user_added',
          name: 'User Added Category',
          colorHex: '#00AAFF',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final idle = TimerState.idle();

      await tester.binding.setSurfaceSize(const Size(1700, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedProjectIdProvider.overrideWith((ref) => project.id),
            timerProvider.overrideWith((ref) => _FakeTimerNotifier(ref, idle)),
            timerTickProvider.overrideWith((ref) => Stream.value(idle)),
          ],
          child: const MaterialApp(home: ProjectDetailScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final categoryDropdown = find
          .byType(DropdownButtonFormField<String>)
          .first;
      expect(categoryDropdown, findsOneWidget);

      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      expect(find.text('User Added Category'), findsAtLeastNWidgets(1));
    },
  );
}
