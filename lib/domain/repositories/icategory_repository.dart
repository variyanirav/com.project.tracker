import '../entities/category_entity.dart';

/// Abstract repository for category operations.
abstract class ICategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();

  Future<CategoryEntity?> getCategoryById(String id);

  Future<CategoryEntity> createCategory({
    required String name,
    String? colorHex,
  });

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(
    String categoryId, {
    required String fallbackCategoryId,
  });
}
