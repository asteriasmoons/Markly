//
//  MarklyApp.swift
//  Markly
//

import SwiftUI
import SwiftData

@main
struct MarklyApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BookmarkItem.self,
            BookmarkNote.self,
            BookmarkFolder.self,
            PinCollection.self,
            MarklyActivity.self,
            AuthUser.self,
            UserSettings.self,
            SubmittedReport.self,
            SubmittedReportAttachment.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
