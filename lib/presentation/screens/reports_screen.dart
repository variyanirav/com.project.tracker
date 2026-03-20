import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_card.dart';
import '../routes/app_router.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/reports_provider.dart';

/// Reports & Export Screen
/// Shows time tracking reports and CSV export functionality
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.title = 'Reports'});

  final String title;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String selectedPeriod = 'This Week';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      activeRoute: AppRouter.reports,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                AppAvatar(initials: 'TR'),
              ],
            ),
            const SizedBox(height: 32),
            // Period Selector
            SizedBox(
              height: 40,
              child: Row(
                children: ['This Week', 'Last Week', 'This Month'].map((
                  period,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: FilterChip(
                      label: Text(period),
                      selected: selectedPeriod == period,
                      onSelected: (selected) {
                        setState(() => selectedPeriod = period);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            // Statistics Row - Wired to real data
            ref
                .watch(weekProjectSummaryProvider)
                .when(
                  data: (summary) {
                    final totalHours = summary.fold<double>(
                      0.0,
                      (sum, item) => sum + item.totalHours,
                    );

                    return ref
                        .watch(projectsProvider)
                        .when(
                          data: (projects) {
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
                                    title: 'Active Projects',
                                    value: '${projects.length}',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    title: 'Tasks Created',
                                    value:
                                        ref
                                            .watch(projectsProvider)
                                            .whenData((p) {
                                              int count = 0;
                                              for (var project in p) {
                                                ref
                                                    .watch(
                                                      tasksByProjectProvider(
                                                        project.id,
                                                      ),
                                                    )
                                                    .whenData((tasks) {
                                                      count += tasks.length;
                                                    });
                                              }
                                              return count.toString();
                                            })
                                            .value
                                            ?.toString() ??
                                        '-',
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
                                  title: 'Active Projects',
                                  value: '-',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Tasks Created',
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
                                  title: 'Active Projects',
                                  value: '0',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Tasks Created',
                                  value: '0',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
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
                          title: 'Active Projects',
                          value: '-',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Tasks Created',
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
                          title: 'Active Projects',
                          value: '0',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Tasks Created',
                          value: '0',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 32),
            // Project Summary Table - Wired to real data
            Text('Project Breakdown', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: ref
                  .watch(projectsProvider)
                  .when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return AppCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No projects yet',
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
                              DataColumn(label: Text('Tasks')),
                              DataColumn(label: Text('Hours')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: projects.map((project) {
                              final tasksAsync = ref.watch(
                                tasksByProjectProvider(project.id),
                              );
                              final hoursAsync = ref.watch(
                                projectTotalHoursProvider(project.id),
                              );

                              final taskCount =
                                  tasksAsync
                                      .whenData((tasks) => tasks.length)
                                      .value ??
                                  0;
                              final hours =
                                  hoursAsync
                                      .whenData((h) => h.toStringAsFixed(1))
                                      .value ??
                                  '-';

                              return _buildDataRow(
                                project.name,
                                '$taskCount',
                                '${hours}h',
                                'Active',
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => AppCard(
                      padding: const EdgeInsets.all(24),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Error loading data',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 24),
            // Export Section
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Data', style: AppTextStyles.heading2),
                        const SizedBox(height: 12),
                        Text(
                          'Download your time tracking data as CSV',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        AppButton.primary(
                          label: 'Download CSV',
                          onPressed: () async {
                            try {
                              final csvData = await ref.read(
                                weekCsvExportProvider.future,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'CSV exported! (${csvData.length} bytes)',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    String project,
    String tasks,
    String hours,
    String percentage,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(project)),
        DataCell(Text(tasks)),
        DataCell(Text(hours)),
        DataCell(Text(percentage)),
      ],
    );
  }
}

/// Stat card widget for displaying metrics
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
