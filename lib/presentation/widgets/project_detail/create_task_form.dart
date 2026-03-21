import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Form for creating a new task
class CreateTaskForm extends StatefulWidget {
  final Function(String title, String? description) onCreateTask;

  const CreateTaskForm({super.key, required this.onCreateTask});

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

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
