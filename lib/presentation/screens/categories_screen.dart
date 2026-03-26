import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/category_entity.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../providers/category_provider.dart';
import '../providers/repository_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/daily_goal_settings_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      _showMessage('Category name is required', isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      await ref.read(
        createCategoryProvider(CreateCategoryParams(name: name)).future,
      );
      _newCategoryController.clear();
      _showMessage('Category created successfully');
    } catch (_) {
      _showMessage(
        'Unable to create category. Name may already exist.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _editCategory(CategoryEntity category) async {
    final controller = TextEditingController(text: category.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result == category.name) {
      return;
    }

    if (result.isEmpty) {
      _showMessage('Category name is required', isError: true);
      return;
    }

    try {
      await ref.read(
        updateCategoryProvider(
          category.copyWith(name: result, updatedAt: DateTime.now().toUtc()),
        ).future,
      );
      _showMessage('Category updated successfully');
    } catch (_) {
      _showMessage(
        'Unable to update category. Name may already exist.',
        isError: true,
      );
    }
  }

  Future<void> _deleteCategory(
    CategoryEntity category,
    List<CategoryEntity> allCategories,
  ) async {
    if (category.id == AppDatabase.uncategorizedCategoryId) {
      _showMessage('Uncategorized category cannot be deleted', isError: true);
      return;
    }

    final fallbackOptions = allCategories
        .where((c) => c.id != category.id)
        .toList();

    if (fallbackOptions.isEmpty) {
      _showMessage(
        'No fallback category available for reassignment',
        isError: true,
      );
      return;
    }

    var fallbackId =
        fallbackOptions.any((c) => c.id == AppDatabase.uncategorizedCategoryId)
        ? AppDatabase.uncategorizedCategoryId
        : fallbackOptions.first.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Delete Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete "${category.name}"? Existing tasks will be reassigned.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: fallbackId,
                    decoration: const InputDecoration(
                      labelText: 'Reassign tasks to',
                      border: OutlineInputBorder(),
                    ),
                    items: fallbackOptions
                        .map(
                          (fallback) => DropdownMenuItem<String>(
                            value: fallback.id,
                            child: Text(fallback.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => fallbackId = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(
        deleteCategoryProvider(
          DeleteCategoryParams(
            categoryId: category.id,
            fallbackCategoryId: fallbackId,
          ),
        ).future,
      );
      _showMessage('Category deleted successfully');
    } catch (_) {
      _showMessage('Unable to delete category', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyGoalHoursAsync = ref.watch(dailyGoalProvider);

    return CustomScaffold(
      activeRoute: AppRouter.categories,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Daily Goal Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DailyGoalSettingsDialog(
                    currentGoalHours: dailyGoalHoursAsync.when(
                      data: (hours) => hours.round(),
                      loading: () => 8,
                      error: (_, __) => 8,
                    ),
                    onSavePressed: (hours) async {
                      await ref
                          .read(dailyGoalRepositoryProvider)
                          .setDailyGoal(hours * 60);

                      ref.invalidate(dailyGoalProvider);
                      ref.invalidate(dailyProgressProvider);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Daily goal set to $hours hours'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Tooltip(
            message: ref.watch(themeProvider) ? 'Light Mode' : 'Dark Mode',
            child: IconButton(
              icon: Icon(
                ref.watch(themeProvider) ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacing4),
            Text(
              'Create and control task categories used across tasks and reports.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'New category name',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          if (!_isCreating) {
                            _createCategory();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createCategory,
                        icon: _isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing16),
            ref
                .watch(categoriesProvider)
                .when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Center(
                        child: Text('No categories available'),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppConstants.spacing8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isUncategorized =
                            category.id == AppDatabase.uncategorizedCategoryId;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          title: Text(category.name),
                          subtitle: isUncategorized
                              ? const Text('System fallback category')
                              : null,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isUncategorized
                                      ? Colors.grey
                                      : Colors.red,
                                ),
                                onPressed: isUncategorized
                                    ? null
                                    : () =>
                                          _deleteCategory(category, categories),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Failed to load categories: $error')),
                ),
          ],
        ),
      ),
    );
  }
}
