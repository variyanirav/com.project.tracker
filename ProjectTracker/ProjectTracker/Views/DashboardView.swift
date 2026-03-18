//
//  DashboardView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var projectManager: ProjectManager
    @State private var showProjectList = false
    @State private var selectedProject: Project?
    @State private var selectedTask: Task?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ProjectTracker")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Time Tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { showProjectList = true }) {
                        Image(systemName: "list.bullet")
                            .font(.body)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .help("View Projects")
                }
                .padding()
                
                Divider()
                
                // Timer Display Section
                VStack(spacing: 20) {
                    // Current Timer Status
                    if timerManager.isRunning {
                        VStack(spacing: 12) {
                            if let project = selectedProject {
                                Text("Tracking: \(project.name)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Timer Running")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            TimerDisplayView()
                                .environmentObject(timerManager)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    } else if timerManager.isPaused {
                        VStack(spacing: 12) {
                            Text("Timer Paused")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text(TimeFormatter.formatReadable(timerManager.elapsedSeconds))
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 12) {
                            Text("No Timer Active")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if projectManager.projects.isEmpty {
                                Text("Create a project to start tracking time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select a project below to start")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Project/Task Selection
                    if !timerManager.isRunning {
                        VStack(spacing: 8) {
                            if !projectManager.projects.isEmpty {
                                Picker("Project", selection: $selectedProject) {
                                    Text("Select Project").tag(nil as Project?)
                                    ForEach(projectManager.projects) { project in
                                        Text(project.name).tag(project as Project?)
                                    }
                                }
                                
                                if let project = selectedProject {
                                    let tasks = projectManager.getTasks(for: project)
                                    if !tasks.isEmpty {
                                        Picker("Task", selection: $selectedTask) {
                                            Text("Select Task").tag(nil as Task?)
                                            ForEach(tasks) { task in
                                                Text(task.name).tag(task as Task?)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Timer Controls
                    HStack(spacing: 12) {
                        if !timerManager.isRunning && !timerManager.isPaused {
                            Button(action: { startTimer() }) {
                                Label("Start", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedProject == nil)
                        } else if timerManager.isRunning {
                            Button(action: { timerManager.pauseTimer() }) {
                                Label("Pause", systemImage: "pause.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: { timerManager.stopTimer() }) {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        } else if timerManager.isPaused {
                            Button(action: { timerManager.resumeTimer() }) {
                                Label("Resume", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: { timerManager.stopTimer() }) {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding()
                }
                .padding()
                
                Divider()
                
                // Quick Stats
                VStack(spacing: 16) {
                    Text("Today's Summary")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Projects",
                            value: "\(projectManager.projects.count)",
                            icon: "folder"
                        )
                        StatCard(
                            title: "Tasks",
                            value: "\(projectManager.getTodayTaskCount())",
                            icon: "checkmark.circle"
                        )
                        StatCard(
                            title: "Hours",
                            value: String(format: "%.1f", projectManager.getTodayHours()),
                            icon: "clock"
                        )
                    }
                }
                .padding()
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Divider()
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Right-click for options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Dashboard")
            .popover(isPresented: $showProjectList, arrowEdge: .trailing) {
                ProjectListView()
                    .environmentObject(projectManager)
                    .frame(minWidth: 450, minHeight: 500)
            }
        }
    }
    
    private func startTimer() {
        guard let project = selectedProject else { return }
        let taskId = selectedTask?.id ?? UUID()
        timerManager.startTimer(taskId: taskId, projectId: project.id)
    }
}

// MARK: - Timer Display Component
struct TimerDisplayView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatTime(timerManager.elapsedSeconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            Text("\(timerManager.elapsedSeconds) seconds")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView()
        .environmentObject(TimerManager.shared)
}
