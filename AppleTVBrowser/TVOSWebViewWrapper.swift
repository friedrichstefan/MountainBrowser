//
//  TVOSWebViewWrapper.swift
//  AppleTVBrowser
//
//  UIWebView Wrapper für tvOS - NO WebKit!
//  Basierend auf der Objective-C Referenz-Implementation
//

import SwiftUI
import UIKit
import Combine

/// UIViewControllerRepresentable Wrapper für UIWebView auf tvOS
/// Verwendet UIViewController um Siri Remote-Eingaben korrekt zu empfangen
struct TVOSWebViewWrapper: UIViewControllerRepresentable {
    
    // MARK: - Bindings
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String
    
    // MARK: - Properties
    var onNavigationChange: ((String) -> Void)?
    var onPan: ((CGPoint) -> Void)?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    
    // WebViewController-Referenz für externe Steuerung
    var webViewController: TVOSWebViewController?
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> TVOSWebViewHostController {
        let controller = TVOSWebViewHostController()
        controller.coordinator = context.coordinator
        controller.onPan = onPan
        controller.onTap = onTap
        controller.onDoubleTap = onDoubleTap
        
        // Übergebe externe WebViewController-Referenz
        DispatchQueue.main.async {
            self.webViewController?.webView = controller.webView
            print("✅ WebView-Referenz an Controller übergeben")
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: TVOSWebViewHostController, context: Context) {
        // Aktualisiere Callbacks
        uiViewController.onPan = onPan
        uiViewController.onTap = onTap
        uiViewController.onDoubleTap = onDoubleTap
        
        // Lade neue URL wenn sich urlString geändert hat
        if !urlString.isEmpty && urlString != context.coordinator.currentURL {
            context.coordinator.currentURL = urlString
            uiViewController.loadURL(urlString)
        }
        
        // Aktualisiere WebView-Referenz falls noch nicht gesetzt
        if webViewController?.webView == nil {
            webViewController?.webView = uiViewController.webView
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var parent: TVOSWebViewWrapper
        var currentURL: String = ""
        
        init(_ parent: TVOSWebViewWrapper) {
            self.parent = parent
        }
        
        // Diese Methoden werden vom TVOSWebViewHostController aufgerufen
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
                self.saveToHistory(url: currentURL, title: pageTitle)
            }
        }
        
        func webViewDidFail(error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                print("❌ WebView Fehler: \(error.localizedDescription)")
            }
        }
        
        // MARK: - Helper Methods
        
        private func saveToHistory(url: String, title: String) {
            let historyItem = [url, title]
            var history = UserDefaults.standard.array(forKey: "HISTORY") as? [[String]] ?? []
            
            // Entferne Duplikate
            history.removeAll { $0[0] == url }
            
            // Füge neues Item am Anfang hinzu
            history.insert(historyItem, at: 0)
            
            // Begrenze auf 100 Einträge
            if history.count > 100 {
                history = Array(history.prefix(100))
            }
            
            UserDefaults.standard.set(history, forKey: "HISTORY")
        }
    }
    
}

// MARK: - TVOSWebViewHostController

/// UIViewController der Siri Remote-Eingaben korrekt empfängt
class TVOSWebViewHostController: UIViewController {
    
    var webView: UIView?
    var coordinator: TVOSWebViewWrapper.Coordinator?
    
    // Callbacks
    var onPan: ((CGPoint) -> Void)?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    
    // Touch-Tracking für Swipe-Gesten auf der Siri Remote
    private var touchStartLocation: CGPoint = .zero
    private var lastTouchLocation: CGPoint = .zero
    private var lastTapTime: Date = Date.distantPast
    private let doubleTapInterval: TimeInterval = 0.3
    private var hasMoved: Bool = false
    
    // Kontinuierliche Bewegung
    private var moveTimer: Timer?
    private var currentDirection: CGPoint = .zero
    
    // Skalierungsfaktor für Siri Remote Touchpad
    private let touchScaleFactor: CGFloat = 2.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Erstelle UIWebView
        setupWebView()
        
        // Wichtig: View muss fokussierbar sein für Siri Remote
        view.isUserInteractionEnabled = true
        
        print("🎮 TVOSWebViewHostController geladen")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Setze diesen Controller als First Responder für Press-Events
        let success = becomeFirstResponder()
        print("🎮 ViewDidAppear - becomeFirstResponder: \(success)")
        print("🎮 onTap callback gesetzt: \(onTap != nil)")
        print("🎮 onPan callback gesetzt: \(onPan != nil)")
        print("🎮 onDoubleTap callback gesetzt: \(onDoubleTap != nil)")
        
        // Füge Tap Gesture Recognizer hinzu als Backup
        setupGestureRecognizers()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private func setupGestureRecognizers() {
        // Entferne alte Recognizers
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
        
        // Tap Gesture für Select-Button auf Siri Remote
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
        print("🎮 Tap Gesture Recognizer hinzugefügt")
        
        // Play/Pause für Moduswechsel
        let playPauseRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePlayPauseGesture(_:)))
        playPauseRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPauseRecognizer)
        print("🎮 Play/Pause Gesture Recognizer hinzugefügt")
    }
    
    @objc private func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        print("🎮 TAP GESTURE ERKANNT! State: \(recognizer.state.rawValue)")
        print("🎮 onTap ist: \(onTap != nil ? "gesetzt" : "nil")")
        if let tap = onTap {
            print("🎮 Rufe onTap callback auf...")
            tap()
            print("🎮 onTap callback aufgerufen")
        } else {
            print("❌ onTap ist nil!")
        }
    }
    
    @objc private func handlePlayPauseGesture(_ recognizer: UITapGestureRecognizer) {
        print("🎮 PLAY/PAUSE GESTURE ERKANNT! State: \(recognizer.state.rawValue)")
        print("🎮 onDoubleTap ist: \(onDoubleTap != nil ? "gesetzt" : "nil")")
        if let doubleTap = onDoubleTap {
            print("🎮 Rufe onDoubleTap callback auf...")
            doubleTap()
            print("🎮 onDoubleTap callback aufgerufen")
        } else {
            print("❌ onDoubleTap ist nil!")
        }
    }
    
    private func setupWebView() {
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("❌ UIWebView nicht verfügbar")
            return
        }
        
        let webView = webViewClass.init()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .black
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup Delegate
        webView.setValue(self, forKey: "delegate")
        
        // Deaktiviere User Interaction auf WebView (wird über unser Cursor-System gesteuert)
        webView.isUserInteractionEnabled = false
        
        // Konfiguriere ScrollView
        if let scrollView = webView.value(forKey: "scrollView") as? UIScrollView {
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
        }
        
        // Setze User Agent
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15"
        UserDefaults.standard.register(defaults: ["UserAgent": userAgent])
        
        self.webView = webView
        print("✅ UIWebView erstellt")
    }
    
    func loadURL(_ urlString: String) {
        guard let webView = webView, let url = URL(string: urlString) else { return }
        
        let request = URLRequest(url: url)
        let loadRequestSelector = NSSelectorFromString("loadRequest:")
        if webView.responds(to: loadRequestSelector) {
            webView.perform(loadRequestSelector, with: request)
            print("🌐 Lade URL: \(urlString)")
        }
    }
    
    // MARK: - Siri Remote Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartLocation = touch.location(in: view)
        lastTouchLocation = touchStartLocation
        hasMoved = false
        print("👆 Touch began at: \(touchStartLocation)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentLocation = touch.location(in: view)
        
        // Berechne Delta seit letzter Position
        let deltaX = currentLocation.x - lastTouchLocation.x
        let deltaY = currentLocation.y - lastTouchLocation.y
        
        // Minimale Bewegungsschwelle um Jitter zu vermeiden
        let minMovement: CGFloat = 0.5
        guard abs(deltaX) > minMovement || abs(deltaY) > minMovement else {
            return
        }
        
        hasMoved = true
        
        // Skaliere die Bewegung für die Siri Remote
        let scaledDelta = CGPoint(
            x: deltaX * touchScaleFactor,
            y: deltaY * touchScaleFactor
        )
        
        // Callback sofort aufrufen - keine Debug-Ausgabe um Performance nicht zu beeinträchtigen
        onPan?(scaledDelta)
        
        lastTouchLocation = currentLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("👆 Touch ended - hasMoved: \(hasMoved)")
        
        // Wenn keine Bewegung war -> als Tap werten (wird aber vom Select-Button gehandelt)
        // Touch-basierte Taps deaktiviert, da der Select-Button die primäre Tap-Quelle ist
        
        stopContinuousMove()
        hasMoved = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopContinuousMove()
    }
    
    // MARK: - Press Handling (D-Pad und Buttons)
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        print("🎮 ===== pressesBegan aufgerufen mit \(presses.count) Press-Events =====")
        
        for press in presses {
            print("🎮 Press Type Raw Value: \(press.type.rawValue)")
            if let key = press.key {
                print("🎮 Press Key: \(String(describing: key.keyCode))")
            } else {
                print("🎮 Press Key: keine")
            }
            
            switch press.type {
            case .select:
                print("🎮 ➡️ SELECT/OK TASTE GEDRÜCKT")
                print("🎮 onTap ist: \(onTap != nil ? "gesetzt" : "nil")")
                if let tap = onTap {
                    print("🎮 Rufe onTap callback auf...")
                    tap()
                    print("🎮 onTap callback wurde aufgerufen")
                } else {
                    print("❌ onTap callback ist nil!")
                }
                
            case .playPause:
                print("🎮 ➡️ PLAY/PAUSE TASTE GEDRÜCKT")
                print("🎮 onDoubleTap ist: \(onDoubleTap != nil ? "gesetzt" : "nil")")
                if let doubleTap = onDoubleTap {
                    doubleTap()
                }
                
            case .menu:
                print("🎮 ➡️ MENU TASTE GEDRÜCKT")
                super.pressesBegan(presses, with: event)
                
            case .upArrow:
                print("🎮 ➡️ PFEIL HOCH GEDRÜCKT")
                startContinuousMove(direction: CGPoint(x: 0, y: -20))
                
            case .downArrow:
                print("🎮 ➡️ PFEIL RUNTER GEDRÜCKT")
                startContinuousMove(direction: CGPoint(x: 0, y: 20))
                
            case .leftArrow:
                print("🎮 ➡️ PFEIL LINKS GEDRÜCKT")
                startContinuousMove(direction: CGPoint(x: -20, y: 0))
                
            case .rightArrow:
                print("🎮 ➡️ PFEIL RECHTS GEDRÜCKT")
                startContinuousMove(direction: CGPoint(x: 20, y: 0))
                
            case .pageUp:
                print("🎮 ➡️ PAGE UP GEDRÜCKT")
                super.pressesBegan(presses, with: event)
                
            case .pageDown:
                print("🎮 ➡️ PAGE DOWN GEDRÜCKT")
                super.pressesBegan(presses, with: event)
            
            case .tvRemoteOneTwoThree:
                print("🎮 ➡️ TV REMOTE 1-2-3 GEDRÜCKT")
                super.pressesBegan(presses, with: event)
                
            @unknown default:
                print("🎮 ➡️ UNBEKANNTE TASTE GEDRÜCKT: \(press.type.rawValue)")
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .upArrow, .downArrow, .leftArrow, .rightArrow:
                stopContinuousMove()
            default:
                super.pressesEnded(presses, with: event)
            }
        }
    }
    
    private func startContinuousMove(direction: CGPoint) {
        currentDirection = direction
        onPan?(direction) // Sofortige erste Bewegung
        
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.onPan?(self.currentDirection)
        }
    }
    
    private func stopContinuousMove() {
        moveTimer?.invalidate()
        moveTimer = nil
        currentDirection = .zero
    }
    
    // MARK: - UIWebViewDelegate Methods
    
    @objc func webViewDidStartLoad(_ webView: UIView) {
        coordinator?.webViewDidStartLoad()
    }
    
    @objc func webViewDidFinishLoad(_ webView: UIView) {
        var canGoBack = false
        var canGoForward = false
        var pageTitle = ""
        var currentURL = ""
        
        if let back = webView.value(forKey: "canGoBack") as? Bool {
            canGoBack = back
        }
        
        if let forward = webView.value(forKey: "canGoForward") as? Bool {
            canGoForward = forward
        }
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                pageTitle = title
            }
        }
        
        if let request = webView.value(forKey: "request") as? URLRequest,
           let url = request.url {
            currentURL = url.absoluteString
        }
        
        coordinator?.webViewDidFinishLoad(canGoBack: canGoBack, canGoForward: canGoForward, pageTitle: pageTitle, currentURL: currentURL)
    }
    
    @objc func webView(_ webView: UIView, didFailLoadWithError error: Error) {
        coordinator?.webViewDidFail(error: error)
    }
    
    @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
        return true
    }
}

// MARK: - WebView Controller für Interaktion

/// Controller für WebView-Operationen von außen
class TVOSWebViewController: ObservableObject {
    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    
    var webView: UIView?
    
    /// Klick an Position im WebView
    func clickAtPoint(_ point: CGPoint) {
        print("🖱️ clickAtPoint aufgerufen mit Position: \(point)")
        
        guard let webView = self.webView else {
            print("❌ WebView ist nil!")
            return
        }
        
        print("✅ WebView vorhanden, Frame: \(webView.frame)")
        
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else {
            print("❌ WebView antwortet nicht auf JS-Selector!")
            return
        }
        
        // Berechne Skalierung
        let displayWidthStr = evaluateJavaScript("window.innerWidth") ?? "1920"
        let displayWidth = Int(displayWidthStr) ?? Int(webView.frame.width)
        let scale = webView.frame.width / CGFloat(displayWidth)
        
        let scaledX = Int(point.x / scale)
        let scaledY = Int(point.y / scale)
        
        print("📐 Scale: \(scale), Skalierte Position: (\(scaledX), \(scaledY))")
        
        // Ermittle Element unter der Position
        let elementInfoJS = """
            (function() {
                var el = document.elementFromPoint(\(scaledX), \(scaledY));
                if (el) {
                    return el.tagName + ' | ' + (el.id || 'no-id') + ' | ' + (el.className || 'no-class') + ' | ' + (el.href || 'no-href');
                }
                return 'kein Element';
            })()
        """
        
        if let elementInfo = evaluateJavaScript(elementInfoJS) {
            print("🔍 Element unter Cursor: \(elementInfo)")
        }
        
        // Führe Click aus
        let clickJS = """
            (function() {
                var el = document.elementFromPoint(\(scaledX), \(scaledY));
                if (el) {
                    el.click();
                    return 'geklickt auf ' + el.tagName;
                }
                return 'kein Element gefunden';
            })()
        """
        
        if let result = evaluateJavaScript(clickJS) {
            print("✅ Click-Ergebnis: \(result)")
        }
        
        // Prüfe auf Input-Felder
        let fieldTypeJS = """
            (function() {
                var el = document.elementFromPoint(\(scaledX), \(scaledY));
                return el ? el.type || 'undefined' : 'no-element';
            })()
        """
        
        if let fieldType = evaluateJavaScript(fieldTypeJS) {
            print("🔍 Field Type: \(fieldType)")
        }
    }
    
    /// Scrollt im WebView
    func scroll(by offset: CGFloat) {
        let scrollJS = "window.scrollBy(0, \(offset))"
        _ = evaluateJavaScript(scrollJS)
    }
    
    func evaluateJavaScript(_ script: String) -> String? {
        guard let webView = self.webView else { return nil }
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        guard webView.responds(to: jsSelector) else {
            return nil
        }
        
        return webView.perform(jsSelector, with: script)?
            .takeUnretainedValue() as? String
    }
}
