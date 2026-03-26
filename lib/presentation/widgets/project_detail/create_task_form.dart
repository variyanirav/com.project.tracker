import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import '../../../core/constants/app_strings.dart';
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.labels.taskTitle,
              hintText: AppStrings.labels.taskTitleHint,
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
                    decoration: InputDecoration(
                      labelText: 'Category',
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
                  decoration: InputDecoration(
                    labelText: 'Category',
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
            decoration: InputDecoration(
              labelText: AppStrings.labels.description,
              hintText: AppStrings.labels.descriptionHint,
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
