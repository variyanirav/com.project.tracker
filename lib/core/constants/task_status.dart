import 'package:flutter/material.dart';

/// Task status enum - Shared across the app
enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('inProgress', 'In Progress'),
  inReview('inReview', 'In Review'),
  onHold('onHold', 'On Hold'),
  complete('complete', 'Complete'),
  archived('archived', 'Archived');

  final String code;
  final String label;
  const TaskStatus(this.code, this.label);

  /// Parse a task status from code or label.
  static TaskStatus? tryParse(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;

    final normalized = _normalizeStatusValue(rawValue);
    for (final status in TaskStatus.values) {
      if (_normalizeStatusValue(status.code) == normalized ||
          _normalizeStatusValue(status.label) == normalized) {
        return status;
      }
    }

    return null;
  }

  /// Parse with a fallback for unknown values.
  static TaskStatus fromValue(
    String? rawValue, {
    TaskStatus fallback = TaskStatus.todo,
  }) {
    return tryParse(rawValue) ?? fallback;
  }

  /// Convert raw stored status into UI-safe human readable text.
  static String formatLabel(String? rawValue) {
    final parsed = tryParse(rawValue);
    if (parsed != null) {
      return parsed.label;
    }

    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return '';
    return _titleCaseStatus(value);
  }

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
      case TaskStatus.archived:
        return const Color(0xFF64748B); // Gray
    }
  }
}

String _normalizeStatusValue(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]+'), '');
}

String _titleCaseStatus(String value) {
  final withSpaces = value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim();

  if (withSpaces.isEmpty) return withSpaces;

  return withSpaces
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}
