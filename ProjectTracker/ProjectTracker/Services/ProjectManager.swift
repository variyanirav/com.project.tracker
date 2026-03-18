//
//  ProjectManager.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import Foundation
import SQLite3

class ProjectManager: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    
    private let db = DatabaseManager.shared
    
    static let shared = ProjectManager()
    
    private init() {
        loadProjects()
    }
    
    // MARK: - Project CRUD
    
    func loadProjects() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let query = "SELECT id, name, description, client_name, hourly_rate, status, created_at, updated_at FROM projects ORDER BY updated_at DESC"
            
            self.projects = self.db.query(query) { statement in
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let description = String(cString: sqlite3_column_text(statement, 2))
                let clientName = String(cString: sqlite3_column_text(statement, 3))
                let hourlyRate = Double(sqlite3_column_double(statement, 4))
                let statusRaw = String(cString: sqlite3_column_text(statement, 5))
                let createdAtRaw = String(cString: sqlite3_column_text(statement, 6))
                let updatedAtRaw = String(cString: sqlite3_column_text(statement, 7))
                
                let status = Project.ProjectStatus(rawValue: statusRaw) ?? .active
                let createdAt = createdAtRaw.parseISO8601() ?? Date()
                let updatedAt = updatedAtRaw.parseISO8601() ?? Date()
                
                return Project(
                    id: UUID(uuidString: id) ?? UUID(),
                    name: name,
                    description: description,
                    status: status,
                    hourlyRate: hourlyRate,
                    clientName: clientName.isEmpty ? nil : clientName,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
            
            Logger.info("Loaded \(self.projects.count) projects from database")
        }
    }
    
    func createProject(name: String, description: String, hourlyRate: Double = 0.0, clientName: String? = nil) -> Project {
        let project = Project(
            id: UUID(),
            name: name,
            description: description,
            status: .active,
            hourlyRate: hourlyRate,
            clientName: clientName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let query = """
        INSERT INTO projects (id, name, description, client_name, hourly_rate, status, created_at, updated_at)
        VALUES ('\(project.id.uuidString)', '\(name.replacingOccurrences(of: "'", with: "''"))', '\(description.replacingOccurrences(of: "'", with: "''"))', '\(clientName ?? "")' , \(hourlyRate), 'active', datetime('now'), datetime('now'))
        """
        
        if db.execute(query) {
            Logger.info("Project created: \(name) (Rate: $\(hourlyRate)/hr)")
            DispatchQueue.main.async { [weak self] in
                self?.projects.insert(project, at: 0)
            }
        } else {
            Logger.error("Failed to create project: \(name)")
        }
        
        return project
    }
    
    func updateProjectRate(_ project: Project, hourlyRate: Double) {
        let query = """
        UPDATE projects SET hourly_rate = \(hourlyRate), updated_at = datetime('now') WHERE id = '\(project.id.uuidString)'
        """
        
        if db.execute(query) {
            Logger.info("Project rate updated: \(project.name) to $\(hourlyRate)/hr")
            DispatchQueue.main.async { [weak self] in
                if let index = self?.projects.firstIndex(where: { $0.id == project.id }) {
                    self?.projects[index].hourlyRate = hourlyRate
                }
            }
        } else {
            Logger.error("Failed to update project rate")
        }
    }
    
    func deleteProject(_ project: Project) {
        let query = "DELETE FROM projects WHERE id = '\(project.id.uuidString)'"
        
        if db.execute(query) {
            Logger.info("Project deleted: \(project.name)")
            DispatchQueue.main.async { [weak self] in
                self?.projects.removeAll { $0.id == project.id }
                if self?.selectedProject?.id == project.id {
                    self?.selectedProject = nil
                }
            }
        } else {
            Logger.error("Failed to delete project: \(project.name)")
        }
    }
    
    // MARK: - Task CRUD
    
    func getTasks(for project: Project) -> [Task] {
        let query = "SELECT id, project_id, name, status, created_at FROM tasks WHERE project_id = '\(project.id.uuidString)' ORDER BY created_at DESC"
        
        return db.query(query) { statement in
            let id = String(cString: sqlite3_column_text(statement, 0))
            let projectId = String(cString: sqlite3_column_text(statement, 1))
            let name = String(cString: sqlite3_column_text(statement, 2))
            let statusRaw = String(cString: sqlite3_column_text(statement, 3))
            let createdAtRaw = String(cString: sqlite3_column_text(statement, 4))
            
            let status = Task.TaskStatus(rawValue: statusRaw) ?? .todo
            let createdAt = createdAtRaw.parseISO8601() ?? Date()
            
            return Task(
                id: UUID(uuidString: id) ?? UUID(),
                projectId: UUID(uuidString: projectId) ?? UUID(),
                name: name,
                status: status,
                createdAt: createdAt
            )
        }
    }
    
    func createTask(for project: Project, name: String) -> Task {
        let task = Task(
            id: UUID(),
            projectId: project.id,
            name: name,
            status: .todo,
            createdAt: Date()
        )
        
        let query = """
        INSERT INTO tasks (id, project_id, name, status, created_at)
        VALUES ('\(task.id.uuidString)', '\(project.id.uuidString)', '\(name.replacingOccurrences(of: "'", with: "''"))', 'todo', datetime('now'))
        """
        
        if db.execute(query) {
            Logger.info("Task created: \(name) for project \(project.name)")
        } else {
            Logger.error("Failed to create task: \(name)")
        }
        
        return task
    }
    
    func deleteTask(_ task: Task) {
        let query = "DELETE FROM tasks WHERE id = '\(task.id.uuidString)'"
        
        if db.execute(query) {
            Logger.info("Task deleted: \(task.name)")
        } else {
            Logger.error("Failed to delete task: \(task.name)")
        }
    }
    
    func updateTaskStatus(_ task: Task, status: Task.TaskStatus) {
        let query = "UPDATE tasks SET status = '\(status.rawValue)' WHERE id = '\(task.id.uuidString)'"
        
        if db.execute(query) {
            Logger.info("Task status updated: \(task.name) -> \(status.rawValue)")
        } else {
            Logger.error("Failed to update task status: \(task.name)")
        }
    }
    
    // MARK: - Statistics
    
    func getProjectCount() -> Int {
        return db.scalar("SELECT COUNT(*) FROM projects")
    }
    
    func getTaskCount(for project: Project) -> Int {
        return db.scalar("SELECT COUNT(*) FROM tasks WHERE project_id = '\(project.id.uuidString)'")
    }
    
    func getTodayTaskCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date()).ISO8601Format()
        return db.scalar("SELECT COUNT(*) FROM time_entries WHERE date >= '\(today)'")
    }
    
    func getTodayHours() -> Double {
        let today = Calendar.current.startOfDay(for: Date()).ISO8601Format()
        let query = "SELECT COALESCE(SUM(duration), 0) FROM time_entries WHERE date >= '\(today)'"
        let seconds = db.scalar(query)
        return Double(seconds) / 3600.0
    }
}
