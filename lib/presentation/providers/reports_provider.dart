import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_tracker/core/constants/task_status.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/task_entity.dart';
import 'package:project_tracker/domain/entities/timer_session_entity.dart';

import 'project_provider.dart';
import 'repository_provider.dart';
import 'timer_provider.dart';

enum ReportPeriod { thisWeek, lastWeek, thisMonth }

class CsvExportParams {
  final ReportPeriod period;
  final String? projectId;
  final String? categoryId;
  final DateTime? customStartUtc;
  final DateTime? customEndUtcExclusive;

  const CsvExportParams({
    required this.period,
    this.projectId,
    this.categoryId,
    this.customStartUtc,
    this.customEndUtcExclusive,
  });

  bool get hasCustomRange =>
      customStartUtc != null && customEndUtcExclusive != null;

  @override
  bool operator ==(Object other) {
    return other is CsvExportParams &&
        other.period == period &&
        other.projectId == projectId &&
        other.categoryId == categoryId &&
        other.customStartUtc == customStartUtc &&
        other.customEndUtcExclusive == customEndUtcExclusive;
  }

  @override
  int get hashCode => Object.hash(
    period,
    projectId,
    categoryId,
    customStartUtc,
    customEndUtcExclusive,
  );
}

final sessionDetailCsvExportFileProvider =
    FutureProvider.family<String, CsvExportParams>((ref, params) async {
      final csvData = await ref.watch(
        sessionDetailCsvExportProvider(params).future,
      );
      final now = DateTime.now();
      final filename =
          'project_tracker_sessions_${_rangeLabel(params)}_${params.projectId ?? 'all_projects'}_${params.categoryId ?? 'all_categories'}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.csv';

      final directories = <Directory>[];

      final preferredDir = await ref.watch(
        reportExportDirectoryProvider.future,
      );
      directories.add(preferredDir);

      final documentsDir = await getApplicationDocumentsDirectory();
      if (documentsDir.path != preferredDir.path) {
        directories.add(documentsDir);
      }

      final tempDir = await getTemporaryDirectory();
      if (tempDir.path != preferredDir.path &&
          tempDir.path != documentsDir.path) {
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

({DateTime start, DateTime end}) _rangeForParams(CsvExportParams params) {
  if (params.hasCustomRange) {
    return (start: params.customStartUtc!, end: params.customEndUtcExclusive!);
  }

  return _periodRange(params.period);
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

String _rangeLabel(CsvExportParams params) {
  if (params.hasCustomRange) {
    final start = DateFormat(
      'yyyyMMdd',
    ).format(params.customStartUtc!.toLocal());
    final endInclusive = params.customEndUtcExclusive!
        .subtract(const Duration(days: 1))
        .toLocal();
    final end = DateFormat('yyyyMMdd').format(endInclusive);
    return 'custom_${start}_to_$end';
  }

  return _periodLabel(params.period);
}

String formatReportDateRange(CsvExportParams params) {
  final range = _rangeForParams(params);
  final formatter = DateFormat('dd MMM yyyy');
  final localStart = range.start.toLocal();
  final localEndInclusive = range.end
      .subtract(const Duration(milliseconds: 1))
      .toLocal();
  return '${formatter.format(localStart)} - ${formatter.format(localEndInclusive)}';
}

String _escapeCsv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String _ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }

  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String _formatHumanReadableDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final monthYear = DateFormat('MMMM yyyy').format(local);
  return '${local.day}${_ordinalSuffix(local.day)} $monthYear';
}

String _formatHumanReadableDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final datePart = _formatHumanReadableDate(local);
  final timePart = DateFormat('hh:mm a').format(local);
  return '$datePart, $timePart';
}

/// Unified provider for project summaries using selected period/project/category.
final projectSummaryProvider =
    FutureProvider.family<List<ProjectReportData>, CsvExportParams>((
      ref,
      params,
    ) async {
      final projects = await ref.watch(projectsProvider.future);
      final timerRepository = ref.read(timerSessionRepositoryProvider);
      final taskRepository = ref.read(taskRepositoryProvider);
      final range = _rangeForParams(params);

      final scopedProjects = params.projectId == null
          ? projects
          : projects
                .where((project) => project.id == params.projectId)
                .toList();

      final summaries = <ProjectReportData>[];

      for (final project in scopedProjects) {
        final tasks = await taskRepository.getTasksByProject(project.id);
        final filteredTasks = params.categoryId == null
            ? tasks
            : tasks
                  .where((task) => task.categoryId == params.categoryId)
                  .toList();
        final filteredTaskIds = filteredTasks.map((task) => task.id).toSet();

        final sessions = await timerRepository.getSessionsByProject(project.id);
        final periodSessions = sessions.where((session) {
          final inRange =
              !session.startTime.isBefore(range.start) &&
              session.startTime.isBefore(range.end);
          if (!inRange) {
            return false;
          }

          if (params.categoryId == null) {
            return true;
          }

          return filteredTaskIds.contains(session.taskId);
        }).toList();

        final totalSeconds = periodSessions.fold<int>(
          0,
          (sum, session) => sum + session.totalSeconds,
        );

        summaries.add(
          ProjectReportData(
            projectId: project.id,
            projectName: project.name,
            totalHours: totalSeconds / 3600.0,
            sessionCount: periodSessions.length,
            taskCount: filteredTasks.length,
            sessions: periodSessions,
          ),
        );
      }

      summaries.sort((a, b) => b.totalHours.compareTo(a.totalHours));
      return summaries;
    });

/// Backward-compatible weekly summary used by older consumers.
final weekProjectSummaryProvider = FutureProvider<List<ProjectReportData>>((
  ref,
) async {
  return ref.watch(
    projectSummaryProvider(
      const CsvExportParams(period: ReportPeriod.thisWeek),
    ).future,
  );
});

/// Provider for daily project summary.
final dailyProjectSummaryProvider = FutureProvider<List<ProjectReportData>>((
  ref,
) async {
  final todayStart = TimezoneHelper.getTodayStartUtc();
  final summaries = await ref.watch(
    projectSummaryProvider(
      CsvExportParams(
        period: ReportPeriod.thisWeek,
        customStartUtc: todayStart,
        customEndUtcExclusive: todayStart.add(const Duration(days: 1)),
      ),
    ).future,
  );

  return summaries
      .where((summary) => summary.totalHours > 0 || summary.sessionCount > 0)
      .toList();
});

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

/// Detailed CSV export with task breakdown (legacy export route).
final detailedCsvExportProvider = FutureProvider<String>((ref) async {
  final projects = await ref.watch(projectsProvider.future);
  final timerRepository = ref.read(timerSessionRepositoryProvider);
  final taskRepository = ref.read(taskRepositoryProvider);

  final csvBuffer = StringBuffer();
  csvBuffer.writeln(
    'Project,Task,Billing Type,Start Time,End Time,Duration (Hours),Date',
  );

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
          isBillable: true,
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
      final dateStr = _formatHumanReadableDate(session.startTime);
      final startTimeStr = _formatHumanReadableDateTime(session.startTime);
      final endTimeStr = _formatHumanReadableDateTime(endTime);

      csvBuffer.writeln(
        '${project.name},${task.taskName},${task.isBillable ? 'Billable' : 'Non-billable'},$startTimeStr,$endTimeStr,${durationHours.toStringAsFixed(2)},$dateStr',
      );
    }
  }

  return csvBuffer.toString();
});

/// Session-level CSV export with start/stop notes for traceability.
final sessionDetailCsvExportProvider = FutureProvider.family<String, CsvExportParams>((
  ref,
  params,
) async {
  final projects = await ref.watch(projectsProvider.future);
  final timerRepository = ref.read(timerSessionRepositoryProvider);
  final taskRepository = ref.read(taskRepositoryProvider);
  final categoryRepository = ref.read(categoryRepositoryProvider);
  final categories = await categoryRepository.getAllCategories();
  final categoryMap = {for (final c in categories) c.id: c.name};
  final range = _rangeForParams(params);

  final scopedProjects = params.projectId == null
      ? projects
      : projects.where((project) => project.id == params.projectId).toList();

  final csvBuffer = StringBuffer();
  csvBuffer.writeln(
    'Report Range,${_escapeCsv(formatReportDateRange(params))}',
  );
  csvBuffer.writeln(
    'Scope,${_escapeCsv(params.projectId == null ? 'All projects' : params.projectId!)},${_escapeCsv(params.categoryId == null ? 'All categories' : params.categoryId!)}',
  );
  csvBuffer.writeln('');
  csvBuffer.writeln(
    'Project,Task,Billing Type,Category,Session Start,Session End,Duration (Hours),Start Note,Stop Note',
  );

  for (final project in scopedProjects) {
    final tasks = await taskRepository.getTasksByProject(project.id);
    final taskMap = {for (final task in tasks) task.id: task};
    final sessions = await timerRepository.getSessionsByProject(project.id);
    final periodSessions = sessions
        .where(
          (s) =>
              !s.startTime.isBefore(range.start) &&
              s.startTime.isBefore(range.end),
        )
        .toList();

    for (final session in periodSessions) {
      final task = taskMap[session.taskId];
      if (task == null) continue;

      if (params.categoryId != null && task.categoryId != params.categoryId) {
        continue;
      }

      final categoryName =
          categoryMap[task.categoryId] ??
          categoryMap[AppDatabase.uncategorizedCategoryId] ??
          'Uncategorized';
      final endTime = session.endTime ?? DateTime.now();

      csvBuffer.writeln(
        '${_escapeCsv(project.name)},${_escapeCsv(task.taskName)},${_escapeCsv(task.isBillable ? 'Billable' : 'Non-billable')},${_escapeCsv(categoryName)},${_escapeCsv(_formatHumanReadableDateTime(session.startTime))},${_escapeCsv(_formatHumanReadableDateTime(endTime))},${(session.totalSeconds / 3600.0).toStringAsFixed(2)},${_escapeCsv(session.startNote?.trim() ?? '')},${_escapeCsv(session.stopNote?.trim() ?? '')}',
      );
    }
  }

  return csvBuffer.toString();
});

/// Task-level CSV breakdown for selected filters.
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
  final range = _rangeForParams(params);

  final projects = params.projectId == null
      ? allProjects
      : allProjects.where((p) => p.id == params.projectId).toList();

  final csvBuffer = StringBuffer();
  csvBuffer.writeln(
    'Report Range,${_escapeCsv(formatReportDateRange(params))}',
  );
  csvBuffer.writeln(
    'Scope,${_escapeCsv(params.projectId == null ? 'All projects' : params.projectId!)},${_escapeCsv(params.categoryId == null ? 'All categories' : params.categoryId!)}',
  );
  csvBuffer.writeln('');
  csvBuffer.writeln(
    'Project,Task,Billing Type,Category,Task Status,Session Count,Total Hours (${_rangeLabel(params)}),Last Session Start',
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
        (sum, session) => sum + session.totalSeconds,
      );
      final totalHours = (totalSeconds / 3600.0).toStringAsFixed(2);
      final categoryName =
          categoryMap[task.categoryId] ??
          categoryMap[AppDatabase.uncategorizedCategoryId] ??
          'Uncategorized';
      final latestSession = taskSessions.isEmpty
          ? null
          : _formatHumanReadableDateTime(
              taskSessions
                  .map((session) => session.startTime)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
            );

      csvBuffer.writeln(
        '${_escapeCsv(project.name)},${_escapeCsv(task.taskName)},${_escapeCsv(task.isBillable ? 'Billable' : 'Non-billable')},${_escapeCsv(categoryName)},${_escapeCsv(TaskStatus.formatLabel(task.status))},${taskSessions.length},$totalHours,${_escapeCsv(latestSession ?? '')}',
      );
    }
  }

  return csvBuffer.toString();
});

final reportExportDirectoryProvider = FutureProvider<Directory>((ref) async {
  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    return downloadsDir;
  }

  return getApplicationDocumentsDirectory();
});

final csvExportFileProvider = FutureProvider.family<String, CsvExportParams>((
  ref,
  params,
) async {
  final csvData = await ref.watch(
    taskBreakdownCsvExportProvider(params).future,
  );
  final now = DateTime.now();
  final filename =
      'project_tracker_${_rangeLabel(params)}_${params.projectId ?? 'all_projects'}_${params.categoryId ?? 'all_categories'}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.csv';

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

final weekCsvExportFileProvider = FutureProvider<String>((ref) async {
  return ref.watch(
    csvExportFileProvider(
      const CsvExportParams(period: ReportPeriod.thisWeek, projectId: null),
    ).future,
  );
});

final totalHodayProvider = FutureProvider<double>((ref) {
  return ref.watch(todayTotalHoursProvider.future);
});

final totalWeekHoursProvider = FutureProvider<double>((ref) {
  return ref.watch(weekTotalHoursProvider.future);
});

class ProjectReportData {
  final String projectId;
  final String projectName;
  final double totalHours;
  final int sessionCount;
  final int taskCount;
  final List<TimerSessionEntity> sessions;

  ProjectReportData({
    required this.projectId,
    required this.projectName,
    required this.totalHours,
    required this.sessionCount,
    required this.taskCount,
    required this.sessions,
  });
}

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
      final range = _rangeForParams(params);

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
