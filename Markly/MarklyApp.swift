//
//  MarklyApp.swift
//  Markly
//

import SwiftUI
import SwiftData

@main
struct MarklyApp: App {
    @UIApplicationDelegateAdaptor(MarklyNotificationDelegate.self) private var notificationDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

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
            WordDictionary.self,
            DictionaryWord.self,
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
                .onOpenURL { url in
                    appState.handleReportConversationURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: MarklyReportConversationNotificationManager.conversationNotificationOpened
                )) { notification in
                    guard let reportID = notification.object as? String else { return }
                    appState.handleReportConversationID(reportID)
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await MarklyReportConversationNotificationManager.scanForNewMessages() }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
