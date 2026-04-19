import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../providers/category_provider.dart';
import '../providers/project_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/repository_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/daily_goal_settings_dialog.dart';
import '../widgets/reports/reports_components.dart';

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
    final palette = ReportsPalette(isDark: isDark);
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
      child: ColoredBox(
        color: palette.page,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 1280
                ? 1180.0
                : constraints.maxWidth - 48;
            final isWideTableLayout = contentWidth >= 1100;
            final statCardsPerRow = contentWidth >= 1120 ? 4 : 2;
            final statCardWidth =
                (contentWidth - (16 * (statCardsPerRow - 1))) / statCardsPerRow;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(palette),
                      const SizedBox(height: 24),
                      _buildFilterPanel(
                        context,
                        palette,
                        reportParams,
                        contentWidth,
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

                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: statCardWidth,
                                    child: ReportsMetricCard(
                                      palette: palette,
                                      title: 'Total Hours',
                                      value: totalHours.toStringAsFixed(1),
                                      suffix: ' h',
                                      icon: Icons.schedule,
                                      iconColor: palette.accent,
                                    ),
                                  ),
                                  SizedBox(
                                    width: statCardWidth,
                                    child: ReportsMetricCard(
                                      palette: palette,
                                      title: 'Sessions',
                                      value: '$totalSessions',
                                      suffix: '',
                                      icon: Icons.history,
                                      iconColor: const Color(0xFF9BC1FF),
                                    ),
                                  ),
                                  SizedBox(
                                    width: statCardWidth,
                                    child: ReportsMetricCard(
                                      palette: palette,
                                      title: 'Active Projects',
                                      value: '$activeProjects',
                                      suffix: '',
                                      icon: Icons.folder,
                                      iconColor: const Color(0xFFFFB595),
                                    ),
                                  ),
                                  SizedBox(
                                    width: statCardWidth,
                                    child: ReportsMetricCard(
                                      palette: palette,
                                      title: 'Tasks In Scope',
                                      value: '$tasksInScope',
                                      suffix: '',
                                      icon: Icons.task_alt,
                                      iconColor: const Color(0xFF6CA5FF),
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (_, __) => ReportsPanel(
                              palette: palette,
                              child: Text(
                                'Unable to load overview metrics',
                                style: AppTypography.body.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 24),
                      isWideTableLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCategoryTable(
                                    palette,
                                    reportParams,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildProjectTable(
                                    palette,
                                    reportParams,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildCategoryTable(palette, reportParams),
                                const SizedBox(height: 16),
                                _buildProjectTable(palette, reportParams),
                              ],
                            ),
                      const SizedBox(height: 24),
                      _buildExportPanel(context, palette, reportParams),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ReportsPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Reports',
              style: AppTypography.screenTitle.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your productivity metrics',
              style: AppTypography.screenSubtitle.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const AppAvatar(initials: 'TR'),
      ],
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    ReportsPalette palette,
    CsvExportParams reportParams,
    double contentWidth,
  ) {
    final fieldWidth = contentWidth >= 980
        ? (contentWidth - 20 - 20 - 20) / 3
        : contentWidth >= 700
        ? (contentWidth - 20 - 20) / 2
        : contentWidth;

    return ReportsPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: fieldWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE RANGE',
                      style: AppTypography.labelCaps.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...ReportPeriod.values.map((period) {
                          final isSelected =
                              !_useCustomDateRange && _selectedPeriod == period;
                          return _PeriodButton(
                            label: _periodLabel(period),
                            selected: isSelected,
                            palette: palette,
                            onPressed: () {
                              setState(() {
                                _selectedPeriod = period;
                                _useCustomDateRange = false;
                              });
                            },
                          );
                        }),
                        _PeriodButton(
                          label: 'Custom',
                          selected: _useCustomDateRange,
                          palette: palette,
                          trailingIcon: Icons.calendar_month,
                          onPressed: () => _pickCustomDateRange(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: ref
                    .watch(projectsProvider)
                    .when(
                      data: (projects) => DropdownButtonFormField<String>(
                        initialValue: _selectedReportProjectId,
                        decoration: reportsInputDecoration(
                          palette: palette,
                          label: 'PROJECT SCOPE',
                        ),
                        dropdownColor: palette.panelLowest,
                        style: AppTypography.body.copyWith(
                          color: palette.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('All Projects'),
                          ),
                          ...projects.map(
                            (project) => DropdownMenuItem<String>(
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
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ),
              SizedBox(
                width: fieldWidth,
                child: ref
                    .watch(categoriesProvider)
                    .when(
                      data: (categories) => DropdownButtonFormField<String>(
                        initialValue: _selectedReportCategoryId,
                        decoration: reportsInputDecoration(
                          palette: palette,
                          label: 'CATEGORY FILTER',
                        ),
                        dropdownColor: palette.panelLowest,
                        style: AppTypography.body.copyWith(
                          color: palette.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('All Categories'),
                          ),
                          ...categories.map(
                            (category) => DropdownMenuItem<String>(
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
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Applied Date Range: ${formatReportDateRange(reportParams)}',
            style: AppTypography.helper.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTable(ReportsPalette palette, CsvExportParams params) {
    return ref
        .watch(categorySummaryProvider(params))
        .when(
          data: (summary) {
            if (summary.isEmpty) {
              return ReportsPanel(
                palette: palette,
                child: _NoDataMessage(
                  title: 'Category Breakdown',
                  message: 'No category data for selected filters',
                  palette: palette,
                ),
              );
            }

            return ReportsPanel(
              palette: palette,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Text(
                      'Category Breakdown',
                      style: AppTypography.sectionTitle.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dividerThickness: 0,
                      dataRowHeight: 42,
                      headingRowColor: MaterialStatePropertyAll(
                        palette.tableHeader,
                      ),
                      dataTextStyle: AppTypography.bodySmall.copyWith(
                        color: palette.textPrimary,
                      ),
                      headingTextStyle: AppTypography.label.copyWith(
                        color: palette.textSecondary,
                        letterSpacing: 1.0,
                      ),
                      columns: const [
                        DataColumn(label: Text('CATEGORY')),
                        DataColumn(label: Text('TASK COUNT')),
                        DataColumn(label: Text('SESSIONS')),
                        DataColumn(label: Text('HOURS')),
                      ],
                      rows: summary.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return DataRow(
                          color: MaterialStatePropertyAll(
                            index.isEven ? palette.panel : palette.panelHigh,
                          ),
                          cells: [
                            DataCell(Text(row.categoryName)),
                            DataCell(Text('${row.taskCount}')),
                            DataCell(Text('${row.sessionCount}')),
                            DataCell(
                              Text(
                                row.totalHours.toStringAsFixed(1),
                                style: AppTypography.actionLabel.copyWith(
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
          loading: () => ReportsPanel(
            palette: palette,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => ReportsPanel(
            palette: palette,
            child: Text(
              'Error loading category report',
              style: AppTypography.body.copyWith(color: palette.textSecondary),
            ),
          ),
        );
  }

  Widget _buildProjectTable(ReportsPalette palette, CsvExportParams params) {
    return ref
        .watch(projectSummaryProvider(params))
        .when(
          data: (summary) {
            if (summary.isEmpty) {
              return ReportsPanel(
                palette: palette,
                child: _NoDataMessage(
                  title: 'Project Breakdown',
                  message: 'No projects for selected filters',
                  palette: palette,
                ),
              );
            }

            return ReportsPanel(
              palette: palette,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Text(
                      'Project Breakdown',
                      style: AppTypography.sectionTitle.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dividerThickness: 0,
                      dataRowHeight: 42,
                      headingRowColor: MaterialStatePropertyAll(
                        palette.tableHeader,
                      ),
                      dataTextStyle: AppTypography.bodySmall.copyWith(
                        color: palette.textPrimary,
                      ),
                      headingTextStyle: AppTypography.label.copyWith(
                        color: palette.textSecondary,
                        letterSpacing: 1.0,
                      ),
                      columns: const [
                        DataColumn(label: Text('PROJECT')),
                        DataColumn(label: Text('TASKS')),
                        DataColumn(label: Text('SESSIONS')),
                        DataColumn(label: Text('HOURS')),
                      ],
                      rows: summary.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return DataRow(
                          color: MaterialStatePropertyAll(
                            index.isEven ? palette.panel : palette.panelHigh,
                          ),
                          cells: [
                            DataCell(Text(item.projectName)),
                            DataCell(Text('${item.taskCount}')),
                            DataCell(Text('${item.sessionCount}')),
                            DataCell(
                              Text(
                                item.totalHours.toStringAsFixed(1),
                                style: AppTypography.actionLabel.copyWith(
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
          loading: () => ReportsPanel(
            palette: palette,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => ReportsPanel(
            palette: palette,
            child: Text(
              'Error loading project data',
              style: AppTypography.body.copyWith(color: palette.textSecondary),
            ),
          ),
        );
  }

  Widget _buildExportPanel(
    BuildContext context,
    ReportsPalette palette,
    CsvExportParams reportParams,
  ) {
    final projectText = _selectedReportProjectId == 'all'
        ? 'All Projects'
        : _selectedReportProjectId;
    final categoryText = _selectedReportCategoryId == 'all'
        ? 'All Categories'
        : _selectedReportCategoryId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.subtleBorder),
        gradient: LinearGradient(
          colors: _exportGradient(palette.isDark),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ios_share, color: palette.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Export Data',
                      style: AppTypography.sectionTitle.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.panelLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.subtleBorder),
                  ),
                  child: Text(
                    'APPLIED FILTERS\nDate: ${formatReportDateRange(reportParams)}  •  Project: $projectText  •  Category: $categoryText',
                    style: AppTypography.helper.copyWith(
                      color: palette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ReportsActionButton(
                label: 'Download Summary CSV',
                icon: Icons.table_view,
                palette: palette,
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
                          content: Text('Summary CSV exported to: $savedPath'),
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
              ReportsActionButton(
                label: 'Download Detailed CSV',
                icon: Icons.download,
                primary: true,
                palette: palette,
                onPressed: () async {
                  try {
                    final savedPath = await ref.read(
                      sessionDetailCsvExportFileProvider(reportParams).future,
                    );
                    setState(() {
                      _lastExportedCsvPath = savedPath;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Detailed CSV exported to: $savedPath'),
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
              _ExportFolderButton(
                palette: palette,
                enabled: _lastExportedCsvPath != null,
                onPressed: _lastExportedCsvPath == null
                    ? null
                    : () => _openExportFolder(context),
              ),
            ],
          ),
          SelectableText(
            _lastExportedCsvPath == null
                ? 'Last export location: Not exported yet'
                : 'Last export location: $_lastExportedCsvPath',
            style: AppTypography.helper.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  List<Color> _exportGradient(bool isDark) {
    if (isDark) {
      return const [AppColors.darkSurface, AppColors.darkBg];
    }

    return const [AppColors.lightSurface, AppColors.lightCard];
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final ReportsPalette palette;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? palette.panelHigh : palette.panelLowest,
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.65)
                  : palette.subtleBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: selected ? palette.textPrimary : palette.textSecondary,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(
                  trailingIcon,
                  size: 14,
                  color: selected ? palette.accent : palette.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage({
    required this.title,
    required this.message,
    required this.palette,
  });

  final String title;
  final String message;
  final ReportsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: AppTypography.body.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _ExportFolderButton extends StatelessWidget {
  const _ExportFolderButton({
    required this.palette,
    required this.enabled,
    required this.onPressed,
  });

  final ReportsPalette palette;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: enabled ? palette.panelLowest : palette.panelHigh,
            border: Border.all(color: palette.subtleBorder),
          ),
          child: Icon(
            Icons.folder_open,
            size: 18,
            color: enabled ? palette.textSecondary : palette.textMuted,
          ),
        ),
      ),
    );
  }
}
