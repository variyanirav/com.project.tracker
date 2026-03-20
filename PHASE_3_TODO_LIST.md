# Phase 3: Database & Data Integration - Complete TODO List

**Status:** Ready to Start  
**Date Created:** March 20, 2026  
**Duration Estimate:** 3-5 days  
**Objective:** Integrate Drift ORM database, implement repositories, and wire providers for real data

---

## 📋 Decisions Made

### Storage Strategy
- ✅ **Daily Goal**: SharedPreferences (fast, simple, local)
- ✅ **Timer State**: SharedPreferences (temporary during session) → DB (on pause/stop)
- ✅ **Project/Task Data**: SQLite via Drift ORM
- ✅ **Timezone**: All timestamps stored in UTC, convert to local on display

### Timer Persistence
- ✅ Save state to SharedPreferences on pause/stop (not every second)
- ✅ On app close with active timer: save state, mark as stopped
- ✅ User manually resumes next time (few seconds loss is acceptable)
- ✅ No auto-resume feature

### Business Logic
- ✅ Task `totalSeconds` = cumulative sum of all timer sessions for that task
- ✅ Each timer session = separate DB entry
- ✅ Project total hours = computed on-the-fly (SUM of all task totalSeconds)
- ✅ Consistency > Performance (critical for client billing)

### Architecture
- ✅ Use abstract repository interfaces (domain layer)
- ✅ Implement in data layer
- ✅ Utility functions for timezone conversion (centralized)

---

## 🗂️ Phase 3.1: Database Setup (Drift ORM)

### 1.1 Database Table Definitions
- [ ] **1.1.1** Create `lib/data/database/tables/projects_table.dart`
  - Fields: id, name, description, avatarEmoji, status, createdAt, updatedAt
  - Primary key: id
  
- [ ] **1.1.2** Create `lib/data/database/tables/tasks_table.dart`
  - Fields: id, projectId (FK), taskName, description, status, totalSeconds, isRunning, lastStartedAt, lastSessionId, createdAt, updatedAt
  - Primary key: id
  - Foreign key: projectId → projects(id)
  
- [ ] **1.1.3** Create `lib/data/database/tables/timer_sessions_table.dart`
  - Fields: id, taskId (FK), projectId (FK), startTime, endTime, elapsedSeconds, isPaused, notes, createdAt
  - Primary key: id
  - Foreign keys: taskId, projectId
  
- [ ] **1.1.4** Create `lib/data/database/tables/app_settings_table.dart`
  - Fields: key, value (for future settings storage, if needed)
  
- [ ] **1.1.5** Create `lib/data/database/app_database.dart`
  - Import all table classes
  - Annotate with @DriftDatabase
  - Include all tables: projects, tasks, timerSessions, appSettings
  - Create getter methods for table DAOs

- [ ] **1.1.6** Create/Update `build.yaml` in project root
  - Add Drift configuration
  - Set sqlite3 as database

- [ ] **1.1.7** Run code generation
  - Command: `flutter pub run build_runner build`
  - Verify `.drift.dart` files generated in `lib/data/database/`
  - Verify `database.g.dart` created

- [ ] **1.1.8** Verify database compilation
  - Run: `flutter analyze`
  - No errors in generated database code

---

## 🔄 Phase 3.2: Utility Functions (Timezone & Time Calculations)

### 2.1 Timezone Utilities
- [ ] **2.1.1** Create `lib/core/utils/timezone_helper.dart`
  - `DateTime toUtc(DateTime local)` - convert local to UTC before storing
  - `DateTime toLocal(DateTime utc)` - convert UTC to local for display
  - `String formatTimestampForDisplay(DateTime utc)` - display-ready format
  - `DateTime getCurrentDateUtc()` - get today in UTC
  - `DateTime getMonday(DateTime utcDate)` - get Monday of week

### 2.2 Time Aggregation Utilities
- [ ] **2.2.1** Create `lib/core/utils/time_aggregator.dart`
  - `int sumTaskHours(List<TimerSession> sessions)` - total seconds for task
  - `int calculateDailyHours(List<TimerSession> sessions, DateTime dayUtc)` - sum for specific day
  - `int calculateWeeklyHours(List<TimerSession> sessions, DateTime weekStartUtc)` - sum Mon-Sun
  - `int calculateTotalHours(List<TimerSession> sessions)` - sum all-time
  - `bool isToday(DateTime sessionUtc)` - check if session happened today
  - `bool isThisWeek(DateTime sessionUtc)` - check if session in current week
  - `Duration formatSecondsToDuration(int seconds)` - 7200 → 2h

### 2.3 SharedPreferences Helper
- [ ] **2.3.1** Create `lib/core/utils/shared_preferences_helper.dart`
  - `Future<void> saveDailyGoal(int minutes)` - save goal
  - `Future<int> getDailyGoal()` - fetch goal or default 480
  - `Future<void> saveActiveTimer(String? taskId, int elapsedSeconds)` - temp timer state
  - `Future<(String?, int)?> getActiveTimer()` - fetch temp state
  - `Future<void> clearActiveTimer()` - clear on stop

---

## 📊 Phase 3.3: Data Models (Presentation Layer)

### 3.1 Create Models from Database
- [ ] **3.1.1** Create `lib/data/models/project_model.dart`
  - Properties: id, name, description, avatarEmoji, status, createdAt, updatedAt
  - Methods: `ProjectEntity toEntity()`, `factory ProjectModel.fromEntity()`

- [ ] **3.1.2** Create `lib/data/models/task_model.dart`
  - Properties: id, projectId, taskName, description, status, totalSeconds, isRunning, lastStartedAt, lastSessionId, createdAt, updatedAt
  - Methods: `TaskEntity toEntity()`, `factory TaskModel.fromEntity()`
  - Helper: `String getDurationFormatted()` - display "2h 30m"

- [ ] **3.1.3** Create `lib/data/models/timer_session_model.dart`
  - Properties: id, taskId, projectId, startTime, endTime, elapsedSeconds, isPaused, notes, createdAt
  - Methods: `TimerSessionEntity toEntity()`, `factory TimerSessionModel.fromEntity()`

---

## 🏛️ Phase 3.4: Repository Interfaces (Domain Layer - Abstraction)

### 4.1 Abstract Repository Classes
- [ ] **4.1.1** Create `lib/domain/repositories/i_project_repository.dart`
  - Methods:
    - `Future<void> createProject(ProjectEntity project)`
    - `Future<ProjectEntity?> getProjectById(String id)`
    - `Future<List<ProjectEntity>> getAllProjects()`
    - `Future<void> updateProject(ProjectEntity project)`
    - `Future<void> deleteProject(String id)`
    - `Future<int> getProjectTotalHours(String projectId)` - computed

- [ ] **4.1.2** Create `lib/domain/repositories/i_task_repository.dart`
  - Methods:
    - `Future<void> createTask(TaskEntity task)`
    - `Future<TaskEntity?> getTaskById(String id)`
    - `Future<List<TaskEntity>> getTasksByProject(String projectId, {int limit = 20, int offset = 0})`
    - `Future<void> updateTask(TaskEntity task)`
    - `Future<void> deleteTask(String id)`
    - `Future<List<TaskEntity>> getTasksForToday(String projectId)`
    - `Future<void> updateTaskStatus(String taskId, String newStatus)`
    - `Future<int> getTodaysTotalSeconds(String projectId)` - sum today
    - `Future<int> getWeeklyTotalSeconds(String projectId)` - sum this week

- [ ] **4.1.3** Create `lib/domain/repositories/i_timer_session_repository.dart`
  - Methods:
    - `Future<void> createTimerSession(TimerSessionEntity session)`
    - `Future<TimerSessionEntity?> getActiveTimer()` - only 1 running
    - `Future<void> stopTimer(String sessionId, DateTime endTime)`
    - `Future<List<TimerSessionEntity>> getSessionsByTask(String taskId)`
    - `Future<List<TimerSessionEntity>> getSessionsByProject(String projectId)`
    - `Future<List<TimerSessionEntity>> getSessionsForDay(String projectId, DateTime dayUtc)`

- [ ] **4.1.4** Create `lib/domain/repositories/i_daily_goal_repository.dart`
  - Methods:
    - `Future<void> setDailyGoal(int minutes)`
    - `Future<int> getDailyGoal()` - returns 480 if not set
    - `Future<void> resetToDefault()`

---

## 💾 Phase 3.5: Repository Implementations (Data Layer)

### 5.1 Project Repository
- [ ] **5.1.1** Create `lib/data/repositories/project_repository.dart` (implements IProjectRepository)
  - [ ] 5.1.1a Constructor: receive AppDatabase instance
  - [ ] 5.1.1b `createProject()` - insert to projects table
  - [ ] 5.1.1c `getProjectById()` - select by id
  - [ ] 5.1.1d `getAllProjects()` - select all, order by createdAt DESC
  - [ ] 5.1.1e `updateProject()` - update with new data
  - [ ] 5.1.1f `deleteProject()` - delete + cascade delete tasks
  - [ ] 5.1.1g `getProjectTotalHours()` - SELECT SUM(totalSeconds) FROM tasks WHERE projectId = ?
  - Error handling: try-catch all methods, throw custom exceptions

### 5.2 Task Repository
- [ ] **5.2.1** Create `lib/data/repositories/task_repository.dart` (implements ITaskRepository)
  - [ ] 5.2.1a Constructor: receive AppDatabase + TimerSessionRepository
  - [ ] 5.2.1b `createTask()` - insert with status='ToDo', totalSeconds=0
  - [ ] 5.2.1c `getTaskById()` - select by id
  - [ ] 5.2.1d `getTasksByProject()` - paginated, order by createdAt DESC
  - [ ] 5.2.1e `updateTask()` - update task fields
  - [ ] 5.2.1f `deleteTask()` - delete + cascade
  - [ ] 5.2.1g `getTasksForToday()` - filter by DATE(createdAt) = TODAY
  - [ ] 5.2.1h `updateTaskStatus()` - set status, update updatedAt
  - [ ] 5.2.1i `getTodaysTotalSeconds()` - query sessions from today, sum elapsedSeconds
  - [ ] 5.2.1j `getWeeklyTotalSeconds()` - query sessions from Mon-Sun, sum
  - Error handling: try-catch all methods

### 5.3 Timer Session Repository
- [ ] **5.3.1** Create `lib/data/repositories/timer_session_repository.dart` (implements ITimerSessionRepository)
  - [ ] 5.3.1a Constructor: receive AppDatabase + TaskRepository
  - [ ] 5.3.1b `createTimerSession()` - insert new session, set isRunning=true
  - [ ] 5.3.1c `getActiveTimer()` - SELECT WHERE isRunning=true LIMIT 1
  - [ ] 5.3.1d `stopTimer()` - update endTime, isRunning=false, update task totalSeconds
  - [ ] 5.3.1e `getSessionsByTask()` - select all for task, order by startTime DESC
  - [ ] 5.3.1f `getSessionsByProject()` - select all for project
  - [ ] 5.3.1g `getSessionsForDay()` - filter by date, query from 00:00 to 23:59 UTC
  - Error handling: try-catch all

### 5.4 Daily Goal Repository
- [ ] **5.4.1** Create `lib/data/repositories/daily_goal_repository.dart` (implements IDailyGoalRepository)
  - [ ] 5.4.1a Constructor: receive SharedPreferencesHelper
  - [ ] 5.4.1b `setDailyGoal()` - save to SharedPreferences
  - [ ] 5.4.1c `getDailyGoal()` - fetch or return 480 default
  - [ ] 5.4.1d `resetToDefault()` - set to 480

---

## 🔌 Phase 3.6: Service Layer (Optional but Recommended)

### 6.1 Database Service
- [ ] **6.1.1** Create `lib/services/database_service.dart`
  - Singleton pattern for AppDatabase
  - `Future<void> initializeDatabase()` - called on app startup
  - `AppDatabase getDatabase()` - getter

### 6.2 Timer Service (Prepares for Phase 4)
- [ ] **6.2.1** Create `lib/services/timer_service.dart` (basic)
  - Store references to repositories
  - `Future<void> startTimer(String taskId, String projectId)` - create session
  - `Future<void> stopTimer(String sessionId)` - stop & save
  - `Future<(String?, int)?> getActiveTimer()` - from SharedPrefs

---

## 🚀 Phase 3.7: Riverpod Providers (Wire Data from DB)

### 7.1 Database Provider
- [ ] **7.1.1** Create `lib/presentation/providers/database_provider.dart`
  - `databaseProvider` - provide AppDatabase singleton
  - `projectRepositoryProvider` - provide initialized repository
  - `taskRepositoryProvider` - provide initialized repository
  - `timerSessionRepositoryProvider` - provide initialized repository
  - `dailyGoalRepositoryProvider` - provide initialized repository

### 7.2 Project Provider Updates
- [ ] **7.2.1** Update `lib/presentation/providers/project_provider.dart`
  - [ ] 7.2.1a `allProjectsProvider` - fetch from DB via repository
  - [ ] 7.2.1b `projectDetailProvider(String projectId)` - single project + hours calculated
  - [ ] 7.2.1c `projectTotalHoursProvider(String projectId)` - computed from DB
  - [ ] 7.2.1d `createProjectProvider` - StateNotifier to create & persist

### 7.3 Task Provider Updates
- [ ] **7.3.1** Update `lib/presentation/providers/task_provider.dart`
  - [ ] 7.3.1a `tasksByProjectProvider(String projectId)` - paginated from DB
  - [ ] 7.3.1b `todayTasksProvider(String projectId)` - filtered from DB
  - [ ] 7.3.1c `createTaskProvider` - create with status='ToDo'
  - [ ] 7.3.1d `updateTaskStatusProvider(String taskId, String status)` - update status
  - [ ] 7.3.1e `taskHoursProvider(String taskId)` - get totalSeconds

### 7.4 Timer Provider Updates
- [ ] **7.4.1** Update `lib/presentation/providers/timer_provider.dart`
  - [ ] 7.4.1a `activeTimerProvider` - fetch from DB via repository
  - [ ] 7.4.1b `startTimerProvider` - StateNotifier
    - Check if another timer active → show dialog "Stop current?"
    - Create new session, save to SharedPrefs
    - Update task status to 'In Progress'
  - [ ] 7.4.1c `stopTimerProvider` - stop timer, update task totalSeconds, save to DB
  - [ ] 7.4.1d `timerDisplayProvider` - format elapsed time for UI (HH:MM:SS)
  - [ ] 7.4.1e `pauseTimerProvider` (optional for Phase 4)

### 7.5 Daily Goal Provider
- [ ] **7.5.1** Create `lib/presentation/providers/daily_goal_provider.dart`
  - [ ] 7.5.1a `dailyGoalProvider` - StateNotifier, fetch from repository
  - [ ] 7.5.1b `todayProgressProvider` - calculate % (todaysHours / dailyGoal)
  - [ ] 7.5.1c `updateDailyGoalProvider` - StateNotifier to update & persist

---

## 🎨 Phase 3.8: UI Screen Updates (Wire Providers)

### 8.1 Dashboard Screen
- [ ] **8.1.1** Update `lib/presentation/screens/dashboard_screen.dart`
  - [ ] 8.1.1a Watch `allProjectsProvider` instead of mock data
  - [ ] 8.1.1b Watch `dailyProgressProvider` for dynamic progress display
  - [ ] 8.1.1c Watch `activeTimerProvider` to show running timer card conditionally
  - [ ] 8.1.1d Wire "Add Project" to create via `createProjectProvider`
  - [ ] 8.1.1e Wire "Daily Goal" settings dialog to `updateDailyGoalProvider`
  - [ ] 8.1.1f Show real project cards with DB data

### 8.2 Project List Screen
- [ ] **8.2.1** Update `lib/presentation/screens/project_list_screen.dart`
  - [ ] 8.2.1a Watch `allProjectsProvider`
  - [ ] 8.2.1b Wire edit/delete buttons to repositories
  - [ ] 8.2.1c Show real data from DB

### 8.3 Project Detail Screen
- [ ] **8.3.1** Update `lib/presentation/screens/project_detail_screen.dart`
  - [ ] 8.3.1a Watch `projectDetailProvider(projectId)` for project data
  - [ ] 8.3.1b Watch `projectTotalHoursProvider` for hours display
  - [ ] 8.3.1c Watch `tasksByProjectProvider` for task list (with pagination)
  - [ ] 8.3.1d Watch `todayTasksProvider` for today's section
  - [ ] 8.3.1e Wire "Create Task" button to `createTaskProvider`
  - [ ] 8.3.1f Wire "Start Timer" to `startTimerProvider`
    - Check `activeTimerProvider` for conflicts
    - Show dialog if another timer running
  - [ ] 8.3.1g Update task status when timer starts
  - [ ] 8.3.1h Wire "Stop Timer" to `stopTimerProvider`

### 8.4 Reports Screen
- [ ] **8.4.1** Update `lib/presentation/screens/reports_screen.dart`
  - [ ] 8.4.1a Use providers for real data (implement later in Phase 4)

---

## ✅ Phase 3.9: Testing & Verification

### 9.1 Build & Compilation
- [ ] **9.1.1** Run `flutter pub get`
- [ ] **9.1.2** Run `flutter pub run build_runner build` (all Drift code generated)
- [ ] **9.1.3** Run `flutter analyze` (no errors)
- [ ] **9.1.4** Run `flutter run -d macos` (app launches without crashes)

### 9.2 Manual Testing
- [ ] **9.2.1** Create a project
  - [ ] 9.2.1a Open dashboard
  - [ ] 9.2.1b Click "Add New Project"
  - [ ] 9.2.1c Enter name, description, emoji
  - [ ] 9.2.1d Click "Create"
  - [ ] 9.2.1e Verify project appears on dashboard
  - [ ] 9.2.1f Close app, reopen → data persists

- [ ] **9.2.2** Create a task
  - [ ] 9.2.2a Open project detail
  - [ ] 9.2.2b Click "Create Task"
  - [ ] 9.2.2c Enter title, description, status
  - [ ] 9.2.2d Verify task appears in list
  - [ ] 9.2.2e Close app, reopen → task persists

- [ ] **9.2.3** Start timer
  - [ ] 9.2.3a Click task "Start" button
  - [ ] 9.2.3b Verify timer running card shows on dashboard
  - [ ] 9.2.3c Verify task status changed to "In Progress" in list
  - [ ] 9.2.3d Try to start another timer → shows "Stop current?" dialog

- [ ] **9.2.4** Stop timer
  - [ ] 9.2.4a Click "Stop" on running timer card
  - [ ] 9.2.4b Verify timer card disappears from dashboard
  - [ ] 9.2.4c Verify task totalSeconds updated
  - [ ] 9.2.4d Verify task hours display updated ("2h 30m")

- [ ] **9.2.5** Daily goal
  - [ ] 9.2.5a Click "Daily Goal Settings" button
  - [ ] 9.2.5b Set goal to 5 hours
  - [ ] 9.2.5c Close dialog
  - [ ] 9.2.5d Verify dashboard progress card updated
  - [ ] 9.2.5e Close app, reopen → goal persists

- [ ] **9.2.6** Data consistency
  - [ ] 9.2.6a Create multiple tasks
  - [ ] 9.2.6b Start/stop on each
  - [ ] 9.2.6c Verify project total = sum of all task hours
  - [ ] 9.2.6d Verify today's progress updated correctly

### 9.3 Error Handling
- [ ] **9.3.1** Test edge cases
  - [ ] 9.3.1a Delete project with tasks → tasks deleted
  - [ ] 9.3.1b Create task with empty title → validation error
  - [ ] 9.3.1c Start timer with no task → handled gracefully

---

## 📝 Phase 3.10: Documentation & Cleanup

### 10.1 Code Documentation
- [ ] **10.1.1** Add inline comments to complex logic (timezone, aggregation)
- [ ] **10.1.2** Document repository method contracts

### 10.2 Update ROADMAP
- [ ] **10.2.1** Update ROADMAP.md Phase 3 status to 100% complete
- [ ] **10.2.2** Document decisions made

### 10.3 Prepare for Phase 4
- [ ] **10.3.1** Document Phase 4 timer service requirements
- [ ] **10.3.2** Note any technical debt or future improvements

---

## 📊 Summary

**Total Tasks: ~85 individual items**

**By Category:**
- Database Setup: 8 tasks
- Utility Functions: 8 tasks
- Data Models: 3 tasks
- Repository Interfaces: 4 tasks
- Repository Implementations: 15 tasks
- Service Layer: 2 tasks
- Riverpod Providers: 18 tasks
- UI Integration: 10 tasks
- Testing: 12 tasks
- Documentation: 3 tasks

**Estimated Timeline:**
- Database setup: 1 day
- Repositories: 1.5 days
- Providers & UI: 1.5 days
- Testing & debugging: 1 day
- **Total: 3-4 days** (compressed schedule, high focus)

---

## 🎯 Success Criteria

**Phase 3 is complete when:**
- ✅ All Drift tables created and code generated
- ✅ All repositories implemented with full CRUD
- ✅ All providers wired to DB data (not mock)
- ✅ Dashboard shows real projects with real hours
- ✅ Project detail shows real tasks with real hours
- ✅ Timer system enforces single active timer
- ✅ Daily goal stored & displayed dynamically
- ✅ All manual tests pass
- ✅ `flutter analyze` returns clean build
- ✅ Data persists across app restarts

---

## 🔑 Key Decisions Implemented

1. ✅ **Daily Goal**: SharedPreferences (simple, fast)
2. ✅ **Timer State**: Temporary in SharedPrefs, persistent in DB on pause/stop
3. ✅ **Timezone**: UTC storage, local display via utilities
4. ✅ **Task Hours**: Cumulative per task, aggregated to project
5. ✅ **Project Hours**: On-the-fly calculation (consistency for billing)
6. ✅ **Repository Pattern**: Abstract interfaces → concrete implementation
7. ✅ **Timer Constraint**: Only 1 active across entire app

---

**Ready to start Phase 3? Answer me one final question:**

Should I start with **Database Setup (1.1)** or would you like me to clarify anything else first?
