//
//  AppleTVBrowserApp.swift
//  AppleTVBrowser
//

import SwiftUI
import SwiftData

@main
struct AppleTVBrowserApp: App {
    @State private var controlManager = TVOSControlManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            BookmarkFolder.self,
            HistoryEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Enable iCloud sync
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainBrowserView()
                .tvOSRemoteOptimized()
                .onAppear {
                    TVOSInputConfiguration.configure()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
