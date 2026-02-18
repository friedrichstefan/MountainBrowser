//
//  WikipediaInfo.swift
//  AppleTVBrowser
//
//  Datenmodell für Wikipedia Knowledge Panel (wie bei Google)
//

import Foundation

/// Wikipedia-Informationen für Knowledge Panel
struct WikipediaInfo: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let summary: String
    let imageURL: String?
    let articleURL: String
    let infoFields: [InfoField]
    let language: String // "de", "en", etc.
    
    /// Key-Value Informationen aus Wikipedia Infobox
    struct InfoField: Identifiable, Codable, Hashable, Sendable {
        let id: UUID
        let key: String    // z.B. "Gegründet", "Hauptsitz", "CEO"
        let value: String  // z.B. "1976", "Cupertino, CA", "Tim Cook"
        
        init(key: String, value: String) {
            self.id = UUID()
            self.key = key
            self.value = value
        }
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        summary: String,
        imageURL: String? = nil,
        articleURL: String,
        infoFields: [InfoField] = [],
        language: String = "de"
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.imageURL = imageURL
        self.articleURL = articleURL
        self.infoFields = infoFields
        self.language = language
    }
    
    // MARK: - Computed Properties
    
    var displaySummary: String {
        // Begrenzt auf maximal 200 Zeichen für TV-Darstellung
        if summary.count <= 200 {
            return summary
        }
        
        let truncated = String(summary.prefix(197))
        return truncated + "..."
    }
    
    var primaryInfoFields: [InfoField] {
        // Zeigt nur die wichtigsten 4 Informationen an
        return Array(infoFields.prefix(4))
    }
    
    var attributionText: String {
        switch language {
        case "de":
            return "Von Wikipedia"
        case "en":
            return "From Wikipedia"
        default:
            return "From Wikipedia"
        }
    }
}

// MARK: - Wikipedia Service

actor WikipediaService {
    
    // MARK: - Error Types
    enum WikipediaError: LocalizedError {
        case invalidURL
        case noResults
        case networkError(Error)
        case parsingError
        case articleNotFound
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Ungültige Wikipedia URL"
            case .noResults:
                return "Keine Wikipedia-Artikel gefunden"
            case .networkError(let error):
                return "Netzwerkfehler: \(error.localizedDescription)"
            case .parsingError:
                return "Fehler beim Verarbeiten der Wikipedia-Daten"
            case .articleNotFound:
                return "Wikipedia-Artikel nicht gefunden"
            }
        }
    }
    
    // MARK: - Configuration
    private struct Configuration {
        static let requestTimeout: TimeInterval = 10
        static let userAgent = "AppleTVBrowser/1.0 (tvOS; like Safari)"
        static let maxSummaryLength = 200
        
        // Wikipedia API URLs
        static let baseURLs = [
            "de": "https://de.wikipedia.org/api/rest_v1",
            "en": "https://en.wikipedia.org/api/rest_v1"
        ]
        
        static let searchURLs = [
            "de": "https://de.wikipedia.org/w/api.php",
            "en": "https://en.wikipedia.org/w/api.php"
        ]
    }
    
    // MARK: - Properties
    private var session: URLSession
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Configuration.requestTimeout
        config.httpAdditionalHeaders = [
            "User-Agent": Configuration.userAgent,
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Sucht nach Wikipedia-Informationen für eine Suchanfrage
    func searchWikipedia(query: String) async throws -> WikipediaInfo? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw WikipediaError.invalidURL
        }
        
        // Versuche zuerst deutsche Wikipedia, dann englische
        for language in ["de", "en"] {
            do {
                if let info = try await fetchWikipediaInfo(query: trimmedQuery, language: language) {
                    return info
                }
            } catch {
                print("⚠️ Wikipedia \(language): \(error.localizedDescription)")
                continue
            }
        }
        
        return nil // Keine Wikipedia-Info gefunden
    }
    
    // MARK: - Private Methods
    
    private func fetchWikipediaInfo(query: String, language: String) async throws -> WikipediaInfo? {
        // Schritt 1: Suche nach passenden Artikeln
        guard let pageTitle = try await searchWikipediaPage(query: query, language: language) else {
            return nil
        }
        
        // Schritt 2: Hole detaillierte Informationen für den Artikel
        return try await fetchPageDetails(pageTitle: pageTitle, language: language)
    }
    
    private func searchWikipediaPage(query: String, language: String) async throws -> String? {
        guard let searchBaseURL = Configuration.searchURLs[language],
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WikipediaError.invalidURL
        }
        
        let urlString = "\(searchBaseURL)?action=query&format=json&list=search&srsearch=\(encodedQuery)&srlimit=1"
        
        guard let url = URL(string: urlString) else {
            throw WikipediaError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let queryResult = json["query"] as? [String: Any],
              let searchResults = queryResult["search"] as? [[String: Any]],
              let firstResult = searchResults.first,
              let title = firstResult["title"] as? String else {
            return nil
        }
        
        return title
    }
    
    private func fetchPageDetails(pageTitle: String, language: String) async throws -> WikipediaInfo? {
        guard let baseURL = Configuration.baseURLs[language],
              let encodedTitle = pageTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw WikipediaError.invalidURL
        }
        
        // Wikipedia REST API für Summary
        let summaryURL = "\(baseURL)/page/summary/\(encodedTitle)"
        
        guard let url = URL(string: summaryURL) else {
            throw WikipediaError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WikipediaError.parsingError
        }
        
        // Parse Wikipedia Summary
        guard let title = json["title"] as? String,
              let extract = json["extract"] as? String,
              !extract.isEmpty else {
            return nil
        }
        
        let imageURL = (json["thumbnail"] as? [String: Any])?["source"] as? String
        let pageURL = json["content_urls"] as? [String: Any]
        let desktopURL = (pageURL?["desktop"] as? [String: Any])?["page"] as? String ?? ""
        
        // Basis Info-Felder (diese könnten durch Infobox-Parsing erweitert werden)
        var infoFields: [WikipediaInfo.InfoField] = []
        
        // Füge Sprache als Info hinzu
        let languageDisplayName = language == "de" ? "Deutsch" : "English"
        infoFields.append(WikipediaInfo.InfoField(key: "Sprache", value: languageDisplayName))
        
        return WikipediaInfo(
            title: title,
            summary: extract,
            imageURL: imageURL,
            articleURL: desktopURL,
            infoFields: infoFields,
            language: language
        )
    }
}

// MARK: - Preview Data

extension WikipediaInfo {
    /// Erstellt ein Beispiel für Previews
    static var example: WikipediaInfo {
        WikipediaInfo(
            title: "Apple",
            summary: "Apple Inc. ist ein US-amerikanisches Technologieunternehmen mit Sitz in Cupertino, Kalifornien. Das Unternehmen entwickelt und vertreibt Computer, Smartphones und Unterhaltungselektronik sowie Betriebssysteme und Anwendungssoftware.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/200px-Apple_logo_black.svg.png",
            articleURL: "https://de.wikipedia.org/wiki/Apple",
            infoFields: [
                WikipediaInfo.InfoField(key: "Gegründet", value: "1976"),
                WikipediaInfo.InfoField(key: "Hauptsitz", value: "Cupertino, Kalifornien"),
                WikipediaInfo.InfoField(key: "CEO", value: "Tim Cook"),
                WikipediaInfo.InfoField(key: "Branche", value: "Technologie")
            ]
        )
    }
}