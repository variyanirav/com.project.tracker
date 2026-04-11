import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/timer_provider.dart';
import 'timer_session_note_dialog.dart';

/// View Task Dialog
/// Opens as a modal dialog to view task details in read-only format
class ViewTaskDialog extends ConsumerStatefulWidget {
  final TaskEntity task;
  final bool readOnly;

  const ViewTaskDialog({super.key, required this.task, this.readOnly = false});

  @override
  ConsumerState<ViewTaskDialog> createState() => _ViewTaskDialogState();
}

class _ViewTaskDialogState extends ConsumerState<ViewTaskDialog> {
  bool get _isReadOnly {
    return widget.readOnly ||
        TaskStatus.fromValue(widget.task.status) == TaskStatus.archived;
  }

  String _sessionFilter = 'all';
  String _sortColumn = 'start';
  bool _sortAscending = false;

  final ScrollController _overviewScrollController = ScrollController();
  final ScrollController _descriptionScrollController = ScrollController();
  final ScrollController _metaScrollController = ScrollController();
  final ScrollController _sessionVerticalScrollController = ScrollController();
  final ScrollController _sessionHorizontalScrollController =
      ScrollController();

  @override
  void dispose() {
    _overviewScrollController.dispose();
    _descriptionScrollController.dispose();
    _metaScrollController.dispose();
    _sessionVerticalScrollController.dispose();
    _sessionHorizontalScrollController.dispose();
    super.dispose();
  }

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

  Future<void> _editSessionStartNote(
    BuildContext context,
    String sessionId,
    String? initialValue,
  ) async {
    final result = await showTimerSessionNoteDialog(
      context,
      title: 'Edit Start Note',
      hintText: 'Update the note saved when the session starts',
      initialValue: initialValue,
    );

    if (result == null) {
      return;
    }

    final normalized = result.trim().isEmpty ? null : result.trim();
    await ref.read(
      updateTimerSessionStartNoteProvider(
        UpdateTimerSessionStartNoteParams(
          sessionId: sessionId,
          startNote: normalized,
        ),
      ).future,
    );

    ref.invalidate(timerSessionsByTaskProvider(widget.task.id));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Start note updated')));
    }
  }

  Future<void> _editSessionStopNote(
    BuildContext context,
    String sessionId,
    String? initialValue,
  ) async {
    final result = await showTimerSessionNoteDialog(
      context,
      title: 'Edit Stop Note',
      hintText: 'Update the note saved when the session stops',
      initialValue: initialValue,
    );

    if (result == null) {
      return;
    }

    final normalized = result.trim().isEmpty ? null : result.trim();
    await ref.read(
      updateTimerSessionStopNoteProvider(
        UpdateTimerSessionStopNoteParams(
          sessionId: sessionId,
          stopNote: normalized,
        ),
      ).future,
    );

    ref.invalidate(timerSessionsByTaskProvider(widget.task.id));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stop note updated')));
    }
  }

  Future<void> _deleteSession(BuildContext context, String sessionId) async {
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
    ref.invalidate(timerSessionsByTaskProvider(widget.task.id));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted')));
    }
  }

  Future<void> _copySessionStopNote(BuildContext context, String value) async {
    await _copyToClipboard(context, value);
  }

  Future<void> _handleSessionAction(
    BuildContext context,
    String action,
    dynamic session,
    String stopNoteText,
  ) async {
    if (_isReadOnly && action != 'copyStop') {
      return;
    }

    switch (action) {
      case 'editStart':
        await _editSessionStartNote(context, session.id, session.startNote);
        return;
      case 'editStop':
        await _editSessionStopNote(context, session.id, session.stopNote);
        return;
      case 'copyStop':
        await _copySessionStopNote(context, stopNoteText);
        return;
      case 'delete':
        await _deleteSession(context, session.id);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final status = TaskStatus.fromValue(task.status);
    final screenSize = MediaQuery.of(context).size;
    final dialogMaxWidth = screenSize.width >= 1600
        ? 1240.0
        : (screenSize.width * 0.9).clamp(640.0, 1120.0);
    final isWideLayout = dialogMaxWidth >= 980;

    final sessionsAsync = ref.watch(timerSessionsByTaskProvider(task.id));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 640,
          maxWidth: dialogMaxWidth,
          minHeight: 520,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Task Details', style: AppTextStyles.heading2),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: isWideLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _taskOverviewCard(context),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: _taskMetaCard(context, status),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _taskOverviewCard(context),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 4,
                                  child: _taskMetaCard(context, status),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 6,
                      child: _sessionHistoryTable(context, sessionsAsync),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskOverviewCard(BuildContext context) {
    final description = widget.task.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brightness = theme.brightness;
    final borderColor = theme.dividerColor;
    final mutedSurface = brightness == Brightness.dark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.22)
        : colors.surfaceContainerHighest.withValues(alpha: 0.58);
    final panelTint = brightness == Brightness.dark
        ? colors.primaryContainer.withValues(alpha: 0.16)
        : colors.primaryContainer.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelTint,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final descriptionBoxHeight = (constraints.maxHeight * 0.58).clamp(
            90.0,
            220.0,
          );

          return SingleChildScrollView(
            controller: _overviewScrollController,
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.task.taskName, style: AppTextStyles.heading2),
                const SizedBox(height: 14),
                Text(
                  'Description',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: descriptionBoxHeight,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mutedSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Scrollbar(
                      controller: _descriptionScrollController,
                      child: SingleChildScrollView(
                        controller: _descriptionScrollController,
                        primary: false,
                        child: Text(
                          hasDescription
                              ? description
                              : 'No description provided',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _taskMetaCard(BuildContext context, TaskStatus status) {
    final timerStatus = widget.task.isRunning
        ? '⏱️ Currently Tracking'
        : '⏹️ Not Tracking';
    final timerStatusColor = widget.task.isRunning
        ? Colors.green
        : Colors.orange;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brightness = theme.brightness;
    final borderColor = theme.dividerColor;
    final panelTint = brightness == Brightness.dark
        ? colors.secondaryContainer.withValues(alpha: 0.20)
        : colors.secondaryContainer.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelTint,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        controller: _metaScrollController,
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metaLabelValue(
              brightness: brightness,
              label: 'Progress Status',
              valueWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.getColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: status.getColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _metaLabelValue(
              brightness: brightness,
              label: 'Timer Status',
              valueWidget: Text(
                timerStatus,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: timerStatusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _metaLabelValue(
              brightness: brightness,
              label: 'Total Time Logged',
              valueWidget: Text(
                DateTimeFormatter.formatSeconds(widget.task.totalSeconds),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _metaLabelValue(
              brightness: brightness,
              label: 'Created On',
              valueWidget: Text(
                DateTimeFormatter.formatDate(widget.task.createdAt),
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaLabelValue({
    required Brightness brightness,
    required String label,
    required Widget valueWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        valueWidget,
      ],
    );
  }

  Widget _sessionHistoryTable(
    BuildContext context,
    AsyncValue<List<dynamic>> sessionsAsync,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brightness = theme.brightness;
    final headerBg = colors.surfaceContainerHighest.withValues(
      alpha: brightness == Brightness.dark ? 0.22 : 0.56,
    );
    final borderColor = theme.dividerColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Session History', style: AppTextStyles.titleSmall),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _sessionFilter == 'all',
                    onSelected: (_) => setState(() => _sessionFilter = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('In Progress'),
                    selected: _sessionFilter == 'inProgress',
                    onSelected: (_) =>
                        setState(() => _sessionFilter = 'inProgress'),
                  ),
                  ChoiceChip(
                    label: const Text('Completed'),
                    selected: _sessionFilter == 'completed',
                    onSelected: (_) =>
                        setState(() => _sessionFilter = 'completed'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                final filtered = sessions.where((session) {
                  if (_sessionFilter == 'inProgress') {
                    return session.endTime == null;
                  }
                  if (_sessionFilter == 'completed') {
                    return session.endTime != null;
                  }
                  return true;
                }).toList();

                final sorted = [...filtered]
                  ..sort((a, b) {
                    final compare = _sortColumn == 'duration'
                        ? a.totalSeconds.compareTo(b.totalSeconds)
                        : a.startTime.compareTo(b.startTime);
                    return _sortAscending ? compare : -compare;
                  });

                if (sorted.isEmpty) {
                  return Text(
                    'No sessions logged yet',
                    style: AppTextStyles.bodySmall,
                  );
                }

                const rowHeight = 54.0;
                const actionColumnWidth = 120.0;

                return Scrollbar(
                  controller: _sessionHorizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _sessionHorizontalScrollController,
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1198,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: headerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _headerCell(
                                  context: context,
                                  label: 'Start',
                                  width: 210,
                                  sortable: true,
                                  active: _sortColumn == 'start',
                                  ascending: _sortAscending,
                                  onTap: () => _toggleSort('start'),
                                ),
                                _headerCell(
                                  context: context,
                                  label: 'End',
                                  width: 210,
                                ),
                                _headerCell(
                                  context: context,
                                  label: 'Duration',
                                  width: 140,
                                  sortable: true,
                                  active: _sortColumn == 'duration',
                                  ascending: _sortAscending,
                                  onTap: () => _toggleSort('duration'),
                                ),
                                _headerCell(
                                  context: context,
                                  label: 'Start Note',
                                  width: 220,
                                ),
                                _headerCell(
                                  context: context,
                                  label: 'Stop Note',
                                  width: 220,
                                ),
                                _headerCell(
                                  context: context,
                                  label: 'Actions',
                                  width: actionColumnWidth,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Scrollbar(
                              controller: _sessionVerticalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.separated(
                                controller: _sessionVerticalScrollController,
                                itemCount: sorted.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final session = sorted[index];
                                  final startNoteText =
                                      session.startNote?.trim() ??
                                      _legacyNoteValue(
                                        session.notes,
                                        'START: ',
                                      ) ??
                                      '-';
                                  final stopNoteText =
                                      session.stopNote?.trim() ??
                                      _legacyNoteValue(
                                        session.notes,
                                        'STOP: ',
                                      ) ??
                                      '-';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SizedBox(
                                      height: rowHeight,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _textCell(
                                            _formatDateTime(session.startTime),
                                            210,
                                          ),
                                          _textCell(
                                            session.endTime == null
                                                ? 'In progress'
                                                : _formatDateTime(
                                                    session.endTime!,
                                                  ),
                                            210,
                                          ),
                                          _textCell(
                                            DateTimeFormatter.formatSeconds(
                                              session.totalSeconds,
                                            ),
                                            140,
                                          ),
                                          _noteCell(
                                            context,
                                            startNoteText,
                                            220,
                                          ),
                                          _noteCell(context, stopNoteText, 220),
                                          SizedBox(
                                            width: actionColumnWidth,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: PopupMenuButton<String>(
                                                tooltip: 'Actions',
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                                onSelected: (value) =>
                                                    _handleSessionAction(
                                                      context,
                                                      value,
                                                      session,
                                                      stopNoteText,
                                                    ),
                                                itemBuilder: (context) {
                                                  if (_isReadOnly) {
                                                    return const [
                                                      PopupMenuItem(
                                                        value: 'copyStop',
                                                        child: Text(
                                                          'Copy Stop Note',
                                                        ),
                                                      ),
                                                    ];
                                                  }

                                                  return const [
                                                    PopupMenuItem(
                                                      value: 'editStart',
                                                      child: Text(
                                                        'Edit Start Note',
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'editStop',
                                                      child: Text(
                                                        'Edit Stop Note',
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'copyStop',
                                                      child: Text(
                                                        'Copy Stop Note',
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                        'Delete Session',
                                                      ),
                                                    ),
                                                  ];
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: LinearProgressIndicator(minHeight: 2)),
              error: (error, _) => Text(
                'Failed to load sessions: $error',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  Future<void> _copyToClipboard(BuildContext context, String value) async {
    if (value.trim().isEmpty || value == '-') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  Widget _headerCell({
    required BuildContext context,
    required String label,
    required double width,
    bool sortable = false,
    bool active = false,
    bool ascending = false,
    VoidCallback? onTap,
  }) {
    final icon = ascending ? Icons.arrow_upward : Icons.arrow_downward;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: sortable ? onTap : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (sortable) ...[
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 14,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textCell(String value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _noteCell(BuildContext context, String value, double width) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: value,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
      ),
    );
  }

  String? _legacyNoteValue(String? notes, String prefix) {
    if (notes == null) return null;
    for (final rawLine in notes.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }
}
