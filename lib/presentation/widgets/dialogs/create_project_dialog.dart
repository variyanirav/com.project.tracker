import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Create New Project Dialog
class CreateProjectDialog extends StatefulWidget {
  final Function(String title, String description, String emoji)?
  onCreatePressed;

  const CreateProjectDialog({Key? key, this.onCreatePressed}) : super(key: key);

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedEmoji = '📱';

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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter project name')));
      return;
    }

    widget.onCreatePressed?.call(
      _titleController.text,
      _descriptionController.text,
      _selectedEmoji,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacing24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create New Project', style: AppTextStyles.heading2),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.spacing24),

              // Project Name Field
              Text('Project Name', style: AppTextStyles.labelMedium),
              SizedBox(height: AppConstants.spacing8),
              AppTextField(
                label: 'Enter project name',
                controller: _titleController,
                hintText: 'e.g., Mobile App Redesign',
              ),

              SizedBox(height: AppConstants.spacing20),

              // Project Description Field
              Text('Description', style: AppTextStyles.labelMedium),
              SizedBox(height: AppConstants.spacing8),
              AppTextField(
                label: 'Enter project description',
                controller: _descriptionController,
                hintText: 'Short description of the project',
                maxLines: 3,
              ),

              SizedBox(height: AppConstants.spacing20),

              // Emoji Selector
              Text('Project Avatar', style: AppTextStyles.labelMedium),
              SizedBox(height: AppConstants.spacing12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                padding: EdgeInsets.all(AppConstants.spacing16),
                child: Wrap(
                  spacing: AppConstants.spacing12,
                  runSpacing: AppConstants.spacing12,
                  children: _emojiOptions.map((emoji) {
                    final isSelected = emoji == _selectedEmoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPrimary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppConstants.roundRadius,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji, style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: AppConstants.spacing24),

              // Currently Selected Emoji Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Avatar',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing8),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                      border: Border.all(
                        color: AppColors.brandPrimary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _selectedEmoji,
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.spacing32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: AppConstants.spacing16),
                  AppButton.primary(
                    label: 'Create Project',
                    onPressed: _handleCreate,
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
