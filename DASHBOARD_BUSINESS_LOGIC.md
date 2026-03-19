# Dashboard - Business Logic Requirements

**Status**: For Implementation in Phase 2.2  
**Last Updated**: March 19, 2026

## Overview
This document captures all business logic requirements for the Dashboard screen that need to be implemented. These are separate from design/UI changes.

---

## 1. Timer Management System

### 1.1 Single Active Timer
- **Rule**: Only ONE task timer can run at any given time
- **Implementation**:
  - Create a `currentActiveTimerProvider` in Riverpod that holds the active task ID
  - When starting a new timer, check if any timer is already running
  - If running, show a dialog asking: "Stop current task? Start new one?"
  - Options: "Yes", "No", "Cancel"
  - Auto-stop the previous timer before starting the new one

### 1.2 Timer State Management
- **Provider Structure**:
  ```dart
  // Active timer state
  final activeTimerProvider = StateProvider<String?>((ref) => null); // null if no timer running
  
  // Timer duration provider
  final timerDurationProvider = StateNotifierProvider<TimerNotifier, Duration>((ref) {
    return TimerNotifier(Duration.zero);
  });
  
  // Running timer display (formatted)
  final runningTimerDisplayProvider = Provider<String>((ref) {
    final duration = ref.watch(timerDurationProvider);
    return formatDuration(duration);
  });
  ```

- **Properties to Track**:
  - Current active task UUID
  - Elapsed time (Duration)
  - Start timestamp
  - Pause state (if supported)

### 1.3 Timer Operations
- Start: Begin tracking time for a specific task
- Pause: Pause the timer (optional for MVP)
- Resume: Continue from paused state
- Stop: End the timer and save hours to task/project
- Auto-save: Save elapsed time periodically (every 60 seconds)

---

## 2. Task Hours Aggregation

### 2.1 Project Total Hours Calculation
- **Rule**: Sum all task hours within a project
- **Logic**:
  ```
  Project Total Hours = SUM(Task.totalMinutes) for all tasks in project
  ```
  
### 2.2 Data Structure
- Store in Task model:
  - `totalMinutes: int` (cumulative minutes for this task)
  - `completedAt: DateTime?` (null if incomplete)

- Store in Project model:
  - `totalMinutes: int` (computed/cached)
  - Recalculate when any task updates

### 2.3 Recalculation Strategy
- Recalculate project totals whenever:
  - A timer stops
  - A task is created/edited/deleted
  - A task duration is manually updated

- **Performance**: Cache totals in the Project model and invalidate on changes

---

## 3. Daily Goal Tracking

### 3.1 Daily Goal Feature
- **Default**: 8 hours per day
- **Storage**: Local database (Hive/Isar) or SharedPreferences
- **User Can**:
  - Set custom daily goal
  - View progress toward goal on dashboard
  - Reset daily goal (admin/settings)

### 3.2 Provider Structure
```dart
final dailyGoalProvider = StateNotifierProvider<DailyGoalNotifier, int>((ref) {
  // Load from local storage or default to 8 hours (480 minutes)
  return DailyGoalNotifier(480);
});

final todaysTotalHoursProvider = Provider<int>((ref) {
  // Sum all hours from tasks completed today
  // Return in minutes
});

final dailyProgressProvider = Provider<double>((ref) {
  final todaysHours = ref.watch(todaysTotalHoursProvider);
  final dailyGoal = ref.watch(dailyGoalProvider);
  return (todaysHours / dailyGoal).clamp(0.0, 1.0);
});
```

### 3.3 Persistence
- Store in SharedPreferences with key: `daily_goal_minutes`
- Option to reset daily at midnight (if needed)
- Show warning when approaching goal
- Show celebration when goal reached

---

## 4. Task Status Management

### 4.1 Task Statuses
- **To Do**: Initial status when task is created
- **In Progress**: When timer is running or manually set
- **In Review**: Manual status update (for workflows)
- **Complete**: When task is finished/archived

### 4.2 Status Transitions
```
To Do → In Progress (when timer starts)
In Progress → To Do (if paused/stopped without completing)
In Progress → In Review (manual action)
In Review → Complete (approval/confirmation)
Complete → To Do (if reopened)
```

### 4.3 Data Storage
```dart
enum TaskStatus {
  todo,
  inProgress,
  inReview,
  complete,
}

class Task {
  String id;
  String projectId;
  String name;
  String description;
  TaskStatus status;
  int totalMinutes;
  DateTime createdAt;
  DateTime? completedAt;
}
```

---

## 5. Recent Tasks Display

### 5.1 Rule
- Show latest 2 tasks in each project card on dashboard
- Order by: Most recent (creation date DESC)
- Include: Task name + status badge

### 5.2 Filtering
- Filter tasks by project
- Sort by: `createdAt` (DESC)
- Limit: 2 per project

---

## 6. Projects List & Conditional Display

### 6.1 Display Rules
- "Your Projects" section only shows when user has added projects
- If no projects: Show empty state with CTA button "Add Your First Project"
- If projects exist: Show all projects in grid layout

### 6.2 "View All" Projects Page
- New dedicated page showing all projects
- Display columns/info:
  - Project name + emoji/avatar
  - Description
  - Total hours
  - Status (active/inactive)
  - Last updated date
  - Action button: View Details

---

## 7. Running Timer Display on Dashboard

### 7.1 Display Location
- Show as prominent banner/card at the top after daily progress
- Only visible when a timer is actively running
- Hide automatically when timer stops

### 7.2 Content
- Project name
- Current task name
- Running timer (HH:MM:SS)
- Live countdown/stopwatch animation
- Quick actions: Pause, Stop buttons

### 7.3 Styling
- Eye-catching background color (use brand primary or animated gradient)
- Prominent typography
- Timer should be in large monospace font
- Action buttons easily accessible

---

## 8. Project Avatar/Icon System

### 8.1 Avatar Options
- Use emoji characters
- Store in Project model: `avatarEmoji: String` (single emoji)
- User selects emoji when creating project
- Example emojis: 📱💻🎨📊🚀🔧📈

### 8.2 Data Structure
```dart
class Project {
  String id;
  String name;
  String description;
  String avatarEmoji;
  int totalMinutes; // Cached total
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## 9. Local Storage Strategy

### 9.1 Database Choice
- **Option 1**: Hive (key-value, fast, no setup)
- **Option 2**: Isar (relational, more powerful, but heavier)
- **Option 3**: SQLite (traditional, via sqflite)

**Recommendation**: Start with **Hive** for MVP, migrate to Isar later if needed

### 9.2 Data to Persist
- Projects (all data)
- Tasks (all data)
- Daily goal setting
- User preferences (theme, etc.)

### 9.3 Sync Strategy
- All changes saved to local DB immediately
- No cloud sync in Phase 2 (local only)
- Backup strategy: TBD for Phase 3

---

## 10. Add New Project Button

### 10.1 Placement
- Top of "Your Projects" section (above projects grid)
- Right-aligned or center-aligned
- Button style: Primary variant
- Text: "+ Add New Project"

### 10.2 Interaction
- Opens modal dialog or navigation to create project screen
- Form fields:
  - Project name (required)
  - Description (optional)
  - Avatar emoji selector (required, with emoji picker)
- Save creates project and returns to dashboard

---

## 11. Task Creation Flow

### 11.1 Where Tasks Are Created
- In Project Detail screen (via "Start New Task" form)
- Creates task with status = "To Do"
- Starting a timer auto-sets status = "In Progress"

---

## Implementation Priority

**Phase 2.1 (Current)**: Design/UI changes to Dashboard
**Phase 2.2**: Business Logic Implementation
1. Timer management (single active timer, persistence)
2. Task status tracking
3. Hours aggregation
4. Daily goal feature
5. Local database setup
6. View All projects page

---

## Open Questions / Decisions Needed

1. **Auto-save frequency**: Save timer every X seconds? (Suggested: 60 seconds)
2. **Pause timer feature**: Support pause/resume? (Suggested: Phase 3+)
3. **Timezone handling**: Track time in user's timezone?
4. **Daily reset**: What time of day does "daily" reset? (Suggested: Midnight)
5. **Export format**: CSV, PDF, or both for reports?

