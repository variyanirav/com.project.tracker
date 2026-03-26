import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/category_entity.dart';

import '../../providers/category_provider.dart';

/// User-facing category management dialog.
/// Allows creating, renaming, and deleting categories.
class ManageCategoriesDialog extends ConsumerStatefulWidget {
  const ManageCategoriesDialog({super.key});

  @override
  ConsumerState<ManageCategoriesDialog> createState() =>
      _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState
    extends ConsumerState<ManageCategoriesDialog> {
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

  Future<void> _showEditDialog(CategoryEntity category) async {
    final controller = TextEditingController(text: category.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result.isEmpty) {
      _showMessage('Category name is required', isError: true);
      return;
    }

    if (result == category.name) {
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

  Future<void> _showDeleteDialog(
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
                    'Delete "${category.name}"? Tasks using this category will be reassigned.',
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
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
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createCategory,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ref
                    .watch(categoriesProvider)
                    .when(
                      data: (categories) {
                        if (categories.isEmpty) {
                          return const Center(
                            child: Text('No categories available'),
                          );
                        }

                        return ListView.separated(
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isUncategorized =
                                category.id ==
                                AppDatabase.uncategorizedCategoryId;

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
                                    onPressed: () => _showEditDialog(category),
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
                                        : () => _showDeleteDialog(
                                            category,
                                            categories,
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('Failed to load categories: $error'),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
