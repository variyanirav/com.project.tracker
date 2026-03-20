# Phase 3.8 Quick Test Checklist - Copy & Paste Guide

Use this checklist while testing. Copy sections below as you execute each test.

---

## LAUNCH APP
```
cd /Users/niravvariya/Documents/Projects/Desktop/com.project.tracker
flutter run -d macos
```

**Wait for:** 
- [ ] App loads to dashboard
- [ ] No crashes in console
- [ ] Dashboard shows empty state or existing projects

---

## TEST 9.2.1: CREATE PROJECT

### Input Data
```
Title: "Test Mobile App"
Description: "Testing project creation flow"
Emoji: "📱"
```

### Execution
- [ ] Step 1: Dashboard loaded
- [ ] Step 2: Click "Add New Project" button
- [ ] Step 3: Enter data above
- [ ] Step 4: Click "Create"
- [ ] Step 5: Success message appears
- [ ] Step 6: Project visible in grid

### Persistence Test
- [ ] Close app: `Cmd+Q`
- [ ] Rerun: `flutter run -d macos`
- [ ] Navigate to dashboard
- [ ] **RESULT:** Project "Test Mobile App" visible? **YES** ✅ / **NO** ❌

---

## TEST 9.2.2: CREATE TASK

### Navigate to Project
- [ ] Click "Test Mobile App" project card
- [ ] Wait for project detail screen

### Create Tasks (repeat 3 times)

#### Task 1
```
Title: "Design UI Mockups"
Description: "Create initial mockups"
Status: "To Do"
```
- [ ] Enter data
- [ ] Click "Create Task"
- [ ] Task appears in list? **YES** ✅ / **NO** ❌

#### Task 2
```
Title: "Implement Backend API"
Description: "RESTful endpoints"
Status: "In Progress"
```
- [ ] Enter data
- [ ] Click "Create Task"
- [ ] Task appears in list? **YES** ✅ / **NO** ❌

#### Task 3
```
Title: "Database Schema"
Description: "Design database"
Status: "To Do"
```
- [ ] Enter data
- [ ] Click "Create Task"
- [ ] Task appears in list? **YES** ✅ / **NO** ❌

### Persistence Test
- [ ] Close app
- [ ] Rerun: `flutter run -d macos`
- [ ] Navigate to project
- [ ] All 3 tasks visible? **YES** ✅ / **NO** ❌

---

## TEST 9.2.3: START TIMER

### Check Initial State
- [ ] Dashboard open
- [ ] No "Running Timer" card visible? **YES** ✅ / **NO** ❌

### Start Timer
- [ ] Go to project detail
- [ ] Locate "Implement Backend API" task
- [ ] Click timer/start button
- [ ] Task status changed to "In Progress"? **YES** ✅ / **NO** ❌

### Verify Dashboard
- [ ] Return to dashboard
- [ ] "Running Timer" card appears? **YES** ✅ / **NO** ❌
- [ ] Shows project: "Test Mobile App"? **YES** ✅ / **NO** ❌
- [ ] Shows task: "Implement Backend API"? **YES** ✅ / **NO** ❌
- [ ] Time is counting up? **YES** ✅ / **NO** ❌

### Test Single Timer Constraint
- [ ] Go back to project detail
- [ ] Try to start another task
- [ ] Dialog appears: "Stop current timer first?"? **YES** ✅ / **NO** ❌
- [ ] Click Cancel
- [ ] Original timer still running? **YES** ✅ / **NO** ❌

### Let Timer Run
- [ ] Wait 30+ seconds
- [ ] Time on dashboard increases? **YES** ✅ / **NO** ❌

---

## TEST 9.2.4: STOP TIMER

### Stop the Timer
- [ ] On dashboard, click "Stop" button
- [ ] Success message appears? **YES** ✅ / **NO** ❌
- [ ] Timer card disappears? **YES** ✅ / **NO** ❌

### Verify Task Updated
- [ ] Go to project detail
- [ ] Find "Implement Backend API" task
- [ ] Task shows hours (e.g., "0h 1m")? **YES** ✅ / **NO** ❌

### Verify Project Hours Updated
- [ ] Check header "Total Hours"
- [ ] Shows recorded time? **YES** ✅ / **NO** ❌

### Persistence Test
- [ ] Close app
- [ ] Rerun app
- [ ] Go to project
- [ ] Task hours still visible? **YES** ✅ / **NO** ❌

### Multiple Sessions
- [ ] Start timer on same task again
- [ ] Run for 20 seconds
- [ ] Stop timer
- [ ] Task hours increases? **YES** ✅ / **NO** ❌

---

## TEST 9.2.5: DAILY GOAL

### Access Settings
- [ ] On dashboard, click gear icon "Daily Goal Settings"
- [ ] Dialog appears? **YES** ✅ / **NO** ❌

### Update Goal
- [ ] Change value to 5 hours
- [ ] Click Save
- [ ] Message "Daily goal set to 5 hours" appears? **YES** ✅ / **NO** ❌

### Verify Display
- [ ] Dashboard updates with new goal? **YES** ✅ / **NO** ❌

### Persistence Test
- [ ] Close app
- [ ] Rerun app
- [ ] Open settings again
- [ ] Goal still 5 hours? **YES** ✅ / **NO** ❌

### Change Goal Again
- [ ] Set to 10 hours
- [ ] Click Save
- [ ] Close and rerun
- [ ] Shows 10 hours? **YES** ✅ / **NO** ❌

---

## TEST 9.2.6: DATA CONSISTENCY

### Setup Test Data
Task A: 75 seconds timer (1m 15s)
Task B: 165 seconds timer (2m 45s)
Task C: 0 seconds timer (no timer)

- [ ] Create/run timers on tasks A, B, C
- [ ] Stop all timers

### Verify Task Hour Totals
- [ ] Task A shows ~"0h 1m"? **YES** ✅ / **NO** ❌
- [ ] Task B shows ~"0h 2m"? **YES** ✅ / **NO** ❌
- [ ] Task C shows "0h"? **YES** ✅ / **NO** ❌

### Verify Project Total
- [ ] Project total = Sum of all tasks
- [ ] Expected: ~240 seconds = 4 minutes
- [ ] Project shows "0h 4m" or similar? **YES** ✅ / **NO** ❌

### Verify Daily Total
- [ ] On dashboard, daily progress shows ~"0h 4m"? **YES** ✅ / **NO** ❌
- [ ] Progress % = 4m / 5h = ~1.3%? **YES** ✅ / **NO** ❌

---

## TEST 9.2.7: EDIT & DELETE

### Edit Project
- [ ] Go to project list
- [ ] Click edit on "Test Mobile App"
- [ ] Dialog shows current data? **YES** ✅ / **NO** ❌
- [ ] Change title to "Updated Test App"
- [ ] Click Save
- [ ] List shows new name? **YES** ✅ / **NO** ❌
- [ ] Close/reopen app → name persisted? **YES** ✅ / **NO** ❌

### Delete Task
- [ ] Go to project detail
- [ ] Click delete on "Database Schema" task
- [ ] Confirm dialog appears? **YES** ✅ / **NO** ❌
- [ ] Click confirm
- [ ] Task removed from list? **YES** ✅ / **NO** ❌
- [ ] Close/reopen → task still gone? **YES** ✅ / **NO** ❌

### Delete Project
- [ ] Go to project list
- [ ] Click delete on another test project
- [ ] Confirm deletion
- [ ] Project removed? **YES** ✅ / **NO** ❌
- [ ] Close/reopen → still gone? **YES** ✅ / **NO** ❌

---

## TEST 9.3: ERROR HANDLING

### Empty Title Validation
- [ ] Try to create project with empty title
- [ ] Validation prevents it or shows error? **YES** ✅ / **NO** ❌
- [ ] Try to create task with empty title
- [ ] Same validation? **YES** ✅ / **NO** ❌

### Timer Conflict Handling
- [ ] Start timer on Task A
- [ ] Try to start on Task B
- [ ] Shows "Stop current timer" dialog? **YES** ✅ / **NO** ❌
- [ ] Click Cancel → timer A keeps running? **YES** ✅ / **NO** ❌

### Cascade Delete
- [ ] Delete project with multiple tasks
- [ ] All tasks removed (no orphans)? **YES** ✅ / **NO** ❌
- [ ] App doesn't crash? **YES** ✅ / **NO** ❌

---

## FINAL SUMMARY

Count your checkmarks:
- [ ] Tests passed: ____ / 54 items
- [ ] Major issues found: ____
- [ ] Minor issues found: ____

**Overall Status:** ✅ PASS / ⚠️ PARTIAL / ❌ FAIL

---

## Issues Found Form

For each issue, fill out:

### Issue #1
- **Test Name:** (9.2.X test name)
- **Description:** What failed
- **Expected:** What should happen
- **Actual:** What actually happened
- **Severity:** CRITICAL / HIGH / MEDIUM / LOW
- **Reproducible:** YES / NO / SOMETIMES

---

## Time Log

- Test start: ____:____ (HH:MM)
- Test end: ____:____ (HH:MM)
- Total duration: ____ minutes
