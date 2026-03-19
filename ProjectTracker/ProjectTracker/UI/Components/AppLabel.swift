//
//  AppLabel.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

enum AppLabelRole {
    case primary, muted, warning, success, danger
}

struct AppLabel: View {
    let text: String
    var role: AppLabelRole = .primary
    var size: CGFloat = 14
    
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .regular))
            .foregroundColor(color(for: role))
    }
    
    private func color(for role: AppLabelRole) -> Color {
        switch role {
        case .primary:
            return AppColors.primary
        case .muted:
            return AppColors.textMuted
        case .warning:
            return AppColors.warning
        case .success:
            return AppColors.success
        case .danger:
            return AppColors.danger
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AppLabel(text: "Primary", role: .primary)
        AppLabel(text: "Muted", role: .muted)
        AppLabel(text: "Warning", role: .warning)
        AppLabel(text: "Success", role: .success)
        AppLabel(text: "Danger", role: .danger)
    }
    .padding()
    .background(AppColors.background)
}

