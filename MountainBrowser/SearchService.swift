//
//  SearchService.swift
//  MountainBrowser
//

import Foundation
import Combine
import os.log

/// Service für die Web-Suche.
/// Hinweis: Netzwerk-Operationen laufen NICHT auf dem Main Actor.
class SearchService {
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "MountainBrowser", category: "SearchService")
    
    // MARK: - Configuration
    private struct Configuration {
        static let maxResults = 50
        static let requestTimeout: TimeInterval = 30
        static let maxRetries = 2
        static let retryDelay: UInt64 = 1_000_000_000
        
        static let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
    }
    
    // MARK: - Properties
    private var session: URLSession
    private var wikipediaInfos: [String: WikipediaInfo] = [:]
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Configuration.requestTimeout
        config.timeoutIntervalForResource = Configuration.requestTimeout * 2
        config.httpAdditionalHeaders = [
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "de-DE,de;q=0.9,en;q=0.8",
            "User-Agent": Configuration.userAgents.randomElement()!
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Führt eine Web-Suche durch (DuckDuckGo)
    func search(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🔍 DuckDuckGo Web-Suche für: \(trimmedQuery)")
        
        // Versuche DuckDuckGo HTML zuerst
        do {
            let results = try await searchDuckDuckGoHTML(query: trimmedQuery)
            if !results.isEmpty {
                logger.info("✅ DuckDuckGo HTML: \(results.count) Ergebnisse")
                return results
            }
        } catch {
            logger.warning("⚠️ DuckDuckGo HTML fehlgeschlagen: \(error.localizedDescription)")
        }
        
        // Fallback: DuckDuckGo Lite
        do {
            let results = try await searchDuckDuckGoLite(query: trimmedQuery)
            if !results.isEmpty {
                logger.info("✅ DuckDuckGo Lite: \(results.count) Ergebnisse")
                return results
            }
        } catch {
            logger.warning("⚠️ DuckDuckGo Lite fehlgeschlagen: \(error.localizedDescription)")
        }
        
        throw SearchError.noResults
    }
    
    // MARK: - DuckDuckGo HTML Search
    
    private func searchDuckDuckGoHTML(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://html.duckduckgo.com/html/?q=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Configuration.userAgents.randomElement()!, forHTTPHeaderField: "User-Agent")
        
        logger.debug("📤 DuckDuckGo HTML Request: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
        }
        
        logger.debug("📥 DuckDuckGo HTML Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.parsingError
        }
        
        return parseDuckDuckGoHTMLResults(html: html)
    }
    
    private func parseDuckDuckGoHTMLResults(html: String) -> [SearchResult] {
        var results: [SearchResult] = []
        var seenURLs = Set<String>()
        
        let patterns = [
            "<a[^>]*class=\"result__a\"[^>]*href=\"([^\"]+)\"[^>]*>([^<]+)</a>",
            "<a[^>]*href=\"([^\"]+)\"[^>]*class=\"result__a\"[^>]*>([^<]+)</a>"
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
                continue
            }
            
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: nsRange)
            
            for match in matches {
                guard match.numberOfRanges >= 3,
                      let urlRange = Range(match.range(at: 1), in: html),
                      let titleRange = Range(match.range(at: 2), in: html) else {
                    continue
                }
                
                var urlString = String(html[urlRange])
                let title = removingHTMLTags(from: String(html[titleRange])).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if urlString.contains("//duckduckgo.com/l/?") {
                    if let uddgRange = urlString.range(of: "uddg=") {
                        var encodedURL = String(urlString[uddgRange.upperBound...])
                        if let ampRange = encodedURL.range(of: "&") {
                            encodedURL = String(encodedURL[..<ampRange.lowerBound])
                        }
                        if let decodedURL = encodedURL.removingPercentEncoding {
                            urlString = decodedURL
                        }
                    }
                }
                
                guard urlString.hasPrefix("http"),
                      !title.isEmpty,
                      title.count > 2,
                      isValidExternalURL(urlString),
                      !seenURLs.contains(urlString) else {
                    continue
                }
                
                seenURLs.insert(urlString)
                
                let description = extractDescription(for: urlString, from: html)
                
                results.append(SearchResult(
                    title: title,
                    url: urlString,
                    description: description,
                    contentType: .web
                ))
                
                if results.count >= Configuration.maxResults {
                    break
                }
            }
            
            if !results.isEmpty {
                break
            }
        }
        
        return results
    }
    
    // MARK: - DuckDuckGo Lite Search
    
    private func searchDuckDuckGoLite(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://lite.duckduckgo.com/lite/?q=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Configuration.userAgents.randomElement()!, forHTTPHeaderField: "User-Agent")
        
        logger.debug("📤 DuckDuckGo Lite Request: \(url.absoluteString)")
        
        for attempt in 0..<Configuration.maxRetries {
            // FIX: Prüfe ob Task gecancelled wurde bevor wir fortfahren
            try Task.checkCancellation()
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
            }
            
            logger.debug("📥 DuckDuckGo Lite Status: \(httpResponse.statusCode) (Attempt \(attempt + 1))")
            
            if httpResponse.statusCode == 202 {
                if attempt < Configuration.maxRetries - 1 {
                    // FIX: Task.sleep in do/catch wrappen für sauberes Cancellation-Handling
                    do {
                        try await Task.sleep(nanoseconds: Configuration.retryDelay)
                    } catch {
                        // Task wurde gecancelled während des Schlafens — sauber abbrechen
                        throw SearchError.cancelled
                    }
                    continue
                }
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw SearchError.parsingError
            }
            
            return parseDuckDuckGoLiteResults(html: html)
        }
        
        throw SearchError.noResults
    }
    
    private func parseDuckDuckGoLiteResults(html: String) -> [SearchResult] {
        var results: [SearchResult] = []
        var seenURLs = Set<String>()
        
        let pattern = "<a\\s+rel=\"nofollow\"\\s+href=\"([^\"]+)\"[^>]*class=['\"]result-link['\"]>([^<]+)</a>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return results
        }
        
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let urlRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html) else {
                continue
            }
            
            var urlString = String(html[urlRange])
            let title = removingHTMLTags(from: String(html[titleRange])).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if urlString.contains("ad_domain") || urlString.contains("ad_provider") {
                continue
            }
            
            if urlString.contains("duckduckgo.com/l/?uddg=") {
                if let uddgRange = urlString.range(of: "uddg=") {
                    var encodedURL = String(urlString[uddgRange.upperBound...])
                    if let ampRange = encodedURL.range(of: "&") {
                        encodedURL = String(encodedURL[..<ampRange.lowerBound])
                    }
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
            
            guard !title.isEmpty,
                  title.count > 2,
                  !title.contains("more info"),
                  isValidExternalURL(urlString),
                  !seenURLs.contains(urlString) else {
                continue
            }
            
            seenURLs.insert(urlString)
            
            results.append(SearchResult(
                title: title,
                url: urlString,
                description: "",
                contentType: .web
            ))
            
            if results.count >= Configuration.maxResults {
                break
            }
        }
        
        return results
    }
    
    // MARK: - Image Search
    
    func searchImages(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🖼️ Bildersuche für: \(trimmedQuery)")
        
        if APIConfiguration.isGoogleSearchConfigured {
            do {
                let results = try await searchGoogleImages(query: trimmedQuery)
                if !results.isEmpty {
                    return results
                }
            } catch {
                logger.warning("⚠️ Google Images fehlgeschlagen: \(error.localizedDescription)")
            }
        }
        
        logger.info("🔄 Verwende Unsplash Fallback für Bilder")
        return await searchUnsplashImages(query: trimmedQuery)
    }
    
    private func searchGoogleImages(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "\(APIConfiguration.Endpoints.googleCustomSearch)?key=\(APIConfiguration.googleAPIKey)&cx=\(APIConfiguration.googleSearchEngineID)&q=\(encodedQuery)&searchType=image&num=20&safe=moderate"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
        }
        
        if httpResponse.statusCode == 429 {
            throw SearchError.rateLimited
        } else if httpResponse.statusCode == 403 {
            throw SearchError.apiQuotaExceeded
        } else if httpResponse.statusCode != 200 {
            throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
        }
        
        let searchResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        
        guard let items = searchResponse.items, !items.isEmpty else {
            return []
        }
        
        let results: [SearchResult] = items.map { item in
            SearchResult(
                title: item.title,
                url: item.image?.contextLink ?? item.link,
                description: item.snippet ?? "",
                contentType: .image,
                thumbnailURL: item.image?.thumbnailLink ?? item.link,
                imageWidth: item.image?.width,
                imageHeight: item.image?.height,
                source: "Google Images"
            )
        }
        
        logger.info("✅ Google Images: \(results.count) Ergebnisse")
        return results
    }
    
    private func searchUnsplashImages(query: String) async -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        var results: [SearchResult] = []
        
        for i in 1...12 {
            let seed = "\(encodedQuery)\(i)".hashValue
            let imageURL = "https://picsum.photos/seed/\(abs(seed))/800/600"
            let thumbnailURL = "https://picsum.photos/seed/\(abs(seed))/400/300"
            
            results.append(SearchResult(
                title: "\(query) - Bild \(i)",
                url: imageURL,
                description: "Bild zu '\(query)'",
                contentType: .image,
                thumbnailURL: thumbnailURL,
                imageWidth: 800,
                imageHeight: 600,
                source: "Picsum"
            ))
        }
        
        logger.info("✅ Picsum: \(results.count) Bilder")
        return results
    }
    
    // MARK: - Video Search
    
    func searchVideos(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🎥 YouTube-Suche für: \(trimmedQuery)")
        
        guard APIConfiguration.isYouTubeConfigured else {
            logger.warning("⚠️ YouTube API nicht konfiguriert")
            return []
        }
        
        return try await searchYouTubeVideos(query: trimmedQuery)
    }
    
    private func searchYouTubeVideos(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "\(APIConfiguration.Endpoints.youtubeSearch)?part=snippet&maxResults=20&q=\(encodedQuery)&type=video&key=\(APIConfiguration.youtubeAPIKey)&safeSearch=moderate&relevanceLanguage=de"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.networkError(NSError(domain: "HTTP", code: -1))
        }
        
        if httpResponse.statusCode == 429 {
            throw SearchError.rateLimited
        } else if httpResponse.statusCode == 403 {
            throw SearchError.apiQuotaExceeded
        } else if httpResponse.statusCode != 200 {
            throw SearchError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
        }
        
        let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        guard let items = searchResponse.items, !items.isEmpty else {
            return []
        }
        
        let results: [SearchResult] = items.compactMap { item in
            guard let videoId = item.id.videoId else { return nil }
            
            let videoURL = "https://www.youtube.com/watch?v=\(videoId)"
            let thumbnailURL = item.snippet.thumbnails.medium?.url ??
                               item.snippet.thumbnails.high?.url ??
                               item.snippet.thumbnails.default?.url
            
            return SearchResult(
                title: item.snippet.title,
                url: videoURL,
                description: item.snippet.description,
                contentType: .video,
                thumbnailURL: thumbnailURL,
                source: "YouTube"
            )
        }
        
        logger.info("✅ YouTube: \(results.count) Videos")
        return results
    }
    
    // MARK: - Wikipedia Search
    
    func searchWikipedia(query: String) async throws -> WikipediaInfo? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            return nil
        }
        
        logger.info("📖 Wikipedia-Suche für: \(trimmedQuery)")
        
        let wikipediaService = WikipediaService()
        
        do {
            if let info = try await wikipediaService.searchWikipedia(query: trimmedQuery) {
                wikipediaInfos[info.articleURL] = info
                return info
            }
        } catch {
            logger.warning("⚠️ Wikipedia fehlgeschlagen: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func isValidExternalURL(_ url: String) -> Bool {
        guard let urlObject = URL(string: url),
              let host = urlObject.host,
              (urlObject.scheme == "http" || urlObject.scheme == "https") else {
            return false
        }
        
        let blockedDomains = [
            "google.com", "google.de", "gstatic.com", "googleapis.com",
            "googleusercontent.com", "duckduckgo.com", "duck.co"
        ]
        
        let lowercasedHost = host.lowercased()
        
        for domain in blockedDomains {
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
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
    
    private func extractDescription(for url: String, from html: String) -> String {
        let pattern = "class=\"result__snippet[^\"]*\"[^>]*>([^<]+)</[^>]+>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return ""
        }
        
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        
        for match in matches {
            if match.numberOfRanges >= 2,
               let descRange = Range(match.range(at: 1), in: html) {
                let description = removingHTMLTags(from: String(html[descRange]))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !description.isEmpty && description.count > 10 {
                    return description
                }
            }
        }
        
        return ""
    }
    
    // MARK: - Wikipedia Info Access
    
    func getWikipediaInfo(for url: String) -> WikipediaInfo? {
        return wikipediaInfos[url]
    }
}
