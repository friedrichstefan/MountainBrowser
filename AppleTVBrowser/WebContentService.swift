//
//  WebContentService.swift
//  AppleTVBrowser
//
//  Fetcht Webseiten und extrahiert lesbaren Inhalt für tvOS
//  (Da tvOS kein WebKit hat, rendern wir Inhalte nativ in SwiftUI)
//

import Foundation
import os.log

/// Extrahierter Webseiten-Inhalt für native Darstellung
struct WebPageContent: Sendable {
    let url: String
    let title: String
    let siteName: String
    let heroImageURL: String?
    let sections: [ContentSection]
    let links: [PageLink]
    let isReadable: Bool
    
    struct ContentSection: Identifiable, Sendable {
        let id = UUID()
        let type: SectionType
        let text: String
        let imageURL: String?
        
        enum SectionType: Sendable {
            case heading1
            case heading2
            case heading3
            case paragraph
            case quote
            case listItem
            case image
            case code
        }
    }
    
    struct PageLink: Identifiable, Sendable {
        let id = UUID()
        let title: String
        let url: String
    }
    
    static let empty = WebPageContent(
        url: "",
        title: "Seite nicht verfügbar",
        siteName: "",
        heroImageURL: nil,
        sections: [.init(type: .paragraph, text: "Diese Seite konnte nicht geladen werden.", imageURL: nil)],
        links: [],
        isReadable: false
    )
}

/// Service der Webseiten-Inhalte fetcht und für native Darstellung aufbereitet
actor WebContentService {
    
    private let logger = Logger(subsystem: "AppleTVBrowser", category: "WebContentService")
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "de-DE,de;q=0.9,en;q=0.8"
        ]
        self.session = URLSession(configuration: config)
    }
    
    /// Fetcht und parst eine Webseite
    func fetchContent(from urlString: String) async throws -> WebPageContent {
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        logger.info("🌐 Lade Webseite: \(urlString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("❌ HTTP Fehler: \(code)")
            throw SearchError.networkError(NSError(domain: "HTTP", code: code))
        }
        
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw SearchError.parsingError
        }
        
        let content = parseHTML(html, url: urlString)
        logger.info("✅ Webseite geladen: \(content.title) (\(content.sections.count) Abschnitte, \(content.links.count) Links)")
        return content
    }
    
    // MARK: - HTML Parsing
    
    private func parseHTML(_ html: String, url: String) -> WebPageContent {
        let title = extractTitle(from: html)
        let siteName = extractSiteName(from: html, url: url)
        let heroImage = extractHeroImage(from: html, baseURL: url)
        let sections = extractContentSections(from: html)
        let links = extractLinks(from: html, baseURL: url)
        
        return WebPageContent(
            url: url,
            title: title,
            siteName: siteName,
            heroImageURL: heroImage,
            sections: sections,
            links: links,
            isReadable: !sections.isEmpty
        )
    }
    
    private func extractTitle(from html: String) -> String {
        // <title>...</title>
        if let match = html.range(of: "<title[^>]*>(.*?)</title>", options: [.regularExpression, .caseInsensitive]),
           let contentRange = html[match].range(of: ">(.*?)<", options: .regularExpression) {
            let raw = String(html[contentRange]).dropFirst().dropLast()
            return decodeHTMLEntities(String(raw)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // og:title
        if let ogTitle = extractMetaContent(from: html, property: "og:title") {
            return ogTitle
        }
        
        return "Webseite"
    }
    
    private func extractSiteName(from html: String, url: String) -> String {
        if let ogSite = extractMetaContent(from: html, property: "og:site_name") {
            return ogSite
        }
        if let host = URL(string: url)?.host {
            var name = host
            if name.hasPrefix("www.") { name = String(name.dropFirst(4)) }
            return name
        }
        return ""
    }
    
    private func extractHeroImage(from html: String, baseURL: String) -> String? {
        // og:image
        if let ogImage = extractMetaContent(from: html, property: "og:image") {
            return resolveURL(ogImage, base: baseURL)
        }
        // twitter:image
        if let twImage = extractMetaContent(from: html, name: "twitter:image") {
            return resolveURL(twImage, base: baseURL)
        }
        return nil
    }
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]*property=[\"']\(property)[\"'][^>]*content=[\"']([^\"']+)[\"']"
        let pattern2 = "<meta[^>]*content=[\"']([^\"']+)[\"'][^>]*property=[\"']\(property)[\"']"
        
        for p in [pattern, pattern2] {
            if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return decodeHTMLEntities(String(html[range]))
            }
        }
        return nil
    }
    
    private func extractMetaContent(from html: String, name: String) -> String? {
        let pattern = "<meta[^>]*name=[\"']\(name)[\"'][^>]*content=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return decodeHTMLEntities(String(html[range]))
        }
        return nil
    }
    
    // MARK: - Content Extraction
    
    private func extractContentSections(from html: String) -> [WebPageContent.ContentSection] {
        var sections: [WebPageContent.ContentSection] = []
        
        // Entferne Script, Style, Nav, Header, Footer Blöcke
        var cleaned = html
        let removePatterns = [
            "<script[^>]*>.*?</script>",
            "<style[^>]*>.*?</style>",
            "<nav[^>]*>.*?</nav>",
            "<footer[^>]*>.*?</footer>",
            "<header[^>]*>.*?</header>",
            "<aside[^>]*>.*?</aside>",
            "<!--.*?-->",
            "<noscript[^>]*>.*?</noscript>"
        ]
        
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }
        
        // Versuche zuerst <article> oder <main> zu finden
        var contentHTML = cleaned
        if let articleContent = extractTag(from: cleaned, tag: "article") {
            contentHTML = articleContent
        } else if let mainContent = extractTag(from: cleaned, tag: "main") {
            contentHTML = mainContent
        } else if let bodyContent = extractTag(from: cleaned, tag: "body") {
            contentHTML = bodyContent
        }
        
        // Extrahiere Überschriften
        let headingPatterns: [(String, WebPageContent.ContentSection.SectionType)] = [
            ("<h1[^>]*>(.*?)</h1>", .heading1),
            ("<h2[^>]*>(.*?)</h2>", .heading2),
            ("<h3[^>]*>(.*?)</h3>", .heading3)
        ]
        
        for (pattern, type) in headingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let matches = regex.matches(in: contentHTML, range: NSRange(contentHTML.startIndex..., in: contentHTML))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: contentHTML) {
                        let text = stripHTML(String(contentHTML[range]))
                        if text.count > 2 && text.count < 500 {
                            sections.append(.init(type: type, text: text, imageURL: nil))
                        }
                    }
                }
            }
        }
        
        // Extrahiere Absätze
        if let regex = try? NSRegularExpression(pattern: "<p[^>]*>(.*?)</p>", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: contentHTML, range: NSRange(contentHTML.startIndex..., in: contentHTML))
            for match in matches {
                if let range = Range(match.range(at: 1), in: contentHTML) {
                    let text = stripHTML(String(contentHTML[range]))
                    if text.count > 20 {
                        sections.append(.init(type: .paragraph, text: text, imageURL: nil))
                    }
                }
            }
        }
        
        // Extrahiere Blockquotes
        if let regex = try? NSRegularExpression(pattern: "<blockquote[^>]*>(.*?)</blockquote>", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: contentHTML, range: NSRange(contentHTML.startIndex..., in: contentHTML))
            for match in matches {
                if let range = Range(match.range(at: 1), in: contentHTML) {
                    let text = stripHTML(String(contentHTML[range]))
                    if text.count > 10 {
                        sections.append(.init(type: .quote, text: text, imageURL: nil))
                    }
                }
            }
        }
        
        // Extrahiere Listeneinträge
        if let regex = try? NSRegularExpression(pattern: "<li[^>]*>(.*?)</li>", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: contentHTML, range: NSRange(contentHTML.startIndex..., in: contentHTML))
            for match in matches.prefix(30) {
                if let range = Range(match.range(at: 1), in: contentHTML) {
                    let text = stripHTML(String(contentHTML[range]))
                    if text.count > 5 && text.count < 500 {
                        sections.append(.init(type: .listItem, text: text, imageURL: nil))
                    }
                }
            }
        }
        
        // Fallback: Wenn kaum Inhalte gefunden, strip alles und teile in Absätze
        if sections.filter({ $0.type == .paragraph }).count < 2 {
            let fullText = stripHTML(contentHTML)
            let paragraphs = fullText.components(separatedBy: "\n\n").filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 30 }
            for para in paragraphs.prefix(20) {
                let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sections.contains(where: { $0.text == trimmed }) {
                    sections.append(.init(type: .paragraph, text: trimmed, imageURL: nil))
                }
            }
        }
        
        return sections
    }
    
    // MARK: - Link Extraction
    
    private func extractLinks(from html: String, baseURL: String) -> [WebPageContent.PageLink] {
        var links: [WebPageContent.PageLink] = []
        var seenURLs = Set<String>()
        
        // Versuche Links aus dem Hauptinhalt zu extrahieren
        var contentHTML = html
        if let articleContent = extractTag(from: html, tag: "article") {
            contentHTML = articleContent
        } else if let mainContent = extractTag(from: html, tag: "main") {
            contentHTML = mainContent
        }
        
        let pattern = "<a[^>]*href=[\"']([^\"'#]+)[\"'][^>]*>(.*?)</a>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: contentHTML, range: NSRange(contentHTML.startIndex..., in: contentHTML))
            for match in matches {
                guard match.numberOfRanges >= 3,
                      let urlRange = Range(match.range(at: 1), in: contentHTML),
                      let titleRange = Range(match.range(at: 2), in: contentHTML) else { continue }
                
                let href = String(contentHTML[urlRange])
                let title = stripHTML(String(contentHTML[titleRange]))
                
                guard !title.isEmpty,
                      title.count > 2,
                      title.count < 200,
                      !href.hasPrefix("javascript:"),
                      !href.hasPrefix("mailto:"),
                      !href.hasPrefix("#") else { continue }
                
                let resolvedURL = resolveURL(href, base: baseURL)
                
                guard !seenURLs.contains(resolvedURL) else { continue }
                seenURLs.insert(resolvedURL)
                
                links.append(.init(title: title, url: resolvedURL))
                
                if links.count >= 20 { break }
            }
        }
        
        return links
    }
    
    // MARK: - Helpers
    
    private func extractTag(from html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>(.*?)</\(tag)>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }
    
    private func stripHTML(_ string: String) -> String {
        var result = string
        // Tags entfernen
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        result = decodeHTMLEntities(result)
        // Whitespace normalisieren
        if let wsRegex = try? NSRegularExpression(pattern: "\\s+", options: []) {
            result = wsRegex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&ndash;", "–"), ("&mdash;", "—"),
            ("&laquo;", "«"), ("&raquo;", "»"),
            ("&ouml;", "ö"), ("&auml;", "ä"), ("&uuml;", "ü"),
            ("&Ouml;", "Ö"), ("&Auml;", "Ä"), ("&Uuml;", "Ü"),
            ("&szlig;", "ß"), ("&euro;", "€"),
            ("&copy;", "©"), ("&reg;", "®"),
            ("&hellip;", "…"), ("&trade;", "™")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // Numerische Entities: &#123;
        if let numRegex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let matches = numRegex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                if let numRange = Range(match.range(at: 1), in: result),
                   let code = UInt32(result[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    let fullRange = Range(match.range, in: result)!
                    result.replaceSubrange(fullRange, with: String(Character(scalar)))
                }
            }
        }
        return result
    }
    
    private func resolveURL(_ href: String, base: String) -> String {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return href
        }
        guard let baseURL = URL(string: base) else { return href }
        if href.hasPrefix("//") {
            return (baseURL.scheme ?? "https") + ":" + href
        }
        if href.hasPrefix("/") {
            return (baseURL.scheme ?? "https") + "://" + (baseURL.host ?? "") + href
        }
        return baseURL.deletingLastPathComponent().appendingPathComponent(href).absoluteString
    }
}
