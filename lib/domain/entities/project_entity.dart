/// Project entity - Business logic model (Domain layer)
class ProjectEntity {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectEntity({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProjectEntity(id: $id, name: $name, status: $status)';
  }
}
