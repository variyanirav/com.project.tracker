import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/timer_provider.dart';
import 'timer_session_note_dialog.dart';

/// View Task Dialog
/// Opens as a modal dialog to view task details in read-only format
class ViewTaskDialog extends StatelessWidget {
  final TaskEntity task;

  const ViewTaskDialog({super.key, required this.task});

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = hour24 >= 12 ? 'PM' : 'AM';

    return '${local.day} ${months[local.month]} ${local.year}, $hour12:$minute $meridiem';
  }

  Future<void> _editSessionNotes(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String? initialValue,
  ) async {
    final result = await showTimerSessionNoteDialog(
      context,
      title: 'Edit Session Notes',
      hintText: 'Update session notes',
      initialValue: initialValue,
    );

    if (result == null) {
      return;
    }

    final normalized = result.trim().isEmpty ? null : result.trim();
    await ref.read(
      updateTimerSessionNotesProvider(
        UpdateTimerSessionNotesParams(sessionId: sessionId, notes: normalized),
      ).future,
    );

    ref.invalidate(timerSessionsByTaskProvider(task.id));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session notes updated')));
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Session'),
          content: const Text(
            'Are you sure you want to delete this session? This action cannot be undone.',
          ),
          actions: [
            AppButton.secondary(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppButton.danger(
              label: 'Delete',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(deleteTimerSessionProvider(sessionId).future);
    ref.invalidate(timerSessionsByTaskProvider(task.id));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = TaskStatus.fromValue(task.status);

    return Consumer(
      builder: (context, ref, _) {
        final sessionsAsync = ref.watch(timerSessionsByTaskProvider(task.id));

        return AlertDialog(
          title: Text('Task Details', style: AppTextStyles.heading2),
          scrollable: true,
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(task.taskName, style: AppTextStyles.heading2),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress Status',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.getColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.label,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: status.getColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timer Status',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.isRunning
                          ? '⏱️ Currently Tracking'
                          : '⏹️ Not Tracking',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: task.isRunning ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Time Logged',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeFormatter.formatSeconds(task.totalSeconds),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created On',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeFormatter.formatDate(task.createdAt),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (task.description != null && task.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(task.description!, style: AppTextStyles.bodySmall),
                    ],
                  ),
                const SizedBox(height: 24),
                Text('Session History', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                sessionsAsync.when(
                  data: (sessions) {
                    final sorted = [...sessions]
                      ..sort((a, b) => b.startTime.compareTo(a.startTime));

                    if (sorted.isEmpty) {
                      return Text(
                        'No sessions logged yet',
                        style: AppTextStyles.bodySmall,
                      );
                    }

                    return Column(
                      children: sorted.map((session) {
                        final noteText = session.notes?.trim();
                        final hasNote = noteText != null && noteText.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(session.startTime),
                                style: AppTextStyles.labelMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session.endTime == null
                                    ? 'In progress'
                                    : 'Ended: ${_formatDateTime(session.endTime!)}',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duration: ${DateTimeFormatter.formatSeconds(session.totalSeconds)}',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasNote ? noteText : 'No notes',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit Session Notes',
                                    onPressed: () => _editSessionNotes(
                                      context,
                                      ref,
                                      session.id,
                                      session.notes,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Session',
                                    onPressed: () => _deleteSession(
                                      context,
                                      ref,
                                      session.id,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) => Text(
                    'Failed to load sessions: $error',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            AppButton.secondary(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
