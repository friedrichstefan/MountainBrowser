//
//  CursorModeWebView.swift
//  MountainBrowser
//
//  Vollständige Cursor-Modus WebView mit Info-Header und Cursor-Navigation
//  OPTIMIERT: Reduzierte Latenz, EMA-Smoothing, Canvas-basierter Cursor
//

import SwiftUI

// MARK: - Preference Key für Button-Frame-Messung
struct NavBarButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [CursorModeWebView.NavBarButton: CGRect] = [:]
    
    static func reduce(value: inout [CursorModeWebView.NavBarButton: CGRect], nextValue: () -> [CursorModeWebView.NavBarButton: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - WebView Text Input Sheet (Ersatz für UIAlertController)
struct WebViewTextInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var textValue: String
    let prompt: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Dunkler Hintergrund
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                Spacer()
                
                // Icon und Titel
                VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(prompt)
                        .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .multilineTextAlignment(.center)
                    
                    Text("Gib deinen Text ein und drücke OK")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                }
                
                // Eingabefeld
                TextField("Text eingeben", text: $textValue)
                    .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFieldFocused)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 25)
                    .background(
                        RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                    .strokeBorder(
                                        isFieldFocused ? TVOSDesign.Colors.accentBlue : Color.white.opacity(0.4),
                                        lineWidth: isFieldFocused ? 4 : 2
                                    )
                            )
                    )
                    .frame(maxWidth: 900)
                    .submitLabel(.done)
                    .onSubmit {
                        onSubmit()
                    }
                
                // Buttons
                HStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                    Button {
                        onSubmit()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                            Text("OK")
                                .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                .fill(
                                    LinearGradient(
                                        colors: [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onCancel()
                    } label: {
                        Text(L10n.General.cancel)
                            .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                isFieldFocused = true
            }
        }
        .onExitCommand {
            onCancel()
        }
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
    
    // Texteingabe-Sheet für Formulare
    @State private var showTextInputSheet: Bool = false
    @State private var textInputValue: String = ""
    @State private var textInputPrompt: String = "Text eingeben"
    @State private var pendingInputElementId: String? = nil
    
    // Hover-State für Navigation Bar Buttons
    @State private var hoveredNavBarButton: NavBarButton? = nil
    
    // Gemessene Frames der Nav-Bar-Buttons (in globalem Koordinatensystem)
    @State private var navBarButtonFrames: [NavBarButton: CGRect] = [:]
    
    // OPTIMIERT: Hover-Tracking ohne Date()-Allokation, nur bei tatsächlicher Änderung
    @State private var lastHoveredButton: NavBarButton? = nil
    
    // Guard gegen doppeltes Cleanup
    @State private var hasPerformedCleanup: Bool = false
    
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
    
    // Höhe der Navigation-Bar für Koordinaten-Korrektur
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
    
    /// Bestimmt welcher Nav-Bar-Button unter der Cursor-Position liegt
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
            // OPTIMIERT: Hover-Update nur wenn sich der Button tatsächlich ändert
            .onChange(of: cursorManager.position) { _, newPosition in
                let newHover = navBarButton(at: newPosition)
                if newHover != lastHoveredButton {
                    lastHoveredButton = newHover
                    hoveredNavBarButton = newHover
                }
            }
            .cursorGestureHandler(
                cursorManager: cursorManager,
                screenSize: geometry.size,
                onTap: {
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
        .onDisappear {
            cleanupWebView()
        }
        // ERSETZT: fullScreenCover statt .alert für Texteingabe
        .fullScreenCover(isPresented: $showTextInputSheet) {
            WebViewTextInputSheet(
                isPresented: $showTextInputSheet,
                textValue: $textInputValue,
                prompt: textInputPrompt,
                onSubmit: {
                    submitTextInput()
                    showTextInputSheet = false
                },
                onCancel: {
                    textInputValue = ""
                    pendingInputElementId = nil
                    showTextInputSheet = false
                }
            )
        }
    }
    
    // MARK: - Cleanup bei View-Modus-Wechsel
    
    private func cleanupWebView() {
        guard !hasPerformedCleanup else { return }
        hasPerformedCleanup = true
        
        guard let webView = webViewRef else { return }
        
        let cleanup = {
            webView.setValue(nil, forKey: "delegate")
            
            let stopSelector = NSSelectorFromString("stopLoading")
            if webView.responds(to: stopSelector) {
                webView.perform(stopSelector)
            }
            
            let loadSelector = NSSelectorFromString("loadHTMLString:baseURL:")
            if webView.responds(to: loadSelector) {
                webView.perform(loadSelector, with: "<html></html>", with: nil)
            }
            
            if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                scrollView.delegate = nil
            }
        }
        
        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.async {
                cleanup()
            }
        }
        
        webViewRef = nil
    }
    
    // MARK: - Hover-Highlight Helper
    
    private func navButtonBackground(for button: NavBarButton) -> Color {
        if hoveredNavBarButton == button {
            return Color.white.opacity(0.2)
        }
        return Color.clear
    }
    
    private func navButtonForeground(for button: NavBarButton, defaultColor: Color, disabledColor: Color = .gray.opacity(0.4), isEnabled: Bool = true) -> Color {
        guard isEnabled else { return disabledColor }
        if hoveredNavBarButton == button {
            return .blue
        }
        return defaultColor
    }
    
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
                
                // Modus-Wechsel Button (Cursor → Scroll und umgekehrt)
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(hoveredNavBarButton == .settings ? .white : .blue)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Scroll Modus")
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
        .animation(.easeInOut(duration: 0.12), value: hoveredNavBarButton)
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
        // Sicherstellen dass wir auf dem Main-Thread sind
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleTextInputRequest(elementId: elementId, placeholder: placeholder)
            }
            return
        }
        
        pendingInputElementId = elementId
        textInputPrompt = placeholder.isEmpty ? "Text eingeben" : placeholder
        textInputValue = ""
        
        // Kleine Verzögerung, damit die WebView Layout-Updates abschließen kann
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            showTextInputSheet = true
        }
    }
    
    private func submitTextInput() {
        guard let webView = webViewRef else { return }
        
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
        
        safeExecuteJavaScript(webView, script: script)
        
        textInputValue = ""
        pendingInputElementId = nil
    }
    
    // MARK: - Actions
    
    private func handleNavBarTap(cursorPosition: CGPoint) -> Bool {
        guard let button = navBarButton(at: cursorPosition) else {
            return false
        }
        
        switch button {
        case .back:
            handleBackNavigation()
        case .titleURL:
            break
        case .goBack:
            if canGoBack {
                goBack()
            }
        case .goForward:
            if canGoForward {
                goForward()
            }
        case .reload:
            reload()
        case .settings:
            onShowSettings()
        }
        
        return true
    }
    
    private func performCursorClick(screenSize: CGSize) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performCursorClick(screenSize: screenSize)
            }
            return
        }
        
        if handleNavBarTap(cursorPosition: cursorManager.position) {
            return
        }
        
        guard let webView = webViewRef else { return }
        
        let webViewFrame = webView.frame
        let webViewScreenFrame = webView.superview?.convert(webViewFrame, to: nil) ?? webViewFrame
        
        let webViewRelativeX = cursorManager.position.x - webViewScreenFrame.origin.x
        let webViewRelativeY = cursorManager.position.y - webViewScreenFrame.origin.y
        
        let clampedX = max(0, min(webViewFrame.width, webViewRelativeX))
        let clampedY = max(0, min(webViewFrame.height, webViewRelativeY))
        
        let script = """
            (function() {
                var element = document.elementFromPoint(\(clampedX), \(clampedY));
                if (!element) {
                    return JSON.stringify({ type: 'none', id: '', placeholder: '' });
                }
                
                var isTextField = (
                    element.tagName === 'INPUT' && 
                    ['text', 'search', 'email', 'url', 'tel', 'password'].includes(element.type)
                ) || element.tagName === 'TEXTAREA' || element.isContentEditable;
                
                if (isTextField) {
                    return JSON.stringify({
                        type: 'textfield',
                        id: element.id || element.name || '',
                        placeholder: element.placeholder || element.getAttribute('aria-label') || 'Text eingeben'
                    });
                }
                
                var linkElement = element.closest('a[href]');
                if (linkElement && linkElement.href) {
                    if (linkElement.href.indexOf('javascript:') === 0) {
                        linkElement.click();
                        return JSON.stringify({ type: 'js_link', tag: 'A', id: linkElement.id || '' });
                    }
                    window.location.href = linkElement.href;
                    return JSON.stringify({ type: 'link', tag: 'A', url: linkElement.href });
                }
                
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
                
                return JSON.stringify({ type: 'click', tag: element.tagName, id: element.id || '' });
            })();
        """
        
        if let result = safeEvaluateJavaScript(webView, script: script) {
            if let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let type = json["type"], type == "textfield" {
                let elementId = json["id"] ?? ""
                let placeholder = json["placeholder"] ?? "Text eingeben"
                
                self.handleTextInputRequest(elementId: elementId, placeholder: placeholder)
            }
        }
    }
    
    // MARK: - Safe JavaScript Execution Helpers
    
    private func safeEvaluateJavaScript(_ webView: UIView, script: String) -> String? {
        guard Thread.isMainThread else { return nil }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else { return nil }
        
        guard let unmanaged = webView.perform(jsSelector, with: script) else {
            return nil
        }
        
        return unmanaged.takeUnretainedValue() as? String
    }
    
    private func safeExecuteJavaScript(_ webView: UIView, script: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.safeExecuteJavaScript(webView, script: script)
            }
            return
        }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else { return }
        _ = webView.perform(jsSelector, with: script)
    }
    
    // MARK: - Back Navigation
    private func handleBackNavigation() {
        guard let webView = webViewRef else {
            onBack()
            return
        }
        
        if canGoBack {
            let selector = NSSelectorFromString("goBack")
            if webView.responds(to: selector) {
                webView.perform(selector)
            } else {
                onBack()
            }
        } else {
            onBack()
        }
    }
    
    // MARK: - Native Scrolling
    
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
        
        guard viewportHeight > 0, contentHeight > 0 else { return }
        
        let scrollAmount = viewportHeight * 0.15
        let delta = direction == .up ? -scrollAmount : scrollAmount
        
        let maxOffset = max(0, contentHeight - viewportHeight)
        let targetOffset = min(max(0, currentOffset + delta), maxOffset)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: targetOffset)
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
            var viewport = document.querySelector('meta[name="viewport"]');
            if (viewport) {
                viewport.remove();
            }
            
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
            document.head.insertBefore(viewport, document.head.firstChild);
            
            var style = document.getElementById('tvBrowserStyle');
            if (!style) {
                style = document.createElement('style');
                style.id = 'tvBrowserStyle';
                document.head.appendChild(style);
            }
            
            style.textContent = `
                html {
                    font-size: 125% !important;
                    margin: 0 !important;
                    padding: 0 !important;
                }
                
                body {
                    margin: 0 !important;
                    padding: 0 !important;
                    font-size: 1.1em !important;
                    line-height: 1.5 !important;
                }
                
                img, video, iframe, embed, object {
                    max-width: 100% !important;
                    height: auto !important;
                }
                
                pre, code {
                    white-space: pre-wrap !important;
                    word-wrap: break-word !important;
                }
                
                h1 { font-size: 2em !important; }
                h2 { font-size: 1.75em !important; }
                h3 { font-size: 1.5em !important; }
                h4 { font-size: 1.25em !important; }
                
                a {
                    text-decoration: underline !important;
                }
                
                button, input[type="button"], input[type="submit"], .btn {
                    min-height: 44px !important;
                    padding: 12px 20px !important;
                    font-size: 1.1em !important;
                }
            `;
            
            return 'viewport_set';
        })();
        """
    }
    
    private static var mouseEventJavaScript: String {
        """
        (function() {
            window.cursorX = 0;
            window.cursorY = 0;
            
            window.updateCursorPosition = function(x, y) {
                window.cursorX = x;
                window.cursorY = y;
            };
            
            return 'mouse_events_initialized';
        })();
        """
    }
    
    private static var cursorStyleJavaScript: String {
        """
        (function() {
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
            
            return 'cursor_style_initialized';
        })();
        """
    }
    
    func makeUIView(context: Context) -> UIView {
        guard Thread.isMainThread else {
            fatalError("makeUIView muss auf dem Main-Thread aufgerufen werden!")
        }
        
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
        
        guard !context.coordinator.isInvalidated else { return }
        
        containerView.backgroundColor = .black
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
            scrollView.frame = containerView.bounds
        }
        
        webView.frame = containerView.bounds
        
        if let url = url {
            let urlString = url.absoluteString
            let lastURLString = context.coordinator.lastLoadedURL?.absoluteString ?? ""
            
            if urlString != lastURLString && !context.coordinator.isNavigatingInternally {
                context.coordinator.lastLoadedURL = url
                let request = URLRequest(url: url)
                let selector = NSSelectorFromString("loadRequest:")
                if webView.responds(to: selector) {
                    webView.perform(selector, with: request)
                }
            }
        }
        
        updateNavigationStateIfNeeded(webView, context: context)
    }
    
    static func dismantleUIView(_ containerView: UIView, coordinator: Coordinator) {
        coordinator.cleanupWebView()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Helper Methods
    
    private func updateNavigationStateIfNeeded(_ webView: UIView, context: Context) {
        let coordinator = context.coordinator
        guard !coordinator.isUpdatingNavigationState else { return }
        guard !coordinator.isInvalidated else { return }
        coordinator.isUpdatingNavigationState = true
        
        if let back = webView.value(forKey: "canGoBack") as? Bool, back != self.canGoBack {
            DispatchQueue.main.async { self.canGoBack = back }
        }
        if let forward = webView.value(forKey: "canGoForward") as? Bool, forward != self.canGoForward {
            DispatchQueue.main.async { self.canGoForward = forward }
        }
        
        coordinator.isUpdatingNavigationState = false
    }
    
    func safeExecuteJavaScript(_ webView: UIView, script: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.safeExecuteJavaScript(webView, script: script)
            }
            return
        }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else { return }
        _ = webView.perform(jsSelector, with: script)
    }
    
    func safeEvaluateJavaScript(_ webView: UIView, script: String) -> String? {
        guard Thread.isMainThread else { return nil }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else { return nil }
        
        guard let unmanaged = webView.perform(jsSelector, with: script) else {
            return nil
        }
        
        return unmanaged.takeUnretainedValue() as? String
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
        
        var isNavigatingInternally: Bool = false
        var isInvalidated: Bool = false
        
        init(_ parent: CursorWebViewIntegrated) {
            self.parent = parent
        }
        
        func cleanupWebView() {
            guard !isInvalidated else { return }
            isInvalidated = true
            
            let cleanup = { [weak self] in
                guard let self = self, let webView = self.webView else { return }
                
                webView.setValue(nil, forKey: "delegate")
                
                let stopSelector = NSSelectorFromString("stopLoading")
                if webView.responds(to: stopSelector) {
                    webView.perform(stopSelector)
                }
                
                let loadSelector = NSSelectorFromString("loadHTMLString:baseURL:")
                if webView.responds(to: loadSelector) {
                    webView.perform(loadSelector, with: "", with: nil)
                }
                
                if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                    scrollView.delegate = nil
                }
                
                webView.removeFromSuperview()
                
                self.webView = nil
                self.containerView = nil
            }
            
            if Thread.isMainThread {
                cleanup()
            } else {
                DispatchQueue.main.async {
                    cleanup()
                }
            }
        }
        
        deinit {
            isInvalidated = true
            
            if Thread.isMainThread {
                cleanupWebViewImmediate()
            } else {
                let webView = self.webView
                let containerView = self.containerView
                DispatchQueue.main.async {
                    guard let webView = webView else { return }
                    webView.setValue(nil, forKey: "delegate")
                    let stopSelector = NSSelectorFromString("stopLoading")
                    if webView.responds(to: stopSelector) {
                        webView.perform(stopSelector)
                    }
                    if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                        scrollView.delegate = nil
                    }
                    webView.removeFromSuperview()
                    _ = containerView
                }
            }
        }
        
        private func cleanupWebViewImmediate() {
            guard let webView = self.webView else { return }
            webView.setValue(nil, forKey: "delegate")
            let stopSelector = NSSelectorFromString("stopLoading")
            if webView.responds(to: stopSelector) {
                webView.perform(stopSelector)
            }
            if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                scrollView.delegate = nil
            }
            webView.removeFromSuperview()
            self.webView = nil
            self.containerView = nil
        }
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            guard !isInvalidated else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isInvalidated else { return }
                self.parent.isLoading = true
            }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
            guard !isInvalidated else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isInvalidated else { return }
                
                self.parent.isLoading = false
                
                if let title = self.parent.safeEvaluateJavaScript(webView, script: "document.title") {
                    self.parent.title = title
                }
                
                if let request = webView.value(forKey: "request") as? URLRequest,
                   let url = request.url,
                   self.parent.url != url {
                    self.isNavigatingInternally = true
                    self.parent.url = url
                    self.lastLoadedURL = url
                    DispatchQueue.main.async { [weak self] in
                        self?.isNavigatingInternally = false
                    }
                }
                
                if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                    self.parent.onContentSizeChanged(scrollView.contentSize)
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isInvalidated else { return }
                self.injectJavaScriptIfNeeded(webView)
                self.applyViewportAndZoom(webView)
            }
        }
        
        private func injectJavaScriptIfNeeded(_ webView: UIView) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in self?.injectJavaScriptIfNeeded(webView) }
                return
            }
            guard !isInvalidated else { return }
            
            parent.safeExecuteJavaScript(webView, script: CursorWebViewIntegrated.mouseEventJavaScript)
            parent.safeExecuteJavaScript(webView, script: CursorWebViewIntegrated.cursorStyleJavaScript)
            
            hasInjectedJavaScript = true
        }
        
        private func applyViewportAndZoom(_ webView: UIView) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in self?.applyViewportAndZoom(webView) }
                return
            }
            guard !isInvalidated else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, !self.isInvalidated, Thread.isMainThread else { return }
                self.parent.safeExecuteJavaScript(webView, script: self.parent.viewportAndZoomJavaScript)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self, !self.isInvalidated else { return }
                    if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, !self.isInvalidated else { return }
                            self.parent.onContentSizeChanged(scrollView.contentSize)
                        }
                    }
                }
            }
        }
        
        @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
            guard !isInvalidated else { return }
            let nsError = error as NSError
            
            if nsError.code == NSURLErrorCancelled {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isInvalidated else { return }
                self.parent.isLoading = false
            }
        }
        
        @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
            guard !isInvalidated else { return false }
            
            if let url = request.url {
                self.isNavigatingInternally = true
                self.lastLoadedURL = url
                
                DispatchQueue.main.async { [weak self] in
                    self?.isNavigatingInternally = false
                }
            }
            
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

