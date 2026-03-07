//
//  FullscreenWebView.swift
//  AppleTVBrowser
//
//  Echte WebView-Darstellung für Webseiten auf tvOS
//  Verwendet die private UIWebView API via NSClassFromString("UIWebView")
//  analog zum Referenzprojekt von Steven Troughton-Smith / Jip van Akker
//

import SwiftUI

// MARK: - Wrapper für SessionManager Integration (wird von MainBrowserView verwendet)

struct FullscreenWebViewWithSession: View {
    let url: String
    let sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    @State private var webURL: URL?
    @State private var loadError: Bool = false
    
    /// Wechselt den View-Modus zwischen Scroll und Cursor
    private func toggleViewMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch sessionManager.preferences.viewMode {
            case .scrollView:
                sessionManager.preferences.viewMode = .cursorView
            case .cursorView:
                sessionManager.preferences.viewMode = .scrollView
            }
            sessionManager.savePreferences()
        }
        print("🔄 View-Modus gewechselt zu: \(sessionManager.preferences.viewMode.displayName)")
    }
    
    var body: some View {
        Group {
            if loadError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    Text("Ungültige URL")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Zurück") {
                        isPresented = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                // ENTSCHEIDEND: Hier wird jetzt der viewMode ausgewertet!
                switch sessionManager.preferences.viewMode {
                case .cursorView:
                    CursorModeWebView(
                        url: $webURL,
                        preferences: sessionManager.preferences,
                        onNavigationAction: { _ in true },
                        onBack: {
                            isPresented = false
                        },
                        onPlayPause: {
                            toggleViewMode()
                        },
                        onShowSettings: {
                            toggleViewMode()
                        }
                    )
                case .scrollView:
                    ScrollModeWebView(
                        url: $webURL,
                        preferences: sessionManager.preferences,
                        onNavigationAction: { _ in true },
                        onBack: {
                            isPresented = false
                        },
                        onPlayPause: {
                            toggleViewMode()
                        }
                    )
                }
            }
        }
        .onAppear {
            if let parsed = URL(string: url) {
                webURL = parsed
                sessionManager.createSession(url: url)
            } else {
                loadError = true
            }
        }
        .onDisappear {
            sessionManager.updateSession(url: webURL?.absoluteString, scrollPosition: 0)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Legacy Compatibility (für andere Stellen die FullscreenWebView referenzieren)

struct FullscreenWebView: View {
    let url: String
    @Binding var isPresented: Bool
    
    @State private var webURL: URL?
    @State private var loadError: Bool = false
    
    var body: some View {
        Group {
            if loadError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    Text("Ungültige URL")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Zurück") {
                        isPresented = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                CursorModeWebView(
                    url: $webURL,
                    preferences: BrowserPreferences(),
                    onNavigationAction: { _ in true },
                    onBack: {
                        isPresented = false
                    },
                    onPlayPause: { },
                    onShowSettings: { }
                )
            }
        }
        .onAppear {
            if let parsed = URL(string: url) {
                webURL = parsed
            } else {
                loadError = true
            }
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
