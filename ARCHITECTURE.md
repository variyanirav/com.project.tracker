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

### **Design System**

```dart
// Consistent across all components
Color scheme: Dark blue navy (#0B111D), Slate (#1E293B), Brand blue (#007bff)
Typography: Inter font, weights 300-700
Border Radius: 12px (ROUND_TWELVE)
Spacing: 4px, 8px, 12px, 16px, 24px, 32px (multiples of 4)
Shadows: Elevation 2, 4, 8, 16
```

---

## ✨ MVP Features Scope

### **Phase 1: MVP (Clickable Prototype)**
- ✅ Dashboard with project cards
- ✅ Create/edit projects
- ✅ Project detail view with timer
- ✅ Task creation and management
- ✅ Daily progress tracking
- ✅ Light/dark theme toggle

### **Phase 2: Timer & Logic**
- ⏳ Start/pause/stop timer
- ⏳ Background timer persistence
- ⏳ System tray integration
- ⏳ Database persistence

### **Phase 3: Reporting & Export**
- 📊 Weekly/daily reports
- 📊 CSV export functionality
- 📊 Task history view

### **Backlog (Future)**
- 🔔 Notifications
- ⌨️ Keyboard shortcuts
- 📱 Mobile sync
- ☁️ Cloud backup
- 👥 Team collaboration

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
