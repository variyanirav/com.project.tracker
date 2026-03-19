# PROJECT DETAILS - BUSINESS LOGIC & REQUIREMENTS

## Phase 2: Project Details Screen Implementation Guide

---

## 1. TIMER & TASK STATE MANAGEMENT

### Global Timer Constraint
- **Only ONE active timer allowed** across the entire application (all projects)
- User cannot start a new timer while another timer is running (current or different project)
- System should:
  - Show warning/notification if user tries to start timer while one is active
  - Allow pause/stop of existing timer before starting new one
  - Enforce this globally across all projects

### Task Status Flow
- **Default Status on Creation**: `ToDo`
- **On Timer Start**: Status automatically changes from `ToDo` → `In Progress`
- **Available Statuses**: 
  - `ToDo` - Task created but not started
  - `In Progress` - Timer is actively running on this task
  - `In Review` - Requires approval/review
  - `On Hold` - Paused temporarily
  - `Complete` - Task finished
- **Status persistence**: Task status should be saved to database

---

## 2. TIME TRACKING & AGGREGATION

### Daily Count
- **Resets**: Every day at 00:00 (midnight)
- **Scope**: Sum of all completed task durations for the current day
- **Calculation**: Sum(duration) for all tasks where `dateCreated` = today
- **Reset Logic**: When system date changes, reset daily counter to 0

### Weekly Count
- **Week Definition**: Monday 00:00 AM → Sunday 11:59 PM
- **Resets**: Every Monday at 00:00 (resets to 0 at start of new week)
- **Scope**: Sum of all completed task durations for the current week
- **Calculation**: Sum(duration) for all tasks where `dateCreated` is within current week
- **Reset Logic**: When system changes to new Monday, reset weekly counter to 0

### Total Count
- **Scope**: Sum of ALL completed task durations for this project (all-time)
- **Calculation**: Sum(duration) for all tasks in this project
- **Never Resets**: Lifetime total for the project

### Display Format
- Format: `Xh YYm` (e.g., "12h 45m", "2h 30m")
- Show all three counters prominently on project detail screen
- Update in real-time when timer is running

---

## 3. TASK LIST & PAGINATION

### Task List Display Rules
- **Load Limit**: Initial load = 20 tasks
- **Ordering**: By `createdDate` (newest first OR oldest first - clarify with UX)
- **Pagination**: Infinite scroll - load next 20 when user scrolls to bottom
- **Tasks Shown**: All tasks for this project (completed & in-progress)

### Task Information Display
- Task name/title
- Status badge (colored indicator)
- Duration (hours logged)
- Created date & time
- Last updated date & time (if applicable)

---

## 4. TODAY'S TASK SECTION

### Filtering Logic
- **Display**: Only tasks where `workDate` = today (00:00 to 23:59)
- **Purpose**: Show current day's work
- **Edge Case**: If a lengthy task spans multiple days:
  - Task appears in "Today's Tasks" as long as user is actively working on it
  - Once task is stopped/completed, it no longer appears (moves to history)
  - User can resume the same task next day
- **Max items**: Show all (no pagination for today's tasks, or limit to 10?)

### Today's Task Section Behavior
- Shows real-time updates
- Reflects timer state (in-progress, paused, completed)
- Allow action buttons (pause, stop, resume)

---

## 5. START NEW TASK SECTION

### Form Fields Required
- **Title** (required, text input)
- **Description** (optional, long text input)
- **Status Dropdown** (required):
  - Options: `ToDo`, `In Progress`, `In Review`, `On Hold`, `Complete`
  - Default: `ToDo`
- **Start Timer Button**

### Validation Rules
- Title: Min 3 characters, max 100 characters
- Description: Optional, max 500 characters
- Status: Must select one (default = ToDo)

### On Form Submit
1. Validate all required fields
2. Check if another timer is already running (global check)
3. Create task with default status `ToDo`
4. Show success message
5. Clear form
6. If "Start Timer" clicked, automatically:
   - Change status to `In Progress`
   - Start timer for this task
   - Disable other project timers (stop previous if running)

---

## 6. STATUS BADGE COLORS & ICONS

Define status color mapping for consistent UI:
- `ToDo`: Gray/Neutral (#64748B or similar)
- `In Progress`: Blue/Primary (#007BFF)
- `In Review`: Amber/Warning (#FCD34D)
- `On Hold`: Orange (#FB923C)
- `Complete`: Green/Success (#10B981)

---

## 7. DATA MODEL REQUIREMENTS

### Task Model Fields (Recommended)
```
- id: String (UUID)
- projectId: String (reference to project)
- title: String
- description: String?
- status: TaskStatus (enum)
- duration: Duration
- createdDate: DateTime
- updatedDate: DateTime?
- completedDate: DateTime?
- workDate: DateTime (for "Today's Tasks" filter)
- isActive: bool (true if timer running)
- tags: List<String>? (optional, for future filtering)
```

### Provider Requirements
- `activeTimerProvider`: Track which task has active timer
- `tasksProvider`: Fetch tasks with pagination
- `dailyHoursProvider`: Calculate today's hours
- `weeklyHoursProvider`: Calculate this week's hours
- `totalHoursProvider`: Calculate all-time hours
- `todayTasksProvider`: Filter today's tasks

---

## 8. FUTURE ENHANCEMENTS (Out of Scope)

- Task archiving/deletion
- Task filtering by status
- Task search functionality
- Bulk operations (mark complete, delete, etc.)
- Task notes/comments
- Task attachments
- Task dependencies
- Time entry reconciliation (manual edit of logged hours)

---

## IMPLEMENTATION CHECKLIST

- [ ] Create UI for task list with pagination
- [ ] Create status dropdown in "Start New Task" form
- [ ] Add task status badges with colors
- [ ] Implement daily/weekly/total hours calculation
- [ ] Implement global timer constraint (only 1 active)
- [ ] Add auto-status-change when timer starts
- [ ] Implement time reset logic (daily & weekly)
- [ ] Create "Today's Tasks" filter logic
- [ ] Create data models & providers
- [ ] Add database schema for tasks
- [ ] Implement infinite scroll pagination
- [ ] Add form validation

