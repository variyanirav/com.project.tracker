//
//  AppCard.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct AppCard<Content: View>: View {
    var padded: Bool = true
    var background: Color = AppColors.surface
    var borderColor: Color = AppColors.border.opacity(0.8)
    var cornerRadius: CGFloat = AppRadius.twelve
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .if(padded) { view in
                view.padding()
            }
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            AppCard {
                Text("Card with default padding")
            }
            AppCard(padded: false) {
                Text("Card without padding")
            }
        }
        .padding()
    }
}
