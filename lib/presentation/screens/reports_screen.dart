import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../providers/category_provider.dart';
import '../providers/project_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/repository_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/daily_goal_settings_dialog.dart';

/// Reports & Export Screen
/// Shows time tracking reports and CSV export functionality
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.title = 'Reports'});

  final String title;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisWeek;
  bool _useCustomDateRange = false;
  DateTimeRange? _customDateRange;
  String _selectedReportCategoryId = 'all';
  String _selectedReportProjectId = 'all';
  String? _lastExportedCsvPath;

  DateTime _toUtcDayStart(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  CsvExportParams get _activeReportParams {
    if (_useCustomDateRange && _customDateRange != null) {
      final startUtc = _toUtcDayStart(_customDateRange!.start);
      final endUtcExclusive = _toUtcDayStart(
        _customDateRange!.end,
      ).add(const Duration(days: 1));
      return CsvExportParams(
        period: _selectedPeriod,
        projectId: _selectedReportProjectId == 'all'
            ? null
            : _selectedReportProjectId,
        categoryId: _selectedReportCategoryId == 'all'
            ? null
            : _selectedReportCategoryId,
        customStartUtc: startUtc,
        customEndUtcExclusive: endUtcExclusive,
      );
    }

    return CsvExportParams(
      period: _selectedPeriod,
      projectId: _selectedReportProjectId == 'all'
          ? null
          : _selectedReportProjectId,
      categoryId: _selectedReportCategoryId == 'all'
          ? null
          : _selectedReportCategoryId,
    );
  }

  String _periodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.lastWeek:
        return 'Last Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Select Custom Report Range',
    );

    if (picked == null || !context.mounted) {
      return;
    }

    setState(() {
      _useCustomDateRange = true;
      _customDateRange = picked;
    });
  }

  Future<void> _openExportFolder(BuildContext context) async {
    final exportPath = _lastExportedCsvPath;
    if (exportPath == null) return;

    final folderPath = p.dirname(exportPath);
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      } else {
        throw UnsupportedError('Open folder is not supported on this platform');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open folder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyGoalHoursAsync = ref.watch(dailyGoalProvider);
    final reportParams = _activeReportParams;

    return CustomScaffold(
      activeRoute: AppRouter.reports,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Daily Goal Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DailyGoalSettingsDialog(
                    currentGoalHours: dailyGoalHoursAsync.when(
                      data: (hours) => hours.round(),
                      loading: () => 8,
                      error: (_, __) => 8,
                    ),
                    onSavePressed: (hours) async {
                      await ref
                          .read(dailyGoalRepositoryProvider)
                          .setDailyGoal(hours * 60);

                      ref.invalidate(dailyGoalProvider);
                      ref.invalidate(dailyProgressProvider);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Daily goal set to $hours hours'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Tooltip(
            message: ref.watch(themeProvider) ? 'Light Mode' : 'Dark Mode',
            child: IconButton(
              icon: Icon(
                ref.watch(themeProvider) ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final projectTableHeight = (constraints.maxHeight * 0.34).clamp(
            220.0,
            420.0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Reports', style: AppTextStyles.heading1),
                          const SizedBox(height: 4),
                          Text(
                            'Track your productivity metrics',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                      const AppAvatar(initials: 'TR'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Report Filters', style: AppTextStyles.heading2),
                        const SizedBox(height: 8),
                        Text(
                          'These filters apply to Overview, Category Breakdown, Project Breakdown, and CSV export.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ...ReportPeriod.values.map((period) {
                              return FilterChip(
                                label: Text(_periodLabel(period)),
                                selected:
                                    !_useCustomDateRange &&
                                    _selectedPeriod == period,
                                onSelected: (selected) {
                                  if (!selected) return;
                                  setState(() {
                                    _selectedPeriod = period;
                                    _useCustomDateRange = false;
                                  });
                                },
                              );
                            }),
                            FilterChip(
                              label: const Text('Custom Date Range'),
                              selected: _useCustomDateRange,
                              onSelected: (selected) {
                                if (!selected) {
                                  setState(() {
                                    _useCustomDateRange = false;
                                  });
                                  return;
                                }
                                _pickCustomDateRange(context);
                              },
                            ),
                            if (_useCustomDateRange)
                              AppButton.secondary(
                                label: _customDateRange == null
                                    ? 'Select Start & End Date'
                                    : 'Change Date Range',
                                onPressed: () => _pickCustomDateRange(context),
                              ),
                          ],
                        ),
                        if (_useCustomDateRange) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Selected Range: ${formatReportDateRange(reportParams)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 280,
                              child: ref
                                  .watch(projectsProvider)
                                  .when(
                                    data: (projects) {
                                      return DropdownButtonFormField<String>(
                                        initialValue: _selectedReportProjectId,
                                        decoration: const InputDecoration(
                                          labelText: 'Project Scope',
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: 'all',
                                            child: Text('All Projects'),
                                          ),
                                          ...projects.map(
                                            (project) =>
                                                DropdownMenuItem<String>(
                                                  value: project.id,
                                                  child: Text(project.name),
                                                ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _selectedReportProjectId = value;
                                          });
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                            ),
                            SizedBox(
                              width: 280,
                              child: ref
                                  .watch(categoriesProvider)
                                  .when(
                                    data: (categories) {
                                      return DropdownButtonFormField<String>(
                                        initialValue: _selectedReportCategoryId,
                                        decoration: const InputDecoration(
                                          labelText: 'Category Filter',
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: 'all',
                                            child: Text('All Categories'),
                                          ),
                                          ...categories.map(
                                            (category) =>
                                                DropdownMenuItem<String>(
                                                  value: category.id,
                                                  child: Text(category.name),
                                                ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _selectedReportCategoryId = value;
                                          });
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ref
                      .watch(projectSummaryProvider(reportParams))
                      .when(
                        data: (summary) {
                          final totalHours = summary.fold<double>(
                            0.0,
                            (sum, item) => sum + item.totalHours,
                          );
                          final totalSessions = summary.fold<int>(
                            0,
                            (sum, item) => sum + item.sessionCount,
                          );
                          final activeProjects = summary
                              .where((item) => item.sessionCount > 0)
                              .length;
                          final tasksInScope = summary.fold<int>(
                            0,
                            (sum, item) => sum + item.taskCount,
                          );

                          return Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Hours',
                                  value: '${totalHours.toStringAsFixed(1)}h',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Sessions',
                                  value: '$totalSessions',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Active Projects',
                                  value: '$activeProjects',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Tasks In Scope',
                                  value: '$tasksInScope',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Hours',
                                value: '-',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Sessions',
                                value: '-',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Projects',
                                value: '-',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Tasks In Scope',
                                value: '-',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Hours',
                                value: '0h',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Sessions',
                                value: '0',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Projects',
                                value: '0',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Tasks In Scope',
                                value: '0',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text('Category Breakdown', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  ref
                      .watch(categorySummaryProvider(reportParams))
                      .when(
                        data: (summary) {
                          if (summary.isEmpty) {
                            return AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No category data for selected filters',
                                style: AppTextStyles.bodyMedium,
                              ),
                            );
                          }

                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Task Count')),
                                  DataColumn(label: Text('Sessions')),
                                  DataColumn(label: Text('Hours')),
                                ],
                                rows: summary
                                    .map(
                                      (row) => DataRow(
                                        cells: [
                                          DataCell(Text(row.categoryName)),
                                          DataCell(Text('${row.taskCount}')),
                                          DataCell(Text('${row.sessionCount}')),
                                          DataCell(
                                            Text(
                                              '${row.totalHours.toStringAsFixed(2)}h',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading category report',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text('Project Breakdown', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: projectTableHeight,
                    child: ref
                        .watch(projectSummaryProvider(reportParams))
                        .when(
                          data: (summary) {
                            if (summary.isEmpty) {
                              return AppCard(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No projects for selected filters',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              );
                            }

                            return AppCard(
                              padding: const EdgeInsets.all(24),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Project')),
                                    DataColumn(label: Text('Tasks In Scope')),
                                    DataColumn(label: Text('Sessions')),
                                    DataColumn(label: Text('Hours')),
                                  ],
                                  rows: summary
                                      .map(
                                        (item) => DataRow(
                                          cells: [
                                            DataCell(Text(item.projectName)),
                                            DataCell(Text('${item.taskCount}')),
                                            DataCell(
                                              Text('${item.sessionCount}'),
                                            ),
                                            DataCell(
                                              Text(
                                                '${item.totalHours.toStringAsFixed(1)}h',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            );
                          },
                          loading: () => AppCard(
                            padding: const EdgeInsets.all(24),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, __) => AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Error loading project data',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Data', style: AppTextStyles.heading2),
                        const SizedBox(height: 12),
                        Text(
                          'CSV uses the same report filters above.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applied Date Range: ${formatReportDateRange(reportParams)}',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AppButton.primary(
                          label: 'Download Summary CSV',
                          onPressed: () async {
                            try {
                              final savedPath = await ref.read(
                                csvExportFileProvider(reportParams).future,
                              );
                              setState(() {
                                _lastExportedCsvPath = savedPath;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Summary CSV exported to: $savedPath',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: 'Download Session Detail CSV',
                          onPressed: () async {
                            try {
                              final savedPath = await ref.read(
                                sessionDetailCsvExportFileProvider(
                                  reportParams,
                                ).future,
                              );
                              setState(() {
                                _lastExportedCsvPath = savedPath;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Session detail CSV exported to: $savedPath',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: 'Open Export Folder',
                          isEnabled: _lastExportedCsvPath != null,
                          onPressed: _lastExportedCsvPath == null
                              ? null
                              : () => _openExportFolder(context),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _lastExportedCsvPath == null
                              ? 'Last export location: Not exported yet'
                              : 'Last export location: $_lastExportedCsvPath',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMedium),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading2),
        ],
      ),
    );
  }
}
