//
//  AppBadge.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

enum AppBadgeStyle {
    case info, success, warning, danger
}

struct AppBadge: View {
    let text: String
    let style: AppBadgeStyle
    
    private var backgroundColor: Color {
        switch style {
        case .info:
            return AppColors.primary.opacity(0.15)
        case .success:
            return AppColors.success.opacity(0.15)
        case .warning:
            return AppColors.warning.opacity(0.15)
        case .danger:
            return AppColors.danger.opacity(0.15)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .info:
            return AppColors.primary
        case .success:
            return AppColors.success
        case .warning:
            return AppColors.warning
        case .danger:
            return AppColors.danger
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.eight))
    }
}

#Preview {
    VStack(spacing: 10) {
        AppBadge(text: "Info", style: .info)
        AppBadge(text: "Success", style: .success)
        AppBadge(text: "Warning", style: .warning)
        AppBadge(text: "Danger", style: .danger)
    }
    .padding()
    .background(AppColors.background)
}
