import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_card.dart';
import '../routes/app_router.dart';

/// Task status enum
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  inReview('In Review'),
  onHold('On Hold'),
  complete('Complete');

  final String label;
  const TaskStatus(this.label);

  /// Get color for this status
  Color getColor() {
    switch (this) {
      case TaskStatus.todo:
        return const Color(0xFF64748B); // Gray
      case TaskStatus.inProgress:
        return const Color(0xFF007BFF); // Blue
      case TaskStatus.inReview:
        return const Color(0xFFFCD34D); // Amber
      case TaskStatus.onHold:
        return const Color(0xFFFB923C); // Orange
      case TaskStatus.complete:
        return const Color(0xFF10B981); // Green
    }
  }
}

/// Project Detail Screen
/// Shows project information, active timer, and task history
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, this.title = 'Project Detail'});

  final String title;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;
  TaskStatus _selectedStatus = TaskStatus.todo;
  int _currentTaskPage = 0;
  final int _tasksPerPage = 20;

  @override
  void initState() {
    super.initState();
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      activeRoute: AppRouter.projectDetail,
      child: SingleChildScrollView(
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
                    Text('Project Details', style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile App Redesign',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                AppAvatar(initials: 'PM'),
              ],
            ),
            const SizedBox(height: 32),

            // Time Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today\'s Hours',
                    value: '4h 30m',
                    icon: Icons.today,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'This Week',
                    value: '28h 15m',
                    icon: Icons.calendar_today,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Total Hours',
                    value: '156h 45m',
                    icon: Icons.trending_up,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main content: Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Active Task & Timer
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Task Card
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        backgroundColor: isDark
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currently Tracking',
                              style: AppTextStyles.labelMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'UI Design Mockups',
                              style: AppTextStyles.heading2,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Design', style: AppTextStyles.bodySmall),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaskStatus.inProgress
                                        .getColor()
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'In Progress',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: TaskStatus.inProgress.getColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Timer Display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '2:45:23',
                                  style: AppTextStyles.timerDisplay.copyWith(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Control Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton.primary(
                                    label: 'Pause',
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton.danger(
                                    label: 'Stop',
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Start New Task Section
                      Text('Start New Task', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            TextField(
                              controller: _taskTitleController,
                              decoration: InputDecoration(
                                labelText: 'Task Title',
                                hintText: 'Enter task title...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            TextField(
                              controller: _taskDescriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Add task details...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Status Dropdown
                            DropdownButtonFormField<TaskStatus>(
                              initialValue: _selectedStatus,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                }
                              },
                              items: TaskStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: status.getColor(),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(status.label),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: AppButton.primary(
                                label: 'Start Timer',
                                onPressed: () {
                                  // TODO: Implement start timer logic
                                  // - Validate form
                                  // - Check global timer constraint
                                  // - Create task with selected status
                                  // - Auto-change status to "In Progress"
                                  // - Start timer
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // All Tasks Section
                      Text('Project Tasks', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      ..._buildTasksList(isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right: Today's Tasks
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Tasks', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      ..._buildTodayTasksList(isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build tasks list with pagination
  List<Widget> _buildTasksList(bool isDark) {
    final tasks = _generateSampleTasks(100); // Generate sample tasks
    final start = _currentTaskPage * _tasksPerPage;
    final end = (start + _tasksPerPage).clamp(0, tasks.length);
    final paginatedTasks = tasks.sublist(start, end);

    return [
      ...paginatedTasks.map(
        (task) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] as String,
                        style: AppTextStyles.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: task['statusColor'].withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task['status'] as String,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: task['statusColor'],
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${task['duration']} · ${task['date']}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Pagination Controls
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppButton.secondary(
            label: 'Previous',
            onPressed: _currentTaskPage > 0
                ? () {
                    setState(() {
                      _currentTaskPage--;
                    });
                  }
                : null,
          ),
          Text(
            'Page ${_currentTaskPage + 1} of ${(100 / _tasksPerPage).ceil()}',
            style: AppTextStyles.bodySmall,
          ),
          AppButton.secondary(
            label: 'Next',
            onPressed: ((_currentTaskPage + 1) * _tasksPerPage) < 100
                ? () {
                    setState(() {
                      _currentTaskPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    ];
  }

  /// Build today's tasks list
  List<Widget> _buildTodayTasksList(bool isDark) {
    final todayTasks = [
      {
        'title': 'UI Design Review',
        'status': 'In Progress',
        'statusColor': TaskStatus.inProgress.getColor(),
        'duration': '1h 30m',
      },
      {
        'title': 'Mockup Refinement',
        'status': 'In Progress',
        'statusColor': TaskStatus.inProgress.getColor(),
        'duration': '45m',
      },
      {
        'title': 'Client Feedback',
        'status': 'To Do',
        'statusColor': TaskStatus.todo.getColor(),
        'duration': '20m',
      },
      {
        'title': 'Design System Update',
        'status': 'Complete',
        'statusColor': TaskStatus.complete.getColor(),
        'duration': '2h 15m',
      },
    ];

    if (todayTasks.isEmpty) {
      return [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No tasks for today',
              style: AppTextStyles.bodySmall.copyWith(color: Color(0xFFA0AEC0)),
            ),
          ),
        ),
      ];
    }

    return todayTasks
        .map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] as String,
                          style: AppTextStyles.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task['duration'] as String,
                        style: AppTextStyles.bodySmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (task['statusColor'] as Color?)?.withValues(
                                alpha: 0.2,
                              ) ??
                              Colors.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          task['status'] as String,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: task['statusColor'] as Color?,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  /// Generate sample tasks for pagination demo
  List<Map<String, dynamic>> _generateSampleTasks(int count) {
    final statuses = [
      ('To Do', TaskStatus.todo.getColor()),
      ('In Progress', TaskStatus.inProgress.getColor()),
      ('In Review', TaskStatus.inReview.getColor()),
      ('On Hold', TaskStatus.onHold.getColor()),
      ('Complete', TaskStatus.complete.getColor()),
    ];

    return List.generate(count, (index) {
      final status = statuses[index % statuses.length];
      return {
        'title': 'Task ${index + 1}: Design Feature',
        'status': status.$1,
        'statusColor': status.$2,
        'duration': '${2 + (index % 4)}h ${15 * (index % 4)}m',
        'date': DateTime.now()
            .subtract(Duration(days: index % 7))
            .toString()
            .split(' ')[0],
      };
    });
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.labelMedium),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: AppColors.brandPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.headingLarge),
        ],
      ),
    );
  }
}
