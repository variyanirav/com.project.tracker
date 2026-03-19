# Phase 1B: ViewModels & Data Binding (Ready to Start)

**Estimated Duration**: 3 hours  
**Difficulty**: Intermediate  
**Prerequisites**: Phase 1A Complete ✅

---

## 🎯 Overview

Phase 1B connects your beautiful screens to real data. You'll create 3 ViewModels that bridge Views ↔ Services.

**The Flow**:
```
View (See data) ← ViewModel (Transform data) ← Service (Provide data)
View (Trigger action) → ViewModel (Manage logic) → Service (Execute)
```

---

## 📋 Checklist

- [ ] Create DashboardViewModel.swift
- [ ] Create ProjectDetailViewModel.swift  
- [ ] Create ReportsViewModel.swift
- [ ] Update DashboardView to use DashboardViewModel
- [ ] Update ProjectDetailView to use ProjectDetailViewModel
- [ ] Update ReportsView to use ReportsViewModel
- [ ] Compile and test
- [ ] Verify data flows correctly

---

## 1️⃣ DashboardViewModel

**Location**: `UI/ViewModels/DashboardViewModel.swift`

**Purpose**: Aggregate project and timer data for dashboard display

```swift
//
//  DashboardViewModel.swift
//  ProjectTracker
//
//  Created by You on [Date].
//

import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties (UI observes these)
    
    @Published var projects: [Project] = []
    @Published var dailyTotalSeconds: Int = 0
    @Published var activeTaskCount: Int = 0
    @Published var completedTaskCount: Int = 0
    @Published var progressPercentage: Double = 0.0
    
    // MARK: - Dependencies
    
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        projectManager: ProjectManager = .shared,
        timerManager: TimerManager = .shared
    ) {
        self.projectManager = projectManager
        self.timerManager = timerManager
        
        setupBindings()
        refresh()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // When projectManager updates, refresh dashboard
        projectManager.objectWillChange
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // When timer updates, refresh elapsed time
        timerManager.objectWillChange
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Methods
    
    func refresh() {
        updateProjects()
        updateDailyStats()
        updateProgress()
    }
    
    private func updateProjects() {
        projects = projectManager.projects
    }
    
    private func updateDailyStats() {
        let today = Date().dateOnly
        
        // Calculate total hours for today across all projects
        // TODO: Call TimerManager or DatabaseManager to get today's entries
        // For now, use mock calculation
        let todayEntries = [] // Get from database
        dailyTotalSeconds = todayEntries.reduce(0) { $0 + $1.duration }
        
        // Count tasks
        activeTaskCount = projects.reduce(0) { total, project in
            // Count tasks in this project with status "inProgress"
            total + (project.tasks?.filter { $0.status == "inProgress" }.count ?? 0)
        }
        
        completedTaskCount = projects.reduce(0) { total, project in
            // Count tasks in this project with status "completed"
            total + (project.tasks?.filter { $0.status == "completed" }.count ?? 0)
        }
    }
    
    private func updateProgress() {
        // Assuming 8-hour daily goal
        let dailyGoalSeconds = 8 * 3600 // 8 hours in seconds
        let percentage = min(
            Double(dailyTotalSeconds) / Double(dailyGoalSeconds) * 100.0,
            100.0
        )
        progressPercentage = percentage
    }
    
    // MARK: - Actions
    
    func selectProject(_ project: Project) {
        // Navigate to project detail view
        // This will be handled by your navigation
    }
    
    /// Format seconds to human-readable time
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    /// Get formatted daily total
    var dailyTotalFormatted: String {
        formatTime(dailyTotalSeconds)
    }
    
    /// Get formatted progress percentage
    var progressText: String {
        String(format: "%.0f%%", progressPercentage)
    }
}

// MARK: - Preview

extension DashboardViewModel {
    static var preview: DashboardViewModel {
        let vm = DashboardViewModel()
        // Set mock data if desired
        return vm
    }
}
```

---

## 2️⃣ ProjectDetailViewModel

**Location**: `UI/ViewModels/ProjectDetailViewModel.swift`

**Purpose**: Manage single project, current timer, and task list

```swift
//
//  ProjectDetailViewModel.swift
//  ProjectTracker
//
//  Created by You on [Date].
//

import SwiftUI
import Combine

class ProjectDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var project: Project?
    @Published var tasks: [Task] = []
    @Published var currentlyRunningTask: Task?
    @Published var elapsedSeconds: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var activityHistory: [ActivityHistoryItem] = []
    
    // MARK: - Dependencies
    
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var projectManager: ProjectManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        projectId: UUID,
        timerManager: TimerManager = .shared,
        projectManager: ProjectManager = .shared
    ) {
        self.timerManager = timerManager
        self.projectManager = projectManager
        
        // Load project
        self.project = projectManager.getProject(id: projectId)
        
        setupBindings()
        refresh()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        timerManager.objectWillChange
            .sink { [weak self] in
                self?.updateTimerState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Methods
    
    func refresh() {
        if let project = project {
            // Load tasks for this project
            // TODO: Get from ProjectManager
            tasks = project.tasks ?? []
            
            // Load activity history
            // TODO: Get recent entries from DatabaseManager
            updateActivityHistory()
        }
        updateTimerState()
    }
    
    private func updateTimerState() {
        elapsedSeconds = timerManager.elapsedSeconds
        isTimerRunning = timerManager.isRunning
        
        // Find which task is currently running
        if let entry = timerManager.currentEntry {
            // Find the task with matching ID
            currentlyRunningTask = tasks.first { $0.id == entry.taskId }
        } else {
            currentlyRunningTask = nil
        }
    }
    
    private func updateActivityHistory() {
        // TODO: Get from DatabaseManager recent time entries for this project
        // Sort by date descending
        // Create ActivityHistoryItem objects
    }
    
    // MARK: - Timer Actions
    
    func startTimer(taskName: String, taskDescription: String?) {
        guard let project = project else { return }
        
        // Create a task if needed
        let task = Task(
            id: UUID(),
            projectId: project.id,
            name: taskName,
            status: .inProgress,
            createdAt: Date()
        )
        
        // Start timer
        timerManager.startTimer(taskId: task.id, projectId: project.id)
        
        // Update UI
        currentlyRunningTask = task
    }
    
    func pauseTimer() {
        timerManager.pauseTimer()
    }
    
    func resumeTimer() {
        timerManager.resumeTimer()
    }
    
    func stopTimer() {
        timerManager.stopTimer()
        currentlyRunningTask = nil
        refresh()
    }
    
    // MARK: - Formatting
    
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    var timerDisplay: String {
        formatTime(elapsedSeconds)
    }
}

// MARK: - Helper Types

struct ActivityHistoryItem: Identifiable {
    let id = UUID()
    let taskName: String
    let description: String
    let duration: Int  // seconds
    let date: Date
}

// MARK: - Preview

extension ProjectDetailViewModel {
    static var preview: ProjectDetailViewModel {
        let vm = ProjectDetailViewModel(projectId: UUID())
        return vm
    }
}
```

---

## 3️⃣ ReportsViewModel

**Location**: `UI/ViewModels/ReportsViewModel.swift`

**Purpose**: Aggregate weekly data and handle CSV export

```swift
//
//  ReportsViewModel.swift
//  ProjectTracker
//
//  Created by You on [Date].
//

import SwiftUI
import Combine

class ReportsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var projects: [ProjectReport] = []
    @Published var totalTrackedSeconds: Int = 0
    @Published var activeProjectCount: Int = 0
    @Published var selectedTimeRange: Int = 0 // 0=This Week, 1=Last Week, 2=Custom
    @Published var isExporting: Bool = false
    @Published var exportStatus: String = ""
    
    // MARK: - Dependencies
    
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var billingService: BillingService
    @ObservedObject var exportService: ExportService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        projectManager: ProjectManager = .shared,
        billingService: BillingService = .shared,
        exportService: ExportService = .shared
    ) {
        self.projectManager = projectManager
        self.billingService = billingService
        self.exportService = exportService
        
        setupBindings()
        refresh()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        projectManager.objectWillChange
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        $selectedTimeRange
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Methods
    
    func refresh() {
        updateProectReports()
        updateStats()
    }
    
    private func updateProectReports() {
        let dateRange = getDateRange()
        
        // TODO: Get weekly data from BillingService for each project
        projects = projectManager.projects.map { project in
            let summary = billingService.getWeeklySummary(
                projectId: project.id,
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            return ProjectReport(
                project: project,
                totalHours: Double(summary?.totalSeconds ?? 0) / 3600.0,
                totalBillable: project.calculateBillableAmount(hours: Double(summary?.totalSeconds ?? 0) / 3600.0),
                taskCount: (summary?.taskCount) ?? 0
            )
        }
    }
    
    private func updateStats() {
        let dateRange = getDateRange()
        
        // Calculate totals
        totalTrackedSeconds = projects.reduce(0) { total, report in
            total + Int(report.totalHours * 3600)
        }
        
        activeProjectCount = projects.filter { $0.project.status == .active }.count
    }
    
    private func getDateRange() -> (start: Date, end: Date) {
        let today = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case 0: // This Week
            let weekStart = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: today)
            let startDate = calendar.date(from: weekStart)!
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            return (startDate, endDate)
            
        case 1: // Last Week
            let weekStart = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: today)
            let startDate = calendar.date(from: weekStart)!
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: startDate)!
            return (lastWeekStart, startDate)
            
        default: // Custom - for now, default to this week
            let weekStart = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: today)
            let startDate = calendar.date(from: weekStart)!
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            return (startDate, endDate)
        }
    }
    
    // MARK: - Actions
    
    func exportWeeklyBill() {
        isExporting = true
        exportStatus = "Generating report..."
        
        let dateRange = getDateRange()
        
        // TODO: Call ExportService to generate CSV
        DispatchQueue.global().async { [weak self] in
            // Generate CSV file
            let csvContent = self?.generateCSV(dateRange: dateRange) ?? ""
            
            DispatchQueue.main.async {
                self?.isExporting = false
                self?.exportStatus = "Export complete!"
                
                // Save to file
                // TODO: Use exportService or open save dialog
            }
        }
    }
    
    private func generateCSV(dateRange: (start: Date, end: Date)) -> String {
        var csv = "Project,Client,Total Hours,Hourly Rate,Total Billable,Status\n"
        
        for r in projects {
            csv += "\"\(r.project.name)\","
            csv += "\"\(r.project.clientName ?? "N/A")\","
            csv += String(format: "%.2f,", r.totalHours)
            csv += String(format: "%.2f,", r.project.hourlyRate)
            csv += String(format: "%.2f,", r.totalBillable)
            csv += "\(r.project.status.rawValue)\n"
        }
        
        return csv
    }
    
    // MARK: - Formatting
    
    func formatHours(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var totalTrackedFormatted: String {
        formatHours(totalTrackedSeconds)
    }
}

// MARK: - Helper Types

struct ProjectReport {
    let project: Project
    let totalHours: Double
    let totalBillable: Double
    let taskCount: Int
    
    var statusBadgeStyle: AppBadgeStyle {
        switch project.status {
        case .active: return .info
        case .completed: return .success
        case .paused: return .warning
        case .archived: return .info
        }
    }
}

// MARK: - Preview

extension ReportsViewModel {
    static var preview: ReportsViewModel {
        ReportsViewModel()
    }
}
```

---

## 📝 Step 4: Update Views to Use ViewModels

### DashboardView Update

Replace the hardcoded mock data with ViewModel data:

```swift
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // ... Header section

                // Daily Progress Card - USE VIEWMODEL DATA
                VStack(spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            AppTypography.label("Daily Progress")
                            
                            AppTypography.bodyMuted(
                                "You have completed \(viewModel.progressText) of your daily goal."
                            )
                            
                            HStack(spacing: AppSpacing.lg) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    AppTypography.label("Time Logged")
                                    AppTypography.stat(viewModel.dailyTotalFormatted)
                                }
                                
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    AppTypography.label("Tasks")
                                    AppTypography.statSmall("\(viewModel.activeTaskCount)")
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Circular progress with REAL percentage
                        ZStack {
                            Circle()
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: viewModel.progressPercentage / 100.0)
                                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 120, height: 120)
                                .animation(.easeInOut, value: viewModel.progressPercentage)
                            
                            VStack(spacing: 4) {
                                AppTypography.stat(viewModel.progressText)
                            }
                        }
                    }
                }
                // ... rest of card

                // Projects Grid - USE VIEWMODEL DATA
                LazyVGrid(...) {
                    ForEach(viewModel.projects) { project in
                        ProjectCardView(
                            department: project.clientName ?? "Unassigned",
                            projectTitle: project.name,
                            effortToday: viewModel.formatTime(...)  // Calculate from TimerManager
                        ) {
                            viewModel.selectProject(project)
                        }
                    }
                }
            }
        }
    }
}
```

---

## ✅ Testing Checklist

After implementing ViewModels:

- [ ] DashboardViewModel initializes without errors
- [ ] ProjectDetailViewModel initializes for a specific project
- [ ] ReportsViewModel loads and formats data
- [ ] DashboardView displays ViewModel data
- [ ] ProjectDetailView displays project details
- [ ] ReportsView shows weekly totals
- [ ] Timer actions trigger (start/pause/stop)
- [ ] Data updates when services change
- [ ] Progress percentage updates in real-time

---

## 🎯 Success Criteria

You'll know Phase 1B is complete when:

✅ All 3 ViewModels created and compile without errors  
✅ All 3 Views use ViewModels instead of mock data  
✅ Creating a project shows it on Dashboard  
✅ Starting a timer updates ProjectDetail  
✅ Weekly totals load in Reports  
✅ All screens can be switched via navigation  

---

## 📌 Notes

- ViewModels own the data transformation logic
- Views only display what ViewModels provide
- Services remain unchanged (they're already done!)
- Use `@Published` for all properties that affect UI
- Use `@ObservedObject` to watch other managers

---

**Ready to code? Let's go! 🚀**

Follow the templates above, implement the three ViewModels, wire them up to the Views, and you'll have a functional app with real data flowing through!

