import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/reports_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/screens/reports_screen.dart';

class _FakeTimerNotifier extends TimerStateNotifier {
  _FakeTimerNotifier(super.ref, TimerState initial) {
    state = initial;
  }
}

void main() {
  testWidgets('Open Export Folder is enabled only after CSV download', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final idle = TimerState.idle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          weekProjectSummaryProvider.overrideWith((ref) async => []),
          todayTotalHoursProvider.overrideWith((ref) async => 0.0),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          timerProvider.overrideWith((ref) => _FakeTimerNotifier(ref, idle)),
          csvExportFileProvider.overrideWith(
            (ref, params) async => '/tmp/test_export.csv',
          ),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final openButtonFinder = find.widgetWithText(
      OutlinedButton,
      'Open Export Folder',
    );
    OutlinedButton openButton = tester.widget<OutlinedButton>(openButtonFinder);
    expect(openButton.onPressed, isNull);
    expect(find.text('Last export location: Not exported yet'), findsOneWidget);

    await tester.tap(find.text('Download CSV'));
    await tester.pumpAndSettle();

    openButton = tester.widget<OutlinedButton>(openButtonFinder);
    expect(openButton.onPressed, isNotNull);
    expect(
      find.text('Last export location: /tmp/test_export.csv'),
      findsOneWidget,
    );
  });
}
