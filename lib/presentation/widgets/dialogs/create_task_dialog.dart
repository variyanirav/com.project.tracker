import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import 'manage_categories_dialog.dart';
import '../../providers/category_provider.dart';

/// Centered modal dialog for creating a task.
class CreateTaskDialog extends ConsumerStatefulWidget {
  final Future<void> Function(
    String title,
    String? description,
    String categoryId,
    double? estimatedHours,
    bool isBillable,
  )
  onCreatePressed;

  const CreateTaskDialog({super.key, required this.onCreatePressed});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  String _selectedCategoryId = AppDatabase.uncategorizedCategoryId;
  bool _isBillable = true;
  String? _titleError;
  String? _estimatedHoursError;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _validateAndCreate() async {
    setState(() {
      _titleError = null;
      _estimatedHoursError = null;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final estimatedHoursText = _estimatedHoursController.text.trim();
    double? estimatedHours;

    if (title.isEmpty) {
      setState(() => _titleError = 'Task title is required');
      return;
    }

    if (title.length < AppConstants.minTaskNameLength) {
      setState(
        () => _titleError =
            'Task title must be at least ${AppConstants.minTaskNameLength} characters',
      );
      return;
    }

    if (title.length > AppConstants.maxTaskNameLength) {
      setState(
        () => _titleError =
            'Task title can be at most ${AppConstants.maxTaskNameLength} characters',
      );
      return;
    }

    if (estimatedHoursText.isNotEmpty) {
      final parsed = double.tryParse(estimatedHoursText);
      if (parsed == null || parsed <= 0) {
        setState(() {
          _estimatedHoursError =
              'Enter estimated time in hours (for example: 1.5 or 8).';
        });
        return;
      }

      if (parsed > 500) {
        setState(() {
          _estimatedHoursError =
              'Estimated hours should be less than or equal to 500.';
        });
        return;
      }

      estimatedHours = parsed;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onCreatePressed(
        title,
        description.isNotEmpty ? description : null,
        _selectedCategoryId,
        estimatedHours,
        _isBillable,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: surface.panel,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Task',
                          style: AppTypography.sectionTitle.copyWith(
                            color: surface.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing4),
                        Text(
                          'Create a task with clear scope and context.',
                          style: AppTypography.bodySmall.copyWith(
                            color: surface.textSecondary,
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
            ),
            Divider(height: 1, color: surface.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      maxLength: AppConstants.maxTaskNameLength,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'Enter a clear task title',
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                    ),
                    if (_titleError != null) ...[
                      const SizedBox(height: AppConstants.spacing4),
                      Text(
                        _titleError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacing12),
                    ref
                        .watch(categoriesProvider)
                        .when(
                          data: (categories) {
                            if (categories.isNotEmpty &&
                                !categories.any(
                                  (c) => c.id == _selectedCategoryId,
                                )) {
                              _selectedCategoryId = categories.first.id;
                            }

                            final items = categories.isEmpty
                                ? const [
                                    DropdownMenuItem<String>(
                                      value:
                                          AppDatabase.uncategorizedCategoryId,
                                      child: Text('Uncategorized'),
                                    ),
                                  ]
                                : categories
                                      .map(
                                        (category) => DropdownMenuItem<String>(
                                          value: category.id,
                                          child: Text(category.name),
                                        ),
                                      )
                                      .toList();

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: items,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedCategoryId = value,
                                        );
                                      }
                                    },
                            );
                          },
                          loading: () =>
                              const LinearProgressIndicator(minHeight: 2),
                          error: (_, __) => DropdownButtonFormField<String>(
                            initialValue: AppDatabase.uncategorizedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                value: AppDatabase.uncategorizedCategoryId,
                                child: Text('Uncategorized'),
                              ),
                            ],
                            onChanged: _isSaving ? null : (_) {},
                          ),
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                await showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      const ManageCategoriesDialog(),
                                );
                                ref.invalidate(categoriesProvider);
                              },
                        icon: const Icon(Icons.category_outlined),
                        label: const Text('Manage Categories'),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    TextField(
                      controller: _estimatedHoursController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Estimated Hours (Optional)',
                        hintText: 'Enter hours only, e.g. 8 or 2.5',
                        helperText:
                            'Use hours, not days. Leave empty if you do not want to estimate.',
                      ),
                      onChanged: (_) {
                        if (_estimatedHoursError != null) {
                          setState(() => _estimatedHoursError = null);
                        }
                      },
                    ),
                    if (_estimatedHoursError != null) ...[
                      const SizedBox(height: AppConstants.spacing4),
                      Text(
                        _estimatedHoursError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacing12),
                    DropdownButtonFormField<bool>(
                      initialValue: _isBillable,
                      decoration: const InputDecoration(
                        labelText: 'Billing Type',
                      ),
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
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _isBillable = value);
                              }
                            },
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: AppConstants.maxDescriptionLength,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Add optional details, acceptance notes, or context',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: surface.border),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: 'Cancel',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  AppButton.primary(
                    label: _isSaving ? 'Creating...' : 'Create Task',
                    onPressed: _isSaving ? null : _validateAndCreate,
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
