import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/focus_cycle_template_entity.dart';
import '../../../domain/entities/focus_goal_entity.dart';

class FocusTimerSettingsResult {
  const FocusTimerSettingsResult({required this.goal, required this.template});

  final FocusGoalEntity goal;
  final FocusCycleTemplateEntity template;
}

class FocusTimerSettingsDialog extends StatefulWidget {
  const FocusTimerSettingsDialog({
    super.key,
    required this.initialGoal,
    required this.initialTemplate,
  });

  final FocusGoalEntity initialGoal;
  final FocusCycleTemplateEntity initialTemplate;

  @override
  State<FocusTimerSettingsDialog> createState() =>
      _FocusTimerSettingsDialogState();
}

class _FocusTimerSettingsDialogState extends State<FocusTimerSettingsDialog> {
  late final TextEditingController _targetController;
  late final TextEditingController _focusController;
  late final TextEditingController _shortBreakController;
  late final TextEditingController _longBreakController;
  late final TextEditingController _longBreakEveryController;

  late bool _autoStartBreak;
  late bool _autoStartFocus;
  late FocusProgressMode _progressMode;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.initialGoal.targetFocusMinutes.toString(),
    );
    _focusController = TextEditingController(
      text: widget.initialTemplate.focusMinutes.toString(),
    );
    _shortBreakController = TextEditingController(
      text: widget.initialTemplate.shortBreakMinutes.toString(),
    );
    _longBreakController = TextEditingController(
      text: widget.initialTemplate.longBreakMinutes.toString(),
    );
    _longBreakEveryController = TextEditingController(
      text: widget.initialTemplate.longBreakEveryNCycles.toString(),
    );
    _autoStartBreak = widget.initialGoal.autoStartBreak;
    _autoStartFocus = widget.initialGoal.autoStartFocus;
    _progressMode = widget.initialGoal.progressMode;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _focusController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _longBreakEveryController.dispose();
    super.dispose();
  }

  int _parseOrDefault(TextEditingController controller, int fallback) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }

  void _save() {
    final target = _parseOrDefault(_targetController, 60);
    final focus = _parseOrDefault(_focusController, 25);
    final shortBreak = _parseOrDefault(_shortBreakController, 5);
    final longBreak = _parseOrDefault(_longBreakController, 15);
    final every = _parseOrDefault(_longBreakEveryController, 4);

    Navigator.of(context).pop(
      FocusTimerSettingsResult(
        goal: FocusGoalEntity(
          targetFocusMinutes: target,
          autoStartBreak: _autoStartBreak,
          autoStartFocus: _autoStartFocus,
          progressMode: _progressMode,
        ),
        template: FocusCycleTemplateEntity(
          focusMinutes: focus,
          shortBreakMinutes: shortBreak,
          longBreakMinutes: longBreak,
          longBreakEveryNCycles: every,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return Dialog(
      backgroundColor: surface.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Focus Timer Settings',
                      style: AppTypography.sectionTitle.copyWith(
                        color: surface.textPrimary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close settings',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  'Adjust cycle, automation, and progress behavior.',
                  style: AppTypography.bodySmall.copyWith(
                    color: surface.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing20),
                _NumberField(
                  label: 'Target Focus Minutes',
                  controller: _targetController,
                ),
                const SizedBox(height: AppConstants.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Focus',
                        controller: _focusController,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: _NumberField(
                        label: 'Short Break',
                        controller: _shortBreakController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Long Break',
                        controller: _longBreakController,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: _NumberField(
                        label: 'Long Break Every',
                        controller: _longBreakEveryController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing20),
                SwitchListTile.adaptive(
                  value: _autoStartBreak,
                  onChanged: (value) => setState(() => _autoStartBreak = value),
                  title: Text(
                    'Auto-start breaks',
                    style: AppTypography.actionLabel.copyWith(
                      color: surface.textPrimary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _autoStartFocus,
                  onChanged: (value) => setState(() => _autoStartFocus = value),
                  title: Text(
                    'Auto-start focus',
                    style: AppTypography.actionLabel.copyWith(
                      color: surface.textPrimary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  'Progress Mode',
                  style: AppTypography.actionLabel.copyWith(
                    color: surface.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing8),
                SegmentedButton<FocusProgressMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<FocusProgressMode>(
                      value: FocusProgressMode.focusOnly,
                      label: Text('Focus time only'),
                    ),
                    ButtonSegment<FocusProgressMode>(
                      value: FocusProgressMode.focusPlusBreak,
                      label: Text('Focus + break time'),
                    ),
                  ],
                  selected: {_progressMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      setState(() => _progressMode = selection.first);
                    }
                  },
                ),
                const SizedBox(height: AppConstants.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    AppButton.primary(label: 'Save', onPressed: _save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: surface.textSecondary),
        ),
        const SizedBox(height: AppConstants.spacing8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: surface.panelHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              borderSide: BorderSide(color: surface.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              borderSide: BorderSide(color: surface.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              borderSide: BorderSide(color: surface.accentStrong, width: 1.2),
            ),
          ),
          style: AppTypography.body.copyWith(color: surface.textPrimary),
        ),
      ],
    );
  }
}
