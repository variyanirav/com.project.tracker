import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';

Future<String?> showTimerSessionNoteDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');

  void insertText(String text) {
    final selection = controller.selection;
    final currentText = controller.text;

    if (!selection.isValid || selection.isCollapsed) {
      final cursorPosition = selection.isValid && selection.start >= 0
          ? selection.start
          : currentText.length;
      final updatedText = currentText.replaceRange(
        cursorPosition,
        cursorPosition,
        text,
      );
      controller.value = controller.value.copyWith(
        text: updatedText,
        selection: TextSelection.collapsed(
          offset: cursorPosition + text.length,
        ),
        composing: TextRange.empty,
      );
      return;
    }

    final selectedText = selection.textInside(currentText);
    final wrappedText = '$text$selectedText$text';
    controller.value = controller.value.copyWith(
      text:
          selection.textBefore(currentText) +
          wrappedText +
          selection.textAfter(currentText),
      selection: TextSelection.collapsed(
        offset: selection.start + wrappedText.length,
      ),
      composing: TextRange.empty,
    );
  }

  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final surface = AppSurfaceTokens(isDark: isDark);

      return AlertDialog(
        backgroundColor: surface.panel,
        title: Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            color: surface.textPrimary,
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 560),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FormatChip(
                    label: 'Bullet',
                    onPressed: () => insertText('- '),
                  ),
                  _FormatChip(
                    label: 'Number',
                    onPressed: () => insertText('1. '),
                  ),
                  _FormatChip(label: 'Bold', onPressed: () => insertText('**')),
                  _FormatChip(
                    label: 'Italic',
                    onPressed: () => insertText('_'),
                  ),
                  _FormatChip(
                    label: 'Underline',
                    onPressed: () => insertText('[u]'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Scrollbar(
                  child: TextField(
                    controller: controller,
                    minLines: 6,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: formatting is stored as plain text markers so it stays lightweight.',
                style: AppTypography.helper.copyWith(
                  color: surface.textSecondary,
                ),
              ),
            ],
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

  // Dispose after the current frame so pending caret/selection callbacks
  // do not access a disposed controller during dialog close animations.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
  return value;
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: surface.border),
      ),
      child: Text(
        label,
        style: AppTypography.actionLabel.copyWith(color: surface.textPrimary),
      ),
    );
  }
}
