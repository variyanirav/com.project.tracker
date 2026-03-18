//
//  BillingService.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import Foundation
import SQLite3

class BillingService {
    private let db = DatabaseManager.shared
    private let projectManager = ProjectManager.shared
    
    // MARK: - Billing Calculations
    
    /// Calculate billable amount for a project within a date range
    func calculateProjectBilling(
        projectId: UUID,
        startDate: Date,
        endDate: Date
    ) -> BillingPeriod? {
        let startDateStr = startDate.ISO8601Format().split(separator: "T")[0]
        let endDateStr = endDate.ISO8601Format().split(separator: "T")[0]
        
        let query = """
        SELECT COALESCE(SUM(duration), 0) FROM time_entries
        WHERE project_id = '\(projectId.uuidString)'
        AND date >= '\(startDateStr)' AND date <= '\(endDateStr)'
        """
        
        let totalSeconds = db.scalar(query)
        
        // Get project to retrieve hourly rate
        guard let projects = projectManager.projects.first(where: { $0.id == projectId }) else {
            Logger.error("Project not found for billing calculation")
            return nil
        }
        
        return BillingPeriod(
            id: UUID(),
            projectId: projectId,
            startDate: startDate,
            endDate: endDate,
            totalSeconds: totalSeconds,
            hourlyRate: projects.hourlyRate
        )
    }
    
    /// Calculate weekly summary with breakdown by project
    func getWeeklySummary(for weekStartDate: Date) -> WeeklySummary {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        let startStr = weekStartDate.ISO8601Format().split(separator: "T")[0]
        let endStr = weekEndDate.ISO8601Format().split(separator: "T")[0]
        
        var projectSummaries: [WeeklySummary.ProjectSummary] = []
        var totalAmount = 0.0
        
        for project in projectManager.projects {
            let query = """
            SELECT COALESCE(SUM(duration), 0) FROM time_entries
            WHERE project_id = '\(project.id.uuidString)'
            AND date >= '\(startStr)' AND date <= '\(endStr)'
            """
            
            let totalSeconds = db.scalar(query)
            let hours = Double(totalSeconds) / 3600.0
            let amount = hours * project.hourlyRate
            
            if totalSeconds > 0 {
                projectSummaries.append(
                    WeeklySummary.ProjectSummary(
                        projectId: project.id,
                        projectName: project.name,
                        hours: hours,
                        amount: amount
                    )
                )
                totalAmount += amount
            }
        }
        
        let totalHours = Double(projectSummaries.reduce(0) { $0 + Int($1.hours * 3600) }) / 3600.0
        
        // Calculate comparison with previous week
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStartDate)!
        let previousWeekTotal = getWeeklyTotalSeconds(startDate: previousWeekStart)
        let previousWeekHours = Double(previousWeekTotal) / 3600.0
        
        let comparisonPercent = previousWeekHours > 0 ? ((totalHours - previousWeekHours) / previousWeekHours) * 100 : nil
        
        return WeeklySummary(
            weekStartDate: weekStartDate,
            totalHours: totalHours,
            totalAmount: totalAmount,
            projectBreakdown: projectSummaries,
            comparisonPercent: comparisonPercent
        )
    }
    
    /// Get daily total hours
    func getDailyTotal(for date: Date) -> Double {
        let dateStr = date.ISO8601Format().split(separator: "T")[0]
        let query = "SELECT COALESCE(SUM(duration), 0) FROM time_entries WHERE date = '\(dateStr)'"
        let seconds = db.scalar(query)
        return Double(seconds) / 3600.0
    }
    
    /// Get today's amount based on all projects' rates
    func getTodayBillableAmount() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todayStr = today.ISO8601Format().split(separator: "T")[0]
        
        let query = """
        SELECT project_id, COALESCE(SUM(duration), 0) as total_seconds
        FROM time_entries WHERE date = '\(todayStr)'
        GROUP BY project_id
        """
        
        var totalAmount = 0.0
        
        // Query raw results and map to project rates
        for project in projectManager.projects {
            let projectQuery = """
            SELECT COALESCE(SUM(duration), 0) FROM time_entries
            WHERE project_id = '\(project.id.uuidString)' AND date = '\(todayStr)'
            """
            let seconds = db.scalar(projectQuery)
            let hours = Double(seconds) / 3600.0
            totalAmount += hours * project.hourlyRate
        }
        
        return totalAmount
    }
    
    // MARK: - Invoice Generation
    
    /// Create an invoice for a project in a date range
    func createInvoice(
        projectId: UUID,
        startDate: Date,
        endDate: Date
    ) -> Invoice? {
        guard let billing = calculateProjectBilling(
            projectId: projectId,
            startDate: startDate,
            endDate: endDate
        ) else {
            Logger.error("Failed to calculate billing for invoice")
            return nil
        }
        
        let invoice = Invoice(
            id: UUID(),
            projectId: projectId,
            periodStart: startDate,
            periodEnd: endDate,
            totalHours: billing.totalHours,
            hourlyRate: billing.hourlyRate,
            totalAmount: billing.billableAmount,
            status: .draft,
            createdAt: Date()
        )
        
        saveInvoice(invoice)
        return invoice
    }
    
    /// Get all invoices for a project
    func getInvoices(for projectId: UUID) -> [Invoice] {
        let query = """
        SELECT id, projectId, periodStart, periodEnd, totalHours, hourlyRate, totalAmount, status, createdAt, sentAt, paidAt
        FROM invoices WHERE projectId = '\(projectId.uuidString)'
        ORDER BY createdAt DESC
        """
        
        // Note: This is a placeholder. In real implementation, we'd use Core Data or expand DatabaseManager
        // For now, this returns empty as we haven't created the invoices table yet
        return []
    }
    
    /// Mark invoice as sent
    func markInvoiceAsSent(_ invoice: Invoice) {
        var updated = invoice
        updated.sentAt = Date()
        updated.status = .sent
        
        let query = """
        UPDATE invoices SET status = 'sent', sentAt = '\(updated.sentAt?.ISO8601Format() ?? "")' 
        WHERE id = '\(invoice.id.uuidString)'
        """
        
        if db.execute(query) {
            Logger.info("Invoice marked as sent: \(invoice.id)")
        } else {
            Logger.error("Failed to mark invoice as sent")
        }
    }
    
    /// Mark invoice as paid
    func markInvoiceAsPaid(_ invoice: Invoice) {
        var updated = invoice
        updated.paidAt = Date()
        updated.status = .paid
        
        let query = """
        UPDATE invoices SET status = 'paid', paidAt = '\(updated.paidAt?.ISO8601Format() ?? "")' 
        WHERE id = '\(invoice.id.uuidString)'
        """
        
        if db.execute(query) {
            Logger.info("Invoice marked as paid: \(invoice.id)")
        } else {
            Logger.error("Failed to mark invoice as paid")
        }
    }
    
    // MARK: - Private Helpers
    
    private func getWeeklyTotalSeconds(startDate: Date) -> Int {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        
        let startStr = startDate.ISO8601Format().split(separator: "T")[0]
        let endStr = endDate.ISO8601Format().split(separator: "T")[0]
        
        let query = """
        SELECT COALESCE(SUM(duration), 0) FROM time_entries
        WHERE date >= '\(startStr)' AND date <= '\(endStr)'
        """
        
        return db.scalar(query)
    }
    
    private func saveInvoice(_ invoice: Invoice) {
        // Placeholder for invoice persistence
        // This will use Core Data or extended DatabaseManager
        Logger.debug("Invoice saved: \(invoice.id)")
    }
}
