# Project Tracker - Architecture & Design Document

**Created:** March 19, 2026  
**Project:** TimeTracker - Desktop Application (macOS)  
**Status:** MVP Phase - Prototype Development

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Architecture Patterns](#architecture-patterns)
4. [Folder Structure](#folder-structure)
5. [Data Models & Database Schema](#data-models--database-schema)
6. [State Management](#state-management)
7. [Component Library](#component-library)
8. [Features Scope](#features-scope)
9. [Database Migrations](#database-migrations)
10. [Future Extensibility](#future-extensibility)

---

## 🎯 Project Overview

**TimeTracker** is a macOS desktop application for tracking billable hours on projects and tasks. It enables freelancers/developers to:
- Create multiple projects
- Start/pause/stop timers for individual tasks
- View daily progress dashboard
- Export weekly CSV reports for billing
- Track time across sessions seamlessly

### Key Principles
- ✅ **SOLID principles** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- ✅ **DRY (Don't Repeat Yourself)** - Reusable components and utilities
- ✅ **Clean Architecture** - Clear separation of concerns (Presentation, Domain, Data)
- ✅ **Scalability** - Database designed to extend from daily to yearly tracking

---

## 🛠 Tech Stack

| Layer | Technology | Reason |
|-------|-----------|--------|
| **Framework** | Flutter 3.x | Cross-platform, desktop-first, beautiful UI |
| **State Management** | Riverpod | Type-safe, testable, no boilerplate |
| **Database** | SQLite (sqflite) | Local-only, zero-config, scalable |
| **Persistence** | Drift (ORM) | Type-safe queries, migration support |
| **Theme** | Flutter's ThemeData | Native light/dark mode support |
| **Notifications** | flutter_local_notifications | Background notifications |
| **CSV Export** | csv package | Generate CSV reports |
| **System Tray** | system_tray / tray_manager | Menu bar icon on macOS |

---

## 🏗 Architecture Patterns

### **Clean Architecture (3 Layers)**

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (UI/Screens)                        │
│  - Screens, Widgets, BLoCs, Riverpod Consumers          │
├─────────────────────────────────────────────────────────┤
│  DOMAIN LAYER (Business Logic/Entities)                 │
│  - Use Cases, Entities, Repositories (interfaces)       │
├─────────────────────────────────────────────────────────┤
│  DATA LAYER (Data Sources)                              │
│  - Database, Local Storage, APIs                        │
└─────────────────────────────────────────────────────────┘
```

### **Dependency Injection Flow**

```
Riverpod Providers → Services → Repositories → Database
```

---

## 📁 Folder Structure

```
com.project.tracker/
│
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # App configuration
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart        # App-wide constants
│   │   │   └── colors.dart               # Color palette
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # Theme definitions
│   │   │   └── text_styles.dart          # Text styles
│   │   ├── utils/
│   │   │   ├── extensions.dart           # Dart extensions
│   │   │   ├── formatters.dart           # Time/date formatters
│   │   │   └── validators.dart           # Input validators
│   │   └── widgets/                      # Reusable components
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── app_card.dart
│   │       ├── app_icon.dart
│   │       ├── app_avatar.dart
│   │       ├── custom_scaffold.dart
│   │       └── responsive_layout.dart
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   └── local_data_source.dart    # SQLite operations
│   │   ├── models/
│   │   │   ├── project_model.dart
│   │   │   ├── task_model.dart
│   │   │   └── timer_session_model.dart
│   │   ├── repositories/
│   │   │   ├── project_repository.dart
│   │   │   ├── task_repository.dart
│   │   │   └── timer_repository.dart
│   │   └── database/
│   │       ├── app_database.dart         # Drift DB config
│   │       ├── migrations/
│   │       │   └── migration_001.dart
│   │       └── tables/
│   │           ├── projects_table.dart
│   │           ├── tasks_table.dart
│   │           └── timer_sessions_table.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── project_entity.dart
│   │   │   ├── task_entity.dart
│   │   │   └── timer_session_entity.dart
│   │   ├── repositories/
│   │   │   ├── abstract_project_repository.dart
│   │   │   ├── abstract_task_repository.dart
│   │   │   └── abstract_timer_repository.dart
│   │   └── usecases/
│   │       ├── create_project_usecase.dart
│   │       ├── create_task_usecase.dart
│   │       ├── start_timer_usecase.dart
│   │       ├── stop_timer_usecase.dart
│   │       └── export_report_usecase.dart
│   │
│   ├── presentation/
│   │   ├── providers/                   # Riverpod providers
│   │   │   ├── project_provider.dart
│   │   │   ├── task_provider.dart
│   │   │   ├── timer_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── project_detail_screen.dart
│   │   │   ├── reports_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── widgets/                    # Screen-specific widgets
│   │   │   ├── dashboard/
│   │   │   │   ├── project_card.dart
│   │   │   │   ├── daily_progress_card.dart
│   │   │   │   └── project_grid.dart
│   │   │   ├── project_detail/
│   │   │   │   ├── active_task_panel.dart
│   │   │   │   ├── task_history_panel.dart
│   │   │   │   └── timer_display.dart
│   │   │   └── reports/
│   │   │       ├── project_summary_table.dart
│   │   │       └── export_section.dart
│   │   └── routes/
│   │       └── app_router.dart
│   │
│   └── services/
│       ├── database_service.dart       # DB initialization
│       ├── timer_service.dart          # Timer logic
│       ├── notification_service.dart   # Notifications
│       └── export_service.dart         # CSV export
│
├── pubspec.yaml                        # Dependencies
├── build.yaml                          # Build config (Drift)
├── analysis_options.yaml               # Linter rules
├── ARCHITECTURE.md                     # This file
├── AI_README.md                        # AI-ready feature doc
├── DATABASE_SCHEMA.md                  # DB schema docs
└── COMPONENT_LIBRARY.md                # Component reference

```

---

## 📊 Data Models & Database Schema

### **Entity Relationships**

```
┌──────────────┐         ┌────────────┐         ┌──────────────────┐
│  Project     │◄────────│   Task     │◄────────│  TimerSession    │
├──────────────┤         ├────────────┤         ├──────────────────┤
│ id (PK)      │1       │ id (PK)    │1       │ id (PK)          │
│ name         │    *   │ projectId  │    *   │ taskId           │
│ description  │        │ taskName   │        │ startTime        │
│ color        │        │ description│        │ endTime          │
│ createdAt    │        │ status     │        │ elapsedSeconds   │
│ updatedAt    │        │ createdAt  │        │ isPaused         │
│             │        │ updatedAt  │        │ createdAt        │
└──────────────┘         └────────────┘         └──────────────────┘
```

### **Database Tables**

#### **projects**
```sql
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT DEFAULT '#007bff',
  status TEXT DEFAULT 'active', -- active, archived
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

#### **tasks**
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  task_name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- pending, in_progress, completed
  total_seconds INTEGER DEFAULT 0,
  is_running BOOLEAN DEFAULT 0,
  last_started_at INTEGER,
  last_session_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);
```

#### **timer_sessions**
```sql
CREATE TABLE timer_sessions (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  start_time INTEGER NOT NULL,
  pause_time INTEGER,
  resume_time INTEGER,
  end_time INTEGER,
  total_seconds INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT 0,
  session_date TEXT NOT NULL, -- YYYY-MM-DD
  created_at INTEGER NOT NULL,
  FOREIGN KEY (task_id) REFERENCES tasks(id),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);
```

---

## 🔄 State Management (Riverpod)

### **Provider Hierarchy**

```dart
// Providers structure:
projectsProvider              // List of all projects
  ├─ projectByIdProvider       // Single project details
  ├─ projectsForDateProvider   // Projects by date
  └─ dailyProjectStatsProvider // Hours per project/day

tasksProvider                 // List of all tasks
  ├─ tasksByProjectProvider    // Tasks filtered by project
  └─ activeTaskProvider        // Currently running task

timerProvider                 // Timer state and logic
  ├─ currentTimerProvider      // Active timer session
  ├─ timerSessionsProvider     // All timer sessions
  └─ pausedTimerProvider       // Paused timer state

themeProvider                 // Dark/Light mode toggle

reportsProvider               // Export/report data
```

---

## 🎨 Component Library (Reusable Widgets)

### **Core Components (in `core/widgets/`)**

| Component | Purpose |
|-----------|---------|
| `AppButton` | Primary, secondary, danger button variants |
| `AppTextField` | Text input with validation support |
| `AppCard` | Elevated card container |
| `AppIcon` | Icon wrapper with sizing |
| `AppAvatar` | User/project avatar |
| `CustomScaffold` | App structure with nav rail |
| `ResponsiveLayout` | Mobile/tablet/desktop layouts |
| `AppConfirmationDialog` | Reusable async-aware confirmation component |

### **Archive Feature Components (NEW - v1.2.0)**

#### AppConfirmationDialog
**File:** `lib/core/widgets/app_confirmation_dialog.dart`

A reusable dialog component for yes/no decisions with async callback support.

**Properties:**
```dart
- title: String                           // Dialog title
- message: String?                        // Optional description
- confirmText: String = 'Confirm'         // Confirm button label
- cancelText: String = 'Cancel'           // Cancel button label
- confirmButtonColor: Color               // Confirm button color
- onConfirm: FutureOr<void> Function()    // Async callback
```

**Usage:**
```dart
final shouldArchive = await showDialog<bool>(
  context: context,
  builder: (context) => AppConfirmationDialog(
    title: 'Archive Task?',
    message: 'This will move the task to archive.',
    confirmText: 'Archive',
    onConfirm: () async => await archiveTask(taskId),
  ),
) ?? false;
```

#### Archive-Related Enhancements

**TaskStatus Enum Update** (`lib/core/constants/task_status.dart`)
```dart
enum TaskStatus {
  toDo('toDo', 'To Do'),
  inProgress('inProgress', 'In Progress'),
  complete('complete', 'Complete'),
  archived('archived', 'Archived'),  // NEW
}

// Color mapping
getColor() {
  switch (this) {
    case TaskStatus.archived:
      return Color(0xFF64748B);  // Gray
    // ... other cases
  }
}
```

**TaskListView Enhancements** (`lib/presentation/widgets/project_detail/task_list_view.dart`)
```dart
// NEW parameters
class TaskListView extends StatelessWidget {
  final bool readOnly;                    // Hide edit/delete buttons
  final bool showArchiveButton;           // Show archive for complete tasks
  final Function(String)? onArchiveTask;  // Archive callback
}

// NEW conditional rendering
if (!readOnly && task.status == TaskStatus.complete) {
  // Show archive button
}

if (readOnly) {
  // Hide start/stop/edit buttons
}
```

**ViewTaskDialog Enhancements** (`lib/presentation/widgets/dialogs/view_task_dialog.dart`)
```dart
// NEW parameter
class ViewTaskDialog extends ConsumerWidget {
  final bool? readOnly;  // null = auto-detect from task status
}

// NEW auto-detection
@override
Widget build(context, ref) {
  bool isReadOnly = readOnly ?? (task.status == TaskStatus.archived);
  
  // When read-only:
  // - TextFields are disabled
  // - Session Actions menu filtered (copy-only)
  // - No edit/delete buttons visible
}

// NEW session action filtering
if (isReadOnly) {
  actions = [
    SessionAction.copyStopNote,  // Only copy allowed
  ];
} else {
  actions = [
    SessionAction.editStartNote,
    SessionAction.editStopNote,
    SessionAction.copyStopNote,
    SessionAction.deleteSession,
  ];
}
```

**ProjectDetailScreen Archive Tab** (`lib/presentation/screens/project_detail_screen.dart`)
```dart
// NEW state for tab toggle
late TabController _taskTabController;  // 'Tasks' vs 'Archive' tabs

@override
Widget build(context, ref) {
  return Column(
    children: [
      // Tab bar
      TabBar(
        controller: _taskTabController,
        tabs: [
          Tab(text: 'Tasks (${activeTasks.length})'),
          Tab(text: 'Archive (${archivedTasks.length})'),
        ],
      ),
      
      // Tab content
      Expanded(
        child: TabBarView(
          controller: _taskTabController,
          children: [
            // Active tasks view with archive actions
            TaskListView(
              tasks: activeTasks,
              showArchiveButton: true,
              onArchiveTask: _archiveTask,
            ),
            
            // Archived tasks view (read-only + restore)
            TaskListView(
              tasks: archivedTasks,
              readOnly: true,
              showArchiveButton: false,
              onRestoreTask: _restoreTask,  // Restore button instead
            ),
          ],
        ),
      ),
    ],
  );
}

// NEW: Archive with confirmation
Future<void> _archiveTask(String taskId) async {
  bool confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmationDialog(
      title: 'Archive Task?',
      confirmText: 'Archive',
      onConfirm: () async {
        await ref.read(archiveTaskProvider(taskId).future);
      },
    ),
  ) ?? false;
}

// NEW: Restore with confirmation
Future<void> _restoreTask(String taskId) async {
  bool confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmationDialog(
      title: 'Restore Task?',
      message: 'This will move the task back to active work.',
      confirmText: 'Restore',
      onConfirm: () async {
        await ref.read(restoreTaskProvider(taskId).future);
      },
    ),
  ) ?? false;
}
```

### **Design System**

```dart
// Consistent across all components
Color scheme: Dark blue navy (#0B111D), Slate (#1E293B), Brand blue (#007bff)
Archive Color: Gray (#64748B) - indicates read-only/archived state
Typography: Inter font, weights 300-700
Border Radius: 12px (ROUND_TWELVE)
Spacing: 4px, 8px, 12px, 16px, 24px, 32px (multiples of 4)
Shadows: Elevation 2, 4, 8, 16
```

---

## ✨ Features & Implementation Status

### **Phase 1: Foundation (COMPLETE - March 19, 2026)** ✅
- ✅ Clean Architecture setup
- ✅ Folder structure organization
- ✅ Theme system (dark/light modes)
- ✅ Component library (7 reusable widgets)
- ✅ Dashboard UI prototype
- ✅ Documentation suite

### **Phase 2: Core Features (COMPLETE - March 20, 2026)** ✅
- ✅ Project detail screen
- ✅ Task management (CRUD)
- ✅ Timer controls (start/pause/stop)
- ✅ Session history tracking
- ✅ Reports/export screen
- ✅ Dialog system
- ✅ Responsive layouts

### **Phase 2.5: Archive Features (COMPLETE - April 11, 2026)** ✅
- ✅ **Archive Completed Tasks**: One-click archive with confirmation
- ✅ **Read-Only Protection**: Task-level and session-level enforcement
- ✅ **Session History Lock**: Copy-only operations on archived sessions
- ✅ **Restore Workflow**: Return tasks to active work
- ✅ **Archive Tab**: Dedicated view with filtering
- ✅ **AppConfirmationDialog**: Reusable async-aware component
- ✅ **Comprehensive Tests**: 9/9 passing

### **Phase 3: Database Integration (COMPLETE - March 20, 2026)** ✅
- ✅ Drift ORM setup
- ✅ 4 database tables
- ✅ Repository layer (790 lines)
- ✅ Riverpod providers (800+ lines, 50+)
- ✅ UI wiring (3 screens)
- ✅ Full CRUD operations

### **Phase 4: Background Services (PLANNED)** 🔄
- ⏳ Background timer
- ⏳ System tray integration
- ⏳ Notifications
- ⏳ Auto-save state

### **Phase 5: Production Polish (READY)** 🚀
- 📊 Integration tests
- 📊 Performance profiling
- 📊 macOS code signing
- 📊 Auto-update mechanism

---

## 🗄 Database Migrations

We'll use **Drift's built-in migration system**:

```
Version 1: Initial schema (projects, tasks, timer_sessions)
Version 2: Add indexes for performance
Version 3: Add archival for old data
...
```

Each migration is **reversible** and **tested** before deployment.

---

## 🚀 Future Extensibility

### **How to Add New Features**

**Example: Adding "Project Categories"**

1. **Database Layer**
   - Add new table `project_categories`
   - Create migration file
   - Update Drift configuration

2. **Domain Layer**
   - Create `ProjectCategoryEntity`
   - Create `ProjectCategoryRepository` interface

3. **Data Layer**
   - Implement `ProjectCategoryRepository`
   - Create data source methods

4. **Presentation Layer**
   - Create Riverpod provider
   - Build UI/screens
   - Connect to business logic

This **layered approach** makes adding features straightforward and testable.

---

## 📈 Scalability Path

```
Day View (MVP)
   ↓
Weekly View (Phase 2)
   ↓
Monthly View (Phase 3)
   ↓
Yearly View & Analytics (Phase 4)
```

Database schema supports all levels with proper indexing.

---

## 🔐 Security & Best Practices

- ✅ Local-only data (no cloud transmission yet)
- ✅ SQLite encrypted (optional in future)
- ✅ Input validation on all forms
- ✅ Type-safe database queries (Drift)
- ✅ Null safety throughout
- ✅ Error handling and logging

---

## 📚 Related Documents

- [AI_README.md](AI_README.md) - AI-friendly feature documentation
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Detailed database design
- [COMPONENT_LIBRARY.md](COMPONENT_LIBRARY.md) - Component usage guide

---

**Next Steps:** Build clickable prototype with Dart/Flutter UI components
