# TimeTracker Development Roadmap

**Status:** MVP Foundation Complete (March 19, 2026)  
**Next Milestone:** Clickable Prototype with All UI Screens

---

## 🎯 Phase Overview

```
Phase 1: Foundation ✅ [COMPLETE]
   ├── Architecture Design
   ├── Folder Structure
   ├── Theme System
   ├── Component Library
   ├── Dashboard UI
   └── Documentation

Phase 2: Complete UI Prototype ⏳ [NEXT]
   ├── Project Detail Screen
   ├── Reports Screen
   ├── Modals & Dialogs
   └── Responsive Layouts

Phase 3: Database & Logic 🔄 [AFTER UI]
   ├── SQLite Integration
   ├── Drift ORM Setup
   ├── Repository Implementation
   └── Provider Logic

Phase 4: Timer & Features ⚙️ [CORE LOGIC]
   ├── Timer Service
   ├── Start/Pause/Stop
   ├── Background Tracking
   └── CSV Export

Phase 5: Polish & Deploy 🚀 [FINAL]
   ├── Performance Optimization
   ├── Error Handling
   ├── Testing
   └── macOS Signing & Release
```

---

## 📋 Phase 2: Complete UI Prototype (NEXT)

**Duration:** 1-2 days  
**Objective:** Build all screens to match HTML mockups (clickable but not functional)

### **2.1 Project Detail Screen**
**File:** `lib/presentation/screens/project_detail_screen.dart`

**Components to build:**
- ✅ Navigation rail (reuse CustomScaffold)
- ✅ Active task panel with timer display
- 🔲 Timer display (large numbers - 12:45:03)
- 🔲 Pause & Stop buttons
- 🔲 Quick start section (task input fields)
- 🔲 Activity history panel (right sidebar)
- 🔲 History items list (past sessions)

**Corresponding Widgets:**
- `active_task_panel.dart` - Center panel
- `timer_display.dart` - Large timer numbers
- `task_history_panel.dart` - Right sidebar
- `history_item.dart` - History card

**Feature Complexity:** Medium  
**Dependencies:** TimerState provider

### **2.2 Reports & Export Screen**
**File:** `lib/presentation/screens/reports_screen.dart`

**Components to build:**
- ✅ Navigation rail
- 🔲 Weekly summary header
- 🔲 Segmented control (This Week, Last Week, Custom)
- 🔲 Stat cards (Total Tracked, Active Projects)
- 🔲 Project details table
- 🔲 Export section with CSV button

**Corresponding Widgets:**
- `project_summary_table.dart` - Data table
- `stat_card.dart` - Summary cards
- `export_section.dart` - Export button area

**Feature Complexity:** Medium-Low  
**Dependencies:** ReportsProvider

### **2.3 Dialogs & Modals**
- Create Project Modal
- Create Task Modal
- Edit Project Modal
- Confirm Delete Dialog
- Date Range Picker

**Files:**
- `lib/presentation/widgets/dialogs/` (new directory)
- `create_project_dialog.dart`
- `create_task_dialog.dart`
- `confirm_dialog.dart`

### **2.4 Responsive Layouts**
- Desktop layout (1200px+)
- Tablet layout (800-1200px)
- Mobile layout (< 800px, if needed)

**Use `LayoutBuilder` for responsive:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    bool isMobile = constraints.maxWidth < 600;
    return isMobile ? MobileLayout() : DesktopLayout();
  },
)
```

---

## 📊 Phase 3: Database & Data Integration

**Duration:** 1-2 days  
**Objective:** Fully functional database with Drift ORM

### **3.1 Drift Database Setup**

**Files to create:**
1. `lib/data/database/tables/projects_table.dart`
2. `lib/data/database/tables/tasks_table.dart`
3. `lib/data/database/tables/timer_sessions_table.dart`
4. `lib/data/database/app_database.dart` (main DB class)
5. `build.yaml` (Drift configuration)

**Steps:**
```bash
# 1. Create table definitions
# 2. Create AppDatabase with @DriftDatabase annotation
# 3. Add to build.yaml
# 4. Run code generator
flutter pub run build_runner build

# 5. Generated files appear in lib/data/database/
# 6. Implement repositories using generated code
```

### **3.2 Repository Implementation**

**Files to create:**
1. `lib/data/repositories/project_repository.dart` (implements IProjectRepository)
2. `lib/data/repositories/task_repository.dart`
3. `lib/data/repositories/timer_session_repository.dart`

**Each repository:**
- Handles database queries
- Converts models ↔ entities
- Provides type-safe query results

### **3.3 Riverpod Providers with Real Data**

Update in `lib/presentation/providers/`:
- `project_provider.dart` - Fetch from DB
- `task_provider.dart` - Fetch from DB
- `timer_provider.dart` - Manage timer state with DB

---

## ⏰ Phase 4: Timer & Core Features

**Duration:** 2-3 days  
**Objective:** Functional timer with background tracking

### **4.1 Timer Service**

**File:** `lib/services/timer_service.dart`

**Responsibilities:**
- Track elapsed time per task
- Handle pause/resume
- Persist state on app quit
- Calculate total hours/minutes

**Key Methods:**
```dart
class TimerService {
  Future<void> startTimer(String taskId, String projectId);
  Future<void> pauseTimer();
  Future<void> resumeTimer();
  Future<void> stopTimer();
  Stream<Duration> timerTick(); // For UI updates
  Future<TimerState> loadLastTimer();
}
```

### **4.2 Background Tracking**

**Implementation:**
1. When app closes, save timer state to DB
2. On app restart, check for running timer
3. Calculate elapsed time from saved timestamp
4. Resume timer

**Pseudo-code:**
```dart
// On app quit
await timerService.saveLastTimer();

// On app start
final lastTimer = await timerService.loadLastTimer();
if (lastTimer.isRunning) {
  final elapsedSinceClose = DateTime.now().difference(lastTimer.lastSavedTime);
  totalSeconds += elapsedSinceClose.inSeconds;
}
```

### **4.3 CSV Export Service**

**File:** `lib/services/export_service.dart`

**Format:**
```
Project Name,Task Name,Date,Hours:Minutes,Description
Website Redesign,Design Input Fields,2026-03-19,2:30,"Figma mockups"
Mobile App API,API Testing,2026-03-19,1:45,"Postman tests"
```

**Steps:**
1. Query timer_sessions for date range
2. Group by project
3. Format as CSV
4. Save to Downloads folder
5. Open file after export

---

## 🧪 Phase 5: Testing & Optimization

**Duration:** 1-2 days

### **5.1 Unit Tests**
```bash
test/unit/
├── formatters_test.dart
├── validators_test.dart
├── entities_test.dart
└── services_test.dart
```

### **5.2 Widget Tests**
```bash
test/widget/
├── app_button_test.dart
├── app_text_field_test.dart
├── project_card_test.dart
└── daily_progress_card_test.dart
```

### **5.3 Performance**
- Profile with DevTools
- Optimize list rendering (lazy loading)
- Cache expensive computations
- Monitor memory usage

---

## 🚀 Implementation Timeline

### **Week 1 (Mar 19-25, 2026)**
- [x] Phase 1: Foundation ✅
- [ ] Phase 2: All UI Screens (Project Detail, Reports)
- [ ] Phase 3: Database Integration (50%)

### **Week 2 (Mar 26-Apr 1)**
- [ ] Phase 3: Complete Database (50%)
- [ ] Phase 4: Timer Logic (50%)

### **Week 3 (Apr 2-8)**
- [ ] Phase 4: Complete Timer (50%)
- [ ] Phase 5: Testing & Polish (50%)

### **Week 4 (Apr 9-15)**
- [ ] Phase 5: Complete Testing
- [ ] Bug hunting & optimization
- [ ] Release preparation

---

## 🔑 Critical Path Items

1. **UI Mockup → Code** (Dashboard ✅, Detail 🔄, Reports 🔄)
2. **Database Schema** (Ready, needs Drift implementation)
3. **Timer Logic** (Core feature, highest priority)
4. **CSV Export** (Billing requirement)
5. **Background Persistence** (Prevents data loss)

---

## 📝 Priority Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Complete |
| 🔄 | In Progress |
| 🔲 | Ready to Start |
| ⏳ | Blocked/Waiting |
| ⚙️ | Research Needed |

---

## 🎯 Success Criteria

### **Phase 2 Complete When:**
- [ ] All 3 screens built and responsive
- [ ] All dialogs/modals implemented
- [ ] Dark/light theme works on all screens
- [ ] No layout errors/warnings
- [ ] App builds without errors

### **Phase 3 Complete When:**
- [ ] Database queries working
- [ ] CRUD operations functional
- [ ] Repository pattern verified
- [ ] No database errors in logs

### **Phase 4 Complete When:**
- [ ] Timer starts/pauses/stops correctly
- [ ] Background timer persists across app restarts
- [ ] CSV export generates correct format
- [ ] All hours calculations accurate

### **Phase 5 Complete When:**
- [ ] All tests passing (>90% coverage)
- [ ] Zero console errors
- [ ] Performance metrics acceptable
- [ ] App ready for release

---

## 📞 Decision Points

**Q: Should we add cloud sync in MVP?**  
A: NO - Local only per requirements. Add in Phase 6.

**Q: Do we need user authentication?**  
A: NO - Single user, local app only.

**Q: Should timer continue when system sleeps?**  
A: NO - Just save last state, resume on app open.

**Q: Multi-tasking (simultaneous timers)?**  
A: NO - One timer per project max.

**Q: Mobile version needed?**  
A: NO - Desktop macOS only for MVP.

---

## 📚 Documentation Updates Needed

After each phase, update:
1. [COMPONENT_LIBRARY.md](COMPONENT_LIBRARY.md) - New widgets
2. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - DB design verification
3. [AI_README.md](AI_README.md) - New patterns/examples
4. [ARCHITECTURE.md](ARCHITECTURE.md) - Any design changes

---

## 🤝 Collaboration Notes

For future development:
1. Always check [AI_README.md](AI_README.md) before starting
2. Follow naming conventions strictly
3. Keep layers separated
4. Use Riverpod for all state
5. Add tests for new code
6. Update documentation

---

**Current Status:** MVP Foundation Ready  
**Next Action:** Start Phase 2 - Build Project Detail Screen  
**Estimated Completion:** April 15, 2026

Good luck! 🚀
