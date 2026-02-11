//
//  SearchService.swift
//  AppleTVBrowser
//

import Foundation
import os.log

/// Service für die Web-Suche über mehrere Suchmaschinen.
/// Verwendet Actor-Isolation für Thread-Sicherheit.
actor SearchService {
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "AppleTVBrowser", category: "SearchService")
    
    // MARK: - Error Types
    enum SearchError: LocalizedError {
        case invalidURL
        case invalidQuery
        case networkError(Error)
        case parsingError
        case noResults
        case rateLimited
        case allSourcesFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Ungültige Such-URL"
            case .invalidQuery:
                return "Ungültige Suchanfrage"
            case .networkError(let error):
                return "Netzwerkfehler: \(error.localizedDescription)"
            case .parsingError:
                return "Fehler beim Verarbeiten der Suchergebnisse"
            case .noResults:
                return "Keine Ergebnisse gefunden"
            case .rateLimited:
                return "Zu viele Anfragen. Bitte warte einen Moment."
            case .allSourcesFailed:
                return "Alle Suchquellen fehlgeschlagen. Prüfe deine Internetverbindung."
            }
        }
    }
    
    // MARK: - Search Source
    enum SearchSource: String, CaseIterable {
        case duckduckgo = "DuckDuckGo"
        case google = "Google"
    }
    
    // MARK: - Configuration
    private struct Configuration {
        static let maxResults = 20
        static let requestTimeout: TimeInterval = 15
        static let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
        
        // Such-URLs - Using DuckDuckGo Lite for simpler HTML structure
        static let duckDuckGoURL = "https://lite.duckduckgo.com/lite/"
        static let googleURL = "https://www.google.com/search"
        
        // Debugging
        static let enableDebugOutput = true
    }
    
    // MARK: - Properties
    private var session: URLSession
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Configuration.requestTimeout
        config.timeoutIntervalForResource = Configuration.requestTimeout * 2
        config.httpAdditionalHeaders = [
            "User-Agent": Configuration.userAgents.randomElement()!,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "de-DE,de;q=0.9,en;q=0.8"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Führt eine Web-Suche durch und gibt die Ergebnisse zurück.
    /// Versucht mehrere Suchquellen, falls eine fehlschlägt.
    func search(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🔍 Starte Suche für: \(trimmedQuery)")
        
        var lastError: Error?
        
        // Versuche DuckDuckGo zuerst (stabiler)
        do {
            let results = try await searchDuckDuckGo(query: trimmedQuery)
            if !results.isEmpty {
                logger.info("✅ DuckDuckGo: \(results.count) Ergebnisse")
                return results
            }
        } catch {
            logger.warning("⚠️ DuckDuckGo fehlgeschlagen: \(error.localizedDescription)")
            lastError = error
        }
        
        // Fallback: Google
        do {
            let results = try await searchGoogle(query: trimmedQuery)
            if !results.isEmpty {
                logger.info("✅ Google: \(results.count) Ergebnisse")
                return results
            }
        } catch {
            logger.warning("⚠️ Google fehlgeschlagen: \(error.localizedDescription)")
            lastError = error
        }
        
        // Alle Quellen fehlgeschlagen
        logger.error("❌ Alle Suchquellen fehlgeschlagen")
        throw lastError ?? SearchError.allSourcesFailed
    }
    
    // MARK: - DuckDuckGo Search
    
    private func searchDuckDuckGo(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        // Use DuckDuckGo Lite with GET request for simpler structure
        guard let url = URL(string: "\(Configuration.duckDuckGoURL)?q=\(encodedQuery)") else {
            throw SearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        logger.debug("📤 DuckDuckGo Lite Request: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
        }
        
        logger.debug("📥 DuckDuckGo Status: \(httpResponse.statusCode)")
        
        // DuckDuckGo Lite kann auch 202 (Accepted) zurückgeben
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 202 else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.parsingError
        }
        
        logger.debug("📄 HTML Länge: \(html.count) Zeichen")
        
        // Debug: Show HTML structure around search results
        if Configuration.enableDebugOutput {
            debugHTMLStructure(html: html, source: "DuckDuckGo Lite")
        }
        
        return try await parseDuckDuckGoResults(html: html)
    }

    private func parseDuckDuckGoResults(html: String) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        var seenURLs = Set<String>()

        // DuckDuckGo Lite - NEW PATTERN for current HTML structure
        // Matches: <a rel="nofollow" href="//duckduckgo.com/l/?uddg=https%3A...">Title</a>
        let pattern = "<a\\s+rel=\"nofollow\"\\s+href=\"([^\"]+)\"[^>]*class=['\"]result-link['\"]>([^<]+)</a>"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: nsRange)
            
            logger.debug("🔍 Gefundene Links: \(matches.count)")
            
            for match in matches {
                guard match.numberOfRanges >= 3,
                      let urlRange = Range(match.range(at: 1), in: html),
                      let titleRange = Range(match.range(at: 2), in: html) else {
                    continue
                }
                
                var urlString = String(html[urlRange])
                let title = removingHTMLTags(from: String(html[titleRange])).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip ads and internal links
                if urlString.contains("ad_domain") || urlString.contains("ad_provider") {
                    continue
                }
                
                // Clean up URL - handle DuckDuckGo redirects
                // Format: //duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com&rut=...
                if urlString.contains("duckduckgo.com/l/?uddg=") {
                    // Extract the encoded URL from uddg parameter
                    if let uddgRange = urlString.range(of: "uddg=") {
                        var encodedURL = String(urlString[uddgRange.upperBound...])
                        // Remove everything after the first & (tracking parameters)
                        if let ampRange = encodedURL.range(of: "&") {
                            encodedURL = String(encodedURL[..<ampRange.lowerBound])
                        }
                        // Decode the URL
                        if let decodedURL = encodedURL.removingPercentEncoding,
                           decodedURL.hasPrefix("http") {
                            urlString = decodedURL
                        } else {
                            continue
                        }
                    } else {
                        continue
                    }
                } else if urlString.hasPrefix("//") {
                    urlString = "https:" + urlString
                } else if urlString.hasPrefix("/") && !urlString.hasPrefix("//") {
                    continue
                } else if !urlString.hasPrefix("http") {
                    continue
                }
                
                // More lenient filtering
                guard !title.isEmpty,
                      title.count > 2, // Allow shorter titles
                      !title.contains("more info"), // Skip "more info" links
                      isValidExternalURL(urlString),
                      !seenURLs.contains(urlString) else {
                    continue
                }
                
                seenURLs.insert(urlString)
                
                await MainActor.run {
                    results.append(SearchResult(title: title, url: urlString, description: ""))
                }
                
                if results.count >= Configuration.maxResults {
                    break
                }
            }
            
        } catch {
            logger.error("❌ Regex Fehler: \(error)")
            throw SearchError.parsingError
        }
        
        logger.debug("🔎 DuckDuckGo geparst: \(results.count) Ergebnisse")
        
        if results.isEmpty {
            throw SearchError.noResults
        }
        
        return results
    }
    
    // MARK: - Google Search
    
    private func searchGoogle(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Configuration.googleURL)?q=\(encodedQuery)&hl=de&num=\(Configuration.maxResults)") else {
            throw SearchError.invalidURL
        }
        
        logger.debug("📤 Google Request: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
        }
        
        logger.debug("📥 Google Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw SearchError.rateLimited
            }
            throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.parsingError
        }
        
        logger.debug("📄 HTML Länge: \(html.count) Zeichen")
        
        return try await parseGoogleResults(html: html)
    }

    private func parseGoogleResults(html: String) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        var seenURLs = Set<String>()

        // Try multiple patterns for Google search results
        let patterns = [
            // Current Google pattern
            "<a href=\"/url\\?q=([^&\"]+)[^\"]*\"[^>]*><h3[^>]*>(.*?)</h3></a>",
            // Alternative pattern
            "<a[^>]*href=\"/url\\?q=([^&\"]+)[^\"]*\"[^>]*>.*?<h3[^>]*>(.*?)</h3>",
            // Fallback pattern for direct links
            "<a[^>]*href=\"(https?://[^\"]+)\"[^>]*><h3[^>]*>(.*?)</h3></a>",
            // Simple pattern for any external link with title
            "<h3[^>]*><a[^>]*href=\"/url\\?q=([^&\"]+)[^\"]*\"[^>]*>(.*?)</a></h3>"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
                let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: nsRange)

                logger.debug("🔍 Google Pattern \(index + 1): \(matches.count) matches found")

                for match in matches {
                    guard match.numberOfRanges >= 3,
                          let urlRange = Range(match.range(at: 1), in: html),
                          let titleRange = Range(match.range(at: 2), in: html) else {
                        continue
                    }

                    var urlString = String(html[urlRange])
                    let title = removingHTMLTags(from: String(html[titleRange])).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Clean up URL
                    if let decodedURL = urlString.removingPercentEncoding {
                        urlString = decodedURL
                    }
                    
                    // Remove Google tracking parameters
                    if let range = urlString.range(of: "&sa=") {
                        urlString = String(urlString[..<range.lowerBound])
                    }

                    guard !title.isEmpty,
                          title.count > 3,
                          isValidExternalURL(urlString),
                          !seenURLs.contains(urlString) else {
                        continue
                    }

                    seenURLs.insert(urlString)
                    await MainActor.run {
                        results.append(SearchResult(title: title, url: urlString, description: ""))
                    }

                    if results.count >= Configuration.maxResults {
                        break
                    }
                }
                
                if !results.isEmpty {
                    logger.debug("✅ Google Pattern \(index + 1) erfolgreich: \(results.count) Ergebnisse")
                    break
                }
                
            } catch {
                logger.warning("⚠️ Google Pattern \(index + 1) Fehler: \(error)")
            }
        }
        
        logger.debug("🔎 Google geparst: \(results.count) Ergebnisse")
        return results
    }

    // MARK: - Helper Methods
    
    private func isValidExternalURL(_ url: String) -> Bool {
        guard let urlObject = URL(string: url),
              let host = urlObject.host,
              (urlObject.scheme == "http" || urlObject.scheme == "https") else {
            return false
        }
        
        // Filtere bekannte Domains von Suchmaschinen und deren CDNs
        let blockedDomains = [
            "google.com", "google.de", "gstatic.com", "googleapis.com",
            "googleusercontent.com", "duckduckgo.com", "duck.co", "youtube.com"
        ]
        
        let lowercasedHost = host.lowercased()
        
        for domain in blockedDomains {
            // Blockiere die Domain selbst oder Subdomains davon (z.B. ads.google.com)
            if lowercasedHost == domain || lowercasedHost.hasSuffix(".\(domain)") {
                return false
            }
        }
        
        return true
    }

    private func removingHTMLTags(from string: String) -> String {
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
    
    private func extractURLFromDuckDuckGoRedirect(_ redirectString: String) -> String? {
        // Extract URL from DuckDuckGo redirect like "/l/?uddg=https%3A//example.com"
        if let range = redirectString.range(of: "uddg=") {
            let urlPart = String(redirectString[range.upperBound...])
            return urlPart.removingPercentEncoding
        }
        return nil
    }
    
    private func debugHTMLStructure(html: String, source: String) {
        logger.debug("🔍 HTML Debug für \(source):")
        
        // Look for any <a> tags to understand the structure
        do {
            let linkRegex = try NSRegularExpression(pattern: "<a[^>]*href[^>]*>[^<]*</a>", options: .caseInsensitive)
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = linkRegex.matches(in: html, options: [], range: nsRange)
            
            logger.debug("📋 Gefundene Links: \(matches.count)")
            
            // Show first few links for debugging
            for (index, match) in matches.prefix(5).enumerated() {
                if let range = Range(match.range, in: html) {
                    let linkHTML = String(html[range])
                    logger.debug("🔗 Link \(index + 1): \(linkHTML)")
                }
            }
        } catch {
            logger.error("❌ Debug Regex Fehler: \(error)")
        }
    }
}
