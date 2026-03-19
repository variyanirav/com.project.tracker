//
//  ProjectDetailView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct ProjectDetailView: View {
    @State private var quickStartTask = ""
    @State private var quickStartNotes = ""
    @State private var timerSeconds = 45183 // 12:45:03 for display

    var body: some View {
        HStack(spacing: 0) {
            // Left main content
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header: Project title + client
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    AppTypography.title("Web Development")
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(AppColors.primary)
                        AppTypography.bodyMuted("Acme Corp")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Active task panel
                        AppCard {
                            VStack(alignment: .center, spacing: AppSpacing.lg) {
                                AppTypography.label("Currently Working On")
                                
                                AppTypography.headline("UI Design Refinement")
                                
                                Text(formatTime(timerSeconds))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppColors.text)
                                
                                HStack(spacing: AppSpacing.md) {
                                    AppButton("⏸ Pause", style: .secondary, fullWidth: true) {}
                                    AppButton("⏹ Stop", style: .destructive, fullWidth: true) {}
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Quick Start section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            AppTypography.headline("Start New Task")
                            
                            AppTextField("e.g., Code Review", text: $quickStartTask)
                            AppTextField("Short summary...", text: $quickStartNotes)
                            
                            AppButton("Start Timer", style: .primary, fullWidth: true) {}
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.surface.opacity(0.5))
                        .cornerRadius(AppRadius.twelve)
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            }

            // Right sidebar with activity history
            VStack(alignment: .leading, spacing: 0) {
                // Sticky header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    AppTypography.headline("Activity History")
                    AppTypography.caption("Past sessions for this project")
                }
                .padding(AppSpacing.lg)
                .background(AppColors.surface.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)

                // Activity list
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        ForEach(mockActivityItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    AppTypography.captionStrong(item.title)
                                    Spacer()
                                    AppTypography.caption(item.duration)
                                }
                                AppTypography.bodyMuted(item.subtitle)
                                AppTypography.caption(item.date)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.eight)
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .frame(width: 320)
            .background(AppColors.surface)
            .borderLeft()
        }
        .background(AppColors.background)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Mock Data

private struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: String
    let date: String
}

private let mockActivityItems: [ActivityItem] = [
    ActivityItem(
        title: "Database Schema Design",
        subtitle: "Initial setup for PostgreSQL tables and relationships.",
        duration: "2h 15m",
        date: "Oct 24, 2023"
    ),
    ActivityItem(
        title: "API Authentication",
        subtitle: "Implementing JWT and OAuth2 flows for secure access.",
        duration: "4h 02m",
        date: "Oct 23, 2023"
    ),
    ActivityItem(
        title: "Mobile Responsive Fixes",
        subtitle: "Fixed navigation issues on small viewports.",
        duration: "1h 45m",
        date: "Oct 22, 2023"
    ),
    ActivityItem(
        title: "Stakeholder Meeting",
        subtitle: "Monthly progress review with the client team.",
        duration: "0h 58m",
        date: "Oct 22, 2023"
    ),
]

// MARK: - Extensions

extension View {
    func borderLeft() -> some View {
        self.overlay(
            Rectangle()
                .fill(AppColors.border.opacity(0.3))
                .frame(width: 1)
                .ignoresSafeArea(),
            alignment: .leading
        )
    }
}
