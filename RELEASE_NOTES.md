# Release Notes - Project Tracker v1.3.1

**Release Date:** April 20, 2026  
**Version:** 1.3.1 (Build 5)  
**Status:** ✅ Stable Release

---

## 🎉 Highlights

### Task Estimation and Actual Hours Comparison
This release adds optional task-level estimated hours and surfaces estimated vs actual comparisons throughout Project Detail and CSV exports.

**Key Highlights:**
- ✅ Optional estimated-hours input when creating or editing a task
- ✅ Clear guidance to enter hours (not days) with numeric validation
- ✅ Task list tags now show estimate and over/under variance against actual tracked time
- ✅ Task details dialog now includes estimated time and variance summary
- ✅ CSV exports now include an `Estimated (Hours)` column alongside actual duration
- ✅ Backward-compatible database migration adds nullable `estimated_hours` field

---

## 🆕 What's New in v1.3.1

### 1. Optional Estimated Hours on Tasks
- **Create Task Dialog**: Added optional field for estimated hours
- **Edit Task Dialog**: Added editable estimate with the same validations
- **Validation Rules**: Value must be numeric and greater than 0 if provided
- **User Guidance**: Input helper text explicitly asks for hours, not days

**Files Updated:**
- `lib/presentation/widgets/dialogs/create_task_dialog.dart`
- `lib/presentation/widgets/dialogs/edit_task_dialog.dart`
- `lib/presentation/screens/project_detail_screen.dart`
- `lib/presentation/providers/task_provider.dart`

### 2. Estimated vs Actual Visibility in Project Detail
- **Task Row Tags**: Display estimate and variance (over/under/on target)
- **Task Detail Modal**: Added Estimated Time and Variance metadata
- **Decision Support**: Faster visibility into under-estimated or over-worked tasks

**Files Updated:**
- `lib/presentation/widgets/project_detail/task_list_view.dart`
- `lib/presentation/widgets/dialogs/view_task_dialog.dart`

### 3. CSV Export Enhancement
- Added `Estimated (Hours)` to detailed task/session export outputs
- Keeps existing duration/actual hour output intact for billing and analysis

**Files Updated:**
- `lib/presentation/providers/reports_provider.dart`

### 4. Data Model and Migration
- **Database Schema**: Added nullable `estimated_hours` column in `tasks`
- **Schema Version**: Bumped database schema to 8
- **Persistence Wiring**: Entity/model/repository flow now carries optional estimates end-to-end

**Files Updated:**
- `lib/data/database/tables/tasks_table.dart`
- `lib/data/database/app_database.dart`
- `lib/domain/entities/task_entity.dart`
- `lib/domain/repositories/itask_repository.dart`
- `lib/data/repositories/task_repository_impl.dart`
- `lib/data/models/task_model.dart`

---

## ✅ Validation (v1.3.1)

- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter test test/data/task_status_migration_test.dart test/models/timer_session_model_test.dart`
- `flutter analyze` (existing info-level warnings remain; no new errors from this release)

---

## Previous Release - v1.3.0

# Release Notes - Project Tracker v1.3.0

**Release Date:** April 19, 2026  
**Version:** 1.3.0 (Build 4)  
**Status:** ✅ Stable Release

---

## 🎉 Highlights

### Focus Timer - Major Release
This release introduces a standalone, healthy work/break Focus Timer that stays independent from the task timer and restores its active state after restart.

**Key Highlights:**
- ✅ Standalone Focus Timer for healthy work/break sessions
- ✅ 60-minute pure focus default with per-phase tracking
- ✅ Local persistence and restart restore for active focus runs
- ✅ Recent focus history and settings dialog aligned with the app theme
- ✅ Independent from the existing task timer
- ✅ Validated with focused tests and flutter analyze

---

## 🆕 What's New

### 1. Standalone Focus Timer
- **Separate Flow**: Focus Timer has its own route, screen, and navigation item
- **Healthy Work Sessions**: Tracks pure focus time separately from task tracking
- **Phase Tracking**: Each focus phase is tracked with progress, status, and summary state
- **Control Surface**: Start, pause, resume, and stop actions match the rest of the app

**Files Added or Updated:**
- `lib/domain/entities/focus_cycle_template_entity.dart`
- `lib/domain/entities/focus_goal_entity.dart`
- `lib/domain/entities/focus_run_state_entity.dart`
- `lib/domain/entities/focus_run_record_entity.dart`
- `lib/domain/repositories/ifocus_timer_repository.dart`
- `lib/domain/usecases/focus_timer_usecases.dart`
- `lib/presentation/providers/focus_timer_provider.dart`
- `lib/presentation/routes/app_router.dart`
- `lib/app.dart`
- `lib/core/widgets/custom_scaffold.dart`
- `lib/presentation/screens/focus_timer_screen.dart`
- `lib/presentation/widgets/dialogs/focus_timer_settings_dialog.dart`

### 2. Local Persistence and Restore
- **Active Run Restore**: The current focus phase is restored after restart
- **History Storage**: Completed focus runs are written to the local database
- **Migration Support**: The database migration adds the `focus_runs` table automatically
- **No Cloud Sync**: The feature stays local-only as requested

**Files Added or Updated:**
- `lib/data/database/app_database.dart`
- `lib/data/repositories/focus_timer_repository_impl.dart`
- `lib/presentation/providers/repository_provider.dart`

### 3. Notifications and UX
- **Notification Service**: Desktop notification fallback is available for phase transitions
- **Theme Match**: Screen, dialog, and controls follow the current light/dark theme system
- **Navigation Safety**: Focus Timer is added to the shared side menu without disturbing task flows

**Files Added or Updated:**
- `lib/services/focus_notification_service.dart`
- `lib/core/widgets/custom_scaffold.dart`
- `lib/presentation/routes/app_router.dart`
- `lib/app.dart`

### Previous Release - Archive Feature
- Archive completed tasks with one click
- Restore archived tasks to active work queue
- Session history protection (copy-only, no edits)
- Dedicated Archive tab with filtering
- Read-only protection for archived tasks

---

## 📈 Technical Details

### Database Changes
- **Schema Migration Added**: New `focus_runs` table and migration path
- **Backwards Compatible**: Existing project, task, and timer data remains intact
- **Existing Constraints**: All foreign keys and constraints maintained

### Provider Changes
**Files:** `lib/presentation/providers/focus_timer_provider.dart`, `lib/presentation/providers/repository_provider.dart`

```dart
final focusTimerProvider = NotifierProvider<FocusTimerNotifier, FocusTimerState>
final focusTimerHistoryProvider = FutureProvider<List<FocusRunRecordEntity>>
final focusTimerRepositoryProvider = Provider<IFocusTimerRepository>
```

### Repository Changes
**File:** `lib/data/repositories/focus_timer_repository_impl.dart`

```dart
Future<FocusRunStateEntity?> restoreActiveRun()
Future<void> saveActiveRun(FocusRunStateEntity state)
Future<void> clearActiveRun()
Future<void> insertRunRecord(FocusRunRecordEntity record)
Future<List<FocusRunRecordEntity>> listRecentRuns()
```

### UI Changes
- `lib/presentation/screens/focus_timer_screen.dart` provides the timer UI, progress, summary, and recent runs
- `lib/presentation/widgets/dialogs/focus_timer_settings_dialog.dart` matches the existing modal widths and typography
- `lib/core/widgets/custom_scaffold.dart` adds the Focus Timer item to the shared side menu
- `lib/services/focus_notification_service.dart` provides a safe desktop notification fallback

---

## 🐛 Bug Fixes

- Resolved the restart-restore race in the integration flow by waiting for the notifier to finish async initialization before asserting the restored state.

---

## ⚠️ Breaking Changes

None. The Focus Timer is standalone and the existing task timer remains unchanged.

---

## 🔄 Dependencies

No new dependencies were added. Existing versions remain in use:
- flutter_riverpod: ^2.4.0
- drift: ^2.16.0
- All other dependencies unchanged

---

## ✅ Validation

- `flutter test test/domain/focus_timer_usecases_test.dart`
- `flutter test test/data/focus_timer_repository_impl_test.dart`
- `flutter test test/providers/focus_timer_provider_test.dart`
- `flutter test test/screens/focus_timer_screen_test.dart`
- `flutter test test/screens/focus_timer_navigation_test.dart`
- `flutter test test/integration/focus_timer_integration_test.dart`
- `flutter test test/timer_provider_test.dart test/providers/timer_provider_additional_test.dart`
- `flutter analyze --no-fatal-infos`

---

## 🎯 Features by Version

### v1.3.0 (Current) - April 19, 2026
- ✅ Standalone Focus Timer
- ✅ Local persistence and restart restore
- ✅ Phase tracking and recent history
- ✅ Theme-matching screen and settings dialog
- ✅ Side-menu navigation entry
- ✅ Focus-specific and regression tests

### v1.2.0 - April 11, 2026
- ✅ Archive completed tasks
- ✅ Read-only archive protection
- ✅ Session history lock
- ✅ Restore workflow
- ✅ Confirmation dialogs
- ✅ Archive tab with filtering
- ✅ 9 comprehensive tests

### v1.1.0 - March 20, 2026
- ✅ Timer start/pause/stop
- ✅ Project and task management
- ✅ Daily/weekly/total reporting
- ✅ CSV export
- ✅ Session history tracking
- ✅ Database integration

---

## 🚀 Installation & Upgrade

### From v1.2.0 or Earlier
1. The app applies the focus timer migration automatically on launch
2. Existing projects, tasks, and timer history remain intact
3. Install the new build normally
4. The Focus Timer becomes available from the side menu immediately

### Clean Installation
```bash
cd /Users/niravvariya/Documents/Projects/Desktop/com.project.tracker

# Install
flutter pub get

# Run
flutter run -d macos
```

---

## 📝 Known Limitations

- Focus Timer is local-only for now and does not sync across devices.
