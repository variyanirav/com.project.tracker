# Task Categories + Session Notes + Reporting

## 1. Purpose

This document defines the implementation plan for adding:

1. Task categories (Learning, Development, Research, etc.)
2. Session-level notes at timer start/stop
3. Reporting by category and by task (including multi-day tasks)
4. CSV export updates for management-level and session-level analysis

Primary goal:
Keep daily execution simple while enabling accurate roll-up reports without manual summation.

---

## 2. Problem Statement

Current behavior supports:

1. Task creation
2. Timer start/stop
3. Task/session reporting and CSV export

Gaps:

1. No category grouping for aggregate reports
2. No structured context for what was done in each timer run
3. Multi-day tasks are not clearly represented in high-level summaries by category

Expected outcome:

1. Users can keep one real task across multiple days
2. Users can optionally capture session intent/outcome
3. Reports can answer:
   1. How many hours spent per category?
   2. How many hours spent per task across multiple days?
   3. What was done in each work session?

---

## 3. Product Decisions (Final)

1. Keep existing task model as the "goal" item.
2. Add category linkage at task level.
3. Keep timer session as execution log (already exists).
4. Add optional session note capture at:
   1. Timer start (plan/intention)
   2. Timer stop (outcome/result)
5. Reports screen will support filters:
   1. Period
   2. Project
   3. Category
6. CSV export will include category and session-note context.

Non-goals for this phase:

1. Full hierarchical sub-task tree
2. Category permissions/roles
3. Complex analytics dashboards beyond required reports

---

## 4. Architecture Impact

### 4.1 Data Layer

Changes:

1. Add `categories` table
2. Add `categoryId` foreign key in `tasks`
3. Seed default categories
4. Backfill existing tasks to default category mapping

Notes:

1. `timer_sessions.notes` already exists and can be reused
2. Optionally later split into `startNote` and `endNote`

### 4.2 Domain Layer

Changes:

1. Extend task entity with category information
2. Add category entity
3. Extend repository interfaces for category-aware APIs

### 4.3 Provider Layer

Changes:

1. Category providers (list/create/update/delete)
2. Task providers include category in create/update params
3. Timer provider supports optional notes on start/stop
4. Reports providers add category-based aggregations and filters

### 4.4 UI Layer

Changes:

1. Task create/edit forms include category selector
2. Optional note dialog before/after timer session
3. Reports screen includes category filter and category summary section
4. CSV export options include category-aware output

---

## 5. Data Model Design

## 5.1 Categories Table

Recommended fields:

1. id (text, primary key)
2. name (text, unique, required)
3. colorHex (text, nullable)
4. createdAt (datetime)
5. updatedAt (datetime)

Default seed values:

1. Learning
2. Development
3. Research
4. Uncategorized

### 5.2 Tasks Table Extension

Add:

1. categoryId (text, nullable during migration, required by app logic)

Foreign key:

1. tasks.categoryId -> categories.id

Fallback rule:

1. Null/unknown category is treated as Uncategorized in reports and UI

### 5.3 Timer Sessions

Existing `notes` column usage strategy for MVP:

1. On start: save intention note
2. On stop: append or replace with outcome note (standard format)

Example format for single notes field:

1. "START: Learn React Hooks section 5"
2. "STOP: Completed hooks + took notes"

---

## 6. Migration Strategy (v3 -> v4)

## 6.1 Schema Version

1. Increment schema version to 4

## 6.2 Migration Steps

1. Create categories table
2. Add categoryId column to tasks
3. Insert seeded categories (id-based constants)
4. Backfill existing tasks:
   1. If task name starts with "Learning" -> Learning
   2. If task name starts with "Development" -> Development
   3. If task name starts with "Research" -> Research
   4. Else -> Uncategorized
5. Add index on tasks.categoryId for report performance

## 6.3 Safety Rules

1. No existing task or session deletion
2. Migration must be idempotent-safe for partially upgraded local DBs
3. If seed insert fails due to duplicates, continue safely

## 6.4 Rollback Plan

1. Keep export backup capability before release
2. If migration fails, app should surface actionable error and prevent partial writes
3. Maintain migration test coverage for legacy datasets

---

## 7. Reporting Behavior Specification

## 7.1 Filters

1. Period: This Week, Last Week, This Month
2. Project: All/Specific
3. Category: All/Specific

## 7.2 Report Sections

1. Category Summary
   1. Category name
   2. Total hours
   3. Session count
   4. Task count
2. Task Summary
   1. Project
   2. Task
   3. Category
   4. Status
   5. Total hours in selected period
   6. Session count
   7. Last session date
3. Session Details
   1. Date/time
   2. Project
   3. Task
   4. Category
   5. Duration
   6. Notes

## 7.3 CSV Export

Required fields:

1. Category in task and session rows
2. Session notes in session export

Preferred output modes:

1. Three files
   1. category_summary.csv
   2. task_summary.csv
   3. session_detail.csv
2. If one-file export is retained, include section headers with separators

---

## 8. CRUD Behavior (Minimum Viable UX)

### 8.1 Category Add

1. User can add category from category management or task form shortcut
2. Name required, unique validation

### 8.2 Category Edit

1. Rename category
2. Optional color update

### 8.3 Category Delete

Rules:

1. If category has tasks, require reassignment target
2. Default reassignment target: Uncategorized
3. Prevent deletion of Uncategorized

### 8.4 Task Create/Edit

1. Category is mandatory at app level (default to Uncategorized)
2. Existing tasks without category display as Uncategorized

### 8.5 Timer Start/Stop Notes

1. Prompt is optional and skippable
2. Note entry should not block timer reliability
3. If note save fails, timer action should still complete and show warning

---

## 9. SOLID-Oriented Implementation Plan

### Phase 1: Data + Migration

Deliverables:

1. Categories table + DAO/repository
2. Tasks table categoryId
3. Migration and seed/backfill

Checkpoints:

1. App opens old DB successfully
2. Existing tasks visible
3. Category query works

### Phase 2: Domain + Repository Contracts

Deliverables:

1. Task entity extension
2. Category entity
3. Interface updates for category-aware operations

Checkpoints:

1. Build compiles with no interface mismatch
2. Existing behavior unchanged for non-category flows

### Phase 3: UI and Providers (Task CRUD + Timer Notes)

Deliverables:

1. Category dropdown in task create/edit
2. Optional start/stop session notes
3. Provider invalidation updates

Checkpoints:

1. Create/edit task with category works
2. Timer start/stop still reliable with and without notes
3. Session notes visible in detail/report source

### Phase 4: Reports + CSV

Deliverables:

1. Category filter and category summary
2. Task summary includes category
3. Session detail includes notes
4. CSV updated

Checkpoints:

1. Category totals match task/session data
2. Multi-day tasks aggregate correctly
3. CSV columns validated

### Phase 5: QA + Stabilization

Deliverables:

1. Migration tests
2. Repository/unit tests
3. Widget tests
4. Regression checklist pass

Checkpoints:

1. No data loss in migration
2. No timer regressions
3. Report numbers match manual spot checks

---

## 10. Testing Strategy

### 10.1 Unit Tests

1. Category CRUD validation
2. Task create/update with category
3. Category aggregation logic
4. Session notes write/update behavior

### 10.2 Migration Tests

1. v3 seeded DB migrates to v4
2. Existing tasks mapped correctly
3. Legacy data remains intact

### 10.3 Widget Tests

1. Category selector in create/edit forms
2. Start/stop note dialogs
3. Reports filter interactions

### 10.4 Integration/Regression Tests

1. Timer end-to-end run with notes
2. Multi-day task report totals
3. CSV export output verification

---

## 11. Risks and Mitigations

1. Migration complexity on user devices
   1. Mitigation: migration tests + safe default fallback category
2. Timer reliability impact from note prompts
   1. Mitigation: make prompts optional and non-blocking
3. Report performance with larger datasets
   1. Mitigation: indexes on task category/project/date and pre-filtered queries
4. CSV compatibility changes
   1. Mitigation: preserve existing columns where possible, append new fields

---

## 12. Acceptance Criteria

1. Existing users can upgrade without data loss
2. Every task has effective category (explicit or fallback)
3. Multi-day tasks show accurate total hours in reports
4. Category-based totals available for selected period
5. Session notes captured and visible in reports/CSV
6. Timer flow remains stable with no blocking regression

---

## 13. Checkpoint Tracker (Resume Here)

Status legend:

1. NOT_STARTED
2. IN_PROGRESS
3. DONE
4. BLOCKED

Track:

1. CP-01 Data schema changes: DONE
2. CP-02 Migration + backfill: DONE
3. CP-03 Domain/repository contract updates: DONE
4. CP-04 Category UI in task forms: DONE
5. CP-05 Timer note prompts: DONE
6. CP-06 Reports category summary/filter: DONE
7. CP-07 CSV updates: DONE
8. CP-08 Unit/migration/widget tests: DONE
9. CP-09 Regression + release checklist: DONE

Resume protocol:

1. Start from first checkpoint not marked DONE
2. Run related tests for that checkpoint before moving ahead
3. Update this section immediately after each checkpoint

---

## 14. Execution Log Template

Use this structure while implementing to avoid losing track:

1. Date:
2. Owner:
3. Checkpoint ID:
4. Files changed:
5. What was done:
6. Why it was done:
7. Tests executed:
8. Result:
9. Follow-up actions:
10. Risks/notes:

---

## 15. Immediate Next Actions

1. Complete CP-08 by running targeted tests for categories, timer notes, and reports
2. Execute CP-09 release checklist and full regression pass
3. Finalize documentation with test evidence and known baseline analyzer warnings

This sequencing minimizes rework and keeps risk controlled.

---

## 16. Execution Log

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: CP-01, CP-02
4. Files changed:
   1. lib/data/database/tables/categories_table.dart
   2. lib/data/database/tables/tasks_table.dart
   3. lib/data/database/app_database.dart
5. What was done:
   1. Added categories table
   2. Added tasks.categoryId
   3. Added migration to v4 with seed and backfill rules
6. Why it was done:
   1. Enable category-based reporting and backward-compatible migration
7. Tests executed:
   1. flutter analyze lib
8. Result:
   1. Source compiles with existing baseline deprecation warning
9. Follow-up actions:
   1. Validate migration behavior with tests
10. Risks/notes:
   1. Existing test-suite has pre-existing failures unrelated to this feature

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: CP-03, CP-04, CP-05, CP-06, CP-07
4. Files changed:
   1. lib/domain/entities/task_entity.dart
   2. lib/domain/entities/category_entity.dart
   3. lib/domain/repositories/icategory_repository.dart
   4. lib/data/repositories/category_repository_impl.dart
   5. lib/presentation/providers/category_provider.dart
   6. lib/presentation/widgets/project_detail/create_task_form.dart
   7. lib/presentation/widgets/dialogs/edit_task_dialog.dart
   8. lib/presentation/widgets/dialogs/timer_session_note_dialog.dart
   9. lib/presentation/providers/timer_provider.dart
   10. lib/presentation/providers/reports_provider.dart
   11. lib/presentation/screens/reports_screen.dart
5. What was done:
   1. Wired category CRUD and task create/edit category selection
   2. Added optional timer start/stop session notes
   3. Added category summary in reports and category-aware CSV export
6. Why it was done:
   1. Ensure task-level and category-level visibility without manual summation
7. Tests executed:
   1. flutter analyze lib
8. Result:
   1. Feature compiles in source layer
9. Follow-up actions:
   1. Run and stabilize targeted tests
10. Risks/notes:
   1. Full workspace test suite currently contains unrelated legacy test issues

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: CP-08
4. Files changed:
   1. test/data/category_and_task_category_test.dart
   2. test/data/task_status_migration_test.dart
5. What was done:
   1. Added category + task-category integration tests
   2. Updated migration test fixtures for new schema
   3. Executed targeted repository/migration test suite with coverage
6. Why it was done:
   1. Validate schema migration defaults, category assignment, and reassignment behavior
7. Tests executed:
   1. flutter test test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart test/data/timer_session_repository_impl_test.dart
   2. flutter test --coverage test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart test/data/timer_session_repository_impl_test.dart
8. Result:
   1. 12 targeted tests passed
   2. Workspace lcov summary currently ~29.69% (global baseline still below 80%)
9. Follow-up actions:
   1. Expand tests for providers/screens/reports to move toward 80% target
10. Risks/notes:
   1. Existing unrelated test files still fail in full-suite analyze/test runs

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: CP-08 (completion)
4. Files changed:
   1. test/providers/reports_provider_test.dart
   2. test/timer_provider_test.dart
   3. test/screens/reports_screen_test.dart
5. What was done:
   1. Added category-filter and category-summary provider tests
   2. Added timer start/stop note persistence test
   3. Stabilized reports screen test with category provider override
6. Why it was done:
   1. Complete feature coverage for reports and timer note behavior
7. Tests executed:
   1. flutter test test/providers/reports_provider_test.dart test/timer_provider_test.dart test/screens/reports_screen_test.dart test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart test/data/timer_session_repository_impl_test.dart
8. Result:
   1. All targeted tests passed (23 tests)
9. Follow-up actions:
   1. Expand broader workspace tests to reach org-level coverage gate
10. Risks/notes:
   1. Global coverage remains below 80% due unscoped legacy test gaps

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: CP-09
4. Files changed:
   1. FEATURE_TASK_CATEGORIES_IMPLEMENTATION_PLAN.md
5. What was done:
   1. Ran focused regression for feature-critical suites
   2. Re-validated static analysis on source + updated tests
   3. Captured updated coverage baseline
6. Why it was done:
   1. Close implementation with reproducible verification evidence
7. Tests executed:
   1. flutter analyze lib test/providers/reports_provider_test.dart test/timer_provider_test.dart test/screens/reports_screen_test.dart test/data/category_and_task_category_test.dart
   2. flutter test --coverage test/providers/reports_provider_test.dart test/timer_provider_test.dart test/screens/reports_screen_test.dart test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart test/data/timer_session_repository_impl_test.dart
8. Result:
   1. Analyzer clean for updated scope except pre-existing deprecation info in extensions.dart
   2. Updated workspace lcov summary ~36.08%
9. Follow-up actions:
   1. Add additional tests in remaining modules for global 80% target
10. Risks/notes:
   1. Full workspace quality gate (80%+) still pending and requires broader test investment

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: Post-CP Enhancement (Category Management UX)
4. Files changed:
   1. lib/presentation/routes/app_router.dart
   2. lib/core/widgets/custom_scaffold.dart
   3. lib/app.dart
   4. lib/presentation/screens/categories_screen.dart
   5. lib/presentation/screens/project_detail_screen.dart
5. What was done:
   1. Added dedicated Categories screen with full Add/Edit/Delete/Reassign flows
   2. Added sidebar navigation route for Categories so management is reachable from any page
   3. Kept project-detail shortcut dialog for faster in-context category updates
6. Why it was done:
   1. Shift category control from system-seeded-only perception to explicit user-managed CRUD
7. Tests executed:
   1. flutter test test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart
8. Result:
   1. Migration-focused test suite passed (5/5)
9. Follow-up actions:
   1. Add widget tests for categories screen navigation and CRUD interactions
10. Risks/notes:
   1. UI enhancement only; migration schema/logic unchanged and remains covered by existing tests

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: Post-CP Test Hardening (Categories UX)
4. Files changed:
   1. test/screens/categories_screen_test.dart
   2. test/screens/project_detail_category_dropdown_test.dart
5. What was done:
   1. Added widget tests for Categories screen CRUD (add/edit/delete)
   2. Added widget test for sidebar navigation route switch to Categories
   3. Added widget test to verify Project Detail category dropdown includes user-created categories
6. Why it was done:
   1. Lock UX behavior end-to-end and verify user-managed categories are dynamically surfaced
7. Tests executed:
   1. flutter test test/screens/categories_screen_test.dart test/screens/project_detail_category_dropdown_test.dart
8. Result:
   1. 3 tests passed, 0 failed
9. Follow-up actions:
   1. Optionally integrate these tests into full regression and coverage run
10. Risks/notes:
   1. No schema changes in this step; migration safety remains as previously validated

---

## 17. Verification Outcome (Session Notes UX)

Date: 2026-03-26

Verified as implemented:

1. Start/stop session notes are optional and skippable via dialog.
2. Timer start/stop behavior is non-blocking for note persistence failures.
3. Task details now include per-task session history with date-time, duration, and notes.
4. Session notes can now be edited from task details.
5. Sessions can now be deleted from task details with confirmation.

Validation evidence:

1. `flutter test test/screens/view_task_session_history_test.dart`
2. `flutter test test/screens/categories_screen_test.dart test/screens/project_detail_category_dropdown_test.dart test/screens/view_task_session_history_test.dart`

Result:

1. Session-notes UX scope is now implemented and test-covered.

Remaining note:

1. Workspace-level 80% coverage gate still requires broader test expansion beyond this feature slice.

1. Date: 2026-03-26
2. Owner: Copilot + Nirav
3. Checkpoint ID: Post-CP Enhancement (Session History UX)
4. Files changed:
   1. lib/presentation/widgets/dialogs/view_task_dialog.dart
   2. lib/presentation/providers/timer_provider.dart
   3. test/screens/view_task_session_history_test.dart
5. What was done:
   1. Added task-level session history panel in task details dialog
   2. Added session date-time and duration visibility
   3. Added session note edit/delete actions with confirmation
   4. Added provider action to update session notes with invalidation
6. Why it was done:
   1. Ensure captured session notes are visible and manageable by users
7. Tests executed:
   1. flutter analyze lib/presentation/widgets/dialogs/view_task_dialog.dart lib/presentation/providers/timer_provider.dart test/screens/view_task_session_history_test.dart
   2. flutter test test/screens/view_task_session_history_test.dart test/screens/project_detail_category_dropdown_test.dart test/screens/categories_screen_test.dart
   3. flutter test --coverage test/screens/categories_screen_test.dart test/screens/project_detail_category_dropdown_test.dart test/screens/view_task_session_history_test.dart test/timer_provider_test.dart test/providers/reports_provider_test.dart test/data/category_and_task_category_test.dart test/data/task_status_migration_test.dart
8. Result:
   1. Analyzer clean for changed scope
   2. Session history/widget tests passed
   3. Focused coverage baseline moved to ~38.53%
9. Follow-up actions:
   1. Expand test coverage in remaining modules to approach global 80% target
10. Risks/notes:
   1. Feature-complete for session visibility/edit/delete in task details
