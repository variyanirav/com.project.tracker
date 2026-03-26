import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/category_entity.dart';

import 'repository_provider.dart';

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final categories = await repository.getAllCategories();

  if (categories.isNotEmpty) {
    return categories;
  }

  return [
    CategoryEntity(
      id: AppDatabase.uncategorizedCategoryId,
      name: 'Uncategorized',
      colorHex: '#9E9E9E',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];
});

final categoryByIdProvider = FutureProvider.family<CategoryEntity?, String>((
  ref,
  categoryId,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});

final createCategoryProvider =
    FutureProvider.family<void, CreateCategoryParams>((ref, params) async {
      await ref
          .watch(categoryRepositoryProvider)
          .createCategory(name: params.name, colorHex: params.colorHex);

      ref.invalidate(categoriesProvider);
    });

final updateCategoryProvider = FutureProvider.family<void, CategoryEntity>((
  ref,
  category,
) async {
  await ref.watch(categoryRepositoryProvider).updateCategory(category);

  ref.invalidate(categoriesProvider);
  ref.invalidate(categoryByIdProvider(category.id));
});

final deleteCategoryProvider =
    FutureProvider.family<void, DeleteCategoryParams>((ref, params) async {
      await ref
          .watch(categoryRepositoryProvider)
          .deleteCategory(
            params.categoryId,
            fallbackCategoryId: params.fallbackCategoryId,
          );

      ref.invalidate(categoriesProvider);
    });

class CreateCategoryParams {
  final String name;
  final String? colorHex;

  const CreateCategoryParams({required this.name, this.colorHex});
}

class DeleteCategoryParams {
  final String categoryId;
  final String fallbackCategoryId;

  const DeleteCategoryParams({
    required this.categoryId,
    this.fallbackCategoryId = AppDatabase.uncategorizedCategoryId,
  });
}
