//
//  TVOSScrollIndicator.swift
//  MountainBrowser
//
//  Visueller Scroll-Indikator für tvOS WebView-Navigation
//

import SwiftUI
import Combine

struct TVOSScrollIndicator: View {
    let scrollPosition: Double     // 0.0 - 1.0 (0% - 100%)
    let contentHeight: Double      // Gesamthöhe des Contents
    let viewportHeight: Double     // Sichtbare Höhe
    let isScrolling: Bool          // Zeigt an, ob gerade gescrollt wird
    
    @State private var isVisible: Bool = false
    @State private var autoHideTask: Task<Void, Never>?
    
    private var indicatorHeight: CGFloat {
        guard contentHeight > viewportHeight else { return 0 }
        let ratio = viewportHeight / contentHeight
        return max(40, CGFloat(ratio) * 400) // Min 40pt, max abhängig vom Verhältnis
    }
    
    private var indicatorPosition: CGFloat {
        guard contentHeight > viewportHeight else { return 0 }
        let maxOffset = 400 - indicatorHeight // Verfügbarer Raum für Bewegung
        return CGFloat(scrollPosition) * maxOffset
    }
    
    private var scrollPercentage: Int {
        Int(scrollPosition * 100)
    }
    
    var body: some View {
        if contentHeight > viewportHeight {
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Scroll-Prozentanzeige
                    Text("\(scrollPercentage)%")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .opacity(isVisible ? 1.0 : 0.0)
                    
                    // Scroll-Track
                    ZStack(alignment: .top) {
                        // Hintergrund-Track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 12, height: 400)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        // Scroll-Indikator
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: indicatorHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                            )
                            .offset(y: indicatorPosition)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                    .opacity(isVisible ? 1.0 : 0.0)
                }
                .padding(.trailing, 20)
                .padding(.vertical, 40)
            }
            .animation(.easeInOut(duration: 0.3), value: isVisible)
            .onChange(of: isScrolling) { _, newValue in
                if newValue {
                    showIndicator()
                } else {
                    scheduleAutoHide()
                }
            }
            .onAppear {
                if isScrolling {
                    showIndicator()
                }
            }
            // FIX: Task aufräumen wenn View verschwindet
            .onDisappear {
                autoHideTask?.cancel()
                autoHideTask = nil
            }
        }
    }
    
    private func showIndicator() {
        autoHideTask?.cancel()
        autoHideTask = nil
        isVisible = true
    }
    
    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = false
            }
        }
    }
}

// MARK: - ScrollPosition Manager für WebView

@MainActor
class WebViewScrollTracker: ObservableObject {
    @Published var scrollPosition: Double = 0.0
    @Published var contentHeight: Double = 0.0
    @Published var viewportHeight: Double = 0.0
    @Published var isScrolling: Bool = false
    
    private var scrollHideTask: Task<Void, Never>?
    
    // FIX: Observer für StopAllTimers
    private var stopTimersObserver: NSObjectProtocol?
    
    init() {
        // FIX: Auf StopAllTimers reagieren
        stopTimersObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StopAllTimers"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.scrollHideTask?.cancel()
                self?.scrollHideTask = nil
                self?.isScrolling = false
            }
        }
    }
    
    func updateScrollPosition(_ position: Double, contentHeight: Double, viewportHeight: Double) {
        // Scroll-Position normalisieren (0.0 - 1.0)
        let maxScroll = max(0, contentHeight - viewportHeight)
        let normalizedPosition = maxScroll > 0 ? min(1.0, max(0.0, position / maxScroll)) : 0.0
        
        self.scrollPosition = normalizedPosition
        self.contentHeight = contentHeight
        self.viewportHeight = viewportHeight
        
        // Scrolling-Status setzen
        setScrolling(true)
        
        // Auto-hide nach Scroll-Ende
        scrollHideTask?.cancel()
        scrollHideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            self?.setScrolling(false)
        }
    }
    
    private func setScrolling(_ scrolling: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isScrolling = scrolling
        }
    }
    
    deinit {
        // FIX: Observer entfernen
        if let observer = stopTimersObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        scrollHideTask?.cancel()
    }
}

// MARK: - JavaScript für WebView Scroll-Tracking

extension WebViewScrollTracker {
    
    static let scrollTrackingJavaScript: String = """
        (function() {
            console.log('🔧 Scroll-Tracking JavaScript wird initialisiert...');
            
            let lastScrollY = window.pageYOffset || document.documentElement.scrollTop;
            let scrollTimeout;
            
            function updateScrollPosition() {
                const scrollY = window.pageYOffset || document.documentElement.scrollTop;
                const contentHeight = document.documentElement.scrollHeight;
                const viewportHeight = window.innerHeight;
                
                // An Swift senden
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.scrollTracker) {
                    window.webkit.messageHandlers.scrollTracker.postMessage({
                        scrollY: scrollY,
                        contentHeight: contentHeight,
                        viewportHeight: viewportHeight
                    });
                }
                
                // Fallback für UIWebView
                if (typeof window.updateScrollTracker === 'function') {
                    window.updateScrollTracker(scrollY, contentHeight, viewportHeight);
                }
                
                lastScrollY = scrollY;
            }
            
            // Scroll-Events abonnieren
            let isScrolling = false;
            window.addEventListener('scroll', function() {
                if (!isScrolling) {
                    window.requestAnimationFrame(function() {
                        updateScrollPosition();
                        isScrolling = false;
                    });
                    isScrolling = true;
                }
            }, { passive: true });
            
            // Resize-Events für Viewport-Änderungen
            window.addEventListener('resize', function() {
                clearTimeout(scrollTimeout);
                scrollTimeout = setTimeout(updateScrollPosition, 100);
            }, { passive: true });
            
            // Initiale Position senden
            setTimeout(updateScrollPosition, 100);
            
            console.log('✅ Scroll-Tracking JavaScript aktiviert');
            return 'scroll_tracking_initialized';
        })();
    """
    
    static let scrollUpdateJavaScript: String = """
        if (typeof window.updateScrollTracker !== 'function') {
            window.updateScrollTracker = function(scrollY, contentHeight, viewportHeight) {
                // Diese Funktion wird von Swift aus aufgerufen
                console.log('📊 Scroll-Position Update:', scrollY, 'von', contentHeight);
            };
        }
    """
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TVOSScrollIndicator(
            scrollPosition: 0.3,
            contentHeight: 2000,
            viewportHeight: 800,
            isScrolling: true
        )
    }
}
