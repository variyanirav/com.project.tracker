import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/presentation/widgets/project_detail/task_list_item.dart';

void main() {
  testWidgets(
    'TaskListItem shows live running duration when current elapsed is greater than stored seconds',
    (tester) async {
      final task = TaskEntity(
        id: 'task-1',
        projectId: 'project-1',
        taskName: 'Implement feature',
        description: 'desc',
        status: 'inProgress',
        totalSeconds: 0,
        isRunning: true,
        createdAt: DateTime.utc(2026, 3, 21),
        updatedAt: DateTime.utc(2026, 3, 21),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              isTimerRunning: true,
              isThisTaskRunning: true,
              currentRunningElapsedSeconds: 65,
              onViewPressed: () {},
              onStartStopPressed: () {},
              onEditPressed: () {},
              onDeletePressed: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('1m'), findsOneWidget);
      expect(find.textContaining('0m'), findsNothing);
    },
  );
}
