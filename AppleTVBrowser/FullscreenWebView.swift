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
                    // Menü-Button: Wenn wir im WebView zurück gehen können, gehe zurück
                    // Sonst wird die View automatisch durch fullScreenCover geschlossen
                    if canGoBack {
                        print("🔙 WebView goBack (canGoBack=true)")
                        webViewController.goBack()
                    } else {
                        print("🚪 Schließe WebView (canGoBack=false)")
                        dismiss()
                    }
                },
                onPlayPause: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showNavigationBar.toggle()
                    }
                }
            )
            .padding(.top, showNavigationBar ? 100 : 0)
            .ignoresSafeArea(edges: showNavigationBar ? [.bottom, .leading, .trailing] : .all)
            
            // Navigationsleiste oben
            if showNavigationBar {
                navigationBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Loading indicator
            if isLoading {
                loadingIndicator
            }
            
            // Hilfe-Hinweis
            if showNavigationBar {
                VStack {
                    Spacer()
                    helpHint
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            urlString = url
            pageTitle = title.isEmpty ? url : title
        }
        .animation(.easeInOut(duration: 0.3), value: showNavigationBar)
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Zurück")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pageTitle.isEmpty ? "Laden..." : pageTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(urlString)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                Button(action: { webViewController.goBack() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(canGoBack ? .white : .gray)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(canGoBack ? 0.2 : 0.1)))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canGoBack)
                
                Button(action: { webViewController.goForward() }) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(canGoForward ? .white : .gray)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(canGoForward ? 0.2 : 0.1)))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canGoForward)
                
                Button(action: { webViewController.reload() }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .top)
        )
    }
    
    private var helpHint: some View {
        HStack(spacing: 16) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 20))
            Text("Pfeile/Wischen: Scrollen")
                .font(.system(size: 18, weight: .medium))
            
            Spacer()
            
            Image(systemName: "playpause")
                .font(.system(size: 20))
            Text("Play/Pause: Leiste ein/aus")
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
        )
        .padding(.horizontal, 40)
    }
    
    private var loadingIndicator: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("Laden...")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .medium))
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
            Spacer()
        }
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

#Preview {
    FullscreenWebView(
        url: "https://www.example.com",
        title: "Example",
        isPresented: .constant(true)
    )
}