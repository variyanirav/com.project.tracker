//
//  AppIcons.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import SwiftUI

/// Central enumeration for all SF Symbol icons used throughout the app
enum AppIcons {
    // MARK: - Navigation
    static let dashboard = "square.grid.2x2"
    static let projects = "rectangle.on.rectangle"
    static let reports = "chart.bar"
    static let settings = "gear"
    
    // MARK: - Actions
    static let plus = "plus"
    static let minus = "minus"
    static let close = "xmark"
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let more = "ellipsis"
    
    // MARK: - Timer/Time
    static let play = "play.fill"
    static let pause = "pause.fill"
    static let stop = "stop.fill"
    static let timer = "timer"
    static let clock = "clock"
    static let history = "clock.arrow.circlepath"
    
    // MARK: - Project/Task
    static let project = "briefcase"
    static let task = "checkmark.square"
    static let taskCompleted = "checkmark.circle.fill"
    static let taskPending = "circle"
    
    // MARK: - Status
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle"
    static let xmark = "xmark"
    static let xmarkCircle = "xmark.circle"
    static let warning = "exclamationmark.triangle"
    static let info = "info.circle"
    
    // MARK: - Export/Share
    static let export = "arrow.up.doc"
    static let download = "arrow.down.doc"
    static let share = "square.and.arrow.up"
    static let document = "doc"
    static let documentText = "doc.text"
    
    // MARK: - User
    static let user = "person"
    static let userCircle = "person.circle"
    static let users = "person.2"
    static let profile = "person.crop.square"
    
    // MARK: - UI
    static let chevronRight = "chevron.right"
    static let chevronDown = "chevron.down"
    static let magnifyingGlass = "magnifyingglass"
    static let bell = "bell"
    static let bellDot = "bell.badge"
    
    // MARK: - Utilities
    static let trash = "trash"
    static let edit = "pencil"
    static let copy = "doc.on.doc"
    static let link = "link"
    
    // Helper function to get an icon as an Image
    static func image(_ icon: String, size: CGFloat = 24) -> some View {
        Image(systemName: icon)
            .font(.system(size: size))
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Navigation Icons").font(.headline)
                HStack(spacing: 12) {
                    Image(systemName: AppIcons.dashboard)
                    Image(systemName: AppIcons.projects)
                    Image(systemName: AppIcons.reports)
                    Image(systemName: AppIcons.settings)
                }
            }
            
            Group {
                Text("Timer Icons").font(.headline)
                HStack(spacing: 12) {
                    Image(systemName: AppIcons.play)
                    Image(systemName: AppIcons.pause)
                    Image(systemName: AppIcons.stop)
                    Image(systemName: AppIcons.timer)
                }
            }
            
            Group {
                Text("Status Icons").font(.headline)
                HStack(spacing: 12) {
                    Image(systemName: AppIcons.checkmark)
                    Image(systemName: AppIcons.xmark)
                    Image(systemName: AppIcons.warning)
                    Image(systemName: AppIcons.info)
                }
            }
        }
        .padding()
        .font(.system(size: 20))
    }
    .background(AppColors.background)
}
