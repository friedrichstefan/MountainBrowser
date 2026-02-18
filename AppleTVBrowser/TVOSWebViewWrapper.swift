//
//  TVOSWebViewWrapper.swift
//  AppleTVBrowser
//
//  UIWebView Wrapper für tvOS - KEIN WebKit (nicht verfügbar auf tvOS)!
//

import SwiftUI
import UIKit
import Combine

/// UIViewControllerRepresentable Wrapper für UIWebView auf tvOS
struct TVOSWebViewWrapper: UIViewControllerRepresentable {
    
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String
    
    var onNavigationChange: ((String) -> Void)?
    var onPan: ((CGPoint) -> Void)?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    var onMenuPress: (() -> Void)?
    
    @ObservedObject var webViewController: TVOSWebViewController
    
    func makeUIViewController(context: Context) -> TVOSWebViewHostController {
        let controller = TVOSWebViewHostController()
        controller.coordinator = context.coordinator
        controller.onPan = onPan
        controller.onTap = onTap
        controller.onDoubleTap = onDoubleTap
        controller.onMenuPress = onMenuPress
        controller.externalWebViewController = webViewController
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: TVOSWebViewHostController, context: Context) {
        uiViewController.onPan = onPan
        uiViewController.onTap = onTap
        uiViewController.onDoubleTap = onDoubleTap
        uiViewController.onMenuPress = onMenuPress
        
        if let webView = uiViewController.webView {
            if webViewController.webView !== webView {
                webViewController.webView = webView
            }
        }
        
        if !urlString.isEmpty && urlString != context.coordinator.currentURL {
            context.coordinator.currentURL = urlString
            uiViewController.loadURL(urlString)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: TVOSWebViewWrapper
        var currentURL: String = ""
        
        init(_ parent: TVOSWebViewWrapper) {
            self.parent = parent
        }
        
        func webViewDidStartLoad() {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webViewDidFinishLoad(canGoBack: Bool, canGoForward: Bool, pageTitle: String, currentURL: String) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = canGoBack
                self.parent.canGoForward = canGoForward
                self.parent.pageTitle = pageTitle
                self.parent.urlString = currentURL
                self.parent.onNavigationChange?(currentURL)
            }
        }
        
        func webViewDidFail(error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

// MARK: - TVOSWebViewHostController

class TVOSWebViewHostController: UIViewController {
    
    var webView: UIView?
    var coordinator: TVOSWebViewWrapper.Coordinator?
    weak var externalWebViewController: TVOSWebViewController?
    
    var onPan: ((CGPoint) -> Void)?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    var onMenuPress: (() -> Void)?
    
    // Für inkrementelles Pan-Tracking
    private var lastPanTranslation: CGPoint = .zero
    private var moveTimer: Timer?
    private var currentDirection: CGPoint = .zero
    
    // Scroll-Geschwindigkeit - kleinerer Wert = langsameres Scrollen
    private let scrollSpeed: CGFloat = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        
        if #available(tvOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        }
        
        setupWebView()
        setupGestureRecognizers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = becomeFirstResponder()
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView?.frame = view.bounds
    }
    
    override var canBecomeFirstResponder: Bool { true }
    
    // MARK: - Setup
    
    private func setupGestureRecognizers() {
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
        
        // Pan-Geste für Touchpad
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(panRecognizer)
        
        // Tap für Select-Taste
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
        
        // Play/Pause
        let playPauseRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePlayPauseGesture))
        playPauseRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPauseRecognizer)
    }
    
    // MARK: - Pan Gesture (KORRIGIERT)
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            // Reset beim Start der Geste
            lastPanTranslation = .zero
            
        case .changed:
            // Aktuelle Translation seit Gestenbeginn
            let currentTranslation = recognizer.translation(in: view)
            
            // Berechne die DIFFERENZ seit dem letzten Update
            let deltaX = currentTranslation.x - lastPanTranslation.x
            let deltaY = currentTranslation.y - lastPanTranslation.y
            
            // Speichere für nächstes Update
            lastPanTranslation = currentTranslation
            
            // Skaliere die Bewegung
            let scaledDelta = CGPoint(
                x: deltaX * scrollSpeed,
                y: deltaY * scrollSpeed
            )
            
            // Nur bei tatsächlicher Bewegung
            if abs(scaledDelta.x) > 0.1 || abs(scaledDelta.y) > 0.1 {
                onPan?(scaledDelta)
            }
            
        case .ended:
            // Momentum-Scroll bei schneller Bewegung
            let velocity = recognizer.velocity(in: view)
            if abs(velocity.y) > 100 {
                NotificationCenter.default.post(
                    name: NSNotification.Name("StartMomentumScroll"),
                    object: nil,
                    userInfo: ["velocityY": velocity.y * 0.05]
                )
            }
            lastPanTranslation = .zero
            
        case .cancelled, .failed:
            lastPanTranslation = .zero
            
        default:
            break
        }
    }
    
    @objc private func handleTapGesture() {
        onTap?()
    }
    
    @objc private func handlePlayPauseGesture() {
        onDoubleTap?()
    }
    
    // MARK: - WebView Setup
    
    private func setupWebView() {
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("⚠️ UIWebView nicht verfügbar!")
            return
        }
        
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        UserDefaults.standard.register(defaults: ["UserAgent": userAgent])
        
        let webView = webViewClass.init()
        webView.backgroundColor = .black
        webView.isUserInteractionEnabled = false
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.frame = view.bounds
        
        view.addSubview(webView)
        self.webView = webView
        externalWebViewController?.webView = webView
        
        webView.setValue(self, forKey: "delegate")
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
            if #available(tvOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
    }
    
    func loadURL(_ urlString: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.loadURL(urlString)
            }
            return
        }
        
        guard let webView = webView, let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        let loadRequestSelector = NSSelectorFromString("loadRequest:")
        if webView.responds(to: loadRequestSelector) {
            webView.perform(loadRequestSelector, with: request)
        }
    }
    
    // MARK: - Press Handling (Pfeiltasten)
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .select:
                onTap?()
            case .playPause:
                onDoubleTap?()
            case .menu:
                if let menuHandler = onMenuPress {
                    menuHandler()
                } else {
                    super.pressesBegan(presses, with: event)
                }
            case .upArrow:
                startContinuousScroll(direction: CGPoint(x: 0, y: -20))
            case .downArrow:
                startContinuousScroll(direction: CGPoint(x: 0, y: 20))
            case .leftArrow:
                startContinuousScroll(direction: CGPoint(x: -20, y: 0))
            case .rightArrow:
                startContinuousScroll(direction: CGPoint(x: 20, y: 0))
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .upArrow, .downArrow, .leftArrow, .rightArrow:
                stopContinuousScroll()
            default:
                super.pressesEnded(presses, with: event)
            }
        }
    }
    
    private func startContinuousScroll(direction: CGPoint) {
        currentDirection = direction
        onPan?(direction)
        
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.onPan?(self.currentDirection)
        }
    }
    
    private func stopContinuousScroll() {
        moveTimer?.invalidate()
        moveTimer = nil
        currentDirection = .zero
    }
    
    // MARK: - UIWebViewDelegate
    
    @objc func webViewDidStartLoad(_ webView: UIView) {
        coordinator?.webViewDidStartLoad()
    }
    
    @objc func webViewDidFinishLoad(_ webView: UIView) {
        var canGoBack = false
        var canGoForward = false
        var pageTitle = ""
        var currentURL = ""
        
        if let back = webView.value(forKey: "canGoBack") as? Bool { canGoBack = back }
        if let forward = webView.value(forKey: "canGoForward") as? Bool { canGoForward = forward }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                pageTitle = title
            }
        }
        
        if let request = webView.value(forKey: "request") as? URLRequest, let url = request.url {
            currentURL = url.absoluteString
        }
        
        externalWebViewController?.webView = webView
        coordinator?.webViewDidFinishLoad(canGoBack: canGoBack, canGoForward: canGoForward, pageTitle: pageTitle, currentURL: currentURL)
    }
    
    @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
        coordinator?.webViewDidFail(error: error)
    }
    
    @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
        return true
    }
}

// MARK: - TVOSWebViewController

class TVOSWebViewController: ObservableObject {
    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    
    var webView: UIView?
    
    private var displayLink: CADisplayLink?
    private var currentScrollVelocity: CGFloat = 0
    private let scrollDeceleration: CGFloat = 0.95
    private let minVelocityThreshold: CGFloat = 0.5
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMomentumScroll(_:)),
            name: NSNotification.Name("StartMomentumScroll"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMomentumScroll()
    }
    
    @objc private func handleMomentumScroll(_ notification: Notification) {
        guard let velocityY = notification.userInfo?["velocityY"] as? CGFloat else { return }
        startMomentumScroll(initialVelocity: velocityY)
    }
    
    private func startMomentumScroll(initialVelocity: CGFloat) {
        currentScrollVelocity = initialVelocity
        
        guard abs(currentScrollVelocity) > minVelocityThreshold else { return }
        
        stopMomentumScroll()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateMomentumScroll))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateMomentumScroll() {
        currentScrollVelocity *= scrollDeceleration
        
        if abs(currentScrollVelocity) < minVelocityThreshold {
            stopMomentumScroll()
            return
        }
        
        performScroll(by: currentScrollVelocity)
    }
    
    private func stopMomentumScroll() {
        displayLink?.invalidate()
        displayLink = nil
        currentScrollVelocity = 0
    }
    
    private func performScroll(by offset: CGFloat) {
        guard let webView = self.webView,
              let scrollView = webView.value(forKey: "scrollView") as? UIScrollView else {
            return
        }
        
        let currentOffset = scrollView.contentOffset
        let newY = currentOffset.y + offset
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedY = min(max(0, newY), maxY)
        
        // Bounce-Effekt am Rand
        if newY < 0 || newY > maxY {
            currentScrollVelocity *= 0.3
        }
        
        scrollView.contentOffset = CGPoint(x: currentOffset.x, y: clampedY)
    }
    
    /// Scrollt die WebView um den angegebenen Offset
    func scroll(by offset: CGFloat) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.scroll(by: offset)
            }
            return
        }
        
        guard let webView = self.webView,
              let scrollView = webView.value(forKey: "scrollView") as? UIScrollView else {
            return
        }
        
        // Stoppe laufendes Momentum-Scrolling
        stopMomentumScroll()
        
        let currentOffset = scrollView.contentOffset
        let newY = currentOffset.y + offset
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedY = min(max(0, newY), maxY)
        
        scrollView.contentOffset = CGPoint(x: currentOffset.x, y: clampedY)
    }
    
    func evaluateJavaScript(_ script: String) -> String? {
        guard let webView = self.webView else { return nil }
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else { return nil }
        return webView.perform(jsSelector, with: script)?.takeUnretainedValue() as? String
    }
}
