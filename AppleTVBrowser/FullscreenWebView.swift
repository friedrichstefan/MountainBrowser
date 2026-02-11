//
//  FullscreenWebView.swift
//  AppleTVBrowser
//
//  Vollbild-WebView mit echtem UIWebView und Cursor-Steuerung
//

import SwiftUI

struct FullscreenWebView: View {
    let url: String
    let title: String
    @Binding var isPresented: Bool
    
    @StateObject private var webViewController = TVOSWebViewController()
    @StateObject private var cursorManager = CursorManager()
    @State private var autoScrollTimer: Timer?
    @State private var showNavigationBar: Bool = true
    @FocusState private var webViewFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Echter UIWebView via Wrapper - PRIMÄRER FOKUS
                TVOSWebViewWrapper(
                    urlString: $webViewController.urlString,
                    isLoading: $webViewController.isLoading,
                    canGoBack: $webViewController.canGoBack,
                    canGoForward: $webViewController.canGoForward,
                    pageTitle: $webViewController.pageTitle,
                    onNavigationChange: { newURL in
                        print("📍 Navigiert zu: \(newURL)")
                    },
                    onPan: { translation in
                        handlePan(translation: translation)
                    },
                    onTap: {
                        handleTap()
                    },
                    onDoubleTap: {
                        handleDoubleTap()
                    },
                    webViewController: webViewController
                )
                .ignoresSafeArea()
                .focusable(true)
                .focused($webViewFocused)
                
                // Loading Indicator
                if webViewController.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        Text("Lädt...")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .allowsHitTesting(false)
                }
                
                // Cursor- und Scroll-Anzeigen (stabilisiert)
                CursorView(
                    position: $cursorManager.position,
                    state: $cursorManager.state,
                    mode: $cursorManager.mode,
                    isVisible: $cursorManager.isVisible,
                    isClicked: $cursorManager.isClicked
                )
                .opacity(cursorManager.mode == .navigation ? 1 : 0)
                .onChange(of: cursorManager.edgePosition) { _, newEdge in
                    handleEdgeChange(newEdge)
                }
                .allowsHitTesting(false)

                scrollIndicator
                    .opacity(cursorManager.mode == .scroll ? 1 : 0)
                    .allowsHitTesting(false)
                
                // Top Navigation Bar (nicht fokussierbar)
                if showNavigationBar {
                    topNavigationBar
                        .allowsHitTesting(false) // Keine Interaktion über Touch
                }
            }
            .onAppear {
                webViewController.urlString = url
                cursorManager.screenBounds = geometry.frame(in: .global)
                cursorManager.setCursorPosition(CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                webViewFocused = true // Fokus auf WebView setzen
            }
            .onDisappear {
                stopAutoScroll()
            }
            // Menu-Taste zum Verlassen
            .onExitCommand {
                isPresented = false
            }
            // Play/Pause-Taste für Moduswechsel
            .onPlayPauseCommand {
                print("⏯️ Play/Pause gedrückt -> Moduswechsel")
                toggleMode()
            }
        }
    }
    
    // MARK: - Scroll Indicator (nicht interaktiv)
    
    private var scrollIndicator: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.up")
                .font(.system(size: 24, weight: .bold))
            Text("SCROLL")
                .font(.system(size: 14, weight: .bold))
            Image(systemName: "arrow.down")
                .font(.system(size: 24, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.purple.opacity(0.6))
        )
        .position(x: cursorManager.screenBounds.width - 80, y: cursorManager.screenBounds.height / 2)
    }

    // MARK: - Top Navigation (nicht fokussierbar - nur Anzeige)
    
    private var topNavigationBar: some View {
        VStack {
            HStack(spacing: 20) {
                // Zurück-Anzeige (Menu drücken)
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Menu: Zurück")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.15)))
                
                // Titel / URL
                VStack(alignment: .leading, spacing: 4) {
                    if !webViewController.pageTitle.isEmpty {
                        Text(webViewController.pageTitle)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Text(webViewController.urlString)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mode-Anzeige
                HStack(spacing: 8) {
                    Image(systemName: cursorManager.mode == .navigation ? "cursorarrow.rays" : "arrow.up.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                    Text(cursorManager.mode == .navigation ? "Cursor" : "Scroll")
                        .font(.system(size: 16, weight: .medium))
                    Text("(⏯ wechseln)")
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(cursorManager.mode == .navigation ? Color.blue.opacity(0.5) : Color.purple.opacity(0.5))
                )
                
                // Status-Anzeige
                HStack(spacing: 10) {
                    if webViewController.canGoBack {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    if webViewController.canGoForward {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .font(.system(size: 20))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.85),
                        Color.black.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            )
            
            Spacer()
        }
    }
    
    // MARK: - Gesture Handling & Scrolling

    private func handlePan(translation: CGPoint) {
        if cursorManager.mode == .navigation {
            cursorManager.move(by: translation)
        } else {
            let scrollSensitivity: CGFloat = 2.5
            webViewController.scroll(by: translation.y * scrollSensitivity)
        }
    }

    private func handleTap() {
        print("🖱️ ===== handleTap() in FullscreenWebView AUFGERUFEN =====")
        print("🖱️ Aktueller Mode: \(cursorManager.mode)")
        print("🖱️ Cursor Position: \(cursorManager.position)")
        print("🖱️ Cursor sichtbar: \(cursorManager.isVisible)")
        
        guard cursorManager.mode == .navigation else {
            print("🖱️ ABGEBROCHEN: Nicht im navigation mode")
            return
        }
        
        print("🖱️ ✅ Führe Klick aus bei Position: \(cursorManager.position)")
        webViewController.clickAtPoint(cursorManager.position)
        
        print("🖱️ Rufe performClick() am CursorManager auf...")
        cursorManager.performClick()
        print("🖱️ ===== handleTap() BEENDET =====")
    }

    private func handleDoubleTap() {
        print("🖱️🖱️ Double Tap -> toggleMode()")
        toggleMode()
    }
    
    private func handleEdgeChange(_ edge: EdgePosition) {
        switch edge {
        case .top:
            startAutoScroll(direction: -1)
        case .bottom:
            startAutoScroll(direction: 1)
        case .none:
            stopAutoScroll()
        }
    }

    private func startAutoScroll(direction: Int) {
        guard autoScrollTimer == nil else { return }
        let scrollSpeed: CGFloat = 15.0
        let controller = webViewController
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            controller.scroll(by: CGFloat(direction) * scrollSpeed)
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    // MARK: - Actions
    
    private func toggleMode() {
        let previousMode = cursorManager.mode
        cursorManager.toggleMode()

        // Stoppe Auto-Scroll, wenn in den Cursor-Modus gewechselt wird
        if cursorManager.mode == .navigation {
            stopAutoScroll()
        }
        
        print("🔄 Mode: \(previousMode) -> \(cursorManager.mode)")
    }
}

// MARK: - View Bounds Preference Key

struct ViewBoundsKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    FullscreenWebView(
        url: "https://www.apple.com",
        title: "Apple",
        isPresented: .constant(true)
    )
}