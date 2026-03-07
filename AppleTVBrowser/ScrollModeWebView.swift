//
//  ScrollModeWebView.swift
//  AppleTVBrowser
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
                navigationBar
                
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
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.gray)
            
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
                    .fill(Color.white.opacity(0.1))
            )
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 16) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(canGoBack ? .white : .gray.opacity(0.4))
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(canGoForward ? .white : .gray.opacity(0.4))
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    Image(systemName: "scroll")
                        .foregroundColor(.green)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Scroll Modus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
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
        .allowsHitTesting(false)
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
            print("▶️⏸️ Play/Pause im Scroll-Modus (Container-Ebene) → Modus wechseln")
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
            scrollView.backgroundColor = .black
            scrollView.indicatorStyle = .white
            scrollView.showsVerticalScrollIndicator = true
            
            // FIX: Play/Pause Gesture Recognizer direkt auf der ScrollView installieren,
            // weil SIE den Fokus hat und Press-Events empfängt — nicht der Container.
            let playPauseTapOnScrollView = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
            playPauseTapOnScrollView.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
            scrollView.addGestureRecognizer(playPauseTapOnScrollView)
            print("✅ Play/Pause GestureRecognizer auf ScrollView installiert")
        }
        
        // FIX: Auch auf dem WebView selbst installieren als Fallback
        let playPauseTapOnWebView = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
        playPauseTapOnWebView.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        webView.addGestureRecognizer(playPauseTapOnWebView)
        print("✅ Play/Pause GestureRecognizer auf WebView installiert")
        
        // Auch auf dem Container als letzte Absicherung
        let playPauseTapOnContainer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPauseTap))
        playPauseTapOnContainer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        containerView.addGestureRecognizer(playPauseTapOnContainer)
        print("✅ Play/Pause GestureRecognizer auf Container installiert")
        
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
        
        // FIX: Suche nach allen fokusierbaren Subviews und installiere auch dort den Gesture Recognizer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.installPlayPauseOnAllSubviews(of: webView, coordinator: context.coordinator)
        }
        
        return containerView
    }
    
    /// Installiert den Play/Pause Gesture Recognizer rekursiv auf allen Subviews
    private func installPlayPauseOnAllSubviews(of view: UIView, coordinator: Coordinator) {
        for subview in view.subviews {
            // Prüfe ob diese Subview fokussierbar ist oder ein ScrollView
            if subview.canBecomeFocused || subview is UIScrollView {
                let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePlayPauseTap))
                tap.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
                subview.addGestureRecognizer(tap)
                print("✅ Play/Pause GestureRecognizer auf Subview installiert: \(type(of: subview))")
            }
            // Rekursiv weiter in die Tiefe
            installPlayPauseOnAllSubviews(of: subview, coordinator: coordinator)
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
        
        // Update the container's callback
        let coordinator = context.coordinator
        containerView.onPlayPause = { [weak coordinator] in
            print("▶️⏸️ Play/Pause im Scroll-Modus (Container-Ebene Update) → Modus wechseln")
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
            
            // FIX: Nach dem Laden erneut Gesture Recognizer installieren,
            // da UIWebView möglicherweise seine Subview-Hierarchie neu aufbaut
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.installPlayPauseOnAllSubviews(of: webView, coordinator: context.coordinator)
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
    class Coordinator: NSObject {
        var parent: ScrollWebViewRepresentable
        var lastLoadedURL: URL?
        var webView: UIView?
        var containerView: ScrollWebViewContainer?
        
        init(_ parent: ScrollWebViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handlePlayPauseTap() {
            print("▶️⏸️ Play/Pause Gesture erkannt (Coordinator) — rufe onPlayPause auf")
            parent.onPlayPause?()
        }
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            DispatchQueue.main.async { self.parent.isLoading = true }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
            DispatchQueue.main.async {
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
            }
            
            applyViewportFix(webView)
            
            // FIX: Nach jedem Seitenladen Play/Pause Gesture Recognizer erneut installieren,
            // falls UIWebView seine interne View-Hierarchie neu aufgebaut hat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.reinstallPlayPauseGestures(on: webView)
            }
        }
        
        /// Installiert Play/Pause Gesture Recognizer erneut auf der ScrollView nach Seitenladen
        private func reinstallPlayPauseGestures(on webView: UIView) {
            guard let scrollView = webView.value(forKey: "scrollView") as? UIScrollView else {
                print("⚠️ Keine ScrollView gefunden für Gesture-Reinstall")
                return
            }
            
            // Prüfe ob bereits ein Play/Pause Recognizer vorhanden ist
            let hasPlayPause = scrollView.gestureRecognizers?.contains(where: { recognizer in
                guard let tap = recognizer as? UITapGestureRecognizer else { return false }
                return tap.allowedPressTypes.contains(NSNumber(value: UIPress.PressType.playPause.rawValue))
            }) ?? false
            
            if !hasPlayPause {
                let tap = UITapGestureRecognizer(target: self, action: #selector(handlePlayPauseTap))
                tap.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
                scrollView.addGestureRecognizer(tap)
                print("🔄 Play/Pause GestureRecognizer auf ScrollView nachinstalliert")
            } else {
                print("✅ Play/Pause GestureRecognizer auf ScrollView bereits vorhanden")
            }
        }
        
        @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
            DispatchQueue.main.async { self.parent.isLoading = false }
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
        // FIX: Erlaube Fokus, damit Press-Events auch hier ankommen können
        // Der UIWebView/ScrollView wird trotzdem bevorzugt fokussiert,
        // aber als Fallback kann auch der Container Presses empfangen.
        return true
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        
        for press in presses {
            if press.type == .playPause {
                print("▶️⏸️ Play/Pause Press erkannt in ScrollWebViewContainer.pressesEnded")
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
                // Abfangen, damit es nicht weitergereicht wird
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
