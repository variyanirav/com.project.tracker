import 'package:project_tracker/data/database/app_database.dart';
import 'package:project_tracker/core/utils/timezone_helper.dart';

/// ProjectModel represents a Project entity in the application
/// Extends database ProjectData with computed properties and formatters
class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String avatarEmoji;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed/derived fields (calculated from related data)
  final double totalHours;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarEmoji,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.totalHours = 0.0,
  });

  /// Create ProjectModel from database ProjectData
  factory ProjectModel.fromProjectData(
    ProjectData data, {
    double totalHours = 0.0,
  }) {
    return ProjectModel(
      id: data.id,
      name: data.name,
      description: data.description ?? '',
      avatarEmoji: data.avatarEmoji,
      status: data.status,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      totalHours: totalHours,
    );
  }

  /// Convert ProjectModel back to database ProjectData
  ProjectData toProjectData() {
    return ProjectData(
      id: id,
      name: name,
      description: description,
      avatarEmoji: avatarEmoji,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get formatted creation date for display
  String get formattedCreatedAt => TimezoneHelper.formatForDisplay(createdAt);

  /// Get formatted last update date for display
  String get formattedUpdatedAt => TimezoneHelper.formatForDisplay(updatedAt);

  /// Get display-ready total hours (e.g., "45.5 hours")
  String get displayTotalHours {
    if (totalHours == 0) return '0 hours';
    if (totalHours < 1) {
      final minutes = (totalHours * 60).toStringAsFixed(0);
      return '$minutes minutes';
    }
    final rounded = totalHours.toStringAsFixed(1);
    return '$rounded hours';
  }

  /// Check if project is active
  bool get isActive => status == 'active';

  /// Check if project is completed
  bool get isCompleted => status == 'complete';

  /// Check if project is on hold
  bool get isOnHold => status == 'paused';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'ProjectModel(id: $id, name: $name, status: $status, totalHours: $totalHours)';
}
