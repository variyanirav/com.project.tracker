//
//  ProjectListView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State private var showAddProject = false
    @State private var projectName = ""
    @State private var projectDescription = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text("Projects (\(projectManager.projects.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if showAddProject {
                    Button("✕") {
                        showAddProject = false
                        resetForm()
                    }
                    .buttonStyle(.plain)
                    .font(.body)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            if showAddProject {
                // ADD PROJECT FORM
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create New Project")
                                .font(.headline)
                            
                            // Project Name Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Project Name *")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter project name", text: $projectName)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.bottom, 4)
                            }
                            
                            // Description Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ZStack(alignment: .topLeading) {
                                    if projectDescription.isEmpty {
                                        Text("Optional description")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .padding(8)
                                    }
                                    
                                    TextEditor(text: $projectDescription)
                                        .frame(minHeight: 80, maxHeight: 120)
                                        .font(.body)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(6)
                                        .opacity(projectDescription.isEmpty ? 0.5 : 1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                showAddProject = false
                                resetForm()
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Create Project") {
                                createProject()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // PROJECTS LIST
                if projectManager.projects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No Projects Yet")
                                .font(.headline)
                            
                            Text("Create your first project to start tracking time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: { showAddProject = true }) {
                            Label("New Project", systemImage: "plus.circle.fill")
                                .frame(maxWidth: 200)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor).opacity(0.3))
                    
                } else {
                    // Scrollable List
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(projectManager.projects.enumerated()), id: \.element.id) { index, project in
                                ProjectRowView(project: project, projectManager: projectManager)
                                
                                if index < projectManager.projects.count - 1 {
                                    Divider()
                                        .padding(.vertical, 0)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    
                    // Add Button at Bottom
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: { showAddProject = true }) {
                            Label("New Project", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .padding(12)
                    }
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }
    
    private func createProject() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        projectManager.createProject(
            name: trimmedName,
            description: projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        resetForm()
        showAddProject = false
    }
    
    private func resetForm() {
        projectName = ""
        projectDescription = ""
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: Project
    let projectManager: ProjectManager
    
    @State private var isExpanded = false
    @State private var tasks: [Task] = []
    @State private var showAddTask = false
    @State private var newTaskName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Project Header
            Button(action: { 
                isExpanded.toggle()
                if isExpanded && tasks.isEmpty {
                    tasks = projectManager.getTasks(for: project)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if !project.description.isEmpty {
                            Text(project.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                        
                        Text("\(tasks.count) tasks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // Expanded Tasks View
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                
                VStack(spacing: 0) {
                    if tasks.isEmpty && !showAddTask {
                        HStack {
                            Text("No tasks yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { showAddTask = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(tasks, id: \.id) { task in
                            HStack(spacing: 12) {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundColor(task.status == .completed ? .green : .secondary)
                                
                                Text(task.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    projectManager.deleteTask(task)
                                    tasks.removeAll { $0.id == task.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                        }
                        
                        if showAddTask {
                            HStack(spacing: 8) {
                                TextField("Task name", text: $newTaskName)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                
                                Button("Add") {
                                    let newTask = projectManager.createTask(
                                        for: project,
                                        name: newTaskName
                                    )
                                    tasks.append(newTask)
                                    newTaskName = ""
                                    showAddTask = false
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        } else {
                            Button(action: { showAddTask = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text("Add Task")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .background(Color(.controlBackgroundColor).opacity(0.5))
            }
        }
    }
}
#Preview {
    ProjectListView()
        .environmentObject(ProjectManager.shared)
}
