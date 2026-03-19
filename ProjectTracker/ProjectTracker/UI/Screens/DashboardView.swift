//
//  DashboardView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct ProjectData {
    let department: String
    let title: String
    let effort: String
}

struct DashboardView: View {
    let projects = [
        ProjectData(department: "Marketing Dept", title: "Website Redesign", effort: "2h 15m"),
        ProjectData(department: "Development", title: "Mobile App API", effort: "1h 45m"),
        ProjectData(department: "Product Design", title: "Icon System", effort: "1h 24m")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header with title and export button
                    HStack(alignment: .center, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            AppTypography.title("Dashboard")
                            AppTypography.subtitle("Welcome back! Tracking your efficiency today.")
                        }
                        
                        Spacer()
                        
                        AppButton("📊 Export", style: .secondary, fullWidth: false) {}
                            .frame(height: 44)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                // Daily Progress Card with circular progress
                VStack(spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.lg) {
                        // Left: Daily stats
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            AppTypography.label("Daily Progress")
                            
                            AppTypography.bodyMuted("You have completed 68% of your daily goal. Keep going, you're ahead of schedule!")
                            
                            HStack(spacing: AppSpacing.lg) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    AppTypography.label("Time Logged")
                                    AppTypography.stat("5h 24m")
                                }
                                
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    AppTypography.label("Daily Goal")
                                    AppTypography.statSmall("8h 00m")
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Circular progress indicator
                        ZStack {
                            Circle()
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: 0.68)
                                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 120, height: 120)
                                .animation(.easeInOut, value: 0.68)
                            
                            VStack(spacing: 4) {
                                AppTypography.stat("68%")
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.twelve)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.twelve)
                        .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.lg)

                // Projects Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        AppTypography.title2("Your Projects")
                        Spacer()
                        NavigationLink(destination: Text("All Projects")) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                    }

                    // Projects Grid - 3 columns on desktop
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.md),
                            GridItem(.flexible(), spacing: AppSpacing.md),
                            GridItem(.flexible(), spacing: AppSpacing.md)
                        ],
                        spacing: AppSpacing.md
                    ) {
                        ForEach(projects.indices, id: \.self) { index in
                            NavigationLink(destination: ProjectDetailView()) {
                                ProjectCardView(
                                    department: projects[index].department,
                                    projectTitle: projects[index].title,
                                    effortToday: projects[index].effort
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background)
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
