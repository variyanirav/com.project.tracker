//
//  ContentView.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        DashboardView()
            .environmentObject(timerManager)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TimerManager.shared)
}
