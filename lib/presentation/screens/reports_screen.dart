import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_card.dart';
import '../routes/app_router.dart';

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
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Hours',
                    value: '23.5h',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Active Projects',
                    value: '5',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Tasks Completed',
                    value: '34',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Project Summary Table
            Text('Project Breakdown', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Project')),
                      DataColumn(label: Text('Tasks')),
                      DataColumn(label: Text('Hours')),
                      DataColumn(label: Text('Percentage')),
                    ],
                    rows: [
                      _buildDataRow('Mobile App Redesign', '12', '8.5h', '36%'),
                      _buildDataRow('Web Dashboard', '8', '6.2h', '26%'),
                      _buildDataRow('API Integration', '10', '5.8h', '25%'),
                      _buildDataRow('Testing & QA', '4', '3.0h', '13%'),
                    ],
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'CSV export ready for download...',
                                ),
                              ),
                            );
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
