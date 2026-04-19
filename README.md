# Project Tracker - Time Tracking & Task Management

A professional macOS desktop application for tracking billable hours on projects and tasks. Built with Flutter 3.x, Riverpod state management, and Drift ORM with SQLite.

## 🎯 Overview

**Project Tracker** enables freelancers, developers, and teams to:
- ✅ Create and manage multiple projects with custom avatars
- ✅ Track time on individual tasks with start/pause/stop controls
- ✅ Use the standalone Focus Timer for healthy work/break sessions
- ✅ Archive and restore completed tasks with read-only protection
- ✅ View daily progress and aggregate statistics
- ✅ Export weekly CSV reports for billing and analysis
- ✅ Organize work sessions with optional notes and categories

## 🎨 Features

### Core Features (Implemented)
- **Project Management**: Create, edit, delete projects with custom status tracking
- **Task Management**: Full CRUD operations for tasks with status transitions (To Do → In Progress → Complete → Archive)
- **Timer System**: Single active timer with pause/resume/stop functionality
- **Archive System**: Soft-delete with restore capability + read-only session history
- **Reporting**: Dashboard with daily/weekly/total hour calculations
- **CSV Export**: Generate billing reports in standard CSV format
- **Dark/Light Theme**: Full theme toggle support with system preferences integration

### Archive Feature (Latest - v1.2.0)
- **Archive Completed Tasks**: Archive button on completed tasks only
- **Read-Only Protection**: Archived tasks cannot be edited or have timer operations
- **Session History Lock**: Session notes are copy-only (no edit/delete) for archived tasks
- **Restore Workflow**: Restore button returns tasks to completed status with confirmation
- **Full Test Coverage**: 9 comprehensive widget tests validate archive flow and permissions

### Focus Timer Release (Latest - v1.3.0)
- **Standalone Focus Mode**: Dedicated timer for healthy work/break cycles, separate from task tracking
- **Local Persistence**: Active focus state restores after restart without cloud sync
- **Phase Tracking**: Tracks each focus phase with history and summary cards
- **Theme Parity**: Matches the current light/dark themes, dialog widths, and typography
- **Production Validation**: Focus timer domain, data, provider, screen, navigation, and integration tests pass

## 🏗️ Architecture

```
Presentation Layer (Screens, Widgets, Riverpod Providers)
        ↓
Domain Layer (Business Logic, Entities, Repository Interfaces)
        ↓
Data Layer (Repositories, Models, Drift ORM, SQLite Database)
```

**Tech Stack:**
- **Framework**: Flutter 3.x + Dart 3.5.2
- **State Management**: flutter_riverpod 2.4.0
- **Database**: Drift ORM 2.16.0 + SQLite
- **UI Components**: Custom design system with Material Design
- **Theme**: Dark mode (default) + Light mode with system integration

## 📦 Getting Started

### Prerequisites
- macOS 12+ with latest updates
- Flutter 3.9.2+ with Dart 3.5.2+
- Xcode 14+ (for macOS builds)

### Installation & Running

```bash
# Clone or navigate to project
cd /Users/niravvariya/Documents/Projects/Desktop/com.project.tracker

# Install dependencies
flutter pub get

# Run development build
flutter run -d macos

# Run release build
flutter run -d macos --release
```

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete architecture design and patterns
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Developer onboarding guide
- **[ROADMAP.md](ROADMAP.md)** - Project roadmap and phase planning
- **[AI_README.md](AI_README.md)** - AI-ready feature addition patterns
- **[UI_STANDARDS.md](UI_STANDARDS.md)** - UI/UX guidelines and constraints
- **[FOCUS_TIMER_README.md](FOCUS_TIMER_README.md)** - Standalone focus timer requirements, phased plan, and test checklist
- **[FOCUS_TIMER_PHASE_TRACKER.md](FOCUS_TIMER_PHASE_TRACKER.md)** - Execution tracker with per-phase tests and analyze gates

## 🚀 Recent Updates (v1.2.0)

### Archive Feature Release
- ✅ **Completed Tasks Archive**: Archive button appears on completed tasks
- ✅ **Read-Only Enforcement**: Archived tasks are fully read-only
- ✅ **Session History Protection**: Session notes locked to copy operations only
- ✅ **Restore Capability**: One-click restore to completed status
- ✅ **Full Test Coverage**: 9 tests validating archive and restore workflows
- ✅ **Version Bump**: Updated to 1.2.0 for stable release

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/screens/project_detail_screen_test.dart

# Generate coverage report
flutter test --coverage
```

Current test status: **9/9 passing** ✅

## 📋 Project Structure

```
lib/
├── core/              # Shared utilities, theme, reusable widgets
├── data/              # Database, models, repository implementations
├── domain/            # Business logic, entities, interfaces
└── presentation/      # Screens, widgets, Riverpod providers

test/
├── screens/           # Widget tests for screens
├── providers/         # Unit tests for Riverpod logic
├── models/            # Data model tests
└── integration/       # End-to-end integration tests
```

## 🔄 Build & Release

### Development
```bash
flutter run -d macos
```

### Production Release
```bash
# Use the macOS release script (safe with automatic backups)
bash scripts/release_macos_safe.sh

# Or manual build
flutter build macos --release
```

## 📝 Changelog

### Version 1.3.0 - Focus Timer Release
- Added a standalone Focus Timer for healthy work/break sessions
- Implemented local persistence and restart restore for active focus runs
- Added focus history, settings, navigation, and notification support
- Added domain, data, provider, UI, and integration tests for the new feature
- Kept the focus timer independent from the existing task timer

### Version 1.2.0 - Archive Feature Release
- Added archive functionality for completed tasks
- Implemented read-only mode with session history protection
- Added restore workflow with confirmation dialogs
- Added 9 comprehensive widget tests for archive flow
- Full feature documentation and test coverage

### Version 1.1.0 - Timer & Core Features
- Timer start/pause/stop functionality
- Project and task management
- Daily/weekly reporting
- CSV export

### Version 1.0.0 - MVP Foundation
- Clean architecture setup
- Theme system with dark/light modes
- Reusable component library
- Database schema design with Drift ORM

## 🤝 Contributing

See [GETTING_STARTED.md](GETTING_STARTED.md) for development guidelines.

## 📄 License

Private project. All rights reserved.

## 📞 Support

For issues, feature requests, or questions about architecture, refer to:
- [ARCHITECTURE.md](ARCHITECTURE.md) for design patterns
- [AI_README.md](AI_README.md) for feature implementation examples
- Source code comments and documentation

---

**Last Updated**: April 19, 2026  
**Status**: Active Development  
**Current Version**: 1.3.0
