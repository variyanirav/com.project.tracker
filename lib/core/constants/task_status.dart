import 'package:flutter/material.dart';

/// Task status enum - Shared across the app
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  inReview('In Review'),
  onHold('On Hold'),
  complete('Complete');

  final String label;
  const TaskStatus(this.label);

  /// Get color for this status
  Color getColor() {
    switch (this) {
      case TaskStatus.todo:
        return const Color(0xFF64748B); // Gray
      case TaskStatus.inProgress:
        return const Color(0xFF007BFF); // Blue
      case TaskStatus.inReview:
        return const Color(0xFFFCD34D); // Amber
      case TaskStatus.onHold:
        return const Color(0xFFFB923C); // Orange
      case TaskStatus.complete:
        return const Color(0xFF10B981); // Green
    }
  }
}
