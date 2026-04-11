import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/database/app_database.dart';
import '../../providers/project_provider.dart';
import '../../providers/todo_provider.dart';

class UpsertTodoDialog extends ConsumerStatefulWidget {
  final TodoItemData? existingTodo;
  final Future<void> Function(CreateTodoParams params) onCreate;
  final Future<void> Function(UpdateTodoParams params) onUpdate;

  const UpsertTodoDialog({
    super.key,
    this.existingTodo,
    required this.onCreate,
    required this.onUpdate,
  });

  @override
  ConsumerState<UpsertTodoDialog> createState() => _UpsertTodoDialogState();
}

class _UpsertTodoDialogState extends ConsumerState<UpsertTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceUrlController = TextEditingController();

  String _status = todoStatusOpen;
  String _priority = todoPriorityMedium;
  String? _linkedProjectId;
  DateTime? _dueDate;
  DateTime? _snoozedUntil;
  bool _isSaving = false;

  bool get _isEditing => widget.existingTodo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.existingTodo;
    if (todo != null) {
      _titleController.text = todo.title;
      _descriptionController.text = todo.description;
      _referenceUrlController.text = todo.referenceUrl ?? '';
      _status = todo.status;
      _priority = todo.priority;
      _linkedProjectId = todo.linkedProjectId;
      _dueDate = todo.dueDate;
      _snoozedUntil = todo.snoozedUntil;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppConstants.spacing24),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit To-Do' : 'New To-Do',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: AppConstants.spacing4),
                          Text(
                            'Capture reminders, ideas, and follow-ups quickly.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing20),
                TextFormField(
                  controller: _titleController,
                  maxLength: AppConstants.maxTodoTitleLength,
                  decoration: const InputDecoration(labelText: 'Task title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Title must be at least 2 characters';
                    }
                    if (value.trim().length > AppConstants.maxTodoTitleLength) {
                      return 'Title must be ${AppConstants.maxTodoTitleLength} characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacing16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details or context for this to-do item',
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),
                TextFormField(
                  controller: _referenceUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Reference link (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: todoPriorityLow,
                            child: Text('Low'),
                          ),
                          DropdownMenuItem(
                            value: todoPriorityMedium,
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(
                            value: todoPriorityHigh,
                            child: Text('High'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _priority = value);
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: todoStatusOpen,
                            child: Text('Open'),
                          ),
                          DropdownMenuItem(
                            value: todoStatusInProgress,
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: todoStatusDone,
                            child: Text('Done'),
                          ),
                          DropdownMenuItem(
                            value: todoStatusSnoozed,
                            child: Text('Snoozed'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Due date',
                        date: _dueDate,
                        onPickDate: _isSaving
                            ? null
                            : (date) => setState(() => _dueDate = date),
                        onClearDate: _isSaving
                            ? null
                            : () => setState(() => _dueDate = null),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing16),
                    Expanded(
                      child: _DateField(
                        label: 'Snoozed until',
                        date: _snoozedUntil,
                        onPickDate: _isSaving
                            ? null
                            : (date) => setState(() => _snoozedUntil = date),
                        onClearDate: _isSaving
                            ? null
                            : () => setState(() => _snoozedUntil = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing16),
                projectsAsync.when(
                  data: (projects) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _linkedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Link to project (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...projects.map(
                          (project) => DropdownMenuItem<String?>(
                            value: project.id,
                            child: Text(project.name),
                          ),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _linkedProjectId = value),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppConstants.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(_isEditing ? 'Update To-Do' : 'Save To-Do'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await widget.onUpdate(
          UpdateTodoParams(
            id: widget.existingTodo!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            status: _status,
            priority: _priority,
            referenceUrl: _referenceUrlController.text,
            linkedProjectId: _linkedProjectId,
            dueDate: _dueDate,
            snoozedUntil: _snoozedUntil,
          ),
        );
      } else {
        await widget.onCreate(
          CreateTodoParams(
            title: _titleController.text,
            description: _descriptionController.text,
            status: _status,
            priority: _priority,
            referenceUrl: _referenceUrlController.text,
            linkedProjectId: _linkedProjectId,
            dueDate: _dueDate,
            snoozedUntil: _snoozedUntil,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime>? onPickDate;
  final VoidCallback? onClearDate;

  const _DateField({
    required this.label,
    required this.date,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date == null
                  ? 'Not set'
                  : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: date == null
                    ? (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary)
                    : null,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Pick date',
            onPressed: onPickDate == null
                ? null
                : () async {
                    final now = DateTime.now();
                    final result = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 10),
                      initialDate: date ?? now,
                    );
                    if (result != null) {
                      onPickDate!(result.toUtc());
                    }
                  },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Clear date',
            onPressed: date == null ? null : onClearDate,
            icon: const Icon(Icons.clear, size: 18),
          ),
        ],
      ),
    );
  }
}
