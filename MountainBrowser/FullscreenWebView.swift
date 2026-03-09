//
//  FullscreenWebView.swift
//  MountainBrowser
//
//  WebView mit ViewMode-Umschaltung: Scroll-Modus oder Cursor-Modus
//

import SwiftUI

// MARK: - Wrapper für SessionManager Integration (wird von MainBrowserView verwendet)

struct FullscreenWebViewWithSession: View {
    let url: String
    @ObservedObject var sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    @State private var currentURL: URL?
    @State private var showPaywall: Bool = false
    
    var body: some View {
        Group {
            switch sessionManager.preferences.viewMode {
            case .scrollView:
                ScrollModeWebView(
                    url: $currentURL,
                    preferences: sessionManager.preferences,
                    onNavigationAction: { _ in true },
                    onBack: { isPresented = false },
                    onPlayPause: { attemptToggleViewMode() }
                )
                
            case .cursorView:
                // Doppelte Absicherung: Falls der Modus irgendwie ohne Premium gesetzt wurde,
                // sofort zurück zum Scroll-Modus wechseln
                if PremiumManager.shared.canUseCursorMode {
                    CursorModeWebView(
                        url: $currentURL,
                        preferences: sessionManager.preferences,
                        onNavigationAction: { _ in true },
                        onBack: { isPresented = false },
                        onPlayPause: { attemptToggleViewMode() },
                        onShowSettings: { attemptToggleViewMode() }
                    )
                } else {
                    ScrollModeWebView(
                        url: $currentURL,
                        preferences: sessionManager.preferences,
                        onNavigationAction: { _ in true },
                        onBack: { isPresented = false },
                        onPlayPause: { attemptToggleViewMode() }
                    )
                    .onAppear {
                        // Korrigiere den ungültigen Zustand
                        sessionManager.preferences.viewMode = .scrollView
                        sessionManager.savePreferences()
                    }
                }
            }
        }
        .onAppear {
            currentURL = URL(string: url)
            sessionManager.createSession(url: url)
            
            // Beim Erscheinen prüfen: Falls cursorView gesetzt ist aber kein Premium, zurücksetzen
            if sessionManager.preferences.viewMode == .cursorView && !PremiumManager.shared.canUseCursorMode {
                sessionManager.preferences.viewMode = .scrollView
                sessionManager.savePreferences()
            }
        }
        .onDisappear {
            sessionManager.updateSession(url: url, scrollPosition: 0)
        }
        .ignoresSafeArea(.all)
        .overlay {
            if showPaywall {
                PremiumPaywallView(
                    feature: .cursorMode,
                    isPresented: $showPaywall
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }
    
    // MARK: - ViewMode Toggle mit Premium-Prüfung
    
    private func attemptToggleViewMode() {
        let premiumManager = PremiumManager.shared
        
        switch sessionManager.preferences.viewMode {
        case .scrollView:
            // Wechsel zu Cursor: Premium erforderlich
            if premiumManager.canUseCursorMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    sessionManager.preferences.viewMode = .cursorView
                    sessionManager.savePreferences()
                }
            } else {
                // Paywall anzeigen
                showPaywall = true
            }
            
        case .cursorView:
            // Wechsel zurück zu Scroll: Immer erlaubt
            withAnimation(.easeInOut(duration: 0.3)) {
                sessionManager.preferences.viewMode = .scrollView
                sessionManager.savePreferences()
            }
        }
    }
}

// MARK: - Legacy Compatibility (für andere Stellen die FullscreenWebView referenzieren)

struct FullscreenWebView: View {
    let url: String
    @Binding var isPresented: Bool
    
    @State private var currentURL: URL?
    
    var body: some View {
        ScrollModeWebView(
            url: $currentURL,
            preferences: BrowserPreferences(),
            onNavigationAction: { _ in true },
            onBack: { isPresented = false }
        )
        .onAppear {
            currentURL = URL(string: url)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Preview

#Preview {
    FullscreenWebView(
        url: "https://www.google.com",
        isPresented: .constant(true)
    )
}
