//
//  ScrollModeWebView.swift
//  MountainBrowser
//
//  Scroll-Modus WebView mit nativer tvOS Fokus-Navigation
//  Verwendet UIWebView mit aktiviertem ScrollView-Scrolling
//

import SwiftUI

struct ScrollModeWebView: View {
    @Binding var url: URL?
    @State private var isLoading: Bool = false
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var title: String = ""
    @State private var webViewRef: UIView?
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    let onBack: () -> Void
    var onPlayPause: (() -> Void)? = nil
    
    private var pageTitle: String {
        title.isEmpty ? "Laden..." : title
    }
    
    private var urlString: String {
        url?.absoluteString ?? ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                BrowserNavigationBar(
                    pageTitle: pageTitle,
                    urlString: urlString,
                    canGoBack: canGoBack,
                    canGoForward: canGoForward,
                    isLoading: isLoading,
                    modeBadge: .scrollMode
                )
                
                ScrollWebViewRepresentable(
                    url: $url,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    title: $title,
                    webViewRef: $webViewRef,
                    preferences: preferences,
                    onNavigationAction: onNavigationAction,
                    onPlayPause: onPlayPause
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipped()
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onExitCommand {
            handleBackNavigation()
        }
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
}

// MARK: - UIViewRepresentable für Scroll-Modus

struct ScrollWebViewRepresentable: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    @Binding var webViewRef: UIView?
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    var onPlayPause: (() -> Void)? = nil
    
    /// JavaScript das den internen UIWebView Video-Player verhindert.
    /// Der Crash passiert weil WebAVPlayerViewController auf tvOS nil-Objekte bekommt.
    private static let videoFullscreenPreventionJS = """
        (function() {
            var style = document.createElement('style');
            style.textContent = 'video::-webkit-media-controls-fullscreen-button { display: none !important; }';
            document.head.appendChild(style);
            
            document.addEventListener('webkitfullscreenchange', function(e) {
                if (document.webkitFullscreenElement && document.webkitFullscreenElement.tagName === 'VIDEO') {
                    try { document.webkitExitFullscreen(); } catch(err) {}
                }
            }, true);
            
            var origRequestFullscreen = Element.prototype.webkitRequestFullscreen;
            Element.prototype.webkitRequestFullscreen = function() {
                if (this.tagName === 'VIDEO') {
                    console.log('Video fullscreen blocked to prevent tvOS crash');
                    this.setAttribute('playsinline', '');
                    this.setAttribute('webkit-playsinline', '');
                    this.play();
                    return;
                }
                if (origRequestFullscreen) {
                    return origRequestFullscreen.apply(this, arguments);
                }
            };
            
            var videos = document.querySelectorAll('video');
            videos.forEach(function(v) {
                v.setAttribute('playsinline', '');
                v.setAttribute('webkit-playsinline', '');
            });
            
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'VIDEO') {
                            node.setAttribute('playsinline', '');
                            node.setAttribute('webkit-playsinline', '');
                        }
                        if (node.querySelectorAll) {
                            node.querySelectorAll('video').forEach(function(v) {
                                v.setAttribute('playsinline', '');
                                v.setAttribute('webkit-playsinline', '');
                            });
                        }
                    });
                });
            });
            observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
            
            return 'video_fullscreen_prevention_active';
        })();
    """
    
    func makeUIView(context: Context) -> ScrollWebViewContainer {
        let userAgent = preferences.userAgent.isEmpty
            ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15"
            : preferences.userAgent
        
        let dictionary = ["UserAgent": userAgent]
        UserDefaults.standard.register(defaults: dictionary)
        UserDefaults.standard.synchronize()
        
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            let container = ScrollWebViewContainer()
            container.backgroundColor = .black
            container.addSubview(createFallbackLabel())
            return container
        }
        
        let webView = webViewClass.init()
        
        let containerView = ScrollWebViewContainer()
        let coordinator = context.coordinator
        containerView.onPlayPause = { [weak coordinator] in
            coordinator?.parent.onPlayPause?()
        }
        containerView.backgroundColor = .black
        containerView.clipsToBounds = true
        containerView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.clipsToBounds = false
        webView.setValue(context.coordinator, forKey: "delegate")
        webView.layoutMargins = .zero
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.isUserInteractionEnabled = true
        
        configureWebViewMediaSettings(webView)
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.layoutMargins = .zero
            if #available(tvOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
            scrollView.contentOffset = .zero
            scrollView.contentInset = .zero
            scrollView.clipsToBounds = false
            
            scrollView.decelerationRate = .fast
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.alwaysBounceHorizontal = false
            scrollView.isDirectionalLockEnabled = true
            
            scrollView.isScrollEnabled = true
            scrollView.panGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
            scrollView.backgroundColor = .black
            scrollView.indicatorStyle = .white
            scrollView.showsVerticalScrollIndicator = true
            scrollView.showsHorizontalScrollIndicator = false
            
            context.coordinator.scrollView = scrollView
            scrollView.delegate = context.coordinator
            
            let playPauseTapOnScrollView = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
            playPauseTapOnScrollView.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
            scrollView.addGestureRecognizer(playPauseTapOnScrollView)
        }
        
        let playPauseTapOnWebView = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
        playPauseTapOnWebView.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        webView.addGestureRecognizer(playPauseTapOnWebView)
        
        let playPauseTapOnContainer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
        playPauseTapOnContainer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        containerView.addGestureRecognizer(playPauseTapOnContainer)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        
        context.coordinator.webView = webView
        context.coordinator.containerView = containerView
        
        return containerView
    }
    
    private func configureWebViewMediaSettings(_ webView: UIView) {
        let mediaPlaybackRequiresUserAction = NSSelectorFromString("setMediaPlaybackRequiresUserAction:")
        if webView.responds(to: mediaPlaybackRequiresUserAction) {
            webView.perform(mediaPlaybackRequiresUserAction, with: false as NSNumber)
        }
        
        let allowsInlineMediaPlayback = NSSelectorFromString("setAllowsInlineMediaPlayback:")
        if webView.responds(to: allowsInlineMediaPlayback) {
            webView.perform(allowsInlineMediaPlayback, with: true as NSNumber)
        }
        
        let mediaPlaybackAllowsAirPlay = NSSelectorFromString("setMediaPlaybackAllowsAirPlay:")
        if webView.responds(to: mediaPlaybackAllowsAirPlay) {
            webView.perform(mediaPlaybackAllowsAirPlay, with: false as NSNumber)
        }
    }
    
    private func createFallbackLabel() -> UILabel {
        let label = UILabel()
        label.text = "⚠️ WebView nicht verfügbar"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func updateUIView(_ containerView: ScrollWebViewContainer, context: Context) {
        context.coordinator.parent = self
        
        let coordinator = context.coordinator
        containerView.onPlayPause = { [weak coordinator] in
            coordinator?.parent.onPlayPause?()
        }
        
        guard let webView = context.coordinator.webView else { return }
        
        containerView.backgroundColor = .black
        webView.backgroundColor = .black
        webView.frame = containerView.bounds
        
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.frame = containerView.bounds
        }
        
        if let url = url, context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            let request = URLRequest(url: url)
            let selector = NSSelectorFromString("loadRequest:")
            if webView.responds(to: selector) {
                webView.perform(selector, with: request)
            }
        }
        
        if let back = webView.value(forKey: "canGoBack") as? Bool, back != self.canGoBack {
            DispatchQueue.main.async { self.canGoBack = back }
        }
        if let forward = webView.value(forKey: "canGoForward") as? Bool, forward != self.canGoForward {
            DispatchQueue.main.async { self.canGoForward = forward }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ScrollWebViewRepresentable
        var lastLoadedURL: URL?
        var webView: UIView?
        var containerView: ScrollWebViewContainer?
        weak var scrollView: UIScrollView?
        
        private let scrollVelocityDamping: CGFloat = 0.3
        private let minimumVelocityThreshold: CGFloat = 50.0
        private let maxScrollDistance: CGFloat = 600.0
        
        init(_ parent: ScrollWebViewRepresentable) {
            self.parent = parent
        }
        
        // MARK: - UIScrollViewDelegate
        
        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            let currentOffset = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let viewportHeight = scrollView.bounds.height
            let maxOffset = max(0, contentHeight - viewportHeight)
            
            let rawSpeed = abs(velocity.y) * 1000.0
            
            if rawSpeed < minimumVelocityThreshold {
                targetContentOffset.pointee = scrollView.contentOffset
                return
            }
            
            let direction: CGFloat = velocity.y > 0 ? 1.0 : -1.0
            var dampedDistance = rawSpeed * scrollVelocityDamping * direction
            dampedDistance = max(-maxScrollDistance, min(maxScrollDistance, dampedDistance))
            
            let targetY = min(max(0, currentOffset + dampedDistance), maxOffset)
            
            targetContentOffset.pointee = CGPoint(
                x: scrollView.contentOffset.x,
                y: targetY
            )
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.x != 0 {
                scrollView.contentOffset.x = 0
            }
        }
        
        // MARK: - Play/Pause
        
        @objc func handlePlayPauseTap() {
            parent.onPlayPause?()
        }
        
        // MARK: - WebView Delegate Methods
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            // FIX: Main Thread Check
            if Thread.isMainThread {
                self.parent.isLoading = true
            } else {
                DispatchQueue.main.async { self.parent.isLoading = true }
            }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
            // FIX: Alle Operationen auf Main Thread verschieben
            let updateUI = { [weak self] in
                guard let self = self else { return }
                self.parent.isLoading = false
                
                let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
                if webView.responds(to: jsSelector) {
                    if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                        self.parent.title = title
                    }
                }
                
                if let request = webView.value(forKey: "request") as? URLRequest,
                   let url = request.url {
                    self.parent.url = url
                }
                
                self.applyViewportFix(webView)
                self.injectVideoFullscreenPrevention(webView)
            }
            
            if Thread.isMainThread {
                updateUI()
            } else {
                DispatchQueue.main.async { updateUI() }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reapplyScrollSettings()
            }
        }
        
        private func reapplyScrollSettings() {
            guard let webView = webView,
                  let scrollView = webView.value(forKey: "scrollView") as? UIScrollView else {
                return
            }
            
            scrollView.decelerationRate = .fast
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.alwaysBounceHorizontal = false
            scrollView.isDirectionalLockEnabled = true
            scrollView.showsHorizontalScrollIndicator = false
            
            if scrollView.delegate !== self {
                scrollView.delegate = self
            }
        }
        
        private func injectVideoFullscreenPrevention(_ webView: UIView) {
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                webView.perform(jsSelector, with: ScrollWebViewRepresentable.videoFullscreenPreventionJS)
            }
        }
        
        @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
            // FIX: Main Thread Check
            if Thread.isMainThread {
                self.parent.isLoading = false
            } else {
                DispatchQueue.main.async { self.parent.isLoading = false }
            }
        }
        
        @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
            return parent.onNavigationAction(request)
        }
        
        private func applyViewportFix(_ webView: UIView) {
            let script = """
                (function() {
                    var viewport = document.querySelector('meta[name="viewport"]');
                    if (viewport) viewport.remove();
                    viewport = document.createElement('meta');
                    viewport.name = 'viewport';
                    viewport.content = 'width=device-width, initial-scale=1.0, user-scalable=yes';
                    document.head.insertBefore(viewport, document.head.firstChild);
                    
                    document.documentElement.style.backgroundColor = '#000000';
                    document.body.style.backgroundColor = '#000000';
                    document.body.style.fontSize = '125%';
                    document.body.style.lineHeight = '1.5';
                    return 'ok';
                })();
            """
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                webView.perform(jsSelector, with: script)
            }
        }
    }
}

// MARK: - Custom Container View that intercepts Play/Pause presses

class ScrollWebViewContainer: UIView {
    var onPlayPause: (() -> Void)?
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            if press.type == .playPause {
                onPlayPause?()
                handled = true
            }
        }
        
        if !handled {
            super.pressesEnded(presses, with: event)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            if press.type == .playPause {
                handled = true
            }
        }
        
        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            if press.type == .playPause {
                handled = true
            }
        }
        
        if !handled {
            super.pressesChanged(presses, with: event)
        }
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            if press.type == .playPause {
                handled = true
            }
        }
        
        if !handled {
            super.pressesCancelled(presses, with: event)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var url: URL? = URL(string: "https://www.apple.com")
    
    ScrollModeWebView(
        url: $url,
        preferences: BrowserPreferences(),
        onNavigationAction: { _ in true },
        onBack: { }
    )
    .preferredColorScheme(.dark)
}
