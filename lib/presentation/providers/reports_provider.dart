import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'timer_provider.dart';
import 'project_provider.dart';
import 'repository_provider.dart';

/// Provider for this week's project summary (for reports)
final weekProjectSummaryProvider = FutureProvider<List<ProjectReportData>>((
  ref,
) async {
  final projects = await ref.watch(projectsProvider.future);
  final timerRepository = ref.read(timerSessionRepositoryProvider);

  final summaries = <ProjectReportData>[];

  for (final project in projects) {
    final sessions = await timerRepository.getSessionsByProject(project.id);
    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekSessions = sessions.where((s) {
      return s.startTime.isAfter(weekStart) &&
          s.startTime.isBefore(weekStart.add(const Duration(days: 7)));
    }).toList();

    // Calculate total hours from entities
    final totalSeconds = weekSessions.fold<int>(
      0,
      (sum, s) => sum + s.totalSeconds,
    );
    final totalHours = totalSeconds / 3600.0;

    summaries.add(
      ProjectReportData(
        projectId: project.id,
        projectName: project.name,
        totalHours: totalHours,
        sessionCount: weekSessions.length,
        sessions: weekSessions,
      ),
    );
  }

  return summaries;
});

/// Provider for daily project summary
final dailyProjectSummaryProvider = FutureProvider<List<ProjectReportData>>((
  ref,
) async {
  final projects = await ref.watch(projectsProvider.future);
  final timerRepository = ref.read(timerSessionRepositoryProvider);

  final summaries = <ProjectReportData>[];

  for (final project in projects) {
    final sessions = await timerRepository.getSessionsByProject(project.id);
    final today = TimezoneHelper.getTodayStartUtc();
    final todaySessions = sessions.where((s) {
      return s.startTime.isAfter(today) &&
          s.startTime.isBefore(today.add(const Duration(days: 1)));
    }).toList();

    // Calculate total hours from entities
    final totalSeconds = todaySessions.fold<int>(
      0,
      (sum, s) => sum + s.totalSeconds,
    );
    final totalHours = totalSeconds / 3600.0;

    if (totalHours > 0 || todaySessions.isNotEmpty) {
      summaries.add(
        ProjectReportData(
          projectId: project.id,
          projectName: project.name,
          totalHours: totalHours,
          sessionCount: todaySessions.length,
          sessions: todaySessions,
        ),
      );
    }
  }

  return summaries;
});

/// Provider for getting CSV export data for this week
final weekCsvExportProvider = FutureProvider<String>((ref) async {
  final projectSummary = await ref.watch(weekProjectSummaryProvider.future);

  final csvBuffer = StringBuffer();
  csvBuffer.writeln('Project,Total Hours,Session Count');

  for (final project in projectSummary) {
    csvBuffer.writeln(
      '${project.projectName},${project.totalHours.toStringAsFixed(2)},${project.sessionCount}',
    );
  }

  return csvBuffer.toString();
});

/// Provider for getting CSV export data for today
final dayCsvExportProvider = FutureProvider<String>((ref) async {
  final projectSummary = await ref.watch(dailyProjectSummaryProvider.future);

  final csvBuffer = StringBuffer();
  csvBuffer.writeln('Project,Total Hours,Session Count');

  for (final project in projectSummary) {
    csvBuffer.writeln(
      '${project.projectName},${project.totalHours.toStringAsFixed(2)},${project.sessionCount}',
    );
  }

  return csvBuffer.toString();
});

/// Provider for detailed CSV export with task breakdown
final detailedCsvExportProvider = FutureProvider<String>((ref) async {
  final projects = await ref.watch(projectsProvider.future);
  final timerRepository = ref.read(timerSessionRepositoryProvider);
  final taskRepository = ref.read(taskRepositoryProvider);

  final csvBuffer = StringBuffer();
  csvBuffer.writeln('Project,Task,Start Time,End Time,Duration (Hours),Date');

  for (final project in projects) {
    final tasks = await taskRepository.getTasksByProject(project.id);
    final sessions = await timerRepository.getSessionsByProject(project.id);

    for (final session in sessions) {
      final task = tasks.firstWhere(
        (t) => t.id == session.taskId,
        orElse: () => TaskEntity(
          id: '',
          projectId: project.id,
          taskName: 'Unknown Task',
          description: null,
          status: '',
          totalSeconds: 0,
          isRunning: false,
          lastStartedAt: null,
          lastSessionId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final endTime = session.endTime ?? DateTime.now();
      final durationHours = session.totalSeconds / 3600.0;
      final dateStr = TimezoneHelper.formatDateOnly(session.startTime);

      csvBuffer.writeln(
        '${project.name},${task.taskName},${session.startTime.toIso8601String()},${endTime.toIso8601String()},${durationHours.toStringAsFixed(2)},$dateStr',
      );
    }
  }

  return csvBuffer.toString();
});

/// Provider for total hours worked today
final totalHodayProvider = FutureProvider<double>((ref) {
  return ref.watch(todayTotalHoursProvider.future);
});

/// Provider for total hours worked this week
final totalWeekHoursProvider = FutureProvider<double>((ref) {
  return ref.watch(weekTotalHoursProvider.future);
});

/// Report data model for project summaries
class ProjectReportData {
  final String projectId;
  final String projectName;
  final double totalHours;
  final int sessionCount;
  final List<TimerSessionEntity> sessions;

  ProjectReportData({
    required this.projectId,
    required this.projectName,
    required this.totalHours,
    required this.sessionCount,
    required this.sessions,
  });
}
