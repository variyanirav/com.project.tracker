import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/database_provider.dart';
import 'package:project_tracker/presentation/screens/focus_timer_screen.dart';
import 'package:project_tracker/domain/entities/focus_run_state_entity.dart';
import 'package:project_tracker/services/focus_notification_service.dart';

class _FakeFocusNotificationService extends FocusNotificationService {
  @override
  Future<bool> notifyPhaseChange(FocusRunPhase phase) async {
    return true;
  }
}

void main() {
  group('FocusTimerScreen', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('shows controls and supports start/pause/resume/stop flow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            focusNotificationServiceProvider.overrideWithValue(
              _FakeFocusNotificationService(),
            ),
          ],
          child: const MaterialApp(home: FocusTimerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus Timer'), findsOneWidget);
      expect(find.textContaining('Current Phase: Idle'), findsOneWidget);

      await tester.tap(find.byKey(const Key('focus_start_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current Phase: Focus'), findsOneWidget);

      await tester.tap(find.byKey(const Key('focus_pause_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current Phase: Paused'), findsOneWidget);

      await tester.tap(find.byKey(const Key('focus_resume_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current Phase: Focus'), findsOneWidget);

      await tester.tap(find.byKey(const Key('focus_stop_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current Phase: Idle'), findsOneWidget);
    });
  });
}
