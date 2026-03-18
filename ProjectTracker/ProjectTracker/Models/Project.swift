//
//  Project.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import Foundation
import CoreData

// MARK: - Value Types

struct Project: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String
    var status: ProjectStatus
    var hourlyRate: Double  // NEW: Billable rate per hour
    var clientName: String? // NEW: Optional client/department
    let createdAt: Date
    var updatedAt: Date

    enum ProjectStatus: String, Codable {
        case active
        case paused
        case archived
        case completed
    }
    
    // Helper to calculate billable amount for given hours
    func calculateBillableAmount(hours: Double) -> Double {
        return hours * hourlyRate
    }
}

struct Task: Identifiable, Hashable, Codable {
    let id: UUID
    let projectId: UUID
    var name: String
    var status: TaskStatus
    let createdAt: Date

    enum TaskStatus: String, Codable {
        case todo
        case inProgress
        case completed
    }
}

struct TimeEntry: Identifiable {
    let id: UUID
    let taskId: UUID
    let projectId: UUID
    let startTime: Date
    var endTime: Date?
    var duration: Int // seconds
    let date: Date
    var status: EntryStatus
    var wasInterrupted: Bool

    enum EntryStatus: String, Codable {
        case running
        case paused
        case completed
    }
}

// MARK: - Billing Models

struct Invoice: Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    var periodStart: Date
    var periodEnd: Date
    var totalHours: Double
    var hourlyRate: Double
    var totalAmount: Double
    var status: InvoiceStatus
    let createdAt: Date
    var sentAt: Date?
    var paidAt: Date?
    
    enum InvoiceStatus: String, Codable {
        case draft
        case sent
        case paid
        case cancelled
    }
}

struct BillingPeriod: Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    var startDate: Date
    var endDate: Date
    var totalSeconds: Int
    var hourlyRate: Double
    
    var totalHours: Double {
        Double(totalSeconds) / 3600.0
    }
    
    var billableAmount: Double {
        totalHours * hourlyRate
    }
}

struct WeeklySummary: Codable {
    let weekStartDate: Date
    let totalHours: Double
    let totalAmount: Double
    let projectBreakdown: [ProjectSummary]
    let comparisonPercent: Double? // change vs previous week
    
    struct ProjectSummary: Codable {
        let projectId: UUID
        let projectName: String
        let hours: Double
        let amount: Double
    }
}

struct TimerSession: Codable {
    let id: UUID
    var taskId: UUID
    var projectId: UUID
    var timerStartedAt: Date
    var lastHeartbeat: Date
}

struct ExportRow: Codable {
    let date: String
    let project: String
    let task: String
    let duration: String
    let status: String
}

// MARK: - Errors

enum TimerError: LocalizedError {
    case noActiveTimer
    case invalidSession
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .noActiveTimer:
            return "No active timer found"
        case .invalidSession:
            return "Invalid timer session"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

enum ProjectError: LocalizedError {
    case notFound
    case invalidName
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Project not found"
        case .invalidName:
            return "Invalid project name"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

enum TaskError: LocalizedError {
    case notFound
    case invalidName
    case projectNotFound
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Task not found"
        case .invalidName:
            return "Invalid task name"
        case .projectNotFound:
            return "Project not found"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
