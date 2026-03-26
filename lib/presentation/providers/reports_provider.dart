import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/core/constants/task_status.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'timer_provider.dart';
import 'project_provider.dart';
import 'repository_provider.dart';

enum ReportPeriod { thisWeek, lastWeek, thisMonth }

class CsvExportParams {
  final ReportPeriod period;
  final String? projectId;
  final String? categoryId;

  const CsvExportParams({
    required this.period,
    this.projectId,
    this.categoryId,
  });

  @override
  bool operator ==(Object other) {
    return other is CsvExportParams &&
        other.period == period &&
        other.projectId == projectId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(period, projectId, categoryId);
}

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

String _escapeCsv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

({DateTime start, DateTime end}) _periodRange(ReportPeriod period) {
  final now = DateTime.now().toUtc();

  switch (period) {
    case ReportPeriod.thisWeek:
      final start = TimezoneHelper.getWeekStartUtc(referenceDate: now);
      return (start: start, end: start.add(const Duration(days: 7)));
    case ReportPeriod.lastWeek:
      final thisWeekStart = TimezoneHelper.getWeekStartUtc(referenceDate: now);
      final start = thisWeekStart.subtract(const Duration(days: 7));
      return (start: start, end: thisWeekStart);
    case ReportPeriod.thisMonth:
      final start = DateTime.utc(now.year, now.month, 1);
      final end = now.month == 12
          ? DateTime.utc(now.year + 1, 1, 1)
          : DateTime.utc(now.year, now.month + 1, 1);
      return (start: start, end: end);
  }
}

String _periodLabel(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.thisWeek:
      return 'this_week';
    case ReportPeriod.lastWeek:
      return 'last_week';
    case ReportPeriod.thisMonth:
      return 'this_month';
  }
}

/// Task-level CSV breakdown for a selected period, optionally scoped to one project.
/// Exports one row per task (including tasks with zero sessions in selected period).
final taskBreakdownCsvExportProvider = FutureProvider.family<String, CsvExportParams>((
  ref,
  params,
) async {
  final timerRepository = ref.read(timerSessionRepositoryProvider);
  final taskRepository = ref.read(taskRepositoryProvider);
  final categoryRepository = ref.read(categoryRepositoryProvider);
  final allProjects = await ref.watch(projectsProvider.future);
  final categories = await categoryRepository.getAllCategories();
  final categoryMap = {for (final c in categories) c.id: c.name};
  final range = _periodRange(params.period);

  final projects = params.projectId == null
      ? allProjects
      : allProjects.where((p) => p.id == params.projectId).toList();

  final csvBuffer = StringBuffer();
  csvBuffer.writeln(
    'Project,Task,Category,Task Status,Session Count,Total Hours (${_periodLabel(params.period)}),Last Session Start',
  );

  for (final project in projects) {
    final tasks = await taskRepository.getTasksByProject(project.id);
    final sessions = await timerRepository.getSessionsByProject(project.id);
    final periodSessions = sessions
        .where(
          (s) =>
              !s.startTime.isBefore(range.start) &&
              s.startTime.isBefore(range.end),
        )
        .toList();

    final sessionsByTask = <String, List<TimerSessionEntity>>{};
    for (final session in periodSessions) {
      sessionsByTask.putIfAbsent(session.taskId, () => []).add(session);
    }

    for (final task in tasks) {
      if (params.categoryId != null && task.categoryId != params.categoryId) {
        continue;
      }

      final taskSessions = sessionsByTask[task.id] ?? const [];
      final totalSeconds = taskSessions.fold<int>(
        0,
        (sum, s) => sum + s.totalSeconds,
      );
      final totalHours = (totalSeconds / 3600.0).toStringAsFixed(2);
      final categoryName =
          categoryMap[task.categoryId] ??
          categoryMap[AppDatabase.uncategorizedCategoryId] ??
          'Uncategorized';
      final latestSession = taskSessions.isEmpty
          ? null
          : taskSessions
                .map((s) => s.startTime)
                .reduce((a, b) => a.isAfter(b) ? a : b)
                .toIso8601String();

      csvBuffer.writeln(
        '${_escapeCsv(project.name)},${_escapeCsv(task.taskName)},${_escapeCsv(categoryName)},${_escapeCsv(TaskStatus.formatLabel(task.status))},${taskSessions.length},$totalHours,${_escapeCsv(latestSession ?? '')}',
      );
    }
  }

  return csvBuffer.toString();
});

/// Provider that resolves the best directory to save exported reports.
/// Prefers Downloads when available, otherwise falls back to app documents.
final reportExportDirectoryProvider = FutureProvider<Directory>((ref) async {
  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    return downloadsDir;
  }

  return getApplicationDocumentsDirectory();
});

/// Writes period-aware task breakdown CSV report to disk and returns the path.
final csvExportFileProvider = FutureProvider.family<String, CsvExportParams>((
  ref,
  params,
) async {
  final csvData = await ref.watch(
    taskBreakdownCsvExportProvider(params).future,
  );
  final now = DateTime.now();
  final filename =
      'project_tracker_${_periodLabel(params.period)}_${params.projectId ?? 'all_projects'}_${params.categoryId ?? 'all_categories'}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.csv';

  final directories = <Directory>[];

  final preferredDir = await ref.watch(reportExportDirectoryProvider.future);
  directories.add(preferredDir);

  final documentsDir = await getApplicationDocumentsDirectory();
  if (documentsDir.path != preferredDir.path) {
    directories.add(documentsDir);
  }

  final tempDir = await getTemporaryDirectory();
  if (tempDir.path != preferredDir.path && tempDir.path != documentsDir.path) {
    directories.add(tempDir);
  }

  Object? lastError;
  for (final dir in directories) {
    try {
      await dir.create(recursive: true);
      final path = p.join(dir.path, filename);
      final file = File(path);
      await file.writeAsString(csvData, flush: true);
      return file.path;
    } catch (e) {
      lastError = e;
    }
  }

  throw FileSystemException(
    'Unable to write CSV to any export directory',
    lastError?.toString(),
  );
});

/// Writes this week's CSV report to disk and returns the saved file path.
final weekCsvExportFileProvider = FutureProvider<String>((ref) async {
  return ref.watch(
    csvExportFileProvider(
      const CsvExportParams(period: ReportPeriod.thisWeek, projectId: null),
    ).future,
  );
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

/// Category-level summary for selected report params.
final categorySummaryProvider =
    FutureProvider.family<List<CategoryReportData>, CsvExportParams>((
      ref,
      params,
    ) async {
      final taskRepository = ref.read(taskRepositoryProvider);
      final timerRepository = ref.read(timerSessionRepositoryProvider);
      final categoryRepository = ref.read(categoryRepositoryProvider);
      final allProjects = await ref.watch(projectsProvider.future);
      final categories = await categoryRepository.getAllCategories();
      final categoryMap = {for (final c in categories) c.id: c.name};
      final range = _periodRange(params.period);

      final projects = params.projectId == null
          ? allProjects
          : allProjects.where((p) => p.id == params.projectId).toList();

      final summaries = <String, CategoryReportData>{};
      for (final project in projects) {
        final tasks = await taskRepository.getTasksByProject(project.id);
        final sessions = await timerRepository.getSessionsByProject(project.id);
        final periodSessions = sessions
            .where(
              (s) =>
                  !s.startTime.isBefore(range.start) &&
                  s.startTime.isBefore(range.end),
            )
            .toList();

        final taskMap = {for (final task in tasks) task.id: task};
        final touchedTasksByCategory = <String, Set<String>>{};

        for (final session in periodSessions) {
          final task = taskMap[session.taskId];
          if (task == null) {
            continue;
          }
          final categoryId =
              task.categoryId ?? AppDatabase.uncategorizedCategoryId;
          if (params.categoryId != null && categoryId != params.categoryId) {
            continue;
          }

          final existing = summaries[categoryId];
          final totalHours = (session.totalSeconds / 3600.0);

          if (existing == null) {
            summaries[categoryId] = CategoryReportData(
              categoryId: categoryId,
              categoryName: categoryMap[categoryId] ?? 'Uncategorized',
              totalHours: totalHours,
              sessionCount: 1,
              taskCount: 0,
            );
          } else {
            summaries[categoryId] = existing.copyWith(
              totalHours: existing.totalHours + totalHours,
              sessionCount: existing.sessionCount + 1,
            );
          }

          touchedTasksByCategory
              .putIfAbsent(categoryId, () => <String>{})
              .add(task.id);
        }

        touchedTasksByCategory.forEach((categoryId, taskIds) {
          final existing = summaries[categoryId];
          if (existing != null) {
            summaries[categoryId] = existing.copyWith(
              taskCount: existing.taskCount + taskIds.length,
            );
          }
        });
      }

      final sorted = summaries.values.toList()
        ..sort((a, b) => b.totalHours.compareTo(a.totalHours));

      return sorted;
    });

class CategoryReportData {
  final String categoryId;
  final String categoryName;
  final double totalHours;
  final int sessionCount;
  final int taskCount;

  const CategoryReportData({
    required this.categoryId,
    required this.categoryName,
    required this.totalHours,
    required this.sessionCount,
    required this.taskCount,
  });

  CategoryReportData copyWith({
    String? categoryId,
    String? categoryName,
    double? totalHours,
    int? sessionCount,
    int? taskCount,
  }) {
    return CategoryReportData(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      totalHours: totalHours ?? this.totalHours,
      sessionCount: sessionCount ?? this.sessionCount,
      taskCount: taskCount ?? this.taskCount,
    );
  }
}
