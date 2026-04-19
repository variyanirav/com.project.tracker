import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/core/constants/colors.dart';
import 'package:project_tracker/core/widgets/custom_scaffold.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/routes/app_router.dart';
import 'package:project_tracker/presentation/screens/focus_timer_screen.dart';
import 'package:project_tracker/services/focus_notification_service.dart';

class _FakeFocusNotificationService extends FocusNotificationService {
  @override
  Future<bool> notifyPhaseChange(FocusRunPhase phase) async {
    return true;
  }
}

void main() {
  group('Focus timer side-menu navigation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('tapping Dashboard in side menu updates current route', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          focusNotificationServiceProvider.overrideWithValue(
            _FakeFocusNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FocusTimerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      container.read(currentScreenProvider.notifier).state =
          AppRouter.focusTimer;
      expect(container.read(currentScreenProvider), AppRouter.focusTimer);

      await tester.tap(find.byTooltip('Dashboard'));
      await tester.pumpAndSettle();

      expect(container.read(currentScreenProvider), AppRouter.dashboard);
    });

    testWidgets('selected nav icon uses brand color for active route', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomScaffold(
              activeRoute: AppRouter.focusTimer,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tooltip = find.byTooltip('Focus Timer');
      expect(tooltip, findsOneWidget);

      final icon = tester.widget<Icon>(
        find.descendant(of: tooltip, matching: find.byType(Icon)).first,
      );

      expect(icon.color, AppColors.brandPrimary);
    });
  });
}
