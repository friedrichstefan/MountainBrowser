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
    
    var body: some View {
        Group {
            switch sessionManager.preferences.viewMode {
            case .scrollView:
                ScrollModeWebView(
                    url: $currentURL,
                    preferences: sessionManager.preferences,
                    onNavigationAction: { _ in true },
                    onBack: { isPresented = false },
                    onPlayPause: { toggleViewMode() }
                )
                
            case .cursorView:
                CursorModeWebView(
                    url: $currentURL,
                    preferences: sessionManager.preferences,
                    onNavigationAction: { _ in true },
                    onBack: { isPresented = false },
                    onPlayPause: { toggleViewMode() },
                    onShowSettings: { }
                )
            }
        }
        .onAppear {
            currentURL = URL(string: url)
            sessionManager.createSession(url: url)
        }
        .onDisappear {
            sessionManager.updateSession(url: url, scrollPosition: 0)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - ViewMode Toggle
    
    private func toggleViewMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch sessionManager.preferences.viewMode {
            case .scrollView:
                sessionManager.preferences.viewMode = .cursorView
            case .cursorView:
                sessionManager.preferences.viewMode = .scrollView
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