import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/category_provider.dart';

/// Form for creating a new task
class CreateTaskForm extends ConsumerStatefulWidget {
  final Function(String title, String? description, String categoryId)
  onCreateTask;

  const CreateTaskForm({super.key, required this.onCreateTask});

  @override
  ConsumerState<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends ConsumerState<CreateTaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategoryId = AppDatabase.uncategorizedCategoryId;

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

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task title field
          TextField(
            controller: _titleController,
            maxLength: AppConstants.maxTaskNameLength,
            decoration: InputDecoration(
              labelText: AppStrings.labels.taskTitle,
              hintText: AppStrings.labels.taskTitleHint,
              labelStyle: AppTypography.label.copyWith(
                color: surface.textSecondary,
              ),
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
              counterText: 'Max ${AppConstants.maxTaskNameLength} characters',
            ),
          ),
          const SizedBox(height: 12),
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

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    dropdownColor: surface.panel,
                    style: AppTypography.body.copyWith(
                      color: surface.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: AppTypography.label.copyWith(
                        color: surface.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCategoryId = value);
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, __) => DropdownButtonFormField<String>(
                  initialValue: AppDatabase.uncategorizedCategoryId,
                  dropdownColor: surface.panel,
                  style: AppTypography.body.copyWith(
                    color: surface.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: AppTypography.label.copyWith(
                      color: surface.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: AppDatabase.uncategorizedCategoryId,
                      child: Text('Uncategorized'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
          const SizedBox(height: 12),
          // Description field
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: AppConstants.maxDescriptionLength,
            decoration: InputDecoration(
              labelText: AppStrings.labels.description,
              hintText: AppStrings.labels.descriptionHint,
              labelStyle: AppTypography.label.copyWith(
                color: surface.textSecondary,
              ),
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
          // Create button
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: AppStrings.buttons.createTask,
              onPressed: () {
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.validation.taskTitleEmpty),
                    ),
                  );
                  return;
                }

                if (title.length < AppConstants.minTaskNameLength) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Task title must be at least ${AppConstants.minTaskNameLength} characters.',
                      ),
                    ),
                  );
                  return;
                }

                if (title.length > AppConstants.maxTaskNameLength) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Task title can be up to ${AppConstants.maxTaskNameLength} characters.',
                      ),
                    ),
                  );
                  return;
                }

                widget.onCreateTask(
                  title,
                  description.isNotEmpty ? description : null,
                  _selectedCategoryId,
                );
                _clearForm();
              },
            ),
          ),
        ],
      ),
    );
  }
}
