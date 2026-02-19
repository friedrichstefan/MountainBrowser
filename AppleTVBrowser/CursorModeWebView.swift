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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Info Header (nicht interaktiv)
                    infoHeader
                    
                    // WebView mit Cursor
                    webViewWithCursor(geometry: geometry)
                }
            }
            .onAppear {
                cursorManager.updateScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                cursorManager.updateScreenSize(newSize)
            }
            // WICHTIGER FIX: Cursor Gesture Handler MUSS ÜBER DEM CURSOR OVERLAY stehen!
            .cursorGestureHandler(
                cursorPosition: $cursorManager.position,
                screenSize: geometry.size,
                onTap: {
                    print("🔥 GESTURE TAP erkannt!")
                    performCursorClick()
                },
                onMenuPress: {
                    onBack()
                }
            )
            // Cursor Overlay (nur visuell, keine Gestures!)
            .overlay(
                CursorOverlay(
                    position: $cursorManager.position,
                    screenSize: geometry.size,
                    onTap: {
                        // Dieser Callback wird NICHT mehr verwendet!
                        print("⚠️ CursorOverlay onTap - sollte nicht aufgerufen werden!")
                    }
                )
            )
        }
    }
    
    // MARK: - Info Header
    private var infoHeader: some View {
        VStack(spacing: 0) {
            // URL und Status Bar
            HStack(spacing: 20) {
                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                // URL Display
                VStack(alignment: .leading, spacing: 4) {
                    if !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    if let url = url {
                        Text(url.absoluteString)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Cursor Mode Indicator
                HStack(spacing: 8) {
                    Image(systemName: "cursorarrow.click.2")
                        .foregroundColor(.blue)
                    Text("Cursor Modus")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.black.opacity(0.9))
            
            // Thin separator line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
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
        .background(Color.clear)
        .clipped()
    }
    
    // MARK: - Actions (VERBESSERTE IMPLEMENTIERUNG)
    private func performCursorClick() {
        print("🎯 performCursorClick aufgerufen!")
        print("🎯 Cursor Position: \(cursorManager.position)")
        print("🎯 WebView Ref: \(webViewRef != nil ? "verfügbar" : "NIL!")")
        
        guard let webView = webViewRef else { 
            print("❌ Kein WebView verfügbar!")
            return 
        }
        
        // Koordinaten für WebView berechnen (Header-Offset berücksichtigen)
        let headerHeight: CGFloat = 61
        let webViewRelativeX = cursorManager.position.x
        let webViewRelativeY = cursorManager.position.y - headerHeight
        
        print("🎯 WebView relative Koordinaten: (\(webViewRelativeX), \(webViewRelativeY))")
        
        // JavaScript für Klick mit korrigierten Koordinaten
        let script = """
            console.log('🎯 JavaScript Klick ausgeführt bei (' + \(webViewRelativeX) + ', ' + \(webViewRelativeY) + ')');
            
            // Element an der Position finden
            var element = document.elementFromPoint(\(webViewRelativeX), \(webViewRelativeY));
            console.log('🎯 Element gefunden:', element);
            
            if (element) {
                console.log('🎯 Element Tag:', element.tagName);
                console.log('🎯 Element Klassen:', element.className);
                console.log('🎯 Element ID:', element.id);
                
                // Verschiedene Klick-Events erstellen
                var clickEvent = new MouseEvent('click', {
                    view: window,
                    bubbles: true,
                    cancelable: true,
                    clientX: \(webViewRelativeX),
                    clientY: \(webViewRelativeY),
                    button: 0
                });
                
                var mouseDownEvent = new MouseEvent('mousedown', {
                    view: window,
                    bubbles: true,
                    cancelable: true,
                    clientX: \(webViewRelativeX),
                    clientY: \(webViewRelativeY),
                    button: 0
                });
                
                var mouseUpEvent = new MouseEvent('mouseup', {
                    view: window,
                    bubbles: true,
                    cancelable: true,
                    clientX: \(webViewRelativeX),
                    clientY: \(webViewRelativeY),
                    button: 0
                });
                
                // Events dispatchen
                element.dispatchEvent(mouseDownEvent);
                element.dispatchEvent(mouseUpEvent);
                element.dispatchEvent(clickEvent);
                
                // Zusätzlich: native click() aufrufen falls möglich
                if (typeof element.click === 'function') {
                    element.click();
                    console.log('🎯 Native click() aufgerufen');
                }
                
                console.log('🎯 Alle Klick-Events gesendet');
            } else {
                console.log('❌ Kein Element an Position gefunden!');
            }
            
            // Funktions-Check
            if (typeof window.performCursorClick === 'function') {
                window.performCursorClick();
                console.log('🎯 window.performCursorClick() aufgerufen');
            } else {
                console.log('⚠️ window.performCursorClick nicht verfügbar');
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

// MARK: - Improved CursorWebView Integration
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
    
    func makeUIView(context: Context) -> UIView {
        print("🔧 WebView wird erstellt...")
        
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("❌ UIWebView Klasse nicht gefunden!")
            return UIView()
        }
        
        let webView = webViewClass.init()
        webView.backgroundColor = .black
        webView.setValue(context.coordinator, forKey: "delegate")
        
        // Configure webView properties
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
        }
        
        // Set webView properties using setValue
        webView.setValue(true, forKey: "scalesPageToFit")
        webView.setValue(true, forKey: "allowsInlineMediaPlayback")
        webView.setValue(false, forKey: "mediaPlaybackRequiresUserAction")
        
        // Configure based on preferences
        configureWebView(webView, with: preferences)
        
        // Store reference on main thread
        DispatchQueue.main.async {
            self.webViewRef = webView
            print("🔧 WebView Referenz gespeichert")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: UIView, context: Context) {
        context.coordinator.parent = self
        
        // Load URL only if it has actually changed (prevent reload loops)
        if let url = url, context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            let request = URLRequest(url: url)
            let selector = NSSelectorFromString("loadRequest:")
            if webView.responds(to: selector) {
                webView.perform(selector, with: request)
                print("🌐 URL geladen: \(url)")
            }
        }
        
        // Debounced cursor position update
        debouncedCursorUpdate(webView, position: cursorPosition)
        
        // Update navigation state only when needed (prevent update loops)
        updateNavigationStateIfNeeded(webView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentURL(from webView: UIView) -> URL? {
        if let request = webView.value(forKey: "request") as? URLRequest {
            return request.url
        }
        return nil
    }
    
    private func updateCursorPositionInJS(_ webView: UIView, position: CGPoint) {
        let script = """
            if (typeof window.updateCursorPosition === 'function') {
                window.updateCursorPosition(\(position.x), \(position.y));
            } else {
                console.log('⚠️ window.updateCursorPosition nicht verfügbar');
            }
        """
        executeJavaScript(webView, script: script)
    }
    
    // MARK: - Debounced Updates
    
    private func debouncedCursorUpdate(_ webView: UIView, position: CGPoint) {
        // Store the pending position
        if let coordinator = webView.value(forKey: "delegate") as? Coordinator {
            coordinator.pendingCursorPosition = position
            
            // Cancel existing timer
            coordinator.cursorUpdateTimer?.invalidate()
            
            // Create new timer with debounce
            coordinator.cursorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                if let pendingPos = coordinator.pendingCursorPosition {
                    // Get webview geometry
                    let webViewBounds = webView.bounds
                    let webViewFrame = webView.frame
                    
                    // Convert from screen coordinates to WebView coordinates
                    let headerHeight: CGFloat = 61
                    let webViewRelativeX = pendingPos.x - webViewFrame.origin.x
                    let webViewRelativeY = (pendingPos.y - headerHeight) - webViewFrame.origin.y
                    
                    // Clamp to WebView bounds to prevent out-of-bounds coordinates
                    let clampedX = max(0, min(webViewBounds.width, webViewRelativeX))
                    let clampedY = max(0, min(webViewBounds.height, webViewRelativeY))
                    
                    let finalPosition = CGPoint(x: clampedX, y: clampedY)
                    self.updateCursorPositionInJS(webView, position: finalPosition)
                    coordinator.pendingCursorPosition = nil
                }
            }
        }
    }
    
    private func updateNavigationStateIfNeeded(_ webView: UIView) {
        // Use a flag to prevent recursive updates
        guard let coordinator = webView.value(forKey: "delegate") as? Coordinator,
              !coordinator.isUpdatingNavigationState else { return }
        
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
    
    private func executeJavaScript(_ webView: UIView, script: String) {
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            _ = webView.perform(jsSelector, with: script)
        }
    }
    
    private func configureWebView(_ webView: UIView, with preferences: BrowserPreferences) {
        // User agent - check if the property exists before setting
        if !preferences.userAgent.isEmpty {
            // Try to set user agent safely
            if webView.responds(to: NSSelectorFromString("setCustomUserAgent:")) {
                webView.setValue(preferences.userAgent, forKey: "customUserAgent")
            }
        }
    }
    
    // MARK: - Coordinator (VERBESSERT)
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
                
                // Get title
                let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
                if webView.responds(to: jsSelector) {
                    if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                        self.parent.title = title
                    }
                }
                
                // Update URL only if it's different from what we expect
                if let request = webView.value(forKey: "request") as? URLRequest,
                   let url = request.url,
                   self.parent.url != url {
                    self.parent.url = url
                }
            }
            
            // JavaScript injizieren
            injectJavaScriptIfNeeded(webView)
            
            // Report content size with debounce
            reportContentSizeIfNeeded(webView)
        }
        
        private func injectJavaScriptIfNeeded(_ webView: UIView) {
            print("💉 JavaScript wird injiziert...")
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else { 
                print("❌ WebView unterstützt kein JavaScript!")
                return 
            }
            
            // Inject cursor JavaScript from CursorWebView
            parent.executeJavaScript(webView, script: CursorWebView.mouseEventJavaScript)
            parent.executeJavaScript(webView, script: CursorWebView.cursorStyleJavaScript)
            
            // Test JavaScript availability
            let testScript = "console.log('🔧 JavaScript verfügbar!'); typeof window.performCursorClick"
            if let result = webView.perform(jsSelector, with: testScript)?.takeUnretainedValue() as? String {
                print("🔧 JavaScript Test: \(result)")
            }
            
            hasInjectedJavaScript = true
        }
        
        private func reportContentSizeIfNeeded(_ webView: UIView) {
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

#Preview {
    @Previewable @State var url: URL? = URL(string: "https://www.apple.com")
    
    return CursorModeWebView(
        url: $url,
        preferences: BrowserPreferences(),
        onNavigationAction: { _ in true },
        onBack: { }
    )
    .preferredColorScheme(.dark)
}