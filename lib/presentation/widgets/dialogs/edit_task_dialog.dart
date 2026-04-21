import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../providers/category_provider.dart';

/// Edit Task Dialog
/// Opens as a modal dialog to edit an existing task
class EditTaskDialog extends ConsumerStatefulWidget {
  final String taskId;
  final String? initialCategoryId;
  final String initialTitle;
  final String initialDescription;
  final double? initialEstimatedHours;
  final bool initialIsBillable;
  final TaskStatus initialStatus;
  final Function(
    String taskId,
    String categoryId,
    String title,
    String description,
    double? estimatedHours,
    TaskStatus status,
    bool isBillable,
  )
  onSavePressed;

  const EditTaskDialog({
    super.key,
    required this.taskId,
    this.initialCategoryId,
    required this.initialTitle,
    required this.initialDescription,
    this.initialEstimatedHours,
    this.initialIsBillable = true,
    required this.initialStatus,
    required this.onSavePressed,
  });

  @override
  ConsumerState<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedHoursController;
  late TaskStatus _selectedStatus;
  late String _selectedCategoryId;
  late bool _isBillable;
  String? _titleError;
  String? _estimatedHoursError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _estimatedHoursController = TextEditingController(
      text: widget.initialEstimatedHours?.toString() ?? '',
    );
    _selectedStatus = widget.initialStatus;
    _selectedCategoryId =
        widget.initialCategoryId ?? AppDatabase.uncategorizedCategoryId;
    _isBillable = widget.initialIsBillable;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    setState(() {
      _titleError = null;
      _estimatedHoursError = null;
    });

    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter task name');
      return;
    }

    if (_titleController.text.length < 3) {
      setState(() => _titleError = 'Task name must be at least 3 characters');
      return;
    }

    final estimatedHoursText = _estimatedHoursController.text.trim();
    double? estimatedHours;
    if (estimatedHoursText.isNotEmpty) {
      estimatedHours = double.tryParse(estimatedHoursText);
      if (estimatedHours == null || estimatedHours <= 0) {
        setState(() {
          _estimatedHoursError =
              'Enter estimated time in hours (for example: 1.5 or 8).';
        });
        return;
      }

      if (estimatedHours > 500) {
        setState(() {
          _estimatedHoursError =
              'Estimated hours should be less than or equal to 500.';
        });
        return;
      }
    }

    widget.onSavePressed(
      widget.taskId,
      _selectedCategoryId,
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      estimatedHours,
      _selectedStatus,
      _isBillable,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        child: Container(
          width: screenSize.width > 600 ? 500 : screenSize.width - 40,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: surface.panel,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Task',
                    style: AppTypography.sectionTitle.copyWith(
                      color: surface.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Task Title Field
              Text(
                'Task Name',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter task name',
                  hintStyle: AppTypography.helper.copyWith(
                    color: surface.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _titleError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              Text(
                'Description (Optional)',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter task description',
                  hintStyle: AppTypography.helper.copyWith(
                    color: surface.textMuted,
                  ),
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

              Text(
                'Estimated Hours (Optional)',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _estimatedHoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Hours only (e.g. 8 or 2.5)',
                  helperText: 'Enter hours, not days',
                  hintStyle: AppTypography.helper.copyWith(
                    color: surface.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _estimatedHoursError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) {
                  if (_estimatedHoursError != null) {
                    setState(() => _estimatedHoursError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Text(
                'Category',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ref
                  .watch(categoriesProvider)
                  .when(
                    data: (categories) {
                      final selectedExists = categories.any(
                        (c) => c.id == _selectedCategoryId,
                      );
                      if (!selectedExists && categories.isNotEmpty) {
                        _selectedCategoryId = categories.first.id;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: surface.border),
                          borderRadius: BorderRadius.circular(8),
                          color: surface.panelHigh,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (categoryId) {
                            if (categoryId == null) return;
                            setState(() => _selectedCategoryId = categoryId);
                          },
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: surface.border),
                        borderRadius: BorderRadius.circular(8),
                        color: surface.panelHigh,
                      ),
                      child: DropdownButton<String>(
                        value: AppDatabase.uncategorizedCategoryId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem<String>(
                            value: AppDatabase.uncategorizedCategoryId,
                            child: Text('Uncategorized'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                  ),
              const SizedBox(height: 16),

              Text(
                'Billing Type',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: surface.border),
                  borderRadius: BorderRadius.circular(8),
                  color: surface.panelHigh,
                ),
                child: DropdownButton<bool>(
                  value: _isBillable,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem<bool>(
                      value: true,
                      child: Text('Billable'),
                    ),
                    DropdownMenuItem<bool>(
                      value: false,
                      child: Text('Non-billable'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _isBillable = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              Text(
                'Status',
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: surface.border),
                  borderRadius: BorderRadius.circular(8),
                  color: surface.panelHigh,
                ),
                child: DropdownButton<TaskStatus>(
                  value: _selectedStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: TaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) {
                      setState(() => _selectedStatus = status);
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTypography.actionLabel.copyWith(
                        color: surface.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _validateAndSave,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
