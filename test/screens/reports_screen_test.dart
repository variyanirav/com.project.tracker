import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/domain/entities/category_entity.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/presentation/providers/category_provider.dart';
import 'package:project_tracker/presentation/providers/project_provider.dart';
import 'package:project_tracker/presentation/providers/reports_provider.dart';
import 'package:project_tracker/presentation/providers/timer_provider.dart';
import 'package:project_tracker/presentation/screens/reports_screen.dart';

void main() {
  testWidgets('Open Export Folder is enabled only after CSV download', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) async => []),
          projectSummaryProvider.overrideWith((ref, params) async => []),
          dailyGoalProvider.overrideWith((ref) async => 8.0),
          categoriesProvider.overrideWith(
            (ref) async => [
              CategoryEntity(
                id: AppDatabase.learningCategoryId,
                name: 'Learning',
                colorHex: '#3B82F6',
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              ),
            ],
          ),
          csvExportFileProvider.overrideWith(
            (ref, params) async => '/tmp/test_export.csv',
          ),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final openButtonFinder = find.widgetWithText(
      OutlinedButton,
      'Open Export Folder',
    );
    OutlinedButton openButton = tester.widget<OutlinedButton>(openButtonFinder);
    expect(openButton.onPressed, isNull);
    expect(find.text('Last export location: Not exported yet'), findsOneWidget);
    expect(find.text('Category Filter'), findsOneWidget);
    expect(
      find.text('CSV uses the same report filters above.'),
      findsOneWidget,
    );

    expect(find.text('Download Summary CSV'), findsOneWidget);
    expect(find.text('Download Session Detail CSV'), findsOneWidget);

    final downloadButtonFinder = find.text('Download Summary CSV');
    await tester.ensureVisible(downloadButtonFinder);
    await tester.tap(downloadButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    openButton = tester.widget<OutlinedButton>(openButtonFinder);
    expect(openButton.onPressed, isNotNull);
    expect(
      find.text('Last export location: /tmp/test_export.csv'),
      findsOneWidget,
    );
  });
}
