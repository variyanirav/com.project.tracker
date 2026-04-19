# Focus Timer (Wellness Mode) Requirements

Last Updated: 19 April 2026
Status: Approved Draft for Implementation Planning

## 1) Goal

Add a standalone Focus Timer feature that improves productivity and health awareness by encouraging regular breaks during long work periods.

This feature must NOT change existing project/task timer behavior.

## 2) Product Decisions (Resolved)

### Q1. Should "work hour" mean 60 minutes focus only, or include breaks?

Recommended default:
- 60 minutes means pure focus time.

Reason:
- Most productivity systems track focused effort as the primary metric.
- Breaks are recovery time and should be visible separately.
- This keeps reporting consistent and transparent.

User control:
- Add a setting to switch progress mode:
  - Focus Time Only (default)
  - Focus + Break Time

### Q2. Auto-start next session or wait for user?

Recommended default:
- Auto-advance enabled by default for uninterrupted 1-hour goal flow.

Behavior:
- Example with target focus = 60m, cycle = 25/5:
  - Focus 25 -> notification: break started
  - Break 5 -> notification: focus resumed
  - Focus 25 -> notification: break started
  - Break 5 -> notification: focus resumed
  - Focus 10 -> notification: 60-minute goal complete

User control:
- Settings toggles:
  - Auto-start breaks
  - Auto-start focus after breaks

### Q3. Sync across devices now?

Decision:
- No sync/cloud in current scope.
- Keep local-only persistence for this release.

### Q4. Strict Pomodoro or custom model?

Recommended approach:
- Hybrid model with healthy defaults:
  - Default cycle template: 25 focus / 5 short break.
  - Long break: 15 after every 4 full focus cycles.
  - Goal mode: target total focus minutes (for example 60m).

Why this is best for Project Tracker:
- Supports user awareness to avoid continuous sitting.
- Maintains compatibility with common Pomodoro expectations.
- Allows flexible use for different work styles.

## 3) Health and Productivity Basis (Non-medical)

This design uses practical, commonly cited guidance:
- Structured breaks can reduce fatigue and improve sustained concentration in time-boxed workflows.
- Ergonomic office guidance commonly recommends 5-10 minute movement breaks per hour of workstation work.

Implementation note:
- In-app text must avoid medical claims.
- Use wording like: "Suggested break" and "Movement reminder".

## 4) Scope

In scope:
- Standalone Focus Timer module.
- Focus/break cycle engine.
- Local notifications with sound and actionable text.
- Local persistence and resume after restart.
- Basic history for focus sessions.
- Settings for durations, auto-start, and progress mode.

Out of scope (later phase):
- Cross-device sync/cloud.
- Team/shared sessions.
- AI coaching.

## 4.1 Design Parity Requirements (Mandatory)

The Focus Timer feature must visually match the current application system in both dark and light themes.

Must follow existing app patterns:
- Use existing theme tokens, palette, spacing, and typography roles.
- Reuse existing modal/dialog patterns for shape, padding, button hierarchy, and width behavior.
- Match existing dialog widths and responsive breakpoints used by current dialogs.
- Match current top-bar action patterns and icon sizes.

Must not introduce:
- One-off dialog sizes that conflict with current modal rhythm.
- Custom typography scales outside existing text styles.
- Screen-local colors that bypass the shared theme.

Reference baseline:
- UI_STANDARDS.md and currently shipped dashboard/project/todo/reports/dialog design language.

## 5) Architecture Plan (Clean Architecture + DRY)

Current project has:
- Existing task timer provider in presentation layer.
- SharedPreferences helper and settings repository.
- Drift database with migration flow.

New feature must be isolated:
- Keep existing task timer untouched.
- Add new Focus Timer domain/data/presentation flow.

### 5.1 Domain Layer (new)

Add:
- FocusMode enum
  - focusOnly
  - focusPlusBreak
- FocusCycleTemplate entity
  - focusMinutes
  - shortBreakMinutes
  - longBreakMinutes
  - longBreakEveryNCycles
- FocusGoal entity
  - targetFocusMinutes
  - autoStartBreak
  - autoStartFocus
  - progressMode
- FocusRunState entity
  - phase: idle | focus | shortBreak | longBreak | completed | paused
  - remainingSeconds
  - accumulatedFocusSeconds
  - completedFocusCycles

Use cases:
- StartFocusRunUseCase
- PauseFocusRunUseCase
- ResumeFocusRunUseCase
- StopFocusRunUseCase
- TickFocusRunUseCase
- ComputeNextPhaseUseCase

### 5.2 Data Layer (new)

Repository interface:
- IFocusTimerRepository

Persistence:
- SharedPreferences for active in-progress state restore.
- Drift table for completed focus run history.

Proposed table:
- focus_runs
  - id
  - started_at
  - ended_at
  - target_focus_minutes
  - actual_focus_seconds
  - actual_break_seconds
  - cycle_template_json
  - completed

Migration:
- Increment DB schema version by one.
- Add non-destructive migration only.

### 5.3 Presentation Layer (new)

Providers:
- focusTimerProvider (StateNotifier)
- focusTimerTickProvider (stream/ticker)
- focusTimerSettingsProvider
- focusTimerHistoryProvider

UI (standalone screen/widget):
- FocusTimerScreen
- FocusRunControls (start/pause/resume/stop)
- FocusProgressRing
- NextBreakHint
- SessionSummaryCard

Navigation:
- Add dedicated route without changing task timer screens.
- Add one side-menu item using existing nav rail patterns.
- Keep route names in the same route constants style used today.

### 5.5 Side Menu and Navigation Safety

To avoid navigation regressions, implementation must:
- Add Focus Timer route constant and include it in route switching logic.
- Add nav rail item in the shared scaffold navigation source.
- Keep existing routes unchanged and reachable.
- Preserve selected-state highlight behavior for all nav items.
- Ensure project detail navigation still works with selected project state.

### 5.4 Notification Integration

Add notification abstraction:
- IFocusNotificationService

Events:
- Focus started
- Break started
- Break ended / Focus resumed
- Goal completed

Desktop behavior:
- Local notifications with optional sound.
- Graceful fallback if notification permission denied.

## 6) Functional Requirements

FR-1 Start Run
- User can start a focus run by setting target focus minutes.

FR-2 Cycle Progression
- System alternates focus and breaks based on template.
- System auto-completes when target focus time is reached.

FR-3 Notifications
- User receives notifications on phase transitions and run completion.

FR-4 Controls
- User can pause, resume, stop, and restart the run.

FR-5 Persistence
- In-progress run survives app restart.

FR-6 Independence
- Existing task timer and project/task workflows are unchanged.

FR-7 Settings
- User can configure durations and auto-start behavior.
- User can choose progress mode (focus-only vs include-breaks).

## 7) Non-Functional Requirements

- Accurate second-level timing.
- No drift larger than 1 second per minute under normal app conditions.
- Clean architecture boundaries with testable use cases.
- No duplicate logic between existing task timer and focus timer.

## 8) Phase-Wise Execution Plan

Phase 1: Domain and Contracts
- Add domain entities and use cases.
- Add repository/service interfaces.
- Define state machine transitions.

Exit criteria:
- Domain unit tests passing.
- flutter analyze has no new errors.

Phase 2: Data and Persistence
- Add Drift table and migration.
- Add repository implementation.
- Add active state persistence in SharedPreferences.

Exit criteria:
- Migration tests + repository tests passing.
- flutter analyze has no new errors.

Phase 3: Timer Engine and Providers
- Implement state notifier and tick orchestration.
- Implement start/pause/resume/stop.
- Implement auto-transition logic and completion.

Exit criteria:
- Provider tests passing for transitions and accumulation.
- flutter analyze has no new errors.

Phase 4: UI and Notifications
- Add Focus Timer screen and route.
- Add controls, progress, phase badge, and summary.
- Integrate local notifications and fallback UX.

Exit criteria:
- Widget tests and manual sanity checks passing.
- Side menu navigation checks pass for all screens.
- flutter analyze has no new errors.

Phase 5: Reports and Polish
- Add basic focus history view (standalone).
- Final UX copy and settings validation.
- Verify no regressions in existing task timer flow.

Exit criteria:
- Integration tests + smoke checklist completed.
- Full navigation regression checks pass.
- flutter analyze has no new errors.

## 8.1 Quality Gates (Run After Every Phase)

Required command gates:
- Run phase-targeted tests for changed modules.
- Run flutter analyze and fix all new issues before marking phase complete.

Required checks:
- Dark theme visual sanity check.
- Light theme visual sanity check.
- Dialog/modal sizing and typography consistency check.
- Side-menu navigation sanity check.

## 9) Test Cases (Implementation Checklist)

### 9.1 Domain Unit Tests

- Next phase from focus -> short break.
- Next phase from short break -> focus.
- Long break triggers on configured cycle count.
- Goal completion when accumulated focus reaches target.
- Progress mode math for both variants.

### 9.2 Data Layer Tests

- Migration adds focus_runs table without data loss.
- Save and load active run state from SharedPreferences.
- Persist completed run into database with correct totals.

### 9.3 Provider Tests

- Start initializes correct first phase.
- Pause freezes remaining time.
- Resume continues from same remaining time.
- Stop resets state and keeps summary rules.
- Auto-start toggles respected on transitions.
- One-hour target path reaches completed with expected notifications.

### 9.4 Widget Tests

- Start button disabled for invalid input.
- Phase label and remaining timer update correctly.
- Progress ring reflects selected progress mode.
- Settings update state and persist.

### 9.5 Integration/Behavior Tests

- Full run simulation for 60m focus target with 25/5 cycles.
- App restart mid-run restores exact state.
- Existing project/task timer remains fully functional and independent.
- Side-menu navigation between Dashboard, Projects, Categories, To-Do, Reports, and Focus Timer works without state loss.
- Route highlight state remains accurate after repeated screen switches.

## 10) Acceptance Criteria

- User can complete a 60-minute focus goal with automatic break transitions.
- User receives break start/end and completion notifications.
- User can pause/resume/stop anytime.
- Existing timer flow for tasks is unaffected.
- No cloud dependency required.
- All listed test groups pass.

## 11) UX Defaults for First Release

- Target focus: 60 minutes.
- Focus cycle: 25 minutes.
- Short break: 5 minutes.
- Long break: 15 minutes after 4 focus cycles.
- Progress mode default: Focus Time Only.
- Auto-start break default: On.
- Auto-start focus default: On.

## 12) Future Extensions (Later)

- Cloud sync and cross-device continuity.
- Break type presets (walk, stretch, eye rest).
- Weekly focus insights in reports.
- Team accountability and shared focus rooms.
