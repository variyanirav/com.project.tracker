import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Edit Project Dialog
/// Opens as a modal dialog to edit an existing project
class EditProjectDialog extends StatefulWidget {
  final String projectId;
  final String initialName;
  final String initialDescription;
  final String initialEmoji;
  final Function(
    String projectId,
    String name,
    String description,
    String emoji,
  )
  onSavePressed;

  const EditProjectDialog({
    super.key,
    required this.projectId,
    required this.initialName,
    required this.initialDescription,
    required this.initialEmoji,
    required this.onSavePressed,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedEmoji;
  String? _nameError;

  final List<String> _emojiOptions = [
    '📱',
    '💻',
    '🎨',
    '⚙️',
    '📊',
    '🚀',
    '🔧',
    '📈',
    '🎯',
    '💡',
    '📝',
    '🔒',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _selectedEmoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    setState(() => _nameError = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter project name');
      return;
    }

    widget.onSavePressed(
      widget.projectId,
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      _selectedEmoji,
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
        constraints: const BoxConstraints(maxHeight: 750),
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
                  Text('Edit Project', style: AppTextStyles.heading2),
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
                    // Project Name Field
                    Text('Project Name', style: AppTextStyles.labelMedium),
                    SizedBox(height: AppConstants.spacing8),
                    AppTextField(
                      controller: _nameController,
                      label: 'Enter project name',
                      keyboardType: TextInputType.text,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    if (_nameError != null) ...[
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        _nameError!,
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
                      label: 'Enter project description (optional)',
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                    SizedBox(height: AppConstants.spacing24),

                    // Emoji Selector
                    Text('Project Avatar', style: AppTextStyles.labelMedium),
                    SizedBox(height: AppConstants.spacing12),
                    Wrap(
                      spacing: AppConstants.spacing12,
                      runSpacing: AppConstants.spacing12,
                      children: _emojiOptions.map((emoji) {
                        final isSelected = emoji == _selectedEmoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEmoji = emoji);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandPrimary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              color: isSelected
                                  ? AppColors.brandPrimary.withValues(
                                      alpha: 0.1,
                                    )
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: AppConstants.spacing16),

                    // Selected Avatar Display
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Selected Avatar: ',
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
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
                    label: 'Save Project',
                    onPressed: _validateAndSave,
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
