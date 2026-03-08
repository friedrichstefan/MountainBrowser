//
//  FullscreenWebView.swift
//  MountainBrowser
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
        let oldMode = sessionManager.preferences.viewMode
        switch sessionManager.preferences.viewMode {
        case .scrollView:
            sessionManager.preferences.viewMode = .cursorView
        case .cursorView:
            sessionManager.preferences.viewMode = .scrollView
        }
        sessionManager.savePreferences()
        print("🔄 View-Modus gewechselt zu: \(sessionManager.preferences.viewMode.displayName)")
    }
    
    var body: some View {
        Group {
            if loadError {
                ZStack {
                    // Glassmorphic Background
                    GlassmorphicBackground()
                    
                    VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                        // Fehler-Icon mit Glow
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [TVOSDesign.Colors.systemOrange, TVOSDesign.Colors.systemYellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: TVOSDesign.Colors.systemOrange.opacity(0.4), radius: 20, y: 8)
                        
                        VStack(spacing: 12) {
                            Text("Ungültige URL")
                                .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                            
                            Text("Die angegebene Webadresse konnte nicht geladen werden.")
                                .font(.system(size: TVOSDesign.Typography.body))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                .multilineTextAlignment(.center)
                            
                            // URL-Anzeige
                            Text(url)
                                .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium, design: .monospaced))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(TVOSDesign.Colors.cardBackground)
                                )
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 600)
                        
                        // Zurück-Button mit TVOSDesign
                        TVOSButton(title: "Zurück", icon: "arrow.left.circle.fill", style: .secondary) {
                            isPresented = false
                        }
                        .padding(.top, TVOSDesign.Spacing.elementSpacing)
                    }
                }
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
                ZStack {
                    // Glassmorphic Background
                    GlassmorphicBackground()
                    
                    VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                        // Fehler-Icon mit Glow
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [TVOSDesign.Colors.systemOrange, TVOSDesign.Colors.systemYellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: TVOSDesign.Colors.systemOrange.opacity(0.4), radius: 20, y: 8)
                        
                        VStack(spacing: 12) {
                            Text("Ungültige URL")
                                .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                            
                            Text("Die angegebene Webadresse konnte nicht geladen werden.")
                                .font(.system(size: TVOSDesign.Typography.body))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                .multilineTextAlignment(.center)
                            
                            // URL-Anzeige
                            Text(url)
                                .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium, design: .monospaced))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(TVOSDesign.Colors.cardBackground)
                                )
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 600)
                        
                        // Zurück-Button mit TVOSDesign
                        TVOSButton(title: "Zurück", icon: "arrow.left.circle.fill", style: .secondary) {
                            isPresented = false
                        }
                        .padding(.top, TVOSDesign.Spacing.elementSpacing)
                    }
                }
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
