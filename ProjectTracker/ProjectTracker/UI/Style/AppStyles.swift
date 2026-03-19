//
//  AppStyles.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//
//
//  DesignTokensDark.swift
//
//  This file contains the central design tokens for the dark theme,
//  including colors, spacing, radius, and shadow styles.
//  It enforces DRY principles across components by providing a single source of truth.
//

import SwiftUI

enum AppColors {
    // MARK: - Neutral Colors (Background/Surface)
    static let background = Color(#colorLiteral(red: 0.1215686275, green: 0.1215686275, blue: 0.1215686275, alpha: 1)) // #1F1F1F
    static let surface = Color(#colorLiteral(red: 0.1725490196, green: 0.1725490196, blue: 0.1725490196, alpha: 1)) // #2B2B2B
    static let surfaceAlt = Color(#colorLiteral(red: 0.2431372549, green: 0.2431372549, blue: 0.2431372549, alpha: 1)) // #3E3E3E
    static let border = Color(#colorLiteral(red: 0.3176470588, green: 0.3176470588, blue: 0.3176470588, alpha: 1)) // #515151
    
    // MARK: - Text Colors
    static let text = Color(#colorLiteral(red: 0.9333333333, green: 0.9333333333, blue: 0.9333333333, alpha: 1)) // #EE E8E8
    static let textMuted = Color(#colorLiteral(red: 0.6156862745, green: 0.6156862745, blue: 0.6156862745, alpha: 1)) // #9D9D9D
    
    // MARK: - Semantic Colors
    static let primary = Color(#colorLiteral(red: 0.0, green: 0.4784313725, blue: 1.0, alpha: 1)) // #0078D4 (Microsoft Blue)
    static let accent = primary // Alias for primary
    static let success = Color(#colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)) // #4CAF50
    static let warning = Color(#colorLiteral(red: 1.0, green: 0.6470588235, blue: 0.0, alpha: 1)) // #FFA500
    static let danger = Color(#colorLiteral(red: 0.9019607843, green: 0.2980392157, blue: 0.2352941176, alpha: 1)) // #E64929
    
    // MARK: - Component-Specific Colors
    static let cardBackground = surface
    static let buttonBackground = primary
    static let buttonForeground = Color.white
    static let secondaryButtonForeground = text
    
    // MARK: - State-based Colors
    static let inProgress = primary
    static let completed = success
    static let paused = warning
    static let failed = danger
}

enum AppRadius {
    static let large: CGFloat = 16
    static let twelve: CGFloat = 12
    static let eight: CGFloat = 8
    static let four: CGFloat = 4
    static let small: CGFloat = 6
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum AppSizes {
    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconDefault: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let iconXL: CGFloat = 48
    
    // MARK: - Button Sizes
    static let buttonHeightSmall: CGFloat = 32
    static let buttonHeightDefault: CGFloat = 44
    static let buttonHeightLarge: CGFloat = 56
    
    // MARK: - Component Sizes
    static let avatarSmall: CGFloat = 32
    static let avatarDefault: CGFloat = 44
    static let avatarLarge: CGFloat = 64
    
    // MARK: - Card Sizes
    static let cardMinHeight: CGFloat = 80
    
    // MARK: - Touch Target (Apple Human Interface Guidelines)
    static let minimumTouchTarget: CGFloat = 44
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(color: Color = Color.black, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

enum AppShadow {
    static let subtle = ShadowStyle(color: Color.black.opacity(0.15), radius: 4, y: 2)
    static let normal = ShadowStyle(color: Color.black.opacity(0.25), radius: 8, y: 4)
    static let elevated = ShadowStyle(color: Color.black.opacity(0.35), radius: 12, y: 6)
}

// MARK: - Animations
enum AppAnimations {
    static let fast = Animation.easeInOut(duration: 0.15)
    static let normal = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
}
