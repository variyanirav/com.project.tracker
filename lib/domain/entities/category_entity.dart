/// Category entity - Business logic model (Domain layer)
class CategoryEntity {
  final String id;
  final String name;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
