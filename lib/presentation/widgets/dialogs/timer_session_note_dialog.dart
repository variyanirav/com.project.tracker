import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';

Future<String?> showTimerSessionNoteDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue ?? '');

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          AppButton.secondary(
            label: 'Skip',
            onPressed: () => Navigator.of(dialogContext).pop(''),
          ),
          AppButton.primary(
            label: 'Save',
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          ),
        ],
      );
    },
  );
}
