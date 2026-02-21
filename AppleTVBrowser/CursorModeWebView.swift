//
//  CursorModeWebView.swift
//  AppleTVBrowser
//
//  Vollständige Cursor-Modus WebView mit Info-Header und Cursor-Navigation
//

import SwiftUI

struct CursorModeWebView: View {
    @Binding var url: URL?
    @State private var cursorManager = CursorPositionManager()
    @State private var isLoading: Bool = false
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var title: String = ""
    @State private var contentSize: CGSize = .zero
    @State private var webViewRef: UIView?
    @State private var lastLoadedURL: URL? = nil
    @State private var cursorUpdateTimer: Timer?
    @State private var pendingCursorPosition: CGPoint?
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onShowSettings: () -> Void
    
    // Computed Properties für Navigation Bar
    private var urlString: String {
        url?.absoluteString ?? ""
    }
    
    private var pageTitle: String {
        title.isEmpty ? "Laden..." : title
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                
                VStack(spacing: 0) {
                    navigationBar
                    
                    webViewWithCursor(geometry: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                cursorManager.updateScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                cursorManager.updateScreenSize(newSize)
            }
            .cursorGestureHandler(
                cursorPosition: $cursorManager.position,
                screenSize: geometry.size,
                onTap: {
                    print("🔥 GESTURE TAP erkannt!")
                    performCursorClick()
                },
                onMenuPress: {
                    onBack()
                },
                onPlayPause: {
                    onPlayPause()
                }
            )
            .overlay(
                CursorOverlay(
                    position: $cursorManager.position,
                    screenSize: geometry.size,
                    onTap: {
                        print("⚠️ CursorOverlay onTap - sollte nicht aufgerufen werden!")
                    }
                )
            )
        }
        .ignoresSafeArea(.all, edges: .all)
    }
    
    // MARK: - Navigation Bar (Nicht-interaktiv im Cursor-Modus)
    private var navigationBar: some View {
        // Hauptcontainer für alle Navigations-Elemente in der oberen Leiste
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button (Links) - NICHT-INTERAKTIV
            TVOSNavButton(
                icon: "chevron.left",
                label: "Zurück",
                isEnabled: false  // Nicht fokussierbar im Cursor-Modus
            ) {
                // Leer - wird nicht aufgerufen
            }
            
            // URL/Titel-Anzeige (Mittig, nimmt verfügbaren Platz ein) - NICHT-INTERAKTIV
            SafariURLBar(
                urlString: urlString,
                pageTitle: pageTitle,
                isCursorMode: true  // Spezielle nicht-interaktive Version
            )
            .frame(maxWidth: .infinity)
            
            // Navigations-Buttons (Rechts) - NICHT-INTERAKTIV
            HStack(spacing: 16) {
                // Browser Zurück-Button
                TVOSNavIconButton(
                    icon: "arrow.left",
                    isEnabled: false  // Nicht fokussierbar
                ) {
                    // Leer
                }
                
                // Browser Vorwärts-Button
                TVOSNavIconButton(
                    icon: "arrow.right",
                    isEnabled: false  // Nicht fokussierbar
                ) {
                    // Leer
                }
                
                // Reload/Stop Button
                TVOSNavIconButton(
                    icon: isLoading ? "xmark" : "arrow.clockwise",
                    isEnabled: false  // Nicht fokussierbar
                ) {
                    // Leer
                }
                
                // Cursor-Modus Badge statt Einstellungen-Button
                HStack(spacing: 8) {
                    Image(systemName: "cursorarrow.click.2")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Cursor Modus")
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        // BREITERES PADDING: Reduziert um schwarze Streifen an den Seiten zu eliminieren
        .padding(.horizontal, 20) // Reduziert von TVOSDesign.Spacing.safeAreaHorizontal
        .padding(.vertical, 28)    // Leicht erhöht für mehr Höhe
        .background(
            // VOLLBREITER HINTERGRUND: Erstreckt sich über den gesamten Bildschirm
            LinearGradient(
                gradient: Gradient(colors: [
                    // Oben: Nahezu opak (sehr dunkelgrau)
                    TVOSDesign.Colors.background.opacity(0.98),
                    // Mitte: Etwas transparenter
                    TVOSDesign.Colors.background.opacity(0.92),
                    // Unten: Komplett transparent (sanfter Übergang zur Webseite)
                    TVOSDesign.Colors.background.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // WICHTIG: Ignoriert Safe Areas komplett für vollständige Breite
            .ignoresSafeArea(.all) // Geändert von .ignoresSafeArea(.all, edges: .top)
        )
        // ZUSÄTZLICHER VOLLBREITER OVERLAY: Eliminiert definitiv schwarze Ränder
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(.all)
                .allowsHitTesting(false) // Verhindert Interaktion mit dem Overlay
        )
        // WICHTIG: Komplette Navigation Bar nicht-interaktiv machen
        .allowsHitTesting(false)
    }
    
    // MARK: - WebView with Cursor
    private func webViewWithCursor(geometry: GeometryProxy) -> some View {
        CursorWebViewIntegrated(
            url: $url,
            cursorPosition: $cursorManager.position,
            isLoading: $isLoading,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            title: $title,
            webViewRef: $webViewRef,
            preferences: preferences,
            onNavigationAction: onNavigationAction,
            onContentSizeChanged: { size in
                contentSize = size
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .clipped()
    }
    
    // MARK: - Actions
    private func performCursorClick() {
        print("🎯 performCursorClick aufgerufen!")
        print("🎯 Cursor Position: \(cursorManager.position)")
        print("🎯 WebView Ref: \(webViewRef != nil ? "verfügbar" : "NIL!")")
        
        guard let webView = webViewRef else {
            print("❌ Kein WebView verfügbar!")
            return
        }
        
        let script = """
            console.log('🎯 JavaScript Klick wird ausgeführt');
            
            if (typeof window.performCursorClick === 'function') {
                window.performCursorClick();
                console.log('✅ window.performCursorClick() erfolgreich aufgerufen');
            } else {
                console.log('❌ window.performCursorClick nicht verfügbar');
                
                var element = document.elementFromPoint(window.cursorX, window.cursorY);
                if (element) {
                    console.log('🎯 Fallback - Element gefunden:', element.tagName);
                    element.click();
                } else {
                    console.log('❌ Fallback - Kein Element gefunden');
                }
            }
        """
        
        executeJavaScript(webView, script: script)
    }
    
    private func executeJavaScript(_ webView: UIView, script: String) {
        print("🔧 JavaScript wird ausgeführt...")
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            let result = webView.perform(jsSelector, with: script)
            print("🔧 JavaScript Ergebnis: \(String(describing: result))")
        } else {
            print("❌ WebView unterstützt kein JavaScript!")
        }
    }
}

// MARK: - Navigation Actions Helper
extension CursorModeWebView {
    func goBack() {
        guard let webView = webViewRef, canGoBack else { return }
        let selector = NSSelectorFromString("goBack")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func goForward() {
        guard let webView = webViewRef, canGoForward else { return }
        let selector = NSSelectorFromString("goForward")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func reload() {
        guard let webView = webViewRef else { return }
        let selector = NSSelectorFromString("reload")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func resetCursorToCenter() {
        cursorManager.resetToCenter()
    }
}

// MARK: - CursorWebView Integration
struct CursorWebViewIntegrated: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var cursorPosition: CGPoint
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    @Binding var webViewRef: UIView?
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    let onContentSizeChanged: (CGSize) -> Void
    
    typealias UIViewType = UIView
    
    // MARK: - Viewport & Zoom JavaScript
    /// Dieses Script passt die Seite an die Bildschirmbreite an
    /// und vergrößert dann den Text für bessere Lesbarkeit auf TV
    private var viewportAndZoomJavaScript: String {
        """
        (function() {
            // 1. Viewport Meta-Tag setzen/ersetzen für korrekte Breitenanpassung
            var viewport = document.querySelector('meta[name="viewport"]');
            if (viewport) {
                viewport.remove();
            }
            
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
            document.head.insertBefore(viewport, document.head.firstChild);
            
            // 2. CSS für korrekte Anpassung und größeren Text
            var style = document.getElementById('tvBrowserStyle');
            if (!style) {
                style = document.createElement('style');
                style.id = 'tvBrowserStyle';
                document.head.appendChild(style);
            }
            
            style.textContent = `
                /* Verhindere horizontales Overflow und setze transparenten Hintergrund */
                html, body {
                    max-width: 100vw !important;
                    overflow-x: hidden !important;
                    background-color: transparent !important;
                    margin: 0 !important;
                    padding: 0 !important;
                }
                
                /* Bilder und Videos responsive machen */
                img, video, iframe, embed, object {
                    max-width: 100% !important;
                    height: auto !important;
                }
                
                /* Tabellen responsive */
                table {
                    max-width: 100% !important;
                    display: block !important;
                    overflow-x: auto !important;
                }
                
                /* Pre/Code Blöcke umbrechen */
                pre, code {
                    white-space: pre-wrap !important;
                    word-wrap: break-word !important;
                    max-width: 100% !important;
                }
                
                /* Fixe Breiten überschreiben */
                * {
                    max-width: 100vw !important;
                }
                
                /* TEXT VERGRÖSSERUNG für TV */
                html {
                    font-size: 125% !important;
                }
                
                body {
                    font-size: 1.1em !important;
                    line-height: 1.5 !important;
                }
                
                /* Überschriften größer */
                h1 { font-size: 2em !important; }
                h2 { font-size: 1.75em !important; }
                h3 { font-size: 1.5em !important; }
                h4 { font-size: 1.25em !important; }
                
                /* Links besser sichtbar */
                a {
                    text-decoration: underline !important;
                }
                
                /* Buttons größer für TV */
                button, input[type="button"], input[type="submit"], .btn {
                    min-height: 44px !important;
                    padding: 12px 20px !important;
                    font-size: 1.1em !important;
                }
            `;
            
            // 3. Alle fixierten Breiten-Attribute entfernen
            var allElements = document.querySelectorAll('[width]');
            allElements.forEach(function(el) {
                if (el.tagName !== 'IMG' && el.tagName !== 'VIDEO') {
                    el.removeAttribute('width');
                }
            });
            
            // 4. Inline-Styles mit fixen Breiten korrigieren
            var elementsWithStyle = document.querySelectorAll('[style*="width"]');
            elementsWithStyle.forEach(function(el) {
                var style = el.getAttribute('style');
                if (style && style.includes('width:') && style.includes('px')) {
                    // Nur wenn es eine fixe Pixelbreite ist
                    el.style.maxWidth = '100%';
                }
            });
            
            console.log('📐 Viewport und Zoom für TV angepasst');
            return 'viewport_set';
        })();
        """
    }
    
    func makeUIView(context: Context) -> UIView {
        print("🔧 WebView wird erstellt...")
        
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("❌ UIWebView Klasse nicht gefunden!")
            let fallbackView = UIView()
            fallbackView.backgroundColor = .clear
            return fallbackView
        }
        
        let webView = webViewClass.init()
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        webView.setValue(context.coordinator, forKey: "delegate")
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.isScrollEnabled = true
            scrollView.bounces = true
            scrollView.backgroundColor = .clear
            scrollView.isOpaque = false
            // Horizontales Scrollen deaktivieren
            scrollView.showsHorizontalScrollIndicator = false
            
            // WICHTIG: Content Insets auf null setzen um schwarze Ränder zu vermeiden
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
            if #available(tvOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        
        // WICHTIG: scalesPageToFit aktivieren für automatische Anpassung
        webView.setValue(true, forKey: "scalesPageToFit")
        webView.setValue(true, forKey: "allowsInlineMediaPlayback")
        webView.setValue(false, forKey: "mediaPlaybackRequiresUserAction")
        
        configureWebView(webView, with: preferences)
        
        DispatchQueue.main.async {
            self.webViewRef = webView
            print("🔧 WebView Referenz gespeichert")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: UIView, context: Context) {
        context.coordinator.parent = self
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        // Layer-Hintergrund explizit transparent setzen
        if let layer = webView.value(forKey: "layer") as? CALayer {
            layer.backgroundColor = UIColor.clear.cgColor
        }
        
        if let url = url, context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            let request = URLRequest(url: url)
            let selector = NSSelectorFromString("loadRequest:")
            if webView.responds(to: selector) {
                webView.perform(selector, with: request)
                print("🌐 URL geladen: \(url)")
            }
        }
        
        debouncedCursorUpdate(webView, position: cursorPosition, context: context)
        updateNavigationStateIfNeeded(webView, context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Helper Methods
    
    private func updateCursorPositionInJS(_ webView: UIView, position: CGPoint) {
        let script = """
            if (typeof window.updateCursorPosition === 'function') {
                window.updateCursorPosition(\(position.x), \(position.y));
            }
        """
        executeJavaScript(webView, script: script)
    }
    
    private func debouncedCursorUpdate(_ webView: UIView, position: CGPoint, context: Context) {
        let coordinator = context.coordinator
        coordinator.pendingCursorPosition = position
        
        coordinator.cursorUpdateTimer?.invalidate()
        
        coordinator.cursorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
            if let pendingPos = coordinator.pendingCursorPosition {
                let webViewFrame = webView.frame
                let webViewScreenFrame = webView.superview?.convert(webViewFrame, to: nil) ?? webViewFrame
                
                let webViewRelativeX = pendingPos.x - webViewScreenFrame.origin.x
                let webViewRelativeY = pendingPos.y - webViewScreenFrame.origin.y
                
                let clampedX = max(0, min(webViewFrame.width, webViewRelativeX))
                let clampedY = max(0, min(webViewFrame.height, webViewRelativeY))
                
                let finalPosition = CGPoint(x: clampedX, y: clampedY)
                
                self.updateCursorPositionInJS(webView, position: finalPosition)
                coordinator.pendingCursorPosition = nil
            }
        }
    }
    
    private func updateNavigationStateIfNeeded(_ webView: UIView, context: Context) {
        let coordinator = context.coordinator
        
        guard !coordinator.isUpdatingNavigationState else { return }
        
        coordinator.isUpdatingNavigationState = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let back = webView.value(forKey: "canGoBack") as? Bool, back != self.canGoBack {
                self.canGoBack = back
            }
            if let forward = webView.value(forKey: "canGoForward") as? Bool, forward != self.canGoForward {
                self.canGoForward = forward
            }
            coordinator.isUpdatingNavigationState = false
        }
    }
    
    func executeJavaScript(_ webView: UIView, script: String) {
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            _ = webView.perform(jsSelector, with: script)
        }
    }
    
    private func configureWebView(_ webView: UIView, with preferences: BrowserPreferences) {
        if !preferences.userAgent.isEmpty {
            if webView.responds(to: NSSelectorFromString("setCustomUserAgent:")) {
                webView.setValue(preferences.userAgent, forKey: "customUserAgent")
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: CursorWebViewIntegrated
        var lastLoadedURL: URL?
        var cursorUpdateTimer: Timer?
        var pendingCursorPosition: CGPoint?
        var isUpdatingNavigationState: Bool = false
        var hasInjectedJavaScript: Bool = false
        
        init(_ parent: CursorWebViewIntegrated) {
            self.parent = parent
        }
        
        deinit {
            cursorUpdateTimer?.invalidate()
        }
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            print("🌐 WebView lädt...")
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
            print("✅ WebView fertig geladen!")
            
            DispatchQueue.main.async {
                self.parent.isLoading = false
                
                let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
                if webView.responds(to: jsSelector) {
                    if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                        self.parent.title = title
                    }
                }
                
                if let request = webView.value(forKey: "request") as? URLRequest,
                   let url = request.url,
                   self.parent.url != url {
                    self.parent.url = url
                }
            }
            
            // JavaScript injizieren
            injectJavaScriptIfNeeded(webView)
            
            // Viewport und Zoom anpassen
            applyViewportAndZoom(webView)
            
            // Report content size
            reportContentSizeIfNeeded(webView)
        }
        
        private func injectJavaScriptIfNeeded(_ webView: UIView) {
            print("💉 JavaScript wird injiziert...")
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else {
                print("❌ WebView unterstützt kein JavaScript!")
                return
            }
            
            parent.executeJavaScript(webView, script: CursorWebView.mouseEventJavaScript)
            parent.executeJavaScript(webView, script: CursorWebView.cursorStyleJavaScript)
            
            hasInjectedJavaScript = true
        }
        
        private func applyViewportAndZoom(_ webView: UIView) {
            // Viewport und Zoom nach kurzer Verzögerung anwenden
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.parent.executeJavaScript(webView, script: self.parent.viewportAndZoomJavaScript)
                print("📐 Viewport und Zoom angewendet")
            }
        }
        
        private func reportContentSizeIfNeeded(_ webView: UIView) {
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let heightString = webView.perform(jsSelector, with: "document.body.scrollHeight")?.takeUnretainedValue() as? String,
                   let height = Double(heightString) {
                    let size = CGSize(width: webView.frame.width, height: CGFloat(height))
                    DispatchQueue.main.async {
                        self.parent.onContentSizeChanged(size)
                    }
                }
            }
        }
        
        @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
            print("❌ WebView Fehler: \(error)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
            return parent.onNavigationAction(request)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var url: URL? = URL(string: "https://www.apple.com")
    
    return CursorModeWebView(
        url: $url,
        preferences: BrowserPreferences(),
        onNavigationAction: { _ in true },
        onBack: { },
        onPlayPause: { },
        onShowSettings: { }
    )
    .preferredColorScheme(.dark)
}