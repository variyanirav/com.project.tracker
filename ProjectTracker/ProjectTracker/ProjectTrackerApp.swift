//
//  ProjectTrackerApp.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import SwiftUI
import CoreData

@main
struct ProjectTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var projectManager = ProjectManager.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(timerManager)
                .environmentObject(projectManager)
        }
    }
}

