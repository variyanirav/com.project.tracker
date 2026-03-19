//
//  RootNavigationView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

enum AppSection: String, CaseIterable, Hashable {
    case dashboard = "Dashboard"
    case projects = "Projects"
    case reports = "Reports"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard:
            return AppIcons.dashboard
        case .projects:
            return AppIcons.projects
        case .reports:
            return AppIcons.reports
        case .settings:
            return AppIcons.settings
        }
    }
}

/// Root navigation for macOS application - left navigation rail with content area
struct RootNavigationView: View {
    @State private var selectedSection: AppSection = .dashboard
    @State private var selectedProject: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Navigation Rail (Expandable with icons + labels)
            VStack(alignment: .leading, spacing: 0) {
                // Logo/Header
                HStack(spacing: AppSpacing.md) {
                    Text("⏱️")
                        .font(.system(size: 24, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        AppTypography.headline("ProjectTracker")
                        AppTypography.caption("Timer")
                    }
                }
                .padding(AppSpacing.lg)
                .frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface)
                .border(AppColors.border.opacity(0.3), width: 1)

                Divider()
                    .background(AppColors.border.opacity(0.3))

                // Navigation Items
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(AppSection.allCases.dropLast(), id: \.self) { section in
                        NavigationMenuButton(
                            section: section,
                            isSelected: selectedSection == section
                        ) {
                            selectedSection = section
                        }
                    }
                }
                .padding(AppSpacing.md)

                Spacer()

                Divider()
                    .background(AppColors.border.opacity(0.3))

                // Settings at bottom
                NavigationMenuButton(
                    section: .settings,
                    isSelected: selectedSection == .settings
                ) {
                    selectedSection = .settings
                }
                .padding(AppSpacing.md)
            }
            .frame(width: 240)
            .background(AppColors.background)
            .border(AppColors.border.opacity(0.3), width: 1)

            // Main Content Area
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                switch selectedSection {
                case .dashboard:
                    DashboardView()
                case .projects:
                    ProjectDetailView()
                case .reports:
                    ReportsView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .background(AppColors.background)
    }
}

// MARK: - Navigation Menu Button Component

struct NavigationMenuButton: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var iconEmoji: String {
        switch section {
        case .dashboard:
            return "📊"
        case .projects:
            return "📁"
        case .reports:
            return "📈"
        case .settings:
            return "⚙️"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(iconEmoji)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 24)
                
                AppTypography.body(section.rawValue)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.text)
                
                Spacer()
            }
            .frame(height: 44)
            .padding(.horizontal, AppSpacing.md)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: AppRadius.eight)
                    .fill(AppColors.primary.opacity(0.12)) :
                isHovered ?
                RoundedRectangle(cornerRadius: AppRadius.eight)
                    .fill(AppColors.surface) : nil
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Placeholder Settings View

struct SettingsView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            AppTypography.title("Settings")
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                AppTypography.headline("Preferences")
                AppTypography.body("Settings coming soon...")
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
    }
}

#Preview {
    RootNavigationView()
        .preferredColorScheme(.dark)
}
