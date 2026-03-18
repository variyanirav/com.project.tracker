//
//  ExportService.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import Foundation
import SQLite3

class ExportService {
    private let db = DatabaseManager.shared
    private let projectManager = ProjectManager.shared
    
    // MARK: - CSV Export
    
    /// Export time entries for a date range as CSV
    func exportToCSV(
        projectId: UUID? = nil,
        startDate: Date,
        endDate: Date
    ) -> String {
        var csvContent = "Date,Project,Task,Duration (Hours),Billable Amount,Status\n"
        
        let startDateStr = startDate.ISO8601Format().split(separator: "T")[0]
        let endDateStr = endDate.ISO8601Format().split(separator: "T")[0]
        
        var query = """
        SELECT te.id, te.project_id, te.task_id, te.start_time, te.end_time, te.duration, te.date, te.status,
               p.name as project_name, p.hourly_rate,
               t.name as task_name
        FROM time_entries te
        JOIN projects p ON te.project_id = p.id
        LEFT JOIN tasks t ON te.task_id = t.id
        WHERE te.date >= '\(startDateStr)' AND te.date <= '\(endDateStr)'
        """
        
        if let projectId = projectId {
            query += " AND te.project_id = '\(projectId.uuidString)'"
        }
        
        query += " ORDER BY te.date DESC, te.start_time DESC"
        
        // Execute query and build CSV rows
        let rows = db.query(query) { statement -> (date: String, project: String, task: String, hours: Double, amount: Double, status: String) in
            let dateStr = String(cString: sqlite3_column_text(statement, 6))
            let projectName = String(cString: sqlite3_column_text(statement, 8))
            let hourlyRate = Double(sqlite3_column_double(statement, 9))
            let taskName = String(cString: sqlite3_column_text(statement, 10))
            let durationSeconds = Int(sqlite3_column_int(statement, 5))
            let statusStr = String(cString: sqlite3_column_text(statement, 7))
            
            let hours = Double(durationSeconds) / 3600.0
            let amount = hours * hourlyRate
            
            return (
                date: dateStr,
                project: projectName,
                task: taskName,
                hours: hours,
                amount: amount,
                status: statusStr
            )
        }
        
        // Add data rows with proper CSV escaping
        for row in rows {
            let escapedDate = escapeCSV(row.date)
            let escapedProject = escapeCSV(row.project)
            let escapedTask = escapeCSV(row.task)
            let hours = String(format: "%.2f", row.hours)
            let amount = String(format: "%.2f", row.amount)
            let status = escapeCSV(row.status.capitalized)
            
            csvContent += "\(escapedDate),\(escapedProject),\(escapedTask),\(hours),\(amount),\(status)\n"
        }
        
        return csvContent
    }
    
    /// Export weekly invoice as CSV (more detailed format for billing)
    func exportWeeklyInvoiceCSV(
        projectId: UUID,
        weekStartDate: Date
    ) -> String {
        var csvContent = "=== WEEKLY INVOICE ===\n"
        
        guard let project = projectManager.projects.first(where: { $0.id == projectId }) else {
            Logger.error("Project not found for invoice export")
            return csvContent
        }
        
        // Header
        let weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
        csvContent += "\nProject:,\(escapeCSV(project.name))\n"
        if let client = project.clientName {
            csvContent += "Client:,\(escapeCSV(client))\n"
        }
        csvContent += "Period:,\(dateToString(weekStartDate)) - \(dateToString(weekEndDate))\n"
        csvContent += "Rate:,$\(String(format: "%.2f", project.hourlyRate))/hour\n\n"
        
        // Column headers
        csvContent += "Date,Task,Duration (HH:MM:SS),Hours (decimal),Amount\n"
        
        // Detail rows
        let startDateStr = weekStartDate.ISO8601Format().split(separator: "T")[0]
        let endDateStr = weekEndDate.ISO8601Format().split(separator: "T")[0]
        
        let query = """
        SELECT te.date, t.name as task_name, te.duration, te.start_time
        FROM time_entries te
        LEFT JOIN tasks t ON te.task_id = t.id
        WHERE te.project_id = '\(projectId.uuidString)'
        AND te.date >= '\(startDateStr)' AND te.date <= '\(endDateStr)'
        AND te.status = 'completed'
        ORDER BY te.date DESC, te.start_time DESC
        """
        
        var totalSeconds = 0
        let rows = db.query(query) { statement -> (date: String, task: String, duration: Int) in
            let dateStr = String(cString: sqlite3_column_text(statement, 0))
            let taskName = String(cString: sqlite3_column_text(statement, 1))
            let duration = Int(sqlite3_column_int(statement, 2))
            
            totalSeconds += duration
            
            return (date: dateStr, task: taskName, duration: duration)
        }
        
        for row in rows {
            let taskName = escapeCSV(row.task.isEmpty ? "Untracked" : row.task)
            let duration = formatDuration(row.duration)
            let hours = String(format: "%.2f", Double(row.duration) / 3600.0)
            let amount = String(format: "%.2f", (Double(row.duration) / 3600.0) * project.hourlyRate)
            
            csvContent += "\(row.date),\(taskName),\(duration),\(hours),\(amount)\n"
        }
        
        // Summary
        csvContent += "\n"
        csvContent += "TOTAL HOURS:,\(String(format: "%.2f", Double(totalSeconds) / 3600.0))\n"
        csvContent += "TOTAL AMOUNT:,$\(String(format: "%.2f", (Double(totalSeconds) / 3600.0) * project.hourlyRate))\n"
        
        return csvContent
    }
    
    // MARK: - CSV Utilities
    
    private func escapeCSV(_ field: String) -> String {
        // If field contains comma, quotes, or newline, wrap in quotes and escape internal quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - File Operations
    
    /// Save CSV content to file and return file URL
    func saveCSVFile(_ content: String, filename: String = "export.csv") -> URL? {
        guard let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.error("Unable to access Documents directory")
            return nil
        }
        
        let fileURL = documentDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.info("CSV exported to: \(fileURL.path)")
            return fileURL
        } catch {
            Logger.error("Failed to save CSV file: \(error.localizedDescription)")
            return nil
        }
    }
}
