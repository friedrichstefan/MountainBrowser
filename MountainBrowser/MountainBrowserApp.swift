//
//  MountainBrowserApp.swift
//  MountainBrowser
//

import SwiftUI
import SwiftData

@main
struct MountainBrowserApp: App {
    @State private var controlManager = TVOSControlManager.shared
    
    // FIX: Tracking ob die App im Vordergrund ist
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Setze globale UIKit Erscheinung FRÜH beim App-Start
        configureGlobalAppearance()
    }
    
    // FIX: CloudKit-Sync DEAKTIVIERT — das war der Hauptgrund,
    // warum der Apple TV sich selbst aufgeweckt hat!
    // iCloud-Push-Notifications wecken die App im Hintergrund auf,
    // die App aktiviert den Apple TV, und der schaltet per HDMI-CEC den Fernseher ein.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            BookmarkFolder.self,
            HistoryEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            // ❌ VORHER: cloudKitDatabase: .automatic
            // ✅ FIX: CloudKit DEAKTIVIERT — verhindert Hintergrund-Aufwecken
            cloudKitDatabase: .none
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
                .tint(.white)
                .accentColor(.white)
                .preferredColorScheme(.dark)
                .tvOSRemoteOptimized()
                .onAppear {
                    TVOSInputConfiguration.configure()
                }
        }
        .modelContainer(sharedModelContainer)
        // FIX: Reagiere auf scenePhase-Änderungen, um Ressourcen freizugeben
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    /// FIX: Beim Wechsel in den Hintergrund alle Timer und Ressourcen stoppen
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            NotificationCenter.default.post(
                name: NSNotification.Name("StopAllTimers"),
                object: nil
            )
        case .active:
            break
        case .inactive:
            NotificationCenter.default.post(
                name: NSNotification.Name("StopAllTimers"),
                object: nil
            )
        @unknown default:
            break
        }
    }
    
    /// Konfiguriert die globale Erscheinung für alle UIKit-Elemente
    private func configureGlobalAppearance() {
        UIView.appearance().tintColor = .white
        UITextField.appearance().tintColor = .white
        UITextView.appearance().tintColor = .white
        UIActivityIndicatorView.appearance().color = .white
        UINavigationBar.appearance().tintColor = .white
        UITabBar.appearance().tintColor = .white
        UISearchBar.appearance().tintColor = .white
        
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.tintColor = .white }
        }
    }
}
