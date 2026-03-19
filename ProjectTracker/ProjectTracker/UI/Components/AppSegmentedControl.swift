//
//  AppSegmentedControl.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct AppSegmentedControl: View {
    let items: [String]
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    selection = index
                } label: {
                    Text(items[index])
                        .foregroundColor(selection == index ? AppColors.text : AppColors.textMuted)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == index ? AppColors.surface.opacity(0.5) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.border)
                )
        )
    }
}

struct AppSegmentedControl_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var selected = 0
            var body: some View {
                AppSegmentedControl(items: ["First", "Second", "Third"], selection: $selected)
                    .padding()
                    .frame(maxWidth: 300)
            }
        }
        return PreviewWrapper()
            .preferredColorScheme(.dark)
    }
}
