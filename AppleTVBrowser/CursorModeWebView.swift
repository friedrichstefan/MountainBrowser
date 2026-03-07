//
//  CursorModeWebView.swift
//  AppleTVBrowser
//
//  Vollständige Cursor-Modus WebView mit Info-Header und Cursor-Navigation
//

import SwiftUI

// MARK: - Preference Key für Button-Frame-Messung
struct NavBarButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [CursorModeWebView.NavBarButton: CGRect] = [:]
    
    static func reduce(value: inout [CursorModeWebView.NavBarButton: CGRect], nextValue: () -> [CursorModeWebView.NavBarButton: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

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
    
    // NEU: Texteingabe-Sheet für Formulare
    @State private var showTextInputSheet: Bool = false
    @State private var textInputValue: String = ""
    @State private var textInputPrompt: String = "Text eingeben"
    @State private var pendingInputElementId: String? = nil
    
    // NEU: Hover-State für Navigation Bar Buttons
    @State private var hoveredNavBarButton: NavBarButton? = nil
    
    // NEU: Gemessene Frames der Nav-Bar-Buttons (in globalem Koordinatensystem)
    @State private var navBarButtonFrames: [NavBarButton: CGRect] = [:]
    
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
    
    // Computed Property für Mobile-Modus basierend auf User-Agent
    private var useMobileMode: Bool {
        let userAgent = preferences.userAgent.lowercased()
        return userAgent.contains("mobile") || userAgent.contains("iphone") || userAgent.contains("ipad")
    }
    
    // FIX: Höhe der Navigation-Bar für Koordinaten-Korrektur
    private let navigationBarHeight: CGFloat = 100
    
    // MARK: - Nav-Bar Button Identifikation
    enum NavBarButton: Equatable, Hashable {
        case back
        case titleURL
        case goBack
        case goForward
        case reload
        case settings
    }
    
    /// Bestimmt welcher Nav-Bar-Button unter der Cursor-Position liegt (basierend auf gemessenen Frames)
    private func navBarButton(at cursorPosition: CGPoint) -> NavBarButton? {
        for (button, frame) in navBarButtonFrames {
            if frame.contains(cursorPosition) {
                return button
            }
        }
        return nil
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
            .onPreferenceChange(NavBarButtonFramePreferenceKey.self) { frames in
                navBarButtonFrames = frames
            }
            .onAppear {
                cursorManager.updateScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                cursorManager.updateScreenSize(newSize)
            }
            .onChange(of: cursorManager.position) { _, newPosition in
                // Hover-State für Nav-Bar-Buttons aktualisieren
                let newHover = navBarButton(at: newPosition)
                if newHover != hoveredNavBarButton {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredNavBarButton = newHover
                    }
                }
            }
            .cursorGestureHandler(
                cursorPosition: $cursorManager.position,
                screenSize: geometry.size,
                onTap: {
                    print("🔥 GESTURE TAP erkannt!")
                    performCursorClick(screenSize: geometry.size)
                },
                onMenuPress: {
                    handleBackNavigation()
                },
                onPlayPause: {
                    onPlayPause()
                },
                onScroll: { direction in
                    performNativeScroll(direction: direction)
                }
            )
            .overlay(
                CursorOverlay(
                    position: $cursorManager.position,
                    screenSize: geometry.size,
                    onTap: {
                        // Nicht verwendet — Tap kommt über cursorGestureHandler
                    }
                )
            )
        }
        .ignoresSafeArea(.all, edges: .all)
        // Texteingabe-Alert für Suchfelder und Formulare
        .alert(textInputPrompt, isPresented: $showTextInputSheet) {
            TextField("Text eingeben", text: $textInputValue)
            
            Button("OK") {
                submitTextInput()
            }
            
            Button("Abbrechen", role: .cancel) {
                textInputValue = ""
                pendingInputElementId = nil
            }
        } message: {
            Text("Gib deinen Text ein und drücke OK")
        }
    }
    
    // MARK: - Hover-Highlight Helper
    
    /// Gibt die Hintergrundfarbe für einen Nav-Bar-Button basierend auf Hover-State zurück
    private func navButtonBackground(for button: NavBarButton) -> Color {
        if hoveredNavBarButton == button {
            return Color.white.opacity(0.2)
        }
        return Color.clear
    }
    
    /// Gibt die Vordergrundfarbe für einen Nav-Bar-Button basierend auf Hover-State zurück
    private func navButtonForeground(for button: NavBarButton, defaultColor: Color, disabledColor: Color = .gray.opacity(0.4), isEnabled: Bool = true) -> Color {
        guard isEnabled else { return disabledColor }
        if hoveredNavBarButton == button {
            return .blue
        }
        return defaultColor
    }
    
    /// Gibt den Scale-Effekt für einen Nav-Bar-Button basierend auf Hover-State zurück
    private func navButtonScale(for button: NavBarButton) -> CGFloat {
        if hoveredNavBarButton == button {
            return 1.15
        }
        return 1.0
    }
    
    // MARK: - Helper: Frame-Messung für einen Nav-Bar-Button
    private func measureFrame(for button: NavBarButton) -> some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: NavBarButtonFramePreferenceKey.self,
                    value: [button: geo.frame(in: .global)]
                )
        }
    }
    
    // MARK: - Navigation Bar (Visuell interaktiv im Cursor-Modus)
    private var navigationBar: some View {
        HStack(spacing: 16) {
            // Zurück-Icon
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(navButtonForeground(for: .back, defaultColor: .gray))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(navButtonBackground(for: .back))
                )
                .scaleEffect(navButtonScale(for: .back))
                .background(measureFrame(for: .back))
            
            // URL/Titel-Anzeige
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(pageTitle.isEmpty ? urlString : pageTitle)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(hoveredNavBarButton == .titleURL ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
            )
            .scaleEffect(hoveredNavBarButton == .titleURL ? 1.02 : 1.0)
            .frame(maxWidth: .infinity)
            .background(measureFrame(for: .titleURL))
            
            // Nav-Icons
            HStack(spacing: 16) {
                // Browser Zurück
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(navButtonForeground(for: .goBack, defaultColor: .white, isEnabled: canGoBack))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(navButtonBackground(for: .goBack))
                    )
                    .scaleEffect(navButtonScale(for: .goBack))
                    .background(measureFrame(for: .goBack))
                
                // Browser Vorwärts
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(navButtonForeground(for: .goForward, defaultColor: .white, isEnabled: canGoForward))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(navButtonBackground(for: .goForward))
                    )
                    .scaleEffect(navButtonScale(for: .goForward))
                    .background(measureFrame(for: .goForward))
                
                // Reload / Stop
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(navButtonForeground(for: .reload, defaultColor: .gray))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(navButtonBackground(for: .reload))
                    )
                    .scaleEffect(navButtonScale(for: .reload))
                    .background(measureFrame(for: .reload))
                
                // Cursor-Modus Badge / Settings
                HStack(spacing: 8) {
                    Image(systemName: "cursorarrow.click.2")
                        .foregroundColor(hoveredNavBarButton == .settings ? .white : .blue)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Cursor Modus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(hoveredNavBarButton == .settings ? .white : .blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hoveredNavBarButton == .settings ? Color.blue.opacity(0.4) : Color.blue.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(hoveredNavBarButton == .settings ? Color.blue.opacity(0.8) : Color.blue.opacity(0.3), lineWidth: hoveredNavBarButton == .settings ? 2 : 1)
                        )
                )
                .scaleEffect(navButtonScale(for: .settings))
                .background(measureFrame(for: .settings))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    TVOSDesign.Colors.background.opacity(0.98),
                    TVOSDesign.Colors.background.opacity(0.92),
                    TVOSDesign.Colors.background.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
        )
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
                .allowsHitTesting(false)
        )
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.15), value: hoveredNavBarButton)
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
            },
            onTextInputRequired: { elementId, placeholder in
                handleTextInputRequest(elementId: elementId, placeholder: placeholder)
            }
        )
        .frame(width: geometry.size.width, height: geometry.size.height - navigationBarHeight)
        .background(Color.black)
        .clipped()
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Text Input Handling
    
    private func handleTextInputRequest(elementId: String, placeholder: String) {
        print("⌨️ Texteingabe angefordert für Element: \(elementId)")
        pendingInputElementId = elementId
        textInputPrompt = placeholder.isEmpty ? "Text eingeben" : placeholder
        textInputValue = ""
        showTextInputSheet = true
    }
    
    private func submitTextInput() {
        guard let webView = webViewRef else {
            print("❌ Kein WebView für Texteingabe verfügbar!")
            return
        }
        
        let escapedValue = textInputValue
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        let script: String
        if let elementId = pendingInputElementId, !elementId.isEmpty {
            script = """
                (function() {
                    var element = document.getElementById('\(elementId)');
                    if (!element) {
                        element = document.querySelector('input[name="\(elementId)"]');
                    }
                    if (!element) {
                        element = document.querySelector('input[type="text"], input[type="search"], textarea');
                    }
                    if (element) {
                        element.value = '\(escapedValue)';
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));
                        
                        var form = element.closest('form');
                        if (form) {
                            form.submit();
                        }
                        return 'success';
                    }
                    return 'element_not_found';
                })();
            """
        } else {
            script = """
                (function() {
                    var element = document.querySelector('input[type="text"], input[type="search"], textarea');
                    if (element) {
                        element.value = '\(escapedValue)';
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));
                        
                        var form = element.closest('form');
                        if (form) {
                            form.submit();
                        }
                        return 'success';
                    }
                    return 'element_not_found';
                })();
            """
        }
        
        executeJavaScript(webView, script: script)
        
        textInputValue = ""
        pendingInputElementId = nil
    }
    
    // MARK: - Actions
    
    /// Prüft ob der Cursor im Navigation-Bar-Bereich ist und führt die entsprechende Aktion aus.
    /// Gibt `true` zurück, wenn ein Nav-Bar-Button getroffen wurde (kein WebView-Klick nötig).
    private func handleNavBarTap(cursorPosition: CGPoint) -> Bool {
        guard let button = navBarButton(at: cursorPosition) else {
            return false
        }
        
        switch button {
        case .back:
            print("🔙 Nav-Bar Tap: Zurück-Button")
            handleBackNavigation()
        case .titleURL:
            print("🔗 Nav-Bar Tap: Titel/URL-Bereich (keine Aktion)")
            // Könnte URL-Eingabe öffnen, für jetzt ignorieren
        case .goBack:
            print("⬅️ Nav-Bar Tap: Browser Zurück")
            if canGoBack {
                goBack()
            }
        case .goForward:
            print("➡️ Nav-Bar Tap: Browser Vorwärts")
            if canGoForward {
                goForward()
            }
        case .reload:
            print("🔄 Nav-Bar Tap: Reload")
            reload()
        case .settings:
            print("⚙️ Nav-Bar Tap: Settings / Modus-Wechsel")
            onShowSettings()
        }
        
        return true
    }
    
    /// FIX: Cursor-Klick mit korrekter Koordinaten-Umrechnung von Screen → WebView-relativ
    private func performCursorClick(screenSize: CGSize) {
        print("🎯 performCursorClick aufgerufen!")
        print("🎯 Cursor Position (Screen): \(cursorManager.position)")
        print("🎯 WebView Ref: \(webViewRef != nil ? "verfügbar" : "NIL!")")
        
        // FIX: Sicherstellen, dass wir auf dem Main-Thread sind
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performCursorClick(screenSize: screenSize)
            }
            return
        }
        
        // NEU: Prüfe zuerst, ob der Cursor im Navigation-Bar-Bereich ist
        if handleNavBarTap(cursorPosition: cursorManager.position) {
            print("🎯 Nav-Bar-Tap verarbeitet — kein WebView-Klick")
            return
        }
        
        guard let webView = webViewRef else {
            print("❌ Kein WebView verfügbar!")
            return
        }
        
        // FIX: Korrekte Umrechnung von Screen-Koordinaten auf WebView-relative Koordinaten
        let webViewFrame = webView.frame
        let webViewScreenFrame = webView.superview?.convert(webViewFrame, to: nil) ?? webViewFrame
        
        let webViewRelativeX = cursorManager.position.x - webViewScreenFrame.origin.x
        let webViewRelativeY = cursorManager.position.y - webViewScreenFrame.origin.y
        
        let clampedX = max(0, min(webViewFrame.width, webViewRelativeX))
        let clampedY = max(0, min(webViewFrame.height, webViewRelativeY))
        
        print("🎯 WebView Frame: \(webViewFrame)")
        print("🎯 WebView Screen Frame: \(webViewScreenFrame)")
        print("🎯 WebView-relative Position: (\(clampedX), \(clampedY))")
        
        print("🎯 Viewport-Koordinaten für elementFromPoint: (\(clampedX), \(clampedY))")
        
        // VERBESSERT: Textfeld-Erkennung und Klick mit korrekten Koordinaten
        let script = """
            (function() {
                console.log('🎯 JavaScript Klick wird ausgeführt bei', \(clampedX), \(clampedY));
                
                var element = document.elementFromPoint(\(clampedX), \(clampedY));
                if (!element) {
                    console.log('❌ Kein Element an Position gefunden');
                    return JSON.stringify({ type: 'none', id: '', placeholder: '' });
                }
                
                console.log('🎯 Element gefunden:', element.tagName, element.type, element.className);
                
                // Prüfe ob es ein Textfeld ist
                var isTextField = (
                    element.tagName === 'INPUT' && 
                    ['text', 'search', 'email', 'url', 'tel', 'password'].includes(element.type)
                ) || element.tagName === 'TEXTAREA' || element.isContentEditable;
                
                if (isTextField) {
                    console.log('⌨️ Textfeld erkannt!');
                    return JSON.stringify({
                        type: 'textfield',
                        id: element.id || element.name || '',
                        placeholder: element.placeholder || element.getAttribute('aria-label') || 'Text eingeben'
                    });
                }
                
                // Normaler Klick mit vollständiger Event-Simulation
                var mouseDown = new MouseEvent('mousedown', {
                    bubbles: true, cancelable: true,
                    clientX: \(clampedX), clientY: \(clampedY)
                });
                var mouseUp = new MouseEvent('mouseup', {
                    bubbles: true, cancelable: true,
                    clientX: \(clampedX), clientY: \(clampedY)
                });
                var click = new MouseEvent('click', {
                    bubbles: true, cancelable: true,
                    clientX: \(clampedX), clientY: \(clampedY)
                });
                
                element.dispatchEvent(mouseDown);
                element.dispatchEvent(mouseUp);
                element.dispatchEvent(click);
                
                // Falls Link: Explizit navigieren
                var linkElement = element.closest('a[href]');
                if (linkElement && linkElement.href) {
                    console.log('🔗 Link-Klick:', linkElement.href);
                    window.location.href = linkElement.href;
                }
                
                return JSON.stringify({ type: 'click', tag: element.tagName, id: element.id || '' });
            })();
        """
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            if let result = webView.perform(jsSelector, with: script)?.takeUnretainedValue() as? String {
                print("🔧 JavaScript Ergebnis: \(result)")
                
                // Parse JSON-Ergebnis für Textfeld-Erkennung
                if let data = result.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let type = json["type"], type == "textfield" {
                    let elementId = json["id"] ?? ""
                    let placeholder = json["placeholder"] ?? "Text eingeben"
                    
                    DispatchQueue.main.async {
                        self.handleTextInputRequest(elementId: elementId, placeholder: placeholder)
                    }
                }
            }
        }
    }
    
    // MARK: - Back Navigation
    private func handleBackNavigation() {
        print("🔙 Back-Navigation aufgerufen")
        
        guard let webView = webViewRef else {
            print("❌ Kein WebView für Back-Navigation verfügbar!")
            onBack()
            return
        }
        
        if canGoBack {
            print("🔙 WebView kann zurücknavigieren - führe Browser-Back aus")
            let selector = NSSelectorFromString("goBack")
            if webView.responds(to: selector) {
                webView.perform(selector)
                print("✅ Browser goBack() erfolgreich ausgeführt")
            } else {
                onBack()
            }
        } else {
            print("🔙 WebView kann nicht zurücknavigieren - führe App-Back aus")
            onBack()
        }
    }
    
    // MARK: - Native Scrolling (FIX: Verwendet UIScrollView.contentOffset statt JavaScript)
    
    private func performNativeScroll(direction: ScrollDirection) {
        guard let webView = webViewRef else {
            return
        }
        
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performNativeScroll(direction: direction)
            }
            return
        }
        
        guard let scrollView = webView.value(forKey: "scrollView") as? UIScrollView else {
            return
        }
        
        let viewportHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let currentOffset = scrollView.contentOffset.y
        
        let scrollAmount = viewportHeight * 0.30
        let delta = direction == .up ? -scrollAmount : scrollAmount
        
        let maxOffset = max(0, contentHeight - viewportHeight)
        let targetOffset = min(max(0, currentOffset + delta), maxOffset)
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: targetOffset)
        }
    }
    
    private func executeJavaScript(_ webView: UIView, script: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.executeJavaScript(webView, script: script)
            }
            return
        }
        
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
    let onTextInputRequired: (String, String) -> Void
    
    typealias UIViewType = UIView
    
    // Computed Property für Mobile-Modus basierend auf User-Agent
    private var useMobileMode: Bool {
        let userAgent = preferences.userAgent.lowercased()
        return userAgent.contains("mobile") || userAgent.contains("iphone") || userAgent.contains("ipad")
    }
    
    // MARK: - Viewport & Zoom JavaScript
    private var viewportAndZoomJavaScript: String {
        """
        (function() {
            console.log('🔧 Viewport und Zoom JavaScript wird ausgeführt...');
            
            // Viewport Meta-Tag setzen für korrekte Breitenanpassung
            var viewport = document.querySelector('meta[name="viewport"]');
            if (viewport) {
                viewport.remove();
            }
            
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
            document.head.insertBefore(viewport, document.head.firstChild);
            
            // Style für TV-Lesbarkeit — OHNE Hintergrundfarbe zu erzwingen
            var style = document.getElementById('tvBrowserStyle');
            if (!style) {
                style = document.createElement('style');
                style.id = 'tvBrowserStyle';
                document.head.appendChild(style);
            }
            
            style.textContent = `
                /* Grundlegende Textvergrößerung für TV-Lesbarkeit */
                html {
                    font-size: 125% !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    overflow-x: hidden !important;
                }
                
                body {
                    margin: 0 !important;
                    padding: 0 !important;
                    overflow-x: hidden !important;
                    font-size: 1.1em !important;
                    line-height: 1.5 !important;
                }
                
                /* Responsive Medien */
                img, video, iframe, embed, object {
                    max-width: 100% !important;
                    height: auto !important;
                }
                
                table {
                    max-width: 100% !important;
                    overflow-x: auto !important;
                }
                
                pre, code {
                    white-space: pre-wrap !important;
                    word-wrap: break-word !important;
                    max-width: 100% !important;
                }
                
                /* Verhindere horizontales Scrollen */
                * {
                    max-width: 100vw !important;
                    box-sizing: border-box !important;
                }
                
                /* TEXT VERGRÖSSERUNG für TV */
                h1 { font-size: 2em !important; }
                h2 { font-size: 1.75em !important; }
                h3 { font-size: 1.5em !important; }
                h4 { font-size: 1.25em !important; }
                
                /* Links besser sichtbar */
                a {
                    text-decoration: underline !important;
                    color: #1976d2 !important;
                }
                
                /* Buttons größer für TV */
                button, input[type="button"], input[type="submit"], .btn {
                    min-height: 44px !important;
                    padding: 12px 20px !important;
                    font-size: 1.1em !important;
                }
            `;
            
            // Fixe Breiten-Attribute entfernen
            setTimeout(function() {
                var allElements = document.querySelectorAll('[width]');
                allElements.forEach(function(el) {
                    if (el.tagName !== 'IMG' && el.tagName !== 'VIDEO') {
                        el.removeAttribute('width');
                    }
                });
                
                var elementsWithStyle = document.querySelectorAll('[style*="width"]');
                elementsWithStyle.forEach(function(el) {
                    var s = el.getAttribute('style');
                    if (s && s.includes('width:') && s.includes('px')) {
                        el.style.maxWidth = '100%';
                        el.style.width = 'auto';
                    }
                });
                
                console.log('✅ Layout-Anpassungen abgeschlossen');
            }, 100);
            
            console.log('📐 Viewport und Zoom für TV angepasst');
            return 'viewport_set';
        })();
        """
    }
    
    private static var mouseEventJavaScript: String {
        """
        (function() {
            console.log('🖱️ Mouse Event JavaScript wird initialisiert (Click-Only-Modus)...');
            
            window.cursorX = 0;
            window.cursorY = 0;
            
            window.updateCursorPosition = function(x, y) {
                window.cursorX = x;
                window.cursorY = y;
            };
            
            window.performCursorClick = function() {
                console.log('🎯 performCursorClick bei:', window.cursorX, window.cursorY);
                
                var element = document.elementFromPoint(window.cursorX, window.cursorY);
                if (element) {
                    console.log('🎯 Element gefunden:', element.tagName, element.className);
                    
                    var mouseDown = new MouseEvent('mousedown', {
                        bubbles: true, cancelable: true,
                        clientX: window.cursorX, clientY: window.cursorY
                    });
                    var mouseUp = new MouseEvent('mouseup', {
                        bubbles: true, cancelable: true,
                        clientX: window.cursorX, clientY: window.cursorY
                    });
                    var click = new MouseEvent('click', {
                        bubbles: true, cancelable: true,
                        clientX: window.cursorX, clientY: window.cursorY
                    });
                    
                    element.dispatchEvent(mouseDown);
                    element.dispatchEvent(mouseUp);
                    element.dispatchEvent(click);
                    
                    var linkElement = element.closest('a[href]');
                    if (linkElement && linkElement.href) {
                        console.log('🔗 Link-Klick:', linkElement.href);
                        window.location.href = linkElement.href;
                    }
                    
                    return true;
                }
                return false;
            };
            
            console.log('✅ Mouse Event JavaScript initialisiert (Click-Only)');
            return 'mouse_events_initialized';
        })();
        """
    }
    
    private static var cursorStyleJavaScript: String {
        """
        (function() {
            console.log('🎨 Cursor Style JavaScript wird initialisiert (vereinfacht)...');
            
            var style = document.getElementById('cursorHoverStyle');
            if (!style) {
                style = document.createElement('style');
                style.id = 'cursorHoverStyle';
                document.head.appendChild(style);
            }
            
            style.textContent = `
                a:active, button:active {
                    outline: 3px solid #007AFF !important;
                    outline-offset: 2px !important;
                    background-color: rgba(0, 122, 255, 0.1) !important;
                    transition: all 0.1s ease !important;
                }
            `;
            
            console.log('✅ Cursor Style JavaScript initialisiert (vereinfacht)');
            return 'cursor_style_initialized';
        })();
        """
    }
    
    func makeUIView(context: Context) -> UIView {
        guard Thread.isMainThread else {
            fatalError("❌ makeUIView muss auf dem Main-Thread aufgerufen werden!")
        }
        
        print("🔧 WebView wird erstellt...")
        
        let userAgent: String
        if useMobileMode {
            userAgent = "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/15E148 Safari/604.1"
        } else {
            userAgent = preferences.userAgent.isEmpty
                ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15"
                : preferences.userAgent
        }
        
        let dictionary = ["UserAgent": userAgent]
        UserDefaults.standard.register(defaults: dictionary)
        UserDefaults.standard.synchronize()
        
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("❌ UIWebView Klasse nicht gefunden!")
            return createFallbackView()
        }
        
        let webView = webViewClass.init()
        
        let containerView = UIView()
        containerView.backgroundColor = .black
        containerView.clipsToBounds = true
        containerView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.clipsToBounds = false
        webView.setValue(context.coordinator, forKey: "delegate")
        webView.layoutMargins = .zero
        webView.backgroundColor = .white
        webView.isOpaque = true
        webView.isUserInteractionEnabled = true
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.layoutMargins = .zero
            if #available(tvOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
            scrollView.contentOffset = .zero
            scrollView.contentInset = .zero
            scrollView.clipsToBounds = false
            scrollView.bounces = true
            scrollView.isScrollEnabled = true
            scrollView.panGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
            scrollView.backgroundColor = .white
            scrollView.indicatorStyle = .default
            scrollView.showsVerticalScrollIndicator = true
        }
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        context.coordinator.webView = webView
        context.coordinator.containerView = containerView
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        
        return containerView
    }
    
    private func createFallbackView() -> UIView {
        let fallbackContainer = UIView()
        fallbackContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        let label = UILabel()
        label.text = "⚠️ UIWebView nicht verfügbar\n\nDiese tvOS Version unterstützt möglicherweise keine WebView-Darstellung."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        fallbackContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: fallbackContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: fallbackContainer.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: fallbackContainer.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(lessThanOrEqualTo: fallbackContainer.trailingAnchor, constant: -40)
        ])
        
        return fallbackContainer
    }
    
    func updateUIView(_ containerView: UIView, context: Context) {
        context.coordinator.parent = self
        
        guard let webView = context.coordinator.webView else { return }
        
        containerView.backgroundColor = .black
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
            scrollView.frame = containerView.bounds
        }
        
        webView.frame = containerView.bounds
        
        if let url = url, context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            let request = URLRequest(url: url)
            let selector = NSSelectorFromString("loadRequest:")
            if webView.responds(to: selector) {
                webView.perform(selector, with: request)
                print("🌐 URL geladen: \(url)")
            }
        }
        
        updateNavigationStateIfNeeded(webView, context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Helper Methods
    
    private func updateNavigationStateIfNeeded(_ webView: UIView, context: Context) {
        let coordinator = context.coordinator
        guard !coordinator.isUpdatingNavigationState else { return }
        coordinator.isUpdatingNavigationState = true
        
        if let back = webView.value(forKey: "canGoBack") as? Bool, back != self.canGoBack {
            DispatchQueue.main.async { self.canGoBack = back }
        }
        if let forward = webView.value(forKey: "canGoForward") as? Bool, forward != self.canGoForward {
            DispatchQueue.main.async { self.canGoForward = forward }
        }
        
        coordinator.isUpdatingNavigationState = false
    }
    
    func executeJavaScript(_ webView: UIView, script: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.executeJavaScript(webView, script: script)
            }
            return
        }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            _ = webView.perform(jsSelector, with: script)
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: CursorWebViewIntegrated
        var lastLoadedURL: URL?
        var isUpdatingNavigationState: Bool = false
        var hasInjectedJavaScript: Bool = false
        var containerView: UIView?
        var webView: UIView?
        var lastCursorPosition: CGPoint = .zero
        
        init(_ parent: CursorWebViewIntegrated) {
            self.parent = parent
        }
        
        deinit {
            print("🧹 Coordinator deinit - Cleanup durchgeführt")
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
                
                if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                    scrollView.contentInset = .zero
                    scrollView.scrollIndicatorInsets = .zero
                    
                    let contentSize = scrollView.contentSize
                    print("📐 ScrollView Content Size: \(contentSize), Offset: \(scrollView.contentOffset)")
                    self.parent.onContentSizeChanged(contentSize)
                }
            }
            
            DispatchQueue.main.async {
                self.injectJavaScriptIfNeeded(webView)
                self.applyViewportAndZoom(webView)
            }
        }
        
        private func injectJavaScriptIfNeeded(_ webView: UIView) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { self.injectJavaScriptIfNeeded(webView) }
                return
            }
            
            print("💉 JavaScript wird injiziert...")
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else { return }
            
            parent.executeJavaScript(webView, script: CursorWebViewIntegrated.mouseEventJavaScript)
            parent.executeJavaScript(webView, script: CursorWebViewIntegrated.cursorStyleJavaScript)
            
            hasInjectedJavaScript = true
        }
        
        private func applyViewportAndZoom(_ webView: UIView) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { self.applyViewportAndZoom(webView) }
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard Thread.isMainThread else { return }
                self.parent.executeJavaScript(webView, script: self.parent.viewportAndZoomJavaScript)
                print("📐 Viewport angepasst")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                        let contentSize = scrollView.contentSize
                        print("📐 ScrollView Content Size (nach Layout): \(contentSize)")
                        DispatchQueue.main.async {
                            self.parent.onContentSizeChanged(contentSize)
                        }
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

// MARK: - Preview Helper View
private struct CursorModeWebViewPreview: View {
    @State private var url: URL? = URL(string: "https://www.apple.com")
    
    var body: some View {
        CursorModeWebView(
            url: $url,
            preferences: BrowserPreferences(),
            onNavigationAction: { _ in true },
            onBack: { },
            onPlayPause: { },
            onShowSettings: { }
        )
        .preferredColorScheme(.dark)
    }
}
#Preview {
    CursorModeWebViewPreview()
}

