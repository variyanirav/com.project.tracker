//
//  AppButton.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct AppButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case subtle
        case outline
    }

    let title: String
    var style: ButtonStyle = .primary
    var fullWidth: Bool = false
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    init(
        _ title: String,
        style: ButtonStyle = .primary,
        fullWidth: Bool = false,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.fullWidth = fullWidth
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    private var backgroundColor: Color {
        guard isEnabled else { return AppColors.surfaceAlt }
        switch style {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.surface
        case .destructive:
            return AppColors.danger
        case .subtle:
            return AppColors.surfaceAlt
        case .outline:
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        guard isEnabled else { return AppColors.textMuted }
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .subtle:
            return AppColors.text
        case .outline:
            return AppColors.primary
        }
    }

    private var borderColor: Color? {
        switch style {
        case .outline:
            return AppColors.border
        default:
            return nil
        }
    }

    var body: some View {
        Button(action: isEnabled && !isLoading ? action : {}) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
            .frame(height: AppSizes.buttonHeightDefault)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.eight)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.eight)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        AppButton("Primary Button", style: .primary) {}
        AppButton("Secondary Button", style: .secondary) {}
        AppButton("Destructive Button", style: .destructive) {}
        AppButton("Subtle Button", style: .subtle) {}
        AppButton("Outline Button", style: .outline) {}
        AppButton("Disabled Button", isEnabled: false) {}
        AppButton("Loading Button", isLoading: true) {}
    }
    .padding()
    .background(AppColors.background)
}


