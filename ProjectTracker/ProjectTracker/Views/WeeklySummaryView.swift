//
//  WeeklySummaryView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct WeeklySummaryView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State private var currentWeekStart: Date = Calendar.current.dateIntervalOfWeek(for: Date())?.start ?? Date()
    @State private var weeklySummary: WeeklySummary?
    @State private var showExportDialog = false
    
    private let billingService = BillingService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Week Navigation
                VStack(spacing: 16) {
                    HStack {
                        Text("Weekly Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: previousWeek) {
                                Image(systemName: "chevron.left")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            
                            VStack(spacing: 2) {
                                Text(weekLabelRange())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: nextWeek) {
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .disabled(isCurrentWeek)
                        }
                    }
                }
                .padding()
                
                // Total Tracked Time Card
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Text("Total Tracked")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatHours(weeklySummary?.totalHours ?? 0))
                                    .font(.system(size: 40, weight: .bold, design: .default))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(String(format: "$%.2f", weeklySummary?.totalAmount ?? 0))")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    if let comparison = weeklySummary?.comparisonPercent {
                                        HStack(spacing: 4) {
                                            Image(systemName: comparison >= 0 ? "arrow.up.right" : "arrow.down.right")
                                                .font(.caption)
                                                .foregroundColor(comparison >= 0 ? .green : .red)
                                            
                                            Text(String(format: "%.1f%%", abs(comparison)))
                                                .font(.caption2)
                                                .foregroundColor(comparison >= 0 ? .green : .red)
                                            
                                            Text("vs last week")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Active Projects Breakdown
                if let summary = weeklySummary, !summary.projectBreakdown.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hours Per Project")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Simple bar chart representation
                        VStack(spacing: 12) {
                            ForEach(summary.projectBreakdown.sorted(by: { $0.hours > $1.hours }), id: \.projectId) { projectSummary in
                                ProjectSummaryRow(summary: projectSummary)
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("No Time Entries This Week")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color(.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Export for Billing
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("Export for Billing")
                            .font(.headline)
                        
                        Text("Generate CSV with all time entries for this week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Button(action: { showExportDialog = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Generate Report (CSV)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            loadWeeklySummary()
        }
        .onChange(of: currentWeekStart) { _ in
            loadWeeklySummary()
        }
    }
    
    private func loadWeeklySummary() {
        weeklySummary = billingService.getWeeklySummary(for: currentWeekStart)
    }
    
    private func previousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func nextWeek() {
        if !isCurrentWeek {
            currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
        }
    }
    
    private var isCurrentWeek: Bool {
        let now = Date()
        let currentWeek = Calendar.current.dateIntervalOfWeek(for: now)?.start ?? Date()
        return Calendar.current.isDate(currentWeekStart, inSameDayAs: currentWeek)
    }
    
    private func weekLabelRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        let startLabel = formatter.string(from: currentWeekStart)
        let endLabel = formatter.string(from: endDate)
        
        return "\(startLabel) - \(endLabel)"
    }
    
    private func formatHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours.truncatingRemainder(dividingBy: 1)) * 60)
        return String(format: "%dh %dm", wholeHours, minutes)
    }
}

// MARK: - Project Summary Row

struct ProjectSummaryRow: View {
    let summary: WeeklySummary.ProjectSummary
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.projectName)
                        .font(.callout)
                        .fontWeight(.semibold)
                    
                    Text(String(format: "%.1f hours • $%.2f", summary.hours, summary.amount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.controlBackgroundColor))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * min(summary.hours / 40.0, 1.0))
                }
                .frame(height: 8)
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    WeeklySummaryView()
        .environmentObject(ProjectManager.shared)
}
