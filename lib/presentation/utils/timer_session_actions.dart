import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../providers/timer_provider.dart';
import '../widgets/dialogs/timer_session_note_dialog.dart';

Future<void> stopTimerWithOutcomeNote(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final stopNote = await showTimerSessionNoteDialog(
      context,
      title: 'Session Outcome',
      hintText: 'What did you complete in this session?',
    );

    await ref.read(timerProvider.notifier).stopTimer(stopNote: stopNote);
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.messages.timerOperationError('$e')),
        backgroundColor: Colors.red,
      ),
    );
  }
}
