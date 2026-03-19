# ProjectTracker macOS - Implementation Plan
**Version**: 1.0
**Created**: March 18, 2026
**Status**: Active Development

---

## 📋 Executive Summary

Building a production-ready time-tracking application for macOS following SOLID + DRY + Clean Architecture principles. The app tracks hourly work per project/task with daily summaries and weekly CSV billing exports.

**Target Completion**: Phase 1 (MVP) = 2-3 weeks
**Tech Stack**: Swift + SwiftUI + SQLite

---

## 🎯 Core Requirements

### Functional Requirements
- ✅ Start/pause/stop/complete individual tasks
- ✅ One active timer per project at a time
- ✅ Dashboard shows daily hours per project
- ✅ Weekly CSV export with task details
- ✅ Background timer state persistence (NOT continuous)
- ✅ Session recovery on app relaunch

### Non-Functional Requirements
- ✅ SOLID principles (Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion)
- ✅ DRY (Don't Repeat Yourself) - design tokens, reusable components
- ✅ Clean Architecture - Entities → Use Cases → Interface Adapters
- ✅ Responsive to user actions
- ✅ Proper error handling
- ✅ Scalable for future features (monthly/yearly views)

---

## 📁 Architecture Overview

```
ProjectTracker/
│
├── 📦 Core Architecture Layers
│   ├── Models/              # Entities (contracts - no logic)
│   ├── Services/            # Business logic & persistence
│   ├── Local/               # Database & file I/O
│   └── Error/               # Error definitions
│
├── 🎨 Presentation Layer
│   ├── UI/
│   │   ├── Components/      # Reusable UI components (buttons, cards, etc)
│   │   ├── Screens/         # Full screen views (Dashboard, Reports, etc)
│   │   ├── ViewModels/      # State management per screen
│   │   └── Style/           # Design tokens & typography
│   │
│   ├── ContentView.swift    # Root entry point
│   └── ProjectTrackerApp.swift
│
├── 🛠️ Utilities
│   ├── Extensions.swift
│   ├── Logger.swift
│   └── Constants.swift
│
├── 📚 Documentation
│   ├── ARCHITECTURE.md       # Deep dive into layers
│   ├── DATABASE_SCHEMA.md    # SQLite schema & migrations
│   ├── DESIGN_SYSTEM.md      # UI/UX guidelines
│   └── API.md                # Service contracts
│
└── 🧪 Tests
    ├── ProjectTrackerTests/
    └── ProjectTrackerUITests/
```

---

## 🏗️ Implementation Phases

### Phase 1: Foundation (Week 1)
**Scope**: Get working prototype with core features running

#### 1A: Design System Foundation ✅
- [ ] Complete AppTypography with all text styles
- [ ] Complete AppColors with all semantic colors
- [ ] Create AppSizes for spacing/sizing
- [ ] Create AppIcons enum for SF Symbols
- [ ] Create AppAnimations for transitions
- [ ] Review/fix all Components in UI/Components/

#### 1B: Data Binding & ViewModels ✅
- [ ] Create DashboardViewModel (ProjectManager + TimerManager)
- [ ] Create ProjectDetailViewModel (task list + timer state)
- [ ] Create ReportsViewModel (weekly data + export)
- [ ] Connect ViewModels to Views via @ObservedObject

#### 1C: Navigation & Data Flow ✅
- [ ] Implement RootNavigationView with NavigationStack
- [ ] Wire Dashboard → ProjectDetail → Reports navigation
- [ ] Test navigation doesn't break state

#### 1D: Screen Implementation ✅
- [ ] DashboardView: Live project list + daily totals
- [ ] ProjectDetailView: Active timer + task history
- [ ] ReportsView: Weekly summary + CSV export
- [ ] ProjectListView (+ button): Create/edit projects

#### 1E: Testing & Polish ✅
- [ ] Compile without errors
- [ ] Basic user flow test (create project → start timer → view dashboard)
- [ ] Check all 3 mockup screens work
- [ ] Document known limitations

### Phase 2: Enhanced Features (Week 2)
- Navigation history sidebar
- Task filtering/searching
- Project favorites
- Time entry editing
- Pause/resume improvements

### Phase 3: Polish & Optimization (Week 3)
- Performance optimization
- Error recovery
- Data cleanup utilities
- User preferences

---

## 💾 Data Storage Architecture

### Why SQLite?
✅ Modern, scalable, indexed queries
✅ No external dependencies
✅ Supports transactions (data integrity)
✅ Easy to export (CSV from queries)
✅ Scales from daily → yearly views

### Schema
See `DATABASE_SCHEMA.md` - 3 core tables:
- **projects** - Meta + hourly_rate
- **tasks** - Project-linked task definitions
- **time_entries** - Start/end times, durations

### Persistence Strategy
- DatabaseManager handles all queries
- ProjectManager provides Swift objects
- Automatic saves on data changes
- Session recovery via TimerSession table

---

## 🎨 Design System Details

### Colors (Dark Theme)
```
Background:    #1F1F1F (dark navy)
Surface:       #2B2B2B (slightly lighter)
Border:        #515151 (subtle dividers)
Primary:       #0078D4 (Microsoft blue)
Success:       #4CAF50 (green)
Warning:       #FFA500 (orange)
Danger:        #F44336 (red)
Text:          #E8E8E8 (light gray)
TextMuted:     #9E9E9E (muted gray)
```

### Typography Scale
```
Title:         24pt, Bold
Headline:      18pt, Semibold
Body:          14pt, Regular
Caption:       12pt, Medium
Label:         11pt, Medium
```

### Spacing System
```
xxs: 4pt    xs: 8pt    sm: 12pt   md: 16pt
lg:  24pt   xl: 32pt
```

---

## 📐 View Module Breakdown

### 1. **DashboardView**
- Shows all projects with daily totals
- Displays currently active timer (if running)
- Quick actions: + button to create task
- Goal: Replace hardcoded data with `@ObservedObject var viewModel: DashboardViewModel`

### 2. **ProjectDetailView**
- Shows single project: title, client, description
- Large timer display (HH:MM:SS)
- Task list with status badges
- Action buttons: Start/Pause/Stop
- Activity history sidebar
- Goal: Real-time timer + task management

### 3. **ReportsView**
- Weekly summary cards (total hours, active projects)
- Project details table (project, client, status, hours)
- "Export for Billing" button → CSV download
- Date range selector (This Week / Last Week / Custom)
- Goal: Generate billing reports

### 4. **ProjectCreationView** (New)
- Form: Name, Description, Client, Hourly Rate
- Create/Edit functionality
- Goal: Allow project creation from dashboard

---

## 🔌 Service Layer Contracts

### ProjectManager
```swift
@Published var projects: [Project] = []
func createProject(_ project: Project) -> Result<Project, Error>
func updateProject(_ project: Project) -> Bool
func deleteProject(id: UUID) -> Bool
func getProject(id: UUID) -> Project?
```

### TimerManager
```swift
@Published var currentEntry: TimeEntry?
@Published var isRunning: Bool = false
@Published var elapsedSeconds: Int = 0

func startTimer(taskId: UUID, projectId: UUID)
func pauseTimer()
func resumeTimer()
func stopTimer() -> TimeEntry?
```

### BillingService
```swift
func getWeeklySummary(startDate: Date) -> WeeklySummary
func getDailyTotal(projectId: UUID, date: Date) -> Int  // in seconds
func calculateBillableAmount(projectId: UUID, seconds: Int) -> Double
```

### ExportService
```swift
func exportToCSV(projectId: UUID, startDate: Date, endDate: Date) -> URL?
func exportWeeklyBill(date: Date) -> URL?
```

---

## ⚠️ Known Limitations & Decisions

### Timer State Persistence
- **Decision**: Store TimerSession separately
- **Recovery**: On app launch, check for active sessions and resume
- **Battery**: If app is force-quit, timer stops (user must relaunch to continue)
- **Future**: Could extend with watchOS companion for true background tracking

### Single Active Timer
- **Decision**: Only one task can have running timer across all projects
- **Enforcement**: startTimer() stops any existing timer first
- **UX**: Clear UI indication of active task

### Data Storage
- **Decision**: SQLite locally in ~/Library/Application Support/ProjectTracker/
- **No Cloud**: Intentional (privacy-first for freelancers)
- **Backup**: Users can manually backup the database file

### Export Format
- **CSV**: Simple, importable to Excel/accounting software
- **Frequency**: Weekly summaries for billing
- **Future**: Could add JSON, PDF formats

---

## 📅 Daily Development Routine

### Each Morning
- [ ] Open IMPLEMENTATION_PLAN.md (this file)
- [ ] Mark completed tasks ✅
- [ ] Check blockers

### Each Session
- [ ] Work on ONE phase section (1A, 1B, etc)
- [ ] Compile frequently (catch errors early)
- [ ] Test before committing
- [ ] Update progress here

### Definition of "Done" per Section
- ✅ Code compiles without errors
- ✅ All required functionality implemented
- ✅ Basic testing (manual clicking through)
- ✅ No hardcoded values (uses data/viewmodels)
- ✅ Follows design system (uses AppColors, AppTypography, etc)

---

## 🚀 Success Criteria (MVP Done When...)

1. ✅ App launches without crashes
2. ✅ Can create a project (form works)
3. ✅ Can create a task in project
4. ✅ Can start/pause/stop timer
5. ✅ Dashboard shows real project data + daily totals
6. ✅ Can export weekly CSV
7. ✅ Timer state persists across app restarts
8. ✅ All 3 mockup screens are functional and match design

---

## 📖 Documentation Hierarchy

**For You Now**:
- THIS FILE - high level plan
- ARCHITECTURE.md - layer details
- DESIGN_SYSTEM.md - UI guidelines

**For Future AI Developer** (via README):
- CODE_STRUCTURE.md - walking tour of codebase
- SERVICE_LAYER.md - how to add new services
- DATABASE_GUIDE.md - how to modify schema
- TESTING_GUIDE.md - how to write tests

---

## 💡 Tips for Success

1. **Compile Frequently** - Don't go > 30 min without compiling
2. **One Screen at a Time** - Build Dashboard fully before moving to Reports
3. **Test Early** - Manually test each screen as you build it
4. **Keep Design System DRY** - All colors/fonts go in AppStyles, nowhere else
5. **Document as You Go** - Notes make future work faster
6. **Use Type Safety** - Let Swift's compiler catch errors early

---

## 📞 Getting Help

When stuck:
1. Check if similar component already exists (SearchFile for ".swift")
2. Read the error message carefully (usually tells you what's wrong)
3. Check ARCHITECTURE.md for the layer pattern
4. If data not showing: Check if ViewModel is @Published correctly
5. If button doesn't work: Check if action {} is properly connected

---

**Next Step**: Start Phase 1A - Fix Design System
**Estimated Time**: 2 hours
**Deliverable**: App compiles, no UI errors

