//
//  FullscreenWebView.swift
//  MountainBrowser
//
//  TESTFLIGHT-KOMPATIBEL: Verwendet NativeReaderView statt UIWebView
//  Rendert Webseiten als nativen, lesbaren SwiftUI-Content
//

import SwiftUI

// MARK: - Wrapper für SessionManager Integration (wird von MainBrowserView verwendet)

struct FullscreenWebViewWithSession: View {
    let url: String
    let sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NativeReaderView(
            url: url,
            title: extractDisplayTitle(from: url),
            isPresented: $isPresented,
            sessionManager: sessionManager
        )
        .onAppear {
            sessionManager.createSession(url: url)
        }
        .onDisappear {
            sessionManager.updateSession(url: url, scrollPosition: 0)
        }
        .ignoresSafeArea(.all)
    }
    
    private func extractDisplayTitle(from urlString: String) -> String {
        guard let urlObj = URL(string: urlString), let host = urlObj.host else { return urlString }
        var h = host
        if h.hasPrefix("www.") { h = String(h.dropFirst(4)) }
        return h
    }
}

// MARK: - Legacy Compatibility (für andere Stellen die FullscreenWebView referenzieren)

struct FullscreenWebView: View {
    let url: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NativeReaderView(
            url: url,
            title: extractDisplayTitle(from: url),
            isPresented: $isPresented,
            sessionManager: SessionManager()
        )
        .ignoresSafeArea(.all)
    }
    
    private func extractDisplayTitle(from urlString: String) -> String {
        guard let urlObj = URL(string: urlString), let host = urlObj.host else { return urlString }
        var h = host
        if h.hasPrefix("www.") { h = String(h.dropFirst(4)) }
        return h
    }
}

// MARK: - Preview

#Preview {
    FullscreenWebView(
        url: "https://www.google.com",
        isPresented: .constant(true)
    )
}
