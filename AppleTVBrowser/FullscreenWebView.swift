//
//  FullscreenWebView.swift
//  AppleTVBrowser
//
//  Vollbild-WebView für tvOS mit ScrollView/CursorView Modi
//

import SwiftUI
import Combine
import MediaPlayer

struct FullscreenWebView: View {
    let url: String
    let title: String
    @Binding var isPresented: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var sessionManager = SessionManager()
    
    @State private var urlObject: URL?
    @State private var showingSettings = false
    @State private var showModeToast = false
    @State private var currentModeText = ""
    @State private var currentViewMode: BrowserViewMode = .scrollView  // NEU: Separate State für View-Rendering
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Group {
                switch currentViewMode {  // Verwende lokale State statt sessionManager.preferences.viewMode
                case .scrollView:
                    ScrollModeWebView(
                        url: url,
                        title: title,
                        onBack: { dismiss() },
                        onShowSettings: { showingSettings = true },
                        onPlayPause: { toggleViewMode() }
                    )
                case .cursorView:
                    CursorModeWebView(
                        url: $urlObject,
                        preferences: sessionManager.preferences,
                        onNavigationAction: { _ in true },
                        onBack: { dismiss() },
                        onPlayPause: { toggleViewMode() },
                        onShowSettings: { showingSettings = true }
                    )
                }
            }
            
            // Toast für Modus-Wechsel
            if showModeToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        modeToast
                        Spacer()
                    }
                    .padding(.bottom, 80)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
        }
        .onAppear {
            urlObject = URL(string: url)
            // Sync lokale State mit SessionManager beim Erscheinen
            currentViewMode = sessionManager.preferences.viewMode
        }
        .sheet(isPresented: $showingSettings) {
            BrowserSettingsView(sessionManager: sessionManager)
        }
    }
    
    // MARK: - Toast für Modus-Wechsel
    private var modeToast: some View {
        HStack(spacing: 16) {
            Image(systemName: currentViewMode == .cursorView ? "cursorarrow.click.2" : "scroll")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(currentModeText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
    }
    
    // MARK: - Toggle View Mode
    private func toggleViewMode() {
        print("🔥 toggleViewMode aufgerufen - Aktueller Modus: \(currentViewMode)")
        
        let newMode: BrowserViewMode = currentViewMode == .scrollView ? .cursorView : .scrollView
        
        print("🔄 Wechsel zu: \(newMode)")
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            // WICHTIG: Erst lokale State ändern (für UI-Update)
            currentViewMode = newMode
            // Dann SessionManager aktualisieren (für Persistierung)
            sessionManager.preferences.viewMode = newMode
            sessionManager.savePreferences()
            
            currentModeText = newMode == .cursorView ? "🎮 Cursor-Modus aktiviert" : "📜 Scroll-Modus aktiviert"
            showModeToast = true
        }
        
        print("✅ Modus gewechselt zu: \(newMode)")
        
        // Toast nach 2.5 Sekunden ausblenden
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showModeToast = false
            }
        }
    }
}

// MARK: - ScrollView Mode (Original Implementation)
struct ScrollModeWebView: View {
    let url: String
    let title: String
    let onBack: () -> Void
    let onShowSettings: () -> Void
    let onPlayPause: () -> Void
    
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var pageTitle: String = ""
    @State private var showNavigationBar: Bool = true
    @State private var showHelpHint: Bool = true
    
    @State private var helpHintOpacity: Double = 1.0
    @State private var helpHintOffset: CGFloat = 0
    @State private var helpHintScale: CGFloat = 1.0
    @State private var helpHintBlur: CGFloat = 0
    
    @StateObject private var webViewController = WebViewScrollController()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()
            
            WebViewContainer(
                urlString: $urlString,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                pageTitle: $pageTitle,
                showNavigationBar: $showNavigationBar,
                scrollController: webViewController,
                onMenuPress: {
                    if canGoBack {
                        webViewController.goBack()
                    } else {
                        onBack()
                    }
                },
                onPlayPause: {
                    onPlayPause()
                }
            )
            .padding(.top, showNavigationBar ? 100 : 0)
            .ignoresSafeArea(edges: showNavigationBar ? [.bottom, .leading, .trailing] : .all)
            
            if showNavigationBar {
                navigationBar
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                            removal: .move(edge: .top).combined(with: .opacity).animation(.easeOut(duration: 0.4))
                        )
                    )
            }
            
            if isLoading {
                loadingIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.9)).animation(.spring(response: 0.4, dampingFraction: 0.7)))
            }
            
            if showNavigationBar && showHelpHint {
                VStack {
                    Spacer()
                    helpHint
                        .opacity(helpHintOpacity)
                        .offset(y: helpHintOffset)
                        .scaleEffect(helpHintScale)
                        .blur(radius: helpHintBlur)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            urlString = url
            pageTitle = title.isEmpty ? url : title
            startSmoothHelpHintFadeOut()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNavigationBar)
    }
    
    private func startSmoothHelpHintFadeOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 3.5)) {
                helpHintOpacity = 0
                helpHintScale = 0.3
                helpHintOffset = 50
                helpHintBlur = 12
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) {
                showHelpHint = false
            }
        }
    }
    
    // MARK: - Navigationsleiste (Obere graue Leiste mit Buttons und URL-Anzeige)
    private var navigationBar: some View {
        // Hauptcontainer für alle Navigations-Elemente in der oberen Leiste
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button (Links)
            TVOSNavButton(
                icon: "chevron.left",
                label: "Zurück",
                isEnabled: true
            ) {
                onBack()
            }
            
            // URL/Titel-Anzeige (Mittig, nimmt verfügbaren Platz ein)
            SafariURLBar(
                urlString: urlString,
                pageTitle: pageTitle.isEmpty ? "Laden..." : pageTitle
            )
            .frame(maxWidth: .infinity)
            
            // Navigations-Buttons (Rechts) - Vor/Zurück, Reload, Einstellungen
            HStack(spacing: 16) {
                // Browser Zurück-Button
                TVOSNavIconButton(
                    icon: "arrow.left",
                    isEnabled: canGoBack
                ) {
                    webViewController.goBack()
                }
                
                // Browser Vorwärts-Button
                TVOSNavIconButton(
                    icon: "arrow.right",
                    isEnabled: canGoForward
                ) {
                    webViewController.goForward()
                }
                
                // Reload/Stop Button (wechselt Icon je nach Loading-Status)
                TVOSNavIconButton(
                    icon: isLoading ? "xmark" : "arrow.clockwise",
                    isEnabled: true
                ) {
                    webViewController.reload()
                }
                
                // Einstellungen-Button
                TVOSNavIconButton(
                    icon: "gearshape.fill",
                    isEnabled: true
                ) {
                    onShowSettings()
                }
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
    }
    
    private var helpHint: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 22))
                Text("Pfeile/Wischen: Scrollen")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Image(systemName: "playpause.fill")
                    .font(.system(size: 22))
                Text("Play/Pause: Leiste ein/aus")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
            }
        }
        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
        .padding(.horizontal, TVOSDesign.Spacing.cardSpacing)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TVOSDesign.Colors.secondaryBackground.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    private var loadingIndicator: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0)
                Text("Laden...")
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(TVOSDesign.Colors.secondaryBackground.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.4), radius: 25, y: 10)
            )
            Spacer()
        }
    }
}

// MARK: - tvOS Navigation Button Components

struct TVOSNavButton: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var hoverScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
            }
            .foregroundColor(isEnabled ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.tertiaryLabel)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 2.5)
            )
            .scaleEffect(isPressed ? 0.94 : (isFocused ? 1.06 : hoverScale))
            .shadow(
                color: isFocused ? Color.white.opacity(0.35) : Color.black.opacity(0.2),
                radius: isFocused ? 20 : 8,
                y: isFocused ? 8 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .disabled(!isEnabled)
        .onChange(of: isFocused) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                hoverScale = newValue ? 1.0 : 1.0
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
    }
}

struct TVOSNavIconButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isEnabled ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.tertiaryLabel)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
                )
                .overlay(
                    Circle()
                        .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 2.5)
                )
                .scaleEffect(isPressed ? 0.92 : (isFocused ? 1.08 : 1.0))
                .shadow(
                    color: isFocused ? Color.white.opacity(0.35) : Color.black.opacity(0.15),
                    radius: isFocused ? 16 : 6,
                    y: isFocused ? 6 : 3
                )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .disabled(!isEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
    }
}

// MARK: - WebView Scroll Controller

class WebViewScrollController: ObservableObject {
    weak var webView: UIView?
    weak var hostController: WebViewHostController?
    
    func smoothScroll(by offset: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else { return }
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                let scrollJS = """
                    const currentY = window.pageYOffset;
                    const targetY = currentY + \(Int(offset));
                    window.scrollTo({
                        top: targetY,
                        behavior: 'smooth'
                    });
                    true;
                """
                _ = webView.perform(jsSelector, with: scrollJS)
            }
        }
    }
    
    func scroll(by offset: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else { return }
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                let scrollJS = "window.scrollBy(0, \(Int(offset))); true;"
                _ = webView.perform(jsSelector, with: scrollJS)
            }
        }
    }
    
    func goBack() {
        guard let webView = webView else { return }
        let selector = NSSelectorFromString("goBack")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func goForward() {
        guard let webView = webView else { return }
        let selector = NSSelectorFromString("goForward")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func reload() {
        guard let webView = webView else { return }
        let selector = NSSelectorFromString("reload")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
}

// MARK: - WebView Container

struct WebViewContainer: UIViewControllerRepresentable {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String
    @Binding var showNavigationBar: Bool
    
    var scrollController: WebViewScrollController
    var onMenuPress: (() -> Void)?
    var onPlayPause: (() -> Void)?
    
    func makeUIViewController(context: Context) -> WebViewHostController {
        let controller = WebViewHostController()
        controller.delegate = context.coordinator
        controller.scrollController = scrollController
        controller.onMenuPress = onMenuPress
        controller.onPlayPause = onPlayPause
        scrollController.hostController = controller
        return controller
    }
    
    func updateUIViewController(_ controller: WebViewHostController, context: Context) {
        controller.onMenuPress = onMenuPress
        controller.onPlayPause = onPlayPause
        
        if !urlString.isEmpty && urlString != context.coordinator.currentURL {
            context.coordinator.currentURL = urlString
            controller.loadURL(urlString)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: WebViewContainer
        var currentURL: String = ""
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        func didStartLoading() {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func didFinishLoading(canGoBack: Bool, canGoForward: Bool, title: String, url: String) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = canGoBack
                self.parent.canGoForward = canGoForward
                self.parent.pageTitle = title
                self.parent.urlString = url
                self.currentURL = url
            }
        }
        
        func didFailLoading() {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

// MARK: - WebView Host Controller

class WebViewHostController: UIViewController {
    var webView: UIView?
    weak var delegate: WebViewContainer.Coordinator?
    weak var scrollController: WebViewScrollController?
    
    var onMenuPress: (() -> Void)?
    var onPlayPause: (() -> Void)?
    
    private var lastPanY: CGFloat = 0
    private var isPanning = false
    private var scrollTimer: Timer?
    private var currentScrollDirection: CGFloat = 0
    
    // MARK: - Scroll Configuration (SEHR LANGSAM)
    private let arrowScrollAmount: CGFloat = 25           // Sehr langsam bei Pfeiltasten
    private let continuousScrollAmount: CGFloat = 15      // Sehr langsam bei gehaltenem Pfeil
    private let panScrollMultiplier: CGFloat = 1.5        // Sehr langsam beim Wischen
    private let momentumMultiplier: CGFloat = 0.05        // Minimaler Momentum-Effekt
    private let continuousScrollInterval: TimeInterval = 0.08
    private let remoteButtonScrollAmount: CGFloat = 40    // Scroll bei Remote-Tasten
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupWebView()
        setupGestures()
        setupRemoteCommandCenter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
        teardownRemoteCommandCenter()
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView?.frame = view.bounds
    }
    
    // MARK: - WebView Setup
    
    private func setupWebView() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setupWebView()
            }
            return
        }
        
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            return
        }
        
        UserDefaults.standard.register(defaults: [
            "UserAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        ])
        
        let webView = webViewClass.init()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.isUserInteractionEnabled = false
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(webView)
        self.webView = webView
        scrollController?.webView = webView
        
        webView.setValue(self, forKey: "delegate")
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
            scrollView.backgroundColor = .clear
            scrollView.isOpaque = false
            
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
    }
    
    // MARK: - MPRemoteCommandCenter Setup
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.scrollController?.smoothScroll(by: self?.remoteButtonScrollAmount ?? 40)
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.scrollController?.smoothScroll(by: -(self?.remoteButtonScrollAmount ?? 40))
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Web Browser"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "AppleTVBrowser"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func teardownRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Gesture Setup
    
    private func setupGestures() {
        // Pan gesture for touchpad (Siri Remote 1 & 2)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(pan)
        
        // Tap for select button
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(tap)
        
        // Play/Pause button
        let playPause = UITapGestureRecognizer(target: self, action: #selector(handlePlayPause))
        playPause.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPause)
        
        // Menu button
        let menuTap = UITapGestureRecognizer(target: self, action: #selector(handleMenuPress))
        menuTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(menuTap)
        
        // Swipe gestures for Siri Remote 2 Click-Pad edges
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        swipeUp.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        swipeDown.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(swipeDown)
    }
    
    @objc private func handleMenuPress() {
        DispatchQueue.main.async { [weak self] in
            self?.onMenuPress?()
        }
    }
    
    @objc private func handleSwipeUp() {
        scrollController?.smoothScroll(by: -remoteButtonScrollAmount)
    }
    
    @objc private func handleSwipeDown() {
        scrollController?.smoothScroll(by: remoteButtonScrollAmount)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            lastPanY = 0
            isPanning = true
            
        case .changed:
            let deltaY = translation.y - lastPanY
            lastPanY = translation.y
            
            let scrollAmount = -deltaY * panScrollMultiplier
            
            if abs(scrollAmount) < 15 {
                scrollController?.smoothScroll(by: scrollAmount)
            } else {
                scrollController?.scroll(by: scrollAmount)
            }
            
        case .ended:
            isPanning = false
            lastPanY = 0
            
            let momentumY = -velocity.y * momentumMultiplier
            if abs(momentumY) > 5 {
                scrollController?.smoothScroll(by: min(max(momentumY, -50), 50))
            }
            
        case .cancelled:
            isPanning = false
            lastPanY = 0
            
        default:
            break
        }
    }
    
    @objc private func handleTap() {
        // Select button tap - könnte für Interaktion verwendet werden
    }
    
    @objc private func handlePlayPause() {
        DispatchQueue.main.async { [weak self] in
            self?.onPlayPause?()
        }
    }
    
    // MARK: - Press Handling (D-Pad und Siri Remote 2 Click-Pad)
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            switch press.type {
            case .menu:
                DispatchQueue.main.async { [weak self] in
                    self?.onMenuPress?()
                }
                handled = true
                
            case .upArrow:
                startSmoothContinuousScroll(direction: -arrowScrollAmount)
                handled = true
                
            case .downArrow:
                startSmoothContinuousScroll(direction: arrowScrollAmount)
                handled = true
                
            case .leftArrow:
                // Optional: Horizontal scrollen oder andere Aktion
                handled = true
                
            case .rightArrow:
                // Optional: Horizontal scrollen oder andere Aktion
                handled = true
                
            case .playPause:
                onPlayPause?()
                handled = true
                
            case .select:
                // Click auf dem Click-Pad - könnte für Interaktion verwendet werden
                handled = true
                
            case .pageUp:
                // Siri Remote 2: Seite hoch
                scrollController?.smoothScroll(by: -remoteButtonScrollAmount * 3)
                handled = true
                
            case .pageDown:
                // Siri Remote 2: Seite runter
                scrollController?.smoothScroll(by: remoteButtonScrollAmount * 3)
                handled = true
                
            default:
                break
            }
        }
        
        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .upArrow, .downArrow, .leftArrow, .rightArrow:
                stopContinuousScroll()
            default:
                break
            }
        }
        super.pressesEnded(presses, with: event)
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        stopContinuousScroll()
        super.pressesCancelled(presses, with: event)
    }
    
    private func startSmoothContinuousScroll(direction: CGFloat) {
        currentScrollDirection = direction
        scrollController?.smoothScroll(by: direction)
        
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: continuousScrollInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.scrollController?.smoothScroll(by: self.continuousScrollAmount * (self.currentScrollDirection > 0 ? 1 : -1))
        }
    }
    
    private func stopContinuousScroll() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        currentScrollDirection = 0
    }
    
    // MARK: - URL Loading
    
    func loadURL(_ urlString: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.loadURL(urlString)
            }
            return
        }
        
        guard let webView = webView,
              let url = URL(string: urlString) else { return }
        
        let request = URLRequest(url: url)
        let selector = NSSelectorFromString("loadRequest:")
        if webView.responds(to: selector) {
            webView.perform(selector, with: request)
        }
    }
    
    // MARK: - UIWebView Delegate
    
    @objc func webViewDidStartLoad(_ webView: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didStartLoading()
        }
    }
    
    @objc func webViewDidFinishLoad(_ webView: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var canGoBack = false
            var canGoForward = false
            var title = ""
            var currentURL = ""
            
            if let back = webView.value(forKey: "canGoBack") as? Bool {
                canGoBack = back
            }
            if let forward = webView.value(forKey: "canGoForward") as? Bool {
                canGoForward = forward
            }
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                if let t = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                    title = t
                }
            }
            
            if let request = webView.value(forKey: "request") as? URLRequest,
               let url = request.url {
                currentURL = url.absoluteString
            }
            
            // Layer-Hintergrund explizit transparent setzen
            if let layer = webView.value(forKey: "layer") as? CALayer {
                layer.backgroundColor = UIColor.clear.cgColor
            }
            
            // Viewport und Zoom nach kurzer Verzögerung anwenden
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.executeJavaScript(webView, script: self.viewportAndZoomJavaScript)
                print("📐 Viewport und Zoom für ScrollMode angewendet")
            }
            
            self.scrollController?.webView = webView
            self.delegate?.didFinishLoading(canGoBack: canGoBack, canGoForward: canGoForward, title: title, url: currentURL)
        }
    }
    
    @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didFailLoading()
        }
    }
    
    @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
        return true
    }
    
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
            
            console.log('📐 Viewport und Zoom für ScrollMode angepasst');
            return 'viewport_set';
        })();
        """
    }
    
    private func executeJavaScript(_ webView: UIView, script: String) {
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            _ = webView.perform(jsSelector, with: script)
        }
    }
}

// MARK: - Safari-Style URL Bar Component

struct SafariURLBar: View {
    let urlString: String
    let pageTitle: String
    let isCursorMode: Bool
    
    @FocusState private var isFocused: Bool
    @State private var showTitle: Bool = false
    @State private var contentOpacity: Double = 1.0
    
    init(urlString: String, pageTitle: String, isCursorMode: Bool = false) {
        self.urlString = urlString
        self.pageTitle = pageTitle
        self.isCursorMode = isCursorMode
    }
    
    private var isSecure: Bool {
        urlString.hasPrefix("https://")
    }
    
    private var displayURL: String {
        extractDomain(from: urlString)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                contentOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showTitle.toggle()
                withAnimation(.easeInOut(duration: 0.3)) {
                    contentOpacity = 1.0
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSecure ? "lock.fill" : "lock.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSecure ? TVOSDesign.Colors.systemGreen : TVOSDesign.Colors.tertiaryLabel)
                    .animation(.easeInOut(duration: 0.3), value: isSecure)
                
                Text(showTitle ? pageTitle : displayURL)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .opacity(contentOpacity)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)
            .background(
                Capsule()
                    .fill(
                        isFocused 
                        ? TVOSDesign.Colors.focusedCardBackground
                        : Color.white.opacity(0.15)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isFocused ? Color.white.opacity(0.8) : Color.clear,
                        lineWidth: 2
                    )
                    .padding(1)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(
                color: isFocused ? Color.white.opacity(0.3) : Color.black.opacity(0.2),
                radius: isFocused ? 12 : 8,
                y: isFocused ? 6 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2), value: isFocused)
        .onAppear {
            if !pageTitle.isEmpty && pageTitle != "Laden..." {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        contentOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showTitle = true
                        withAnimation(.easeInOut(duration: 0.4)) {
                            contentOpacity = 1.0
                        }
                    }
                }
            }
        }
        .onChange(of: pageTitle) { _, newTitle in
            if !newTitle.isEmpty && newTitle != "Laden..." && !showTitle {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        contentOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showTitle = true
                        withAnimation(.easeInOut(duration: 0.4)) {
                            contentOpacity = 1.0
                        }
                    }
                }
            }
        }
    }
    
    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return urlString
        }
        
        var host = url.host ?? urlString
        
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        return host
    }
}

// MARK: - Wrapper für SessionManager Integration
struct FullscreenWebViewWithSession: View {
    let url: String
    let title: String
    let sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    var body: some View {
        FullscreenWebView(
            url: url,
            title: title,
            isPresented: $isPresented
        )
        .environmentObject(sessionManager)
    }
}

#Preview {
    FullscreenWebView(
        url: "https://www.example.com",
        title: "Example",
        isPresented: .constant(true)
    )
}
