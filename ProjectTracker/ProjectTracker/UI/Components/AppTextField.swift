//
//  AppTextField.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import Foundation
import SwiftUI

struct AppTextField: View {
    @Binding var text: String
    var placeholder: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppRadius.twelve)
                    .fill(AppColors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.twelve)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .foregroundColor(AppColors.text)
    }
}

struct AppTextField_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var text = ""
            var body: some View {
                ZStack {
                    AppColors.background
                        .ignoresSafeArea()
                    AppTextField("Placeholder", text: $text)
                        .padding()
                }
            }
        }
        return PreviewWrapper()
            .preferredColorScheme(.dark)
    }
}
