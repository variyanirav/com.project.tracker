# TODO

## UI Rollout Plan (Phase-Wise)

### Goal
- Roll out the approved Reports typography and surface treatment across all app screens without missing any page.
- Standardize base typography/components first, then migrate screen by screen.

### Screen Inventory (Primary Pages)
- Dashboard: lib/presentation/screens/dashboard_screen.dart
- Project List: lib/presentation/screens/project_list_screen.dart
- Project Detail: lib/presentation/screens/project_detail_screen.dart
- Todo List: lib/presentation/screens/todo_list_screen.dart
- Categories: lib/presentation/screens/categories_screen.dart
- Reports: lib/presentation/screens/reports_screen.dart

### Component Inventory (Shared + Page-Specific)
- Core shared UI: lib/core/widgets/custom_scaffold.dart
- Core shared UI: lib/core/widgets/app_button.dart
- Core shared UI: lib/core/widgets/app_card.dart
- Core shared UI: lib/core/widgets/app_text_field.dart
- Core shared UI: lib/core/widgets/app_empty_state.dart
- Core shared UI: lib/core/widgets/app_avatar.dart

- Dashboard widgets: lib/presentation/widgets/dashboard/daily_progress_card.dart
- Dashboard widgets: lib/presentation/widgets/dashboard/project_card.dart
- Dashboard widgets: lib/presentation/widgets/dashboard/running_timer_card.dart

- Project detail widgets: lib/presentation/widgets/project_detail/project_header.dart
- Project detail widgets: lib/presentation/widgets/project_detail/stats_card.dart
- Project detail widgets: lib/presentation/widgets/project_detail/active_timer_card.dart
- Project detail widgets: lib/presentation/widgets/project_detail/task_list_view.dart
- Project detail widgets: lib/presentation/widgets/project_detail/task_list_item.dart
- Project detail widgets: lib/presentation/widgets/project_detail/timer_control_buttons.dart
- Project detail widgets: lib/presentation/widgets/project_detail/today_tasks_sidebar.dart
- Project detail widgets: lib/presentation/widgets/project_detail/empty_tasks_state.dart
- Project detail widgets: lib/presentation/widgets/project_detail/empty_timer_state.dart
- Project detail widgets: lib/presentation/widgets/project_detail/create_task_form.dart

- Reports widgets: lib/presentation/widgets/reports/reports_components.dart

- Dialogs used across pages: lib/presentation/widgets/dialogs/create_project_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/edit_project_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/create_task_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/edit_task_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/view_task_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/confirm_delete_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/manage_categories_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/upsert_todo_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/timer_session_note_dialog.dart
- Dialogs used across pages: lib/presentation/widgets/dialogs/daily_goal_settings_dialog.dart

## Phase 0 - Baseline and Tokens (In Progress)
- [x] Freeze approved Reports typography/surface tokens as source of truth.
- [x] Add app-wide base typography wrappers/tokens in core theme layer.
- [x] Define text usage matrix (heading, section title, metric value, body, helper, labels).
- [x] Define section surface matrix (page bg, panel, elevated panel, table header, border).
- [ ] Verify dark/light parity before page migration starts.
- [ ] Capture screenshot references for Phase 0 baseline (dark + light) before Phase 1.

## Phase 1 - Shared Components Migration
- [x] Update shared core widgets to consume new typography/surface tokens:
- [x] lib/core/widgets/app_button.dart
- [x] lib/core/widgets/app_card.dart
- [x] lib/core/widgets/app_text_field.dart
- [x] lib/core/widgets/app_empty_state.dart
- [x] lib/core/widgets/app_avatar.dart
- [x] Keep behavior unchanged; visual and token migration only.
- [x] Analyzer check passed for all migrated core widgets.

## Phase 2 - Dashboard + Project List
- [x] Migrate dashboard screen typography/surfaces:
- [x] lib/presentation/screens/dashboard_screen.dart
- [x] lib/presentation/widgets/dashboard/daily_progress_card.dart
- [x] lib/presentation/widgets/dashboard/project_card.dart
- [x] lib/presentation/widgets/dashboard/running_timer_card.dart
- [x] Migrate project list screen typography/surfaces:
- [x] lib/presentation/screens/project_list_screen.dart
- [x] Re-verify empty/loading/error states after visual updates.
- [x] Analyzer check passed for all Phase 2 files.

## Phase 3 - Project Detail (Largest Surface Area)
- [x] Migrate project detail screen typography/surfaces:
- [x] lib/presentation/screens/project_detail_screen.dart
- [x] lib/presentation/widgets/project_detail/project_header.dart
- [x] lib/presentation/widgets/project_detail/stats_card.dart
- [x] lib/presentation/widgets/project_detail/active_timer_card.dart
- [x] lib/presentation/widgets/project_detail/task_list_view.dart
- [x] lib/presentation/widgets/project_detail/task_list_item.dart
- [x] lib/presentation/widgets/project_detail/timer_control_buttons.dart
- [x] lib/presentation/widgets/project_detail/today_tasks_sidebar.dart
- [x] lib/presentation/widgets/project_detail/empty_tasks_state.dart
- [x] lib/presentation/widgets/project_detail/empty_timer_state.dart
- [x] lib/presentation/widgets/project_detail/create_task_form.dart
- [x] Analyzer check passed for all Phase 3 files.

## Phase 4 - Todo + Categories
- [x] Migrate todo list typography/surfaces:
- [x] lib/presentation/screens/todo_list_screen.dart
- [x] Migrate categories screen typography/surfaces:
- [x] lib/presentation/screens/categories_screen.dart
- [x] Re-check list rows, filter bars, and stat cards for surface consistency.
- [x] Analyzer check passed for all Phase 4 files.

## Phase 5 - Dialog System Unification
- [x] Migrate all dialogs to shared typography/surface tokens:
- [x] lib/presentation/widgets/dialogs/create_project_dialog.dart
- [x] lib/presentation/widgets/dialogs/edit_project_dialog.dart
- [x] lib/presentation/widgets/dialogs/create_task_dialog.dart
- [x] lib/presentation/widgets/dialogs/edit_task_dialog.dart
- [x] lib/presentation/widgets/dialogs/view_task_dialog.dart
- [x] lib/presentation/widgets/dialogs/confirm_delete_dialog.dart
- [x] lib/presentation/widgets/dialogs/manage_categories_dialog.dart
- [x] lib/presentation/widgets/dialogs/upsert_todo_dialog.dart
- [x] lib/presentation/widgets/dialogs/timer_session_note_dialog.dart
- [x] lib/presentation/widgets/dialogs/daily_goal_settings_dialog.dart
- [x] Analyzer check passed for all Phase 5 files.

## Phase 6 - Reports Final QA + Global QA
- [x] Revisit reports for final consistency after shared token migration:
- [x] lib/presentation/screens/reports_screen.dart
- [x] lib/presentation/widgets/reports/reports_components.dart
- [x] Full app sweep for typography hierarchy consistency.
- [x] Full app sweep for section background/surface consistency.
- [x] Run targeted widget tests for updated screens.
- [x] Analyzer check passed for Phase 6 touched files.

## Tracking Rules
- Complete phases in order unless a blocker requires reordering.
- For each phase: implement -> run analyzer/tests -> visual check in dark/light -> mark complete.
- No behavior changes during this rollout, only UI/token alignment unless explicitly requested.
