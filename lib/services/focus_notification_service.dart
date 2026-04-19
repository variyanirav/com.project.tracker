import 'dart:io';

import '../domain/entities/focus_run_state_entity.dart';

/// Best-effort desktop notification service with safe fallback behavior.
class FocusNotificationService {
  Future<bool> notifyPhaseChange(FocusRunPhase phase) async {
    final payload = _payloadForPhase(phase);
    if (payload == null) {
      return false;
    }

    try {
      if (Platform.isMacOS) {
        final title = _escapeAppleScript(payload.title);
        final body = _escapeAppleScript(payload.body);
        final script =
            'display notification "$body" with title "$title" subtitle "Project Tracker"';
        final result = await Process.run('osascript', ['-e', script]);
        return result.exitCode == 0;
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  ({String title, String body})? _payloadForPhase(FocusRunPhase phase) {
    switch (phase) {
      case FocusRunPhase.shortBreak:
      case FocusRunPhase.longBreak:
        return (
          title: 'Break Started',
          body: 'Time to stand up and reset for a moment.',
        );
      case FocusRunPhase.focus:
        return (
          title: 'Focus Resumed',
          body: 'Break ended. Back to focused work.',
        );
      case FocusRunPhase.completed:
        return (
          title: 'Goal Complete',
          body: 'Great work. Your focus target is complete.',
        );
      case FocusRunPhase.idle:
      case FocusRunPhase.paused:
        return null;
    }
  }

  String _escapeAppleScript(String input) {
    return input.replaceAll(r'"', r'\"').replaceAll('"', r'\"');
  }
}
