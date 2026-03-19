//
//  ProjectCardView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

/// ProjectCardView displays a project summary card with department, title, and effort
/// Matches the dashboard grid layout from mockups
struct ProjectCardView: View {
    let department: String
    let projectTitle: String
    let effortToday: String
    let action: (() -> Void)?
    
    init(
        department: String,
        projectTitle: String,
        effortToday: String,
        action: (() -> Void)? = nil
    ) {
        self.department = department
        self.projectTitle = projectTitle
        self.effortToday = effortToday
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with department label and play button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    AppTypography.label(department)
                    AppTypography.headline(projectTitle)
                }
                
                Spacer()
                
                // Play action button
                Button(action: action ?? {}) {
                    Image(systemName: AppIcons.play)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: AppSizes.avatarSmall, height: AppSizes.avatarSmall)
                        .background(
                            Circle()
                                .fill(AppColors.primary)
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 4, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Divider
            Divider()
                .background(AppColors.border.opacity(0.5))
            
            // Footer with today's effort
            HStack {
                AppTypography.caption("Today's Effort")
                Spacer()
                AppTypography.captionStrong(effortToday)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.twelve)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.twelve)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.lg) {
            ProjectCardView(
                department: "Marketing Dept",
                projectTitle: "Website Redesign",
                effortToday: "2h 15m"
            )
            
            ProjectCardView(
                department: "Development",
                projectTitle: "Mobile App API",
                effortToday: "1h 45m"
            )
            
            ProjectCardView(
                department: "Product Design",
                projectTitle: "Icon System",
                effortToday: "1h 24m"
            )
        }
        .padding(AppSpacing.lg)
    }
}
