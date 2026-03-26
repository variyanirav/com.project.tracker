import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/presentation/widgets/dialogs/daily_goal_settings_dialog.dart';

void main() {
  Future<void> _openDialog(
    WidgetTester tester, {
    required int currentGoalHours,
    required ValueChanged<int> onSavePressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => DailyGoalSettingsDialog(
                    currentGoalHours: currentGoalHours,
                    onSavePressed: onSavePressed,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('dialog initializes selected hours from currentGoalHours', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openDialog(tester, currentGoalHours: 10, onSavePressed: (_) {});

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 10.0);
    expect(find.text('10 hours'), findsWidgets);
  });

  testWidgets('dialog quick select + save returns selected hours', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? savedHours;

    await _openDialog(
      tester,
      currentGoalHours: 8,
      onSavePressed: (hours) {
        savedHours = hours;
      },
    );

    await tester.tap(find.text('12 hours').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Goal'));
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();

    expect(savedHours, 12);
    expect(find.text('Daily Goal Settings'), findsNothing);
  });
}
