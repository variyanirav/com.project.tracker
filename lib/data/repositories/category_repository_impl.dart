import 'package:drift/drift.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';
import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/domain/entities/category_entity.dart';
import 'package:project_tracker/domain/repositories/icategory_repository.dart';
import 'package:uuid/uuid.dart';

/// Concrete implementation of ICategoryRepository.
class CategoryRepositoryImpl implements ICategoryRepository {
  final AppDatabase db;

  CategoryRepositoryImpl(this.db);

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final rows = await db.categoriesDao.getAllCategories();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    final row = await db.categoriesDao.getCategoryById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<CategoryEntity> createCategory({
    required String name,
    String? colorHex,
  }) async {
    final now = TimezoneHelper.getCurrentUtc();
    final entity = CategoryData(
      id: const Uuid().v4(),
      name: name.trim(),
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );

    await db.categoriesDao.createCategory(entity);
    return _toEntity(entity);
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await db.categoriesDao.updateCategory(
      CategoryData(
        id: category.id,
        name: category.name.trim(),
        colorHex: category.colorHex,
        createdAt: category.createdAt,
        updatedAt: TimezoneHelper.getCurrentUtc(),
      ),
    );
  }

  @override
  Future<void> deleteCategory(
    String categoryId, {
    required String fallbackCategoryId,
  }) async {
    if (categoryId == AppDatabase.uncategorizedCategoryId) {
      throw StateError('Uncategorized category cannot be deleted');
    }

    await (db.update(db.tasks)..where((t) => t.categoryId.equals(categoryId)))
        .write(TasksCompanion(categoryId: Value(fallbackCategoryId)));

    await db.categoriesDao.deleteCategory(categoryId);
  }

  CategoryEntity _toEntity(CategoryData row) {
    return CategoryEntity(
      id: row.id,
      name: row.name,
      colorHex: row.colorHex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
