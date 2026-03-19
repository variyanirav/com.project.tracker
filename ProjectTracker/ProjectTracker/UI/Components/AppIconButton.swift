//
//  AppIconButton.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct AppIconButton: View {
    let systemName: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(selected ? AppColors.primary : AppColors.textMuted)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.twelve)
                        .fill(selected ? AppColors.primary.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.twelve)
                        .stroke(selected ? AppColors.primary.opacity(0.25) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        HStack(spacing: 20) {
            AppIconButton(systemName: "star.fill", selected: true) {}
            AppIconButton(systemName: "star", selected: false) {}
        }
        .padding()
    }
}
