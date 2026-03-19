//
//  ReportsView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct ReportsView: View {
    enum TimeRange: String, CaseIterable {
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case custom = "Custom"
    }
    
    @State private var selectedTimeRange: Int = 0
    
    private let mockProjects = [
        (name: "API Integration", client: "Stripe Labs", status: "In Progress", hours: "18h 45m"),
        (name: "Project Phoenix", client: "Aether Corp", status: "Review", hours: "12h 10m"),
        (name: "Design System Update", client: "Internal", status: "Complete", hours: "6h 30m"),
        (name: "QA Testing - Beta", client: "MetaLogix", status: "In Progress", hours: "4h 50m"),
    ]
    
    private var totalTrackedHours: String {
        "42h 15m"
    }
    
    private var activeProjects: String {
        "6"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and date range selector
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    AppTypography.title("Weekly Summary")
                    Spacer()
                    AppSegmentedControl(
                        items: TimeRange.allCases.map { $0.rawValue },
                        selection: $selectedTimeRange
                    )
                    .frame(width: 250)
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Stat Cards - Total Tracked and Active Projects
                    HStack(spacing: AppSpacing.md) {
                        StatCard(
                            title: "Total Tracked",
                            value: totalTrackedHours,
                            icon: AppIcons.timer
                        )
                        
                        StatCard(
                            title: "Active Projects",
                            value: activeProjects,
                            icon: AppIcons.projects
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Project Details Table Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        AppTypography.headline("Project Details")

                        VStack(spacing: 0) {
                            // Table Header
                            HStack(spacing: AppSpacing.md) {
                                AppTypography.label("Project Name")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                AppTypography.label("Client")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                AppTypography.label("Status")
                                    .frame(width: 100)
                                AppTypography.label("Total Hours")
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surfaceAlt.opacity(0.5))
                            .cornerRadius(AppRadius.twelve)

                            Divider()
                                .background(AppColors.border.opacity(0.3))

                            // Table Rows
                            ForEach(0..<mockProjects.count, id: \.self) { index in
                                let project = mockProjects[index]
                                
                                HStack(spacing: AppSpacing.md) {
                                    AppTypography.body(project.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    AppTypography.body(project.client)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    AppBadge(text: project.status, style: statusStyle(project.status))
                                        .frame(width: 100)
                                    
                                    AppTypography.captionStrong(project.hours)
                                        .frame(width: 100, alignment: .trailing)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.surface.opacity(0.5))

                                if index < mockProjects.count - 1 {
                                    Divider()
                                        .background(AppColors.border.opacity(0.2))
                                }
                            }

                            RoundedRectangle(cornerRadius: AppRadius.twelve, style: .continuous)
                                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.twelve)
                                .fill(AppColors.surface)
                        )
                        .clipped()
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Export for Billing Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        AppTypography.headline("Export for Billing")
                        
                        AppTypography.bodyMuted("Generate a comprehensive CSV report of all tracked hours for the selected period.")
                        
                        AppButton(
                            "📥 Generate Bill (CSV)",
                            style: .primary,
                            fullWidth: true
                        ) {}
                    }
                    .padding(AppSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.twelve)
                            .fill(AppColors.primary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.twelve)
                                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .background(AppColors.background)
    }
    
    private func statusStyle(_ status: String) -> AppBadgeStyle {
        switch status {
        case "In Progress":
            return .info
        case "Complete":
            return .success
        case "Review":
            return .warning
        default:
            return .info
        }
    }
}

// MARK: - Subcomponents

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    AppTypography.caption(title)
                    AppTypography.title2(value)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: AppSizes.avatarLarge, height: AppSizes.avatarLarge)
                    .background(
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                    )
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.twelve)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.twelve)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ReportsView()
        .preferredColorScheme(.dark)
}
