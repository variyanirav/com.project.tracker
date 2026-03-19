//
//  App​Typography​.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

struct AppTypography {
    // MARK: - Display Styles (Large, attention-grabbing)
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(AppColors.text)
    }
    
    static func title2(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .semibold, design: .default))
            .foregroundColor(AppColors.text)
    }
    
    static func subtitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(AppColors.textMuted)
    }
    
    // MARK: - Headline/Label Styles
    static func headline(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold, design: .default))
            .foregroundColor(AppColors.text)
    }
    
    static func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .default))
            .textCase(.uppercase)
            .foregroundColor(AppColors.textMuted)
    }
    
    // MARK: - Body Text Styles
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(AppColors.text)
    }
    
    static func bodyMuted(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(AppColors.textMuted)
    }
    
    // MARK: - Numeric/Stat Styles (Monospaced for alignment)
    static func stat(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(AppColors.primary)
    }
    
    static func statSmall(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundColor(AppColors.primary)
    }
    
    // MARK: - Caption/Small Text
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(AppColors.textMuted)
    }
    
    static func captionStrong(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundColor(AppColors.text)
    }
}

struct AppTypography_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AppTypography.label("Display")
                AppTypography.title("Title Text")
                AppTypography.title2("Title2 Text")
                AppTypography.subtitle("Subtitle Text")
                
                AppTypography.label("Headlines")
                AppTypography.headline("Headline Text")
                AppTypography.label("Labels")
                AppTypography.label("Label Text")
                
                AppTypography.label("Body")
                AppTypography.body("Body Text")
                AppTypography.bodyMuted("Muted Body Text")
                
                AppTypography.label("Statistics")
                AppTypography.stat("99h 45m")
                AppTypography.statSmall("5h 30m")
                
                AppTypography.label("Small")
                AppTypography.caption("Caption Text")
                AppTypography.captionStrong("Strong Caption")
            }
            .padding()
        }
        .background(AppColors.background)
    }
}
