//
//  FullscreenWebView.swift
//  AppleTVBrowser
//
//  Vollbild-WebView für tvOS mit MPRemoteCommandCenter
//

import SwiftUI
import Combine
import MediaPlayer

struct FullscreenWebView: View {
    let url: String
    let title: String
    @Binding var isPresented: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var pageTitle: String = ""
    @State private var showNavigationBar: Bool = true
    @State private var showHelpHint: Bool = true
    
    // Animationswerte für sanftes Verschwinden
    @State private var helpHintOpacity: Double = 1.0
    @State private var helpHintOffset: CGFloat = 0
    @State private var helpHintScaleX: CGFloat = 1.0
    @State private var helpHintScaleY: CGFloat = 1.0
    @State private var helpHintBlur: CGFloat = 0
    
    // Shared WebView Controller
    @StateObject private var webViewController = WebViewScrollController()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()
            
            // WebView mit direktem Scroll-Handling
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
                        print("🔙 WebView goBack (canGoBack=true)")
                        webViewController.goBack()
                    } else {
                        print("🚪 Schließe WebView (canGoBack=false)")
                        dismiss()
                    }
                },
                onPlayPause: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)) {
                        showNavigationBar.toggle()
                    }
                }
            )
            .padding(.top, showNavigationBar ? 100 : 0)
            .ignoresSafeArea(edges: showNavigationBar ? [.bottom, .leading, .trailing] : .all)
            
            // Navigationsleiste oben
            if showNavigationBar {
                navigationBar
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                            removal: .move(edge: .top).combined(with: .opacity).animation(.easeOut(duration: 0.4))
                        )
                    )
            }
            
            // Loading indicator
            if isLoading {
                loadingIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.9)).animation(.spring(response: 0.4, dampingFraction: 0.7)))
            }
            
            // Hilfe-Hinweis mit weichem Verschwinde-Effekt
            if showNavigationBar && showHelpHint {
                VStack {
                    Spacer()
                    helpHint
                        .opacity(helpHintOpacity)
                        .offset(y: helpHintOffset)
                        .scaleEffect(x: helpHintScaleX, y: helpHintScaleY)
                        .blur(radius: helpHintBlur)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            urlString = url
            pageTitle = title.isEmpty ? url : title
            
            // Sanftes Verschwinden des Hilfe-Hinweises starten
            startSmoothHelpHintFadeOut()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNavigationBar)
    }
    
    // MARK: - Smooth Help Hint Fade Out Animation
    
    private func startSmoothHelpHintFadeOut() {
        // Phase 1: Nach 5 Sekunden - sanftes Dimmen beginnt
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut(duration: 2.5)) {
                helpHintOpacity = 0.7
            }
        }
        
        // Phase 2: Nach 7 Sekunden - weiter dimmen, leichter Blur
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            withAnimation(.easeInOut(duration: 2.0)) {
                helpHintOpacity = 0.5
                helpHintBlur = 1
            }
        }
        
        // Phase 3: Nach 9 Sekunden - horizontal zusammenziehen beginnt
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            withAnimation(.easeInOut(duration: 1.5)) {
                helpHintOpacity = 0.3
                helpHintScaleX = 0.85
                helpHintBlur = 3
            }
        }
        
        // Phase 4: Nach 10.5 Sekunden - stark zusammenziehen + nach unten gleiten
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                helpHintOpacity = 0.1
                helpHintScaleX = 0.4
                helpHintScaleY = 0.6
                helpHintOffset = 60
                helpHintBlur = 8
            }
        }
        
        // Phase 5: Nach 12 Sekunden - komplett verschwinden (zu einem Punkt)
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            withAnimation(.easeOut(duration: 0.6)) {
                helpHintOpacity = 0
                helpHintScaleX = 0.1
                helpHintScaleY = 0.2
                helpHintOffset = 80
                helpHintBlur = 15
            }
            
            // View entfernen nach Animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showHelpHint = false
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button mit tvOS Focus Style
            TVOSNavButton(
                icon: "chevron.left",
                label: "Zurück",
                isEnabled: true
            ) {
                dismiss()
            }
            
            // Safari-Style URL Bar (zentriert)
            SafariURLBar(
                urlString: urlString,
                pageTitle: pageTitle.isEmpty ? "Laden..." : pageTitle
            )
            .frame(maxWidth: .infinity)
            
            // Navigation Controls
            HStack(spacing: 16) {
                TVOSNavIconButton(
                    icon: "arrow.left",
                    isEnabled: canGoBack
                ) {
                    webViewController.goBack()
                }
                
                TVOSNavIconButton(
                    icon: "arrow.right",
                    isEnabled: canGoForward
                ) {
                    webViewController.goForward()
                }
                
                TVOSNavIconButton(
                    icon: isLoading ? "xmark" : "arrow.clockwise",
                    isEnabled: true
                ) {
                    webViewController.reload()
                }
            }
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    TVOSDesign.Colors.background.opacity(0.98),
                    TVOSDesign.Colors.background.opacity(0.9),
                    TVOSDesign.Colors.background.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .top)
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

// MARK: - Smooth Animation Constants

private enum SmoothAnimation {
    // Weiche, natürliche Spring-Animationen
    static let focusSpring = Animation.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2)
    static let pressSpring = Animation.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0.1)
    static let hoverSpring = Animation.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.15)
    
    // Geschmeidige Ease-Kurven
    static let smoothEase = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.4)
    static let gentleEase = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.5)
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
            
            // Geschmeidigere Press-Animation
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
    
    func scroll(by offset: CGFloat) {
        // JavaScript-basiertes Scrollen
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else {
                print("❌ WebView nicht verfügbar für Scroll")
                return
            }
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                let scrollJS = "window.scrollBy(0, \(Int(offset))); true;"
                _ = webView.perform(jsSelector, with: scrollJS)
                print("📜 JS Scroll: \(Int(offset))px")
            } else {
                print("❌ JavaScript nicht verfügbar")
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
    
    // Pan tracking
    private var lastPanY: CGFloat = 0
    private var isPanning = false
    
    // Scroll-Timer für kontinuierliches Scrollen
    private var scrollTimer: Timer?
    private var currentScrollDirection: CGFloat = 0
    
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
        print("🎮 Remote Control Events aktiviert")
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
            print("❌ UIWebView nicht verfügbar")
            return
        }
        
        UserDefaults.standard.register(defaults: [
            "UserAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        ])
        
        let webView = webViewClass.init()
        webView.backgroundColor = .black
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
            if #available(tvOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        
        print("✅ WebView erstellt")
    }
    
    // MARK: - MPRemoteCommandCenter Setup
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Skip Forward = Scroll Down
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            print("⏩ Skip Forward -> Scroll Down")
            self?.scrollController?.scroll(by: 300)
            return .success
        }
        
        // Skip Backward = Scroll Up
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            print("⏪ Skip Backward -> Scroll Up")
            self?.scrollController?.scroll(by: -300)
            return .success
        }
        
        // Play/Pause = Toggle Navigation Bar
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            print("⏯️ Toggle Play/Pause -> Navigation Toggle")
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        // Play = auch für Navigation
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            print("▶️ Play -> Navigation Toggle")
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        // Pause = auch für Navigation
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            print("⏸️ Pause -> Navigation Toggle")
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
            return .success
        }
        
        // Now Playing Info setzen (notwendig für Remote Commands)
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Web Browser"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "AppleTVBrowser"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        print("✅ MPRemoteCommandCenter eingerichtet")
    }
    
    private func teardownRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        print("🛑 MPRemoteCommandCenter deaktiviert")
    }
    
    // MARK: - Gesture Setup (zusätzlich zu Remote Commands)
    
    private func setupGestures() {
        // Pan gesture for touchpad
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(pan)
        
        // Tap for select button
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(tap)
        
        // Play/Pause button (als Backup)
        let playPause = UITapGestureRecognizer(target: self, action: #selector(handlePlayPause))
        playPause.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPause)
        
        // Menu button - WICHTIG: Eigene Geste für Menü-Taste
        let menuTap = UITapGestureRecognizer(target: self, action: #selector(handleMenuPress))
        menuTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(menuTap)
        
        print("✅ Gestures eingerichtet")
    }
    
    @objc private func handleMenuPress() {
        print("📱 Menü-Taste gedrückt (Gesture)")
        DispatchQueue.main.async { [weak self] in
            self?.onMenuPress?()
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            print("🖐️ Pan began")
            lastPanY = 0
            isPanning = true
            
        case .changed:
            let deltaY = translation.y - lastPanY
            lastPanY = translation.y
            let scrollAmount = -deltaY * 15.0
            scrollController?.scroll(by: scrollAmount)
            
        case .ended, .cancelled:
            print("🖐️ Pan ended")
            isPanning = false
            lastPanY = 0
            
        default:
            break
        }
    }
    
    @objc private func handleTap() {
        print("👆 Tap")
    }
    
    @objc private func handlePlayPause() {
        print("⏯️ Play/Pause (Gesture)")
        DispatchQueue.main.async { [weak self] in
            self?.onPlayPause?()
        }
    }
    
    // MARK: - Press Handling (D-Pad) mit Timer für kontinuierliches Scrollen
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            switch press.type {
            case .menu:
                print("📱 Menü-Taste gedrückt (pressesBegan)")
                DispatchQueue.main.async { [weak self] in
                    self?.onMenuPress?()
                }
                handled = true
                
            case .upArrow:
                print("⬆️ Up Arrow gedrückt")
                startContinuousScroll(direction: -200)
                handled = true
                
            case .downArrow:
                print("⬇️ Down Arrow gedrückt")
                startContinuousScroll(direction: 200)
                handled = true
                
            case .playPause:
                onPlayPause?()
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
            case .upArrow, .downArrow:
                print("🛑 Arrow released")
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
    
    private func startContinuousScroll(direction: CGFloat) {
        currentScrollDirection = direction
        // Sofort scrollen
        scrollController?.scroll(by: direction)
        
        // Timer für kontinuierliches Scrollen
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.scrollController?.scroll(by: self.currentScrollDirection)
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
            print("🌐 Lade: \(urlString)")
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
            
            self.scrollController?.webView = webView
            self.delegate?.didFinishLoading(canGoBack: canGoBack, canGoForward: canGoForward, title: title, url: currentURL)
            print("✅ Seite geladen: \(title)")
        }
    }
    
    @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didFailLoading()
            print("❌ Fehler: \(error.localizedDescription)")
        }
    }
    
    @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
        return true
    }
}

// MARK: - Safari-Style URL Bar Component

struct SafariURLBar: View {
    let urlString: String
    let pageTitle: String
    
    @FocusState private var isFocused: Bool
    @State private var showTitle: Bool = false
    @State private var contentOpacity: Double = 1.0
    
    private var isSecure: Bool {
        urlString.hasPrefix("https://")
    }
    
    private var displayURL: String {
        extractDomain(from: urlString)
    }
    
    var body: some View {
        Button(action: {
            // Sanfter Crossfade zwischen URL und Titel
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
                // Sicherheits-Icon (grün für HTTPS) mit sanfter Animation
                Image(systemName: isSecure ? "lock.fill" : "lock.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSecure ? TVOSDesign.Colors.systemGreen : TVOSDesign.Colors.tertiaryLabel)
                    .animation(.easeInOut(duration: 0.3), value: isSecure)
                
                // URL oder Titel (umschaltbar) mit Crossfade
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
                // Safari-Style Kapsel mit sanftem Übergang
                Capsule()
                    .fill(
                        isFocused 
                        ? TVOSDesign.Colors.focusedCardBackground
                        : Color.white.opacity(0.15)
                    )
            )
            .overlay(
                // Focus-Rahmen (reduziert)
                Capsule()
                    .stroke(
                        isFocused ? Color.white.opacity(0.8) : Color.clear,
                        lineWidth: 2
                    )
                    .padding(1) // Inset um Überlappung zu vermeiden
            )
            .scaleEffect(isFocused ? 1.05 : 1.0) // Reduzierte Skalierung
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
            // Sanfter automatischer Wechsel zum Titel
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
            // Wenn Titel sich ändert (z.B. nach Laden), sanft aktualisieren
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
    
    // MARK: - Helper Functions
    
    /// Extrahiert Domain aus URL String (ohne www. und Protokoll)
    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return urlString
        }
        
        var host = url.host ?? urlString
        
        // Entferne www. Präfix
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        return host
    }
}

#Preview {
    ZStack {
        TVOSDesign.Colors.background.ignoresSafeArea()
        
        VStack(spacing: 40) {
            // HTTPS Beispiel
            SafariURLBar(
                urlString: "https://www.apple.com/de/tv-home/",
                pageTitle: "Apple TV - Apple (DE)"
            )
            
            // HTTP Beispiel (unsicher)
            SafariURLBar(
                urlString: "http://example.com/test",
                pageTitle: "Test Page"
            )
            
            // Laden-Status
            SafariURLBar(
                urlString: "https://www.google.com",
                pageTitle: "Laden..."
            )
        }
        .padding()
    }
}

#Preview("Original WebView") {
    FullscreenWebView(
        url: "https://www.example.com",
        title: "Example",
        isPresented: .constant(true)
    )
}
