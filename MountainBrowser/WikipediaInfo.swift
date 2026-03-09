//
//  WikipediaInfo.swift
//  MountainBrowser
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
        let key: String
        let value: String
        
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
        return L10n.Wikipedia.fromWikipedia
    }
    
    var localizedLanguageName: String {
        switch language {
        case "de":
            return L10n.Wikipedia.germanWikipedia
        case "en":
            return L10n.Wikipedia.englishWikipedia
        case "fr":
            return L10n.Wikipedia.frenchWikipedia
        case "es":
            return L10n.Wikipedia.spanishWikipedia
        case "it":
            return L10n.Wikipedia.italianWikipedia
        default:
            return L10n.Wikipedia.englishWikipedia
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
                return L10n.Wikipedia.errorInvalidURL
            case .noResults:
                return L10n.Wikipedia.errorNoResults
            case .networkError(let error):
                return "\(L10n.Wikipedia.errorNetwork): \(error.localizedDescription)"
            case .parsingError:
                return L10n.Wikipedia.errorParsing
            case .articleNotFound:
                return L10n.Wikipedia.errorArticleNotFound
            }
        }
    }
    
    // MARK: - Configuration
    private struct Configuration {
        static let requestTimeout: TimeInterval = 10
        static let userAgent = "MountainBrowser/1.0 (tvOS; like Safari)"
        static let maxSummaryLength = 200
        
        // Wikipedia API URLs (unterstützte Sprachen)
        static let baseURLs = [
            "de": "https://de.wikipedia.org/api/rest_v1",
            "en": "https://en.wikipedia.org/api/rest_v1",
            "fr": "https://fr.wikipedia.org/api/rest_v1",
            "es": "https://es.wikipedia.org/api/rest_v1",
            "it": "https://it.wikipedia.org/api/rest_v1"
        ]
        
        static let searchURLs = [
            "de": "https://de.wikipedia.org/w/api.php",
            "en": "https://en.wikipedia.org/w/api.php",
            "fr": "https://fr.wikipedia.org/w/api.php",
            "es": "https://es.wikipedia.org/w/api.php",
            "it": "https://it.wikipedia.org/w/api.php"
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
    
    /// Ermittelt die bevorzugte Wikipedia-Sprache basierend auf den Einstellungen oder der Systemsprache
    /// - Parameter preferredLanguageCode: Optional - die vom Benutzer gewählte Sprache aus den Einstellungen
    private func preferredLanguages(preferredLanguageCode: String? = nil) -> [String] {
        // Unterstützte Wikipedia-Sprachen
        let supportedLanguages = ["de", "en", "fr", "es", "it"]
        
        // Erstelle priorisierte Sprachliste
        var languages: [String] = []
        
        // Wenn eine bevorzugte Sprache übergeben wurde (nicht "system")
        if let preferred = preferredLanguageCode, supportedLanguages.contains(preferred) {
            languages.append(preferred)
        } else {
            // Hole die bevorzugte Systemsprache
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"
            
            // Primäre Sprache (falls unterstützt)
            if supportedLanguages.contains(languageCode) {
                languages.append(languageCode)
            }
        }
        
        // Fallback auf Englisch, wenn nicht bereits enthalten
        if !languages.contains("en") {
            languages.append("en")
        }
        
        // Fallback auf Deutsch, wenn nicht bereits enthalten
        if !languages.contains("de") {
            languages.append("de")
        }
        
        return languages
    }
    
    /// Sucht nach Wikipedia-Informationen für eine Suchanfrage
    /// - Parameters:
    ///   - query: Die Suchanfrage
    ///   - preferredLanguageCode: Optional - die vom Benutzer gewählte Sprache (z.B. "de", "en", "fr", "es", "it")
    ///                            Wenn nil oder "system", wird die Systemsprache verwendet
    func searchWikipedia(query: String, preferredLanguageCode: String? = nil) async throws -> WikipediaInfo? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw WikipediaError.invalidURL
        }
        
        // Versuche Wikipedia-Suche in der Reihenfolge der bevorzugten Sprache(n)
        for language in preferredLanguages(preferredLanguageCode: preferredLanguageCode) {
            do {
                if let info = try await fetchWikipediaInfo(query: trimmedQuery, language: language) {
                    return info
                }
            } catch {
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
        
        let urlString = "\(searchBaseURL)?action=query&format=json&list=search&srsearch=\(encodedQuery)&srlimit=3"
        
        guard let url = URL(string: urlString) else {
            throw WikipediaError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let queryResult = json["query"] as? [String: Any],
              let searchResults = queryResult["search"] as? [[String: Any]] else {
            return nil
        }
        
        // Prüfe mehrere Ergebnisse auf Relevanz
        for result in searchResults {
            guard let title = result["title"] as? String,
                  let snippet = result["snippet"] as? String else {
                continue
            }
            
            // 1. Filtere Begriffsklärungsseiten aus
            if isDisambiguationPage(title: title, snippet: snippet, language: language) {
                continue
            }
            
            // 2. Prüfe Titel-Ähnlichkeit zur Suchanfrage
            let similarity = calculateSimilarity(query: query, title: title)
            if similarity < 0.3 {  // Mindest-Ähnlichkeit von 30%
                continue
            }
            
            // 3. Prüfe ob Snippet ausreichend informativ ist
            let cleanSnippet = cleanHTMLFromSnippet(snippet)
            if cleanSnippet.count < 20 {
                continue
            }
            
            return title
        }
        
        return nil
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
        
        // Basis Info-Felder
        var infoFields: [WikipediaInfo.InfoField] = []
        
        // Füge Sprache als Info hinzu
        let languageDisplayName: String
        switch language {
        case "de":
            languageDisplayName = L10n.Wikipedia.languageNameGerman
        case "en":
            languageDisplayName = L10n.Wikipedia.languageNameEnglish
        case "fr":
            languageDisplayName = L10n.Wikipedia.languageNameFrench
        case "es":
            languageDisplayName = L10n.Wikipedia.languageNameSpanish
        case "it":
            languageDisplayName = L10n.Wikipedia.languageNameItalian
        default:
            languageDisplayName = L10n.Wikipedia.languageNameEnglish
        }
        infoFields.append(WikipediaInfo.InfoField(key: L10n.Wikipedia.language, value: languageDisplayName))
        
        return WikipediaInfo(
            title: title,
            summary: extract,
            imageURL: imageURL,
            articleURL: desktopURL,
            infoFields: infoFields,
            language: language
        )
    }
    
    // MARK: - Helper Methods für Relevanzprüfung
    
    /// Prüft ob ein Wikipedia-Artikel eine Begriffsklärungsseite ist
    private func isDisambiguationPage(title: String, snippet: String, language: String) -> Bool {
        let lowercaseTitle = title.lowercased()
        let lowercaseSnippet = snippet.lowercased()
        
        switch language {
        case "de":
            return lowercaseTitle.contains("begriffsklärung") ||
                   lowercaseTitle.contains("(begriffskl") ||
                   lowercaseSnippet.contains("steht für:") ||
                   lowercaseSnippet.contains("bezeichnet:") ||
                   lowercaseSnippet.contains("kann bezeichnen") ||
                   lowercaseSnippet.contains("ist eine begriffsklärung")
        case "en":
            return lowercaseTitle.contains("disambiguation") ||
                   lowercaseTitle.contains("(disambig") ||
                   lowercaseSnippet.contains("may refer to:") ||
                   lowercaseSnippet.contains("refers to:") ||
                   lowercaseSnippet.contains("disambiguation page")
        default:
            return false
        }
    }
    
    /// Berechnet die Ähnlichkeit zwischen Suchanfrage und Wikipedia-Titel
    private func calculateSimilarity(query: String, title: String) -> Double {
        let normalizedQuery = normalizeString(query)
        let normalizedTitle = normalizeString(title)
        
        if normalizedQuery == normalizedTitle {
            return 1.0
        }
        
        if normalizedTitle.contains(normalizedQuery) {
            return 0.8
        }
        
        let queryWords = Set(normalizedQuery.split(separator: " ").map(String.init))
        let titleWords = Set(normalizedTitle.split(separator: " ").map(String.init))
        
        let intersection = queryWords.intersection(titleWords)
        let union = queryWords.union(titleWords)
        
        if union.isEmpty {
            return 0
        }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    /// Normalisiert einen String für Vergleiche
    private func normalizeString(_ string: String) -> String {
        return string.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-zA-Z0-9äöüß\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// Entfernt HTML-Tags und -Entities aus Wikipedia-Snippets
    private func cleanHTMLFromSnippet(_ snippet: String) -> String {
        var cleaned = snippet
        
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
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
