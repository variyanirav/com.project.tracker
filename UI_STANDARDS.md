# UI Standards Guide

This document defines shared UI constraints for titles, action buttons, and key tracking surfaces so the app looks consistent across screens.

## Goals
- Keep critical cards readable under long user input.
- Standardize title behavior across task and to-do flows.
- Ensure top-right action buttons are visually consistent.

## Global Rules
- Task title max input length: 120 characters.
- To-do title max input length: 120 characters.
- Title rendering in list/card views: max 2 lines with ellipsis.
- Desktop hover behavior: show full title in a tooltip.
- Top-bar primary action button height: 44px.
- Top-bar primary action button min width: 170px.
- Primary create actions should be top-right in section header bars.
- Primary create flows should open centered modal dialogs, not inline forms.
- All create dialogs must maintain the same layout quality in both light and dark themes.
- Page headers for project detail views should be sticky/pinned while scrolling.
- Project detail headers should place the project avatar to the left of the project name.
- Project detail headers should keep the primary create action in the top-right corner.
- Secondary management actions should live inside the create dialog near the relevant field.

## Implemented In
- `lib/core/constants/app_constants.dart`
- `lib/core/widgets/app_button.dart`
- `lib/presentation/widgets/project_detail/active_timer_card.dart`
- `lib/presentation/widgets/project_detail/create_task_form.dart`
- `lib/presentation/widgets/dialogs/create_task_dialog.dart`
- `lib/presentation/widgets/dialogs/upsert_todo_dialog.dart`
- `lib/presentation/screens/todo_list_screen.dart`

## Active Timer Card Pattern
- Header row: tracking indicator + status pill on top-right.
- Task title: two-line limit with tooltip for full text.
- Task details: bordered panel with subtle contrast and internal scroll.
- Timer and controls remain visually separated below details.

## Project Detail Header Pattern
- Keep the header pinned at the top of the page during scroll.
- Show the two-character project avatar on the left side of the project name.
- Keep `Create New Task` as the top-right primary action.
- Move category management into the create-task modal, below the category selector.

## To-Do Top Bar Pattern
- Keep `Create To-Do` action on top-right.
- Use shared AppButton sizing constants.
- Avoid one-off button dimensions in screen-specific widgets.

## Task Creation Pattern
- On project detail pages, show `Create New Task` in the section header top-right.
- Open `New Task` as a centered modal dialog.
- Keep category management as a secondary action near the create button.
- Avoid large inline create forms for primary workflows.

## Input Validation Pattern
- Validate minimum title length before save.
- Enforce maximum title length in both `maxLength` and validator checks.
- Show user-friendly validation messages.

## Notes
- These standards are intentionally lightweight and do not require extra UI packages.
- If future design system work is added, migrate these values into dedicated design tokens.
