//
//  AppleTVBrowserApp.swift
//  AppleTVBrowser
//

import SwiftUI
import SwiftData

@main
struct AppleTVBrowserApp: App {
    @State private var controlManager = TVOSControlManager.shared
    
    init() {
        // Setze globale UIKit Erscheinung FRÜH beim App-Start
        configureGlobalAppearance()
    }
    
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
                .tint(.white)  // Neutrale Tint-Farbe für tvOS Tastatur etc.
                .accentColor(.white)  // System-Akzentfarbe auf Weiß
                .preferredColorScheme(.dark)  // Dunkles tvOS Theme
                .tvOSRemoteOptimized()
                .onAppear {
                    TVOSInputConfiguration.configure()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Konfiguriert die globale Erscheinung für alle UIKit-Elemente
    private func configureGlobalAppearance() {
        // Alle UIKit-Elemente auf Weiß setzen
        UIView.appearance().tintColor = .white
        UITextField.appearance().tintColor = .white
        UITextView.appearance().tintColor = .white
        UIActivityIndicatorView.appearance().color = .white
        UINavigationBar.appearance().tintColor = .white
        UITabBar.appearance().tintColor = .white
        UISearchBar.appearance().tintColor = .white
        
        // Für alle Windows
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.tintColor = .white }
        }
    }
}
