//
//  SearchService_Simplified.swift
//  AppleTVBrowser
//
//  Vereinfachte Version mit besserem Error-Handling
//

import Foundation
import os.log

/// Vereinfachter Such-Service für tvOS
actor SearchServiceSimplified {
    
    private let logger = Logger(subsystem: "AppleTVBrowser", category: "Search")
    
    enum SearchError: LocalizedError {
        case networkError(String)
        case parsingError(String)
        case noResults
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg):
                return "Netzwerkfehler: \(msg)"
            case .parsingError(let msg):
                return "Parse-Fehler: \(msg)"
            case .noResults:
                return "Keine Ergebnisse gefunden"
            }
        }
    }
    
    func search(query: String) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SearchError.parsingError("Leere Suchanfrage")
        }
        
        logger.info("🔍 Suche: \(trimmed)")
        
        // Einfache DuckDuckGo HTML Suche
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://html.duckduckgo.com/html/?q=\(encoded)") else {
            throw SearchError.networkError("Ungültige URL")
        }
        
        do {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", 
                           forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw SearchError.parsingError("Keine UTF-8 Daten")
            }
            
            logger.debug("📄 HTML: \(html.count) Zeichen")
            
            let results = try await parseSimpleDDG(html: html)
            
            if results.isEmpty {
                throw SearchError.noResults
            }
            
            logger.info("✅ \(results.count) Ergebnisse gefunden")
            return results
            
        } catch let error as SearchError {
            throw error
        } catch {
            logger.error("❌ Fehler: \(error.localizedDescription)")
            throw SearchError.networkError(error.localizedDescription)
        }
    }
    
    private func parseSimpleDDG(html: String) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Sehr einfaches Pattern für DuckDuckGo HTML
        let pattern = "<a[^>]*class=\"result__a\"[^>]*href=\"([^\"]+)\"[^>]*>(.*?)</a>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            throw SearchError.parsingError("Regex Fehler")
        }
        
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        
        logger.debug("🔍 \(matches.count) Links gefunden")
        
        for match in matches.prefix(15) {
            guard match.numberOfRanges >= 3,
                  let urlRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html) else {
                continue
            }
            
            let url = String(html[urlRange])
            let title = cleanHTML(String(html[titleRange]))
            
            guard !url.isEmpty, !title.isEmpty,
                  url.hasPrefix("http"),
                  !url.contains("duckduckgo.com") else {
                continue
            }
            
            await MainActor.run {
                results.append(SearchResult(
                    title: title,
                    url: url,
                    description: ""
                ))
            }
        }
        
        return results
    }
    
    private func cleanHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}