//
//  CursorWebView.swift
//  AppleTVBrowser
//
//  WebView mit Cursor-basierter Navigation für tvOS
//

import SwiftUI

struct CursorWebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var cursorPosition: CGPoint
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    
    let preferences: BrowserPreferences
    let onNavigationAction: (URLRequest) -> Bool
    let onContentSizeChanged: (CGSize) -> Void
    
    typealias UIViewType = UIView
    
    func makeUIView(context: Context) -> UIView {
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
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
        
        return webView
    }
    
    func updateUIView(_ webView: UIView, context: Context) {
        context.coordinator.parent = self
        
        // Load URL if changed
        if let url = url {
            let currentURL = getCurrentURL(from: webView)
            if currentURL != url {
                let request = URLRequest(url: url)
                let selector = NSSelectorFromString("loadRequest:")
                if webView.responds(to: selector) {
                    webView.perform(selector, with: request)
                }
            }
        }
        
        // Update cursor position in JavaScript
        updateCursorPositionInJS(webView, position: cursorPosition)
        
        // Update navigation state
        DispatchQueue.main.async {
            if let back = webView.value(forKey: "canGoBack") as? Bool {
                canGoBack = back
            }
            if let forward = webView.value(forKey: "canGoForward") as? Bool {
                canGoForward = forward
            }
        }
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
    
    // MARK: - JavaScript Integration
    private func updateCursorPositionInJS(_ webView: UIView, position: CGPoint) {
        // Convert coordinates considering the webview's frame and scale
        let webViewFrame = webView.frame
        let adjustedX = position.x - webViewFrame.origin.x
        let adjustedY = position.y - webViewFrame.origin.y
        
        let script = """
            if (typeof window.updateCursorPosition === 'function') {
                window.updateCursorPosition(\(adjustedX), \(adjustedY));
            }
        """
        executeJavaScript(webView, script: script)
    }
    
    func performClickAtCursor(_ webView: UIView) {
        let script = """
            if (typeof window.performCursorClick === 'function') {
                window.performCursorClick();
            }
        """
        executeJavaScript(webView, script: script)
    }
    
    private func executeJavaScript(_ webView: UIView, script: String) {
        let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
        if webView.responds(to: jsSelector) {
            _ = webView.perform(jsSelector, with: script)
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: CursorWebView
        
        init(_ parent: CursorWebView) {
            self.parent = parent
        }
        
        @objc func webViewDidStartLoad(_ webView: UIView) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        @objc func webViewDidFinishLoad(_ webView: UIView) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                
                // Get title
                let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
                if webView.responds(to: jsSelector) {
                    if let title = webView.perform(jsSelector, with: "document.title")?.takeUnretainedValue() as? String {
                        self.parent.title = title
                    }
                }
                
                // Update URL
                if let request = webView.value(forKey: "request") as? URLRequest,
                   let url = request.url {
                    self.parent.url = url
                }
            }
            
            // Inject cursor JavaScript
            parent.executeJavaScript(webView, script: CursorWebView.mouseEventJavaScript)
            parent.executeJavaScript(webView, script: CursorWebView.cursorStyleJavaScript)
            
            // Report content size
            let jsSelector = NSSelectorFromString("stringByEvaluatingJavaScriptFromString:")
            if webView.responds(to: jsSelector) {
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
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        @objc func webView(_ webView: UIView, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
            return parent.onNavigationAction(request)
        }
    }
    
    // MARK: - JavaScript Code
    static let mouseEventJavaScript = """
        (function() {
            // Global cursor state
            window.cursorX = window.innerWidth / 2;
            window.cursorY = window.innerHeight / 2;
            window.hoveredElement = null;
            
            // Update cursor position
            window.updateCursorPosition = function(x, y) {
                window.cursorX = x;
                window.cursorY = y;
                
                // Update hover state
                var element = document.elementFromPoint(x, y);
                if (element !== window.hoveredElement) {
                    // Remove hover from previous element
                    if (window.hoveredElement) {
                        var outEvent = document.createEvent('MouseEvents');
                        outEvent.initMouseEvent('mouseout', true, true, window, 0, x, y, x, y, false, false, false, false, 0, null);
                        window.hoveredElement.dispatchEvent(outEvent);
                        window.hoveredElement.classList.remove('tvos-cursor-hover');
                    }
                    
                    // Add hover to new element
                    if (element) {
                        var overEvent = document.createEvent('MouseEvents');
                        overEvent.initMouseEvent('mouseover', true, true, window, 0, x, y, x, y, false, false, false, false, 0, null);
                        element.dispatchEvent(overEvent);
                        element.classList.add('tvos-cursor-hover');
                    }
                    
                    window.hoveredElement = element;
                }
            };
            
            // Perform click at cursor position
            window.performCursorClick = function() {
                var element = document.elementFromPoint(window.cursorX, window.cursorY);
                if (element) {
                    // Create and dispatch mouse events
                    var mouseDownEvent = document.createEvent('MouseEvents');
                    mouseDownEvent.initMouseEvent('mousedown', true, true, window, 0, window.cursorX, window.cursorY, window.cursorX, window.cursorY, false, false, false, false, 0, null);
                    element.dispatchEvent(mouseDownEvent);
                    
                    var mouseUpEvent = document.createEvent('MouseEvents');
                    mouseUpEvent.initMouseEvent('mouseup', true, true, window, 0, window.cursorX, window.cursorY, window.cursorX, window.cursorY, false, false, false, false, 0, null);
                    element.dispatchEvent(mouseUpEvent);
                    
                    var clickEvent = document.createEvent('MouseEvents');
                    clickEvent.initMouseEvent('click', true, true, window, 0, window.cursorX, window.cursorY, window.cursorX, window.cursorY, false, false, false, false, 0, null);
                    element.dispatchEvent(clickEvent);
                    
                    // Handle special elements
                    if (element.tagName === 'A' || element.tagName === 'BUTTON') {
                        element.click();
                    } else if (element.tagName === 'INPUT') {
                        element.focus();
                        if (element.type === 'checkbox' || element.type === 'radio') {
                            element.click();
                        }
                    } else if (element.tagName === 'SELECT') {
                        element.focus();
                    }
                }
            };
            
            console.log('tvOS Cursor JavaScript initialized');
        })();
    """
    
    static let cursorStyleJavaScript = """
        (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = '.tvos-cursor-hover {' +
                'outline: 2px solid #007AFF !important;' +
                'outline-offset: 2px !important;' +
                'background-color: rgba(0, 122, 255, 0.15) !important;' +
                'border-radius: 4px !important;' +
                'transition: all 0.2s ease !important;' +
                'box-shadow: 0 0 8px rgba(0, 122, 255, 0.4) !important;' +
            '}' +
            '.tvos-cursor-hover:hover {' +
                'transform: scale(1.01) !important;' +
                'background-color: rgba(0, 122, 255, 0.2) !important;' +
            '}' +
            'a.tvos-cursor-hover, button.tvos-cursor-hover, [onclick].tvos-cursor-hover {' +
                'box-shadow: 0 0 12px rgba(0, 122, 255, 0.6) !important;' +
                'outline-width: 3px !important;' +
            '}' +
            'input.tvos-cursor-hover, select.tvos-cursor-hover, textarea.tvos-cursor-hover {' +
                'border: 2px solid #007AFF !important;' +
                'box-shadow: 0 0 8px rgba(0, 122, 255, 0.5) !important;' +
            '}';
            document.head.appendChild(style);
            
            console.log('tvOS Cursor CSS styles initialized with hover effects');
        })();
    """
}

// MARK: - Helper Extension
extension CursorWebView {
    func goBack(_ webView: UIView) {
        let selector = NSSelectorFromString("goBack")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func goForward(_ webView: UIView) {
        let selector = NSSelectorFromString("goForward")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
    
    func reload(_ webView: UIView) {
        let selector = NSSelectorFromString("reload")
        if webView.responds(to: selector) {
            webView.perform(selector)
        }
    }
}