//
//  ScrollModeWebView.swift
//  MountainBrowser
//
//  Scroll-Modus WebView mit nativer tvOS Fokus-Navigation
//  Verwendet UIWebView mit aktiviertem ScrollView-Scrolling
//

import SwiftUI
import os.log

// MARK: - Debug Logger
private let scrollWebViewLogger = Logger(subsystem: "MountainBrowser", category: "ScrollModeWebView")

struct ScrollModeWebView: View {
    @Binding var url: URL?
    @State private var isLoading: Bool = false
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var title: String = ""
    @State private var webViewRef: UIView?
    
    // FIX: Texteingabe-Sheet für Formulare (wie im Cursor-Modus)
    @State private var showTextInputSheet: Bool = false
    @State private var textInputValue: String = ""
    @State private var textInputPrompt: String = L10n.Browser.enterText
    @State private var pendingInputElementId: String? = nil
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    let onBack: () -> Void
    var onPlayPause: (() -> Void)? = nil
    
    private var pageTitle: String {
        title.isEmpty ? L10n.General.loading : title
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
                    onPlayPause: onPlayPause,
                    onTextInputRequired: { elementId, placeholder in
                        scrollWebViewLogger.info("📝 onTextInputRequired aufgerufen: id='\(elementId)', placeholder='\(placeholder)'")
                        handleTextInputRequest(elementId: elementId, placeholder: placeholder)
                    }
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
        // FIX: Text-Input-Sheet auch im Scroll-Modus
        .fullScreenCover(isPresented: $showTextInputSheet) {
            WebViewTextInputSheet(
                isPresented: $showTextInputSheet,
                textValue: $textInputValue,
                prompt: textInputPrompt,
                onSubmit: {
                    scrollWebViewLogger.info("✅ Text-Input Submit: '\(textInputValue)' für Element: '\(pendingInputElementId ?? "nil")'")
                    submitTextInput()
                    showTextInputSheet = false
                },
                onCancel: {
                    scrollWebViewLogger.info("❌ Text-Input abgebrochen")
                    textInputValue = ""
                    pendingInputElementId = nil
                    showTextInputSheet = false
                }
            )
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
    
    // MARK: - Text Input Handling
    
    private func handleTextInputRequest(elementId: String, placeholder: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleTextInputRequest(elementId: elementId, placeholder: placeholder)
            }
            return
        }
        
        scrollWebViewLogger.info("🔧 handleTextInputRequest: elementId='\(elementId)', placeholder='\(placeholder)', showTextInputSheet vorher=\(showTextInputSheet)")
        
        pendingInputElementId = elementId
        textInputPrompt = placeholder.isEmpty ? L10n.Browser.enterText : placeholder
        textInputValue = ""
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            scrollWebViewLogger.info("🎬 Setze showTextInputSheet = true")
            showTextInputSheet = true
        }
    }
    
    private func submitTextInput() {
        guard let webView = webViewRef else {
            scrollWebViewLogger.error("❌ submitTextInput: webViewRef ist nil!")
            return
        }
        
        scrollWebViewLogger.info("📤 submitTextInput: Text='\(textInputValue)', ElementId='\(pendingInputElementId ?? "nil")'")
        
        let escapedValue = textInputValue
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        let script: String
        if let elementId = pendingInputElementId, !elementId.isEmpty {
            script = """
                (function() {
                    console.log('tvOS: submitTextInput mit elementId: \(elementId)');
                    var element = document.getElementById('\(elementId)');
                    if (!element) { console.log('tvOS: getElementById fehlgeschlagen, versuche name...'); element = document.querySelector('input[name="\(elementId)"]'); }
                    if (!element) { console.log('tvOS: name fehlgeschlagen, versuche aria-label...'); element = document.querySelector('[aria-label="\(elementId)"]'); }
                    if (!element) {
                        console.log('tvOS: Alle ID-Selektoren fehlgeschlagen, versuche activeElement...');
                        element = document.activeElement;
                        if (!element || (element.tagName !== 'INPUT' && element.tagName !== 'TEXTAREA')) {
                            console.log('tvOS: activeElement ist kein Input (' + (element ? element.tagName : 'null') + '), versuche breite Suche...');
                            element = document.querySelector('input[type="text"], input[type="search"], input:not([type]), textarea, [contenteditable="true"]');
                        }
                    }
                    if (element) {
                        console.log('tvOS: Element gefunden: ' + element.tagName + '#' + element.id + ' name=' + element.name + ' type=' + element.type);
                        element.focus();
                        var nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
                        if (!nativeSetter) nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value');
                        if (nativeSetter && nativeSetter.set) {
                            console.log('tvOS: Verwende nativeInputValueSetter');
                            nativeSetter.set.call(element, '\(escapedValue)');
                        } else {
                            console.log('tvOS: nativeInputValueSetter nicht verfügbar, verwende element.value');
                            element.value = '\(escapedValue)';
                        }
                        console.log('tvOS: Wert gesetzt, dispatche Events...');
                        element.dispatchEvent(new Event('focus', { bubbles: true }));
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));
                        element.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true, key: 'a' }));
                        element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true, key: 'a' }));
                        console.log('tvOS: Element.value nach Setzen: "' + element.value + '"');
                        var form = element.closest('form');
                        if (form) {
                            console.log('tvOS: Form gefunden, suche Submit-Button...');
                            var submitBtn = form.querySelector('input[type="submit"], button[type="submit"], button:not([type])');
                            if (submitBtn) {
                                console.log('tvOS: Submit-Button gefunden: ' + submitBtn.tagName + '#' + submitBtn.id + ', klicke...');
                                submitBtn.click();
                            } else {
                                console.log('tvOS: Kein Submit-Button gefunden, dispatche submit Event...');
                                form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
                            }
                        } else {
                            console.log('tvOS: Kein Form-Element gefunden!');
                        }
                        return 'success:' + element.tagName + '#' + (element.id || element.name || '?');
                    }
                    console.log('tvOS: KEIN Element gefunden!');
                    return 'element_not_found';
                })();
            """
        } else {
            script = """
                (function() {
                    console.log('tvOS: submitTextInput OHNE elementId');
                    var element = document.activeElement;
                    console.log('tvOS: activeElement: ' + (element ? element.tagName + '#' + element.id + ' type=' + element.type : 'null'));
                    if (!element || (element.tagName !== 'INPUT' && element.tagName !== 'TEXTAREA')) {
                        var selectors = [
                            'input[type="search"]', 'input[type="text"]',
                            'input[name*="search"]', 'input[name*="query"]', 'input[name*="keyword"]', 'input[name*="field"]',
                            'input[aria-label*="search" i]', 'input[aria-label*="such" i]',
                            'input[placeholder*="search" i]', 'input[placeholder*="such" i]',
                            'input:not([type="hidden"]):not([type="submit"]):not([type="button"]):not([type="checkbox"]):not([type="radio"])',
                            'textarea', '[contenteditable="true"]'
                        ];
                        for (var i = 0; i < selectors.length; i++) {
                            element = document.querySelector(selectors[i]);
                            if (element && element.offsetParent !== null) {
                                console.log('tvOS: Element via Selektor ' + i + ' gefunden: ' + element.tagName + '#' + element.id);
                                break;
                            }
                            element = null;
                        }
                    }
                    if (element) {
                        console.log('tvOS: Finales Element: ' + element.tagName + '#' + element.id + ' name=' + element.name);
                        element.focus();
                        var nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
                        if (!nativeSetter) nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value');
                        if (nativeSetter && nativeSetter.set) {
                            nativeSetter.set.call(element, '\(escapedValue)');
                        } else {
                            element.value = '\(escapedValue)';
                        }
                        element.dispatchEvent(new Event('focus', { bubbles: true }));
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));
                        element.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true, key: 'a' }));
                        element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true, key: 'a' }));
                        console.log('tvOS: Element.value nach Setzen: "' + element.value + '"');
                        var form = element.closest('form');
                        if (form) {
                            var submitBtn = form.querySelector('input[type="submit"], button[type="submit"], button:not([type])');
                            if (submitBtn) { console.log('tvOS: Submit via Button'); submitBtn.click(); }
                            else { console.log('tvOS: Submit via Event'); form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true })); }
                        } else {
                            console.log('tvOS: Kein Form gefunden');
                        }
                        return 'success:' + element.tagName + '#' + (element.id || element.name || '?');
                    }
                    console.log('tvOS: KEIN Element gefunden! Alle Selektoren fehlgeschlagen.');
                    // Debug: Liste alle sichtbaren Inputs auf der Seite
                    var allInputs = document.querySelectorAll('input, textarea');
                    console.log('tvOS: Gesamt-Inputs auf Seite: ' + allInputs.length);
                    for (var j = 0; j < Math.min(allInputs.length, 10); j++) {
                        var inp = allInputs[j];
                        console.log('  Input ' + j + ': ' + inp.tagName + ' type=' + inp.type + ' id=' + inp.id + ' name=' + inp.name + ' visible=' + (inp.offsetParent !== null));
                    }
                    return 'element_not_found';
                })();
            """
        }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            let result = webView.perform(jsSelector, with: script)?.takeUnretainedValue() as? String
            scrollWebViewLogger.info("📋 JavaScript Ergebnis: '\(result ?? "nil")'")
        } else {
            scrollWebViewLogger.error("❌ WebView responds nicht auf stringByEvaluatingJavaScriptFromString!")
        }
        
        textInputValue = ""
        pendingInputElementId = nil
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
    var onTextInputRequired: ((String, String) -> Void)? = nil
    
    /// JavaScript das den internen UIWebView Video-Player verhindert.
    /// Der Crash passiert weil WebAVPlayerViewController auf tvOS nil-Objekte bekommt.
    static let videoFullscreenPreventionJS = """
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
    
    /// JavaScript zur Textfeld-Erkennung bei Fokus-Änderungen
    private static let textFieldDetectionJS = """
        (function() {
            if (window._tvosTextFieldDetectionInstalled) return 'already_installed';
            window._tvosTextFieldDetectionInstalled = true;
            
            document.addEventListener('focusin', function(e) {
                var el = e.target;
                var tag = el.tagName;
                var inputType = (el.type || '').toLowerCase();
                
                console.log('tvOS focusin: ' + tag + '#' + el.id + ' type=' + inputType + ' name=' + el.name);
                
                var isTextField = (
                    (tag === 'INPUT' &&
                     ['text', 'search', 'email', 'url', 'tel', 'password', 'number', ''].includes(inputType) &&
                     inputType !== 'hidden' && inputType !== 'submit' && inputType !== 'button' &&
                     inputType !== 'checkbox' && inputType !== 'radio')
                ) || tag === 'TEXTAREA' || el.isContentEditable;
                
                console.log('tvOS: isTextField = ' + isTextField);
                
                if (isTextField) {
                    window._tvosLastFocusedInputId = el.id || el.name || '';
                    window._tvosLastFocusedInputPlaceholder = el.placeholder || el.getAttribute('aria-label') || el.title || '';
                    console.log('tvOS: Textfeld gespeichert: id="' + window._tvosLastFocusedInputId + '" placeholder="' + window._tvosLastFocusedInputPlaceholder + '"');
                }
            }, true);
            
            return 'textfield_detection_installed';
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
        // FIX: Textfeld-Erkennung bei Select-Taste im Scroll-Modus
        containerView.onSelect = { [weak coordinator] in
            scrollWebViewLogger.info("🖱️ onSelect aufgerufen (Select-Taste gedrückt)")
            coordinator?.checkForTextFieldFocus()
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
        containerView.onSelect = { [weak coordinator] in
            scrollWebViewLogger.info("🖱️ onSelect aufgerufen (updateUIView)")
            coordinator?.checkForTextFieldFocus()
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
        
        // MARK: - Text Field Focus Detection
        
        /// Prüft ob gerade ein Textfeld fokussiert ist und öffnet das Eingabe-Sheet
        func checkForTextFieldFocus() {
            guard let webView = webView else {
                scrollWebViewLogger.error("❌ checkForTextFieldFocus: webView ist nil!")
                return
            }
            
            scrollWebViewLogger.info("🔍 checkForTextFieldFocus: Prüfe document.activeElement...")
            
            let script = """
                (function() {
                    var el = document.activeElement;
                    console.log('tvOS checkFocus: activeElement = ' + (el ? el.tagName + '#' + el.id + ' type=' + (el.type||'') + ' name=' + (el.name||'') : 'null'));
                    if (!el) return JSON.stringify({ type: 'none' });
                    var tag = el.tagName;
                    var inputType = (el.type || '').toLowerCase();
                    var isTextField = (
                        (tag === 'INPUT' &&
                         ['text', 'search', 'email', 'url', 'tel', 'password', 'number', ''].includes(inputType) &&
                         inputType !== 'hidden' && inputType !== 'submit' && inputType !== 'button' &&
                         inputType !== 'checkbox' && inputType !== 'radio')
                    ) || tag === 'TEXTAREA' || el.isContentEditable;
                    
                    console.log('tvOS checkFocus: isTextField = ' + isTextField);
                    
                    if (isTextField) {
                        return JSON.stringify({
                            type: 'textfield',
                            id: el.id || el.name || '',
                            placeholder: el.placeholder || el.getAttribute('aria-label') || el.title || 'Text eingeben'
                        });
                    }
                    
                    // Auch gespeichertes Feld prüfen (von focusin Event)
                    if (window._tvosLastFocusedInputId !== undefined) {
                        console.log('tvOS checkFocus: Verwende gespeichertes Feld: id="' + window._tvosLastFocusedInputId + '"');
                        var savedEl = document.getElementById(window._tvosLastFocusedInputId);
                        if (!savedEl && window._tvosLastFocusedInputId) {
                            savedEl = document.querySelector('input[name="' + window._tvosLastFocusedInputId + '"]');
                        }
                        if (savedEl) {
                            return JSON.stringify({
                                type: 'textfield',
                                id: window._tvosLastFocusedInputId,
                                placeholder: window._tvosLastFocusedInputPlaceholder || 'Text eingeben'
                            });
                        }
                    }
                    
                    return JSON.stringify({ type: 'other', tag: tag, id: el.id || '', inputType: inputType });
                })();
            """
            
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            guard webView.responds(to: jsSelector) else {
                scrollWebViewLogger.error("❌ WebView responds nicht auf JS selector!")
                return
            }
            
            guard let unmanaged = webView.perform(jsSelector, with: script),
                  let result = unmanaged.takeUnretainedValue() as? String else {
                scrollWebViewLogger.error("❌ JavaScript returned nil!")
                return
            }
            
            scrollWebViewLogger.info("📋 checkForTextFieldFocus JS Ergebnis: '\(result)'")
            
            guard let data = result.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                scrollWebViewLogger.error("❌ JSON Parsing fehlgeschlagen für: '\(result)'")
                return
            }
            
            let type = json["type"] ?? "unknown"
            scrollWebViewLogger.info("📋 Typ: '\(type)', id: '\(json["id"] ?? "")', tag: '\(json["tag"] ?? "")'")
            
            guard type == "textfield" else {
                scrollWebViewLogger.info("ℹ️ Kein Textfeld fokussiert (type='\(type)'), kein Sheet öffnen")
                return
            }
            
            let elementId = json["id"] ?? ""
            let placeholder = json["placeholder"] ?? L10n.Browser.enterText
            
            scrollWebViewLogger.info("✅ Textfeld erkannt! id='\(elementId)', placeholder='\(placeholder)' → öffne Eingabe-Sheet")
            
            DispatchQueue.main.async {
                self.parent.onTextInputRequired?(elementId, placeholder)
            }
        }
        
        // MARK: - WebView Delegate Methods
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            if Thread.isMainThread {
                self.parent.isLoading = true
            } else {
                DispatchQueue.main.async { self.parent.isLoading = true }
            }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
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
                self.injectTextFieldDetection(webView)
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
        
        private func injectTextFieldDetection(_ webView: UIView) {
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
                let result = webView.perform(jsSelector, with: ScrollWebViewRepresentable.textFieldDetectionJS)?.takeUnretainedValue() as? String
                scrollWebViewLogger.info("💉 TextFieldDetection injected: '\(result ?? "nil")'")
            }
        }
        
        @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
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

// MARK: - Custom Container View that intercepts Play/Pause and Select presses

class ScrollWebViewContainer: UIView {
    var onPlayPause: (() -> Void)?
    var onSelect: (() -> Void)?
    
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
            // WICHTIG: Erst den nativen Klick ausführen lassen
            super.pressesEnded(presses, with: event)
            
            // DANN nach kurzer Verzögerung prüfen ob ein Textfeld fokussiert wurde
            for press in presses {
                if press.type == .select {
                    scrollWebViewLogger.info("⏱️ Select-Taste: warte 0.3s bevor checkForTextFieldFocus...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        scrollWebViewLogger.info("⏱️ 0.3s vergangen, rufe onSelect auf")
                        self?.onSelect?()
                    }
                    break
                }
            }
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
