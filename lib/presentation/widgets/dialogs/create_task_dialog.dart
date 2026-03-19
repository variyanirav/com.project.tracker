import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Create Task Dialog
/// Opens as a modal dialog to create a new task for a project
class CreateTaskDialog extends StatefulWidget {
  final Function(String title, String description, TaskStatus status)
  onCreatePressed;

  const CreateTaskDialog({super.key, required this.onCreatePressed});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  TaskStatus _selectedStatus = TaskStatus.todo;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateAndCreate() {
    // Clear previous error
    setState(() => _titleError = null);

    // Validate title
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter task name');
      return;
    }

    if (_titleController.text.length < 3) {
      setState(() => _titleError = 'Task name must be at least 3 characters');
      return;
    }

    // Call callback and close dialog
    widget.onCreatePressed(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedStatus,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create New Task', style: AppTextStyles.heading2),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Title Field
                    Text('Task Name', style: AppTextStyles.labelMedium),
                    SizedBox(height: AppConstants.spacing8),
                    AppTextField(
                      controller: _titleController,
                      label: 'Enter task name',
                      keyboardType: TextInputType.text,
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                    ),
                    if (_titleError != null) ...[
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        _titleError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                    SizedBox(height: AppConstants.spacing16),

                    // Description Field
                    Text('Description', style: AppTextStyles.labelMedium),
                    SizedBox(height: AppConstants.spacing8),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Enter task description (optional)',
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                    SizedBox(height: AppConstants.spacing16),

                    // Status Dropdown
                    Text('Status', style: AppTextStyles.labelMedium),
                    SizedBox(height: AppConstants.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
              ),
            ),
            Divider(height: 1),
            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  AppButton.primary(
                    label: 'Create Task',
                    onPressed: _validateAndCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
