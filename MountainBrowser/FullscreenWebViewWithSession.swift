//
//  TextPreviewWebView.swift
//  MountainBrowser
//
//  TESTFLIGHT-KOMPATIBEL: Text-basierte Webseiten-Vorschau für tvOS
//  Kann als Fallback verwendet werden, wenn NativeReaderView nicht gewünscht ist.
//

import SwiftUI

struct TextPreviewWebView: View {
    let url: String
    let sessionManager: SessionManager
    @Binding var isPresented: Bool
    
    @State private var pageTitle: String = ""
    @State private var isLoading: Bool = true
    @State private var pageContent: String?
    @State private var errorMessage: String?
    @FocusState private var focusedButton: ButtonType?
    
    enum ButtonType: Hashable {
        case close
        case retry
    }
    
    var body: some View {
        ZStack {
            GlassmorphicBackground()
            
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let content = pageContent {
                    contentView(content)
                } else {
                    urlPreviewView
                }
            }
        }
        .onAppear {
            loadPageContent()
        }
        .onExitCommand {
            isPresented = false
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button
            Button(action: { isPresented = false }) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Zurück")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                }
                .foregroundColor(focusedButton == .close ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                        .fill(focusedButton == .close ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .focused($focusedButton, equals: .close)
            
            // URL-Anzeige
            HStack(spacing: 8) {
                Image(systemName: urlSchemeIcon)
                    .font(.system(size: 16))
                    .foregroundColor(urlSchemeColor)
                
                Text(displayURL)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                    .fill(TVOSDesign.Colors.cardBackground)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 20)
        .background(
            TVOSDesign.Colors.navbarBackground.opacity(0.95)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.accentBlue))
                .scaleEffect(2.5)
            
            Text("Seite wird geladen...")
                .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(displayURL)
                .font(.system(size: TVOSDesign.Typography.footnote))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View (geladener Text)
    
    private func contentView(_ content: String) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                // Seitentitel
                if !pageTitle.isEmpty {
                    Text(pageTitle)
                        .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .padding(.bottom, TVOSDesign.Spacing.small)
                }
                
                // Hinweis-Banner
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(TVOSDesign.Colors.accentBlue)
                    
                    Text("Textansicht — Für die vollständige Webseite öffne die URL auf einem anderen Gerät.")
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                        .fill(TVOSDesign.Colors.accentBlue.opacity(0.08))
                )
                
                // Seiteninhalt als Text
                Text(content)
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .lineSpacing(6)
                
                Spacer().frame(height: 40)
                
                // Aktions-Buttons am Ende
                actionButtons
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            .padding(.vertical, TVOSDesign.Spacing.cardSpacing)
        }
    }
    
    // MARK: - URL Preview View (Fallback)
    
    private var urlPreviewView: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(TVOSDesign.Colors.accentBlue.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "globe")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Text(pageTitle.isEmpty ? "Webseite" : pageTitle)
                    .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .multilineTextAlignment(.center)
                
                Text(displayURL)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 800)
                
                Text("Webseiten können auf Apple TV nur als Text dargestellt werden.\nÖffne die URL auf einem iPhone, iPad oder Mac für die vollständige Ansicht.")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 700)
                    .padding(.top, 8)
            }
            
            // Aktions-Buttons
            actionButtons
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(TVOSDesign.Colors.systemOrange)
            
            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Text("Seite konnte nicht geladen werden")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(error)
                    .font(.system(size: TVOSDesign.Typography.callout))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)
            }
            
            HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                TVOSButton(title: "Erneut versuchen", icon: "arrow.clockwise", style: .primary) {
                    loadPageContent()
                }
                
                TVOSButton(title: "Zurück", icon: "chevron.left", style: .secondary) {
                    isPresented = false
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            TVOSButton(title: "Zurück", icon: "chevron.left", style: .secondary) {
                isPresented = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private var displayURL: String {
        guard let urlObj = URL(string: url), let host = urlObj.host else { return url }
        var h = host
        if h.hasPrefix("www.") { h = String(h.dropFirst(4)) }
        return h
    }
    
    private var urlSchemeIcon: String {
        url.hasPrefix("https") ? "lock.fill" : "globe"
    }
    
    private var urlSchemeColor: Color {
        url.hasPrefix("https") ? TVOSDesign.Colors.systemGreen : TVOSDesign.Colors.tertiaryLabel
    }
    
    // MARK: - Actions
    
    private func loadPageContent() {
        isLoading = true
        errorMessage = nil
        pageContent = nil
        
        Task {
            do {
                guard let pageURL = URL(string: url) else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: pageURL)
                request.timeoutInterval = 15
                request.setValue(
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                    forHTTPHeaderField: "User-Agent"
                )
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw URLError(.badServerResponse, userInfo: [
                        NSLocalizedDescriptionKey: "HTTP \(statusCode)"
                    ])
                }
                
                guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                // Titel extrahieren
                let extractedTitle = extractTitle(from: html)
                
                // HTML zu lesbarem Text konvertieren
                let readableText = convertHTMLToReadableText(html)
                
                await MainActor.run {
                    self.pageTitle = extractedTitle ?? displayURL
                    if readableText.trimmingCharacters(in: .whitespacesAndNewlines).count > 50 {
                        self.pageContent = readableText
                    }
                    self.isLoading = false
                }
                
            } catch is CancellationError {
                // Task wurde abgebrochen, nichts tun
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - HTML Parsing Helpers
    
    private func extractTitle(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let titleRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[titleRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
    
    private func convertHTMLToReadableText(_ html: String) -> String {
        var text = html
        
        // Entferne script und style Blöcke
        let blockPatterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<nav[^>]*>[\\s\\S]*?</nav>",
            "<header[^>]*>[\\s\\S]*?</header>",
            "<footer[^>]*>[\\s\\S]*?</footer>",
            "<!--[\\s\\S]*?-->"
        ]
        
        for pattern in blockPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
            }
        }
        
        // Block-Elemente in Zeilenumbrüche
        let blockElements = ["</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>",
                            "<br>", "<br/>", "<br />", "</li>", "</tr>", "</article>", "</section>"]
        for element in blockElements {
            text = text.replacingOccurrences(of: element, with: "\n", options: .caseInsensitive)
        }
        
        // Listenpunkte
        text = text.replacingOccurrences(of: "<li[^>]*>", with: "\n• ", options: [.regularExpression, .caseInsensitive])
        
        // Alle übrigen HTML-Tags entfernen
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        
        // HTML-Entities dekodieren
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&mdash;", "—"), ("&ndash;", "–"),
            ("&laquo;", "«"), ("&raquo;", "»"), ("&copy;", "©"),
            ("&reg;", "®"), ("&trade;", "™"), ("&euro;", "€"),
            ("&pound;", "£"), ("&yen;", "¥"), ("&hellip;", "…")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Numerische Entities
        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches.reversed() {
                if let codeRange = Range(match.range(at: 1), in: text),
                   let code = Int(text[codeRange]),
                   let scalar = Unicode.Scalar(code) {
                    let char = String(Character(scalar))
                    text = (text as NSString).replacingCharacters(in: match.range, with: char)
                }
            }
        }
        
        // Mehrfache Leerzeilen reduzieren
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // Mehrfache Leerzeichen reduzieren
        if let regex = try? NSRegularExpression(pattern: "[ \\t]+", options: []) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
        }
        
        // Zeilen trimmen
        let lines = text.components(separatedBy: "\n")
        let trimmedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        text = trimmedLines.joined(separator: "\n")
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview

#Preview {
    TextPreviewWebView(
        url: "https://de.wikipedia.org/wiki/Apple",
        sessionManager: SessionManager(),
        isPresented: .constant(true)
    )
}
