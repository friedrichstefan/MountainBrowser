//
//  DirectAPISearchService.swift
//  MountainBrowser
//
//  Temporärer Service für direkte API-Calls (nur für Entwicklung/Tests)
//  ACHTUNG: Nicht für App Store verwenden - API-Keys sind im Code sichtbar
//

import Foundation
import Combine
import os.log

/// Service für direkte API-Aufrufe ohne Backend-Proxy
/// WARNUNG: Nur für Entwicklung/Tests geeignet!
@MainActor
class DirectAPISearchService: ObservableObject {
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "MountainBrowser", category: "DirectAPISearchService")
    
    // MARK: - API Configuration
    // Verwendet Keys aus APIConfiguration.swift
    private struct APIKeys {
        // DuckDuckGo Search (kostenlos, kein API-Key erforderlich)
        // Bing Search API (https://portal.azure.com) - wird durch DuckDuckGo ersetzt
        static let bingAPIKey = "YOUR_BING_API_KEY_HERE"
        
        // YouTube Data API (https://console.developers.google.com)
        static let youtubeAPIKey = APIConfiguration.youtubeAPIKey
        
        // Google Custom Search API (https://console.developers.google.com)
        static let googleSearchAPIKey = APIConfiguration.googleAPIKey
        static let googleSearchEngineId = APIConfiguration.googleSearchEngineID
    }
    
    // MARK: - Demo Mode
    private let isDemoMode = false // Demo-Modus deaktiviert - verwende echte API-Keys
    
    /// Demo-Suchergebnisse für Tests
    private func generateDemoResults(query: String, contentType: SearchContentType) -> [SearchResult] {
        let normalizedQuery = query.lowercased()
        
        switch contentType {
        case .web:
            return [
                SearchResult(
                    title: "Wikipedia - \(query)",
                    url: "https://de.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))",
                    description: "Informationen zu \(query) auf Wikipedia - der freien Enzyklopädie.",
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "Demo Mode"
                ),
                SearchResult(
                    title: "\(query) - Offizielle Website",
                    url: "https://www.example.com/\(normalizedQuery)",
                    description: "Offizielle Informationen und Details zu \(query).",
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "Demo Mode"
                ),
                SearchResult(
                    title: "News zu \(query)",
                    url: "https://www.news.com/\(normalizedQuery)",
                    description: "Aktuelle Nachrichten und Updates zu \(query).",
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "Demo Mode"
                )
            ]
            
        case .image:
            return [
                SearchResult(
                    title: "Bild: \(query) #1",
                    url: "https://example.com/image1.jpg",
                    description: "Erstes Beispielbild zu \(query)",
                    contentType: .image,
                    thumbnailURL: "https://via.placeholder.com/300x200?text=\(query)+1",
                    imageWidth: 300,
                    imageHeight: 200,
                    source: "Demo Mode"
                ),
                SearchResult(
                    title: "Bild: \(query) #2",
                    url: "https://example.com/image2.jpg",
                    description: "Zweites Beispielbild zu \(query)",
                    contentType: .image,
                    thumbnailURL: "https://via.placeholder.com/400x300?text=\(query)+2",
                    imageWidth: 400,
                    imageHeight: 300,
                    source: "Demo Mode"
                ),
                SearchResult(
                    title: "Bild: \(query) #3",
                    url: "https://example.com/image3.jpg",
                    description: "Drittes Beispielbild zu \(query)",
                    contentType: .image,
                    thumbnailURL: "https://via.placeholder.com/350x250?text=\(query)+3",
                    imageWidth: 350,
                    imageHeight: 250,
                    source: "Demo Mode"
                )
            ]
            
        case .video:
            return [
                SearchResult(
                    title: "Video: \(query) Tutorial",
                    url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                    description: "Lernvideo und Tutorial zu \(query)",
                    contentType: .video,
                    thumbnailURL: "https://via.placeholder.com/480x360?text=Video+\(query)+1",
                    duration: "10:30",
                    source: "Demo YouTube"
                ),
                SearchResult(
                    title: "Video: \(query) Erklärung",
                    url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                    description: "Detaillierte Erklärung zu \(query)",
                    contentType: .video,
                    thumbnailURL: "https://via.placeholder.com/480x360?text=Video+\(query)+2",
                    duration: "15:45",
                    source: "Demo YouTube"
                )
            ]
            
        case .info:
            return []
        }
    }
    
    /// Generiert Demo Wikipedia-Info
    private func generateDemoWikipediaInfo(query: String) -> WikipediaInfo {
        return WikipediaInfo(
            title: query,
            summary: "Dies ist eine Demo-Zusammenfassung für '\(query)'. In der echten Version würden hier detaillierte Informationen aus Wikipedia angezeigt werden. Um echte Daten zu erhalten, konfigurieren Sie die API-Keys gemäß der Anleitung in API_KEYS_SETUP.md",
            imageURL: "https://via.placeholder.com/400x300?text=\(query)",
            articleURL: "https://de.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))",
            infoFields: [
                WikipediaInfo.InfoField(key: "Status", value: "Demo-Modus aktiv"),
                WikipediaInfo.InfoField(key: "Hinweis", value: "Konfiguriere API-Keys für echte Daten"),
                WikipediaInfo.InfoField(key: "Anleitung", value: "Siehe API_KEYS_SETUP.md")
            ],
            language: "de"
        )
    }
    
    // MARK: - Error Types
    // Verwendet globale SearchError aus SearchError.swift
    
    // MARK: - Properties
    private var session: URLSession
    @Published var wikipediaInfos: [String: WikipediaInfo] = [:]
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Web-Suche über DuckDuckGo als normaler Browser + Google (kombinierte Ergebnisse)
    func search(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🔍 Kombinierte Web-Suche (DuckDuckGo Browser + Google) für: \(trimmedQuery)")
        
        // Parallele Suche über beide Services
        async let duckDuckGoResults = try? searchDuckDuckGoBrowser(query: trimmedQuery)
        async let googleResults = try? searchGoogleWeb(query: trimmedQuery)
        
        let results = await (
            duckDuckGo: duckDuckGoResults ?? [],
            google: googleResults ?? []
        )
        
        // Kombiniere Ergebnisse: DuckDuckGo zuerst, dann Google
        var combinedResults: [SearchResult] = []
        combinedResults.append(contentsOf: results.duckDuckGo)
        combinedResults.append(contentsOf: results.google)
        
        logger.info("✅ Web-Suche: \(results.duckDuckGo.count) DuckDuckGo + \(results.google.count) Google = \(combinedResults.count) gesamt")
        
        return combinedResults
    }
    
    /// Bilder-Suche über Google Custom Search API
    func searchImages(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        // Prüfe API-Keys Konfiguration mit APIConfiguration
        let hasValidAPIKeys = APIConfiguration.isGoogleSearchConfigured
        
        // Demo-Modus: Generiere Demo-Daten wenn API-Keys fehlen oder Demo-Modus aktiv
        if self.isDemoMode || !hasValidAPIKeys {
            logger.info("🖼️ Demo-Modus: Bilder-Suche für \(trimmedQuery) (Grund: \(self.isDemoMode ? "Demo aktiv" : "API-Keys fehlen"))")
            // Simuliere Netzwerk-Delay für realistische Erfahrung
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden
            return generateDemoResults(query: trimmedQuery, contentType: .image)
        }
        
        logger.info("🖼️ Direkte Google Bildersuche für: \(trimmedQuery)")
        
        do {
            return try await searchGoogleImages(query: trimmedQuery)
        } catch {
            logger.error("❌ Google Bildersuche fehlgeschlagen: \(error) - verwende Demo-Daten als Fallback")
            return generateDemoResults(query: trimmedQuery, contentType: .image)
        }
    }
    
    /// Video-Suche über YouTube Data API
    func searchVideos(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        // YouTube API-Key ist konfiguriert - verwende echte API
        logger.info("🎥 Direkte YouTube-Suche für: \(trimmedQuery)")
        
        return try await searchYouTubeVideos(query: trimmedQuery)
    }
    
    /// Wikipedia-Suche (direkte API)
    func searchWikipedia(query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("📖 Wikipedia-Suche für: \(trimmedQuery)")
        
        do {
            if let wikipediaInfo = try await searchWikipediaDirect(query: trimmedQuery) {
                // Store Wikipedia info
                self.wikipediaInfos[wikipediaInfo.articleURL] = wikipediaInfo
                
                return [
                    SearchResult(
                        title: wikipediaInfo.title,
                        url: wikipediaInfo.articleURL,
                        description: wikipediaInfo.displaySummary,
                        contentType: .info,
                        thumbnailURL: wikipediaInfo.imageURL,
                        source: "Wikipedia"
                    )
                ]
            }
            
            return []
            
        } catch {
            logger.error("⚠️ Wikipedia-Suche fehlgeschlagen: \(error)")
            return []
        }
    }
    
    /// Führt alle Suchtypen parallel aus
    func searchAll(query: String) async throws -> (web: [SearchResult], images: [SearchResult], videos: [SearchResult], info: [SearchResult]) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw SearchError.invalidQuery
        }
        
        logger.info("🔍 Gesamtsuche für: \(trimmedQuery)")
        
        // Parallele Ausführung aller Suchtypen
        async let webResults = try? searchBingWeb(query: trimmedQuery)
        async let imageResults = try? searchGoogleImages(query: trimmedQuery)
        async let videoResults = try? searchYouTubeVideos(query: trimmedQuery)
        async let infoResults = try? searchWikipedia(query: trimmedQuery)
        
        let results = await (
            web: webResults ?? [],
            images: imageResults ?? [],
            videos: videoResults ?? [],
            info: infoResults ?? []
        )
        
        logger.info("✅ Gesamtsuche: \(results.web.count) Web, \(results.images.count) Bilder, \(results.videos.count) Videos, \(results.info.count) Info")
        
        return results
    }
    
    // MARK: - Private API Methods
    
    /// DuckDuckGo als normaler Browser (HTML-Scraping Fallback)
    private func searchDuckDuckGoBrowser(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        // Erstelle primär DuckDuckGo-Browser-Link (normale Suchergebnisse)
        let browserURL = "https://duckduckgo.com/?q=\(encodedQuery)&ia=web"
        
        var results: [SearchResult] = []
        
        // Haupt-Browser-Ergebnis für normale Web-Suche
        results.append(SearchResult(
            title: "Suche nach \(query) - DuckDuckGo",
            url: browserURL,
            description: "Vollständige Suchergebnisse zu '\(query)' auf DuckDuckGo anzeigen",
            contentType: .web,
            thumbnailURL: nil,
            source: "DuckDuckGo Browser"
        ))
        
        // Versuche zusätzlich die Instant Answer API für erweiterte Informationen
        do {
            let instantResults = try await searchDuckDuckGoInstantAnswer(query: query)
            results.append(contentsOf: instantResults)
        } catch {
            logger.debug("⚠️ DuckDuckGo Instant Answer nicht verfügbar: \(error)")
        }
        
        return results
    }
    
    /// DuckDuckGo Instant Answer API (zusätzliche Informationen)
    private func searchDuckDuckGoInstantAnswer(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_redirect=1&no_html=1&skip_disambig=1"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        logger.info("📡 DuckDuckGo API Request: \(urlString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("❌ DuckDuckGo API HTTP Error: \(statusCode)")
            throw SearchError.networkError(NSError(domain: "DuckDuckGoAPI", code: -1, userInfo: nil))
        }
        
        // Log die rohen API-Daten zur Debug-Zwecken
        if let dataString = String(data: data, encoding: .utf8) {
            logger.info("📄 DuckDuckGo Raw Response: \(dataString.prefix(500))...")
        }
        
        let duckDuckGoResponse = try JSONDecoder().decode(DuckDuckGoResponse.self, from: data)
        
        // Detaillierte Logs der empfangenen Daten
        logger.info("🔍 DuckDuckGo Response Details:")
        logger.info("   Abstract: '\(duckDuckGoResponse.abstract.prefix(100))...' (length: \(duckDuckGoResponse.abstract.count))")
        logger.info("   Heading: '\(duckDuckGoResponse.heading)'")
        logger.info("   AbstractSource: '\(duckDuckGoResponse.abstractSource)'")
        logger.info("   AbstractURL: '\(duckDuckGoResponse.abstractURL)'")
        logger.info("   Image: '\(duckDuckGoResponse.image)'")
        logger.info("   RelatedTopics count: \(duckDuckGoResponse.relatedTopics.count)")
        
        var results: [SearchResult] = []
        
        // Haupt-Antwort (Abstract) - erweiterte Logging
        if !duckDuckGoResponse.abstract.isEmpty {
            logger.info("✅ Abstract gefunden: \(duckDuckGoResponse.abstract.count) Zeichen")
            
            // Auch kürzere Abstracts verwenden für bessere Ergebnisse
            if duckDuckGoResponse.abstract.count > 20 {
                let result = SearchResult(
                    title: duckDuckGoResponse.heading.isEmpty ? "\(query) - DuckDuckGo Info" : duckDuckGoResponse.heading,
                    url: duckDuckGoResponse.abstractURL.isEmpty ? "https://de.wikipedia.org/wiki/\(encodedQuery)" : duckDuckGoResponse.abstractURL,
                    description: duckDuckGoResponse.abstract,
                    contentType: .web,
                    thumbnailURL: duckDuckGoResponse.image.isEmpty ? nil : duckDuckGoResponse.image,
                    source: duckDuckGoResponse.abstractSource.isEmpty ? "DuckDuckGo" : duckDuckGoResponse.abstractSource
                )
                results.append(result)
                logger.info("📄 Abstract-Result hinzugefügt: '\(result.title)'")
            } else {
                logger.warning("⚠️ Abstract zu kurz (\(duckDuckGoResponse.abstract.count) Zeichen): '\(duckDuckGoResponse.abstract)'")
            }
        } else {
            logger.warning("⚠️ Kein Abstract in DuckDuckGo Response")
        }
        
        // Related Topics mit detailliertem Logging
        logger.info("🔗 Verarbeite \(duckDuckGoResponse.relatedTopics.count) Related Topics:")
        for (index, topic) in duckDuckGoResponse.relatedTopics.enumerated() {
            logger.info("   Topic \(index + 1): '\(topic.text.prefix(50))...' URL: '\(topic.firstURL)'")
            
            // Lockerere Bedingungen für Related Topics
            if !topic.text.isEmpty && !topic.firstURL.isEmpty && topic.text.count > 10 {
                let title = String(topic.text.components(separatedBy: " - ").first ?? topic.text).prefix(80)
                let result = SearchResult(
                    title: String(title),
                    url: topic.firstURL,
                    description: topic.text,
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "DuckDuckGo Related"
                )
                results.append(result)
                logger.info("✅ Related Topic hinzugefügt: '\(result.title)'")
            } else {
                logger.warning("⚠️ Related Topic übersprungen (Text: \(topic.text.count) chars, URL: '\(topic.firstURL)')")
            }
            
            // Maximal 3 Related Topics für bessere UX
            if results.count >= 4 { // 1 Abstract + 3 Related
                break
            }
        }
        
        logger.info("✅ DuckDuckGo Instant Answer: \(results.count) Ergebnisse erstellt")
        
        return results
    }
    
    /// Bing Web Search API (Backup, falls DuckDuckGo nicht funktioniert)
    private func searchBingWeb(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://api.bing.microsoft.com/v7.0/search?q=\(encodedQuery)&count=20&mkt=de-DE"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(APIKeys.bingAPIKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError(NSError(domain: "BingAPI", code: -1, userInfo: nil))
            }
            
            let bingResponse = try JSONDecoder().decode(BingSearchResponse.self, from: data)
            
            let results = bingResponse.webPages?.value?.map { item in
                SearchResult(
                    title: item.name,
                    url: item.url,
                    description: item.snippet ?? "",
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "Bing"
                )
            } ?? []
            
            return results
            
        } catch {
            throw SearchError.networkError(error)
        }
    }
    
    /// Google Custom Search API für Web-Suche
    private func searchGoogleWeb(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        // Prüfe ob Google API-Keys konfiguriert sind
        guard APIKeys.googleSearchAPIKey != "YOUR_GOOGLE_SEARCH_API_KEY_HERE",
              APIKeys.googleSearchEngineId != "YOUR_GOOGLE_SEARCH_ENGINE_ID_HERE" else {
            logger.warning("⚠️ Google Search API Keys nicht konfiguriert - überspringe Google Web-Suche")
            return []
        }
        
        let urlString = "https://www.googleapis.com/customsearch/v1?key=\(APIKeys.googleSearchAPIKey)&cx=\(APIKeys.googleSearchEngineId)&q=\(encodedQuery)&num=10&safe=active&lr=lang_de"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError(NSError(domain: "GoogleAPI", code: -1, userInfo: nil))
            }
            
            let googleResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
            
            let results = googleResponse.items?.map { item in
                SearchResult(
                    title: item.title,
                    url: item.link,
                    description: item.snippet ?? "",
                    contentType: .web,
                    thumbnailURL: nil,
                    source: "Google"
                )
            } ?? []
            
            return results
            
        } catch {
            logger.warning("⚠️ Google Web-Suche fehlgeschlagen: \(error)")
            return []
        }
    }
    
    /// Google Custom Search API für Bilder
    private func searchGoogleImages(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://www.googleapis.com/customsearch/v1?key=\(APIKeys.googleSearchAPIKey)&cx=\(APIKeys.googleSearchEngineId)&q=\(encodedQuery)&searchType=image&num=20&safe=active"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        logger.info("📡 Google Images API Request: \(urlString.replacingOccurrences(of: APIKeys.googleSearchAPIKey, with: "***API_KEY***"))")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SearchError.networkError(NSError(domain: "GoogleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige HTTP Response"]))
            }
            
            logger.info("📊 Google Images API Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                // Log response body for debugging
                if let dataString = String(data: data, encoding: .utf8) {
                    logger.error("❌ Google Images API Error Response: \(dataString.prefix(500))")
                }
                
                switch httpResponse.statusCode {
                case 403:
                    throw SearchError.apiQuotaExceeded
                case 401:
                    throw SearchError.apiKeyMissing
                default:
                    throw SearchError.networkError(NSError(domain: "GoogleAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
                }
            }
            
            let googleResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
            
            let results = googleResponse.items?.map { item in
                SearchResult(
                    title: item.title,
                    url: item.link,
                    description: item.snippet ?? "",
                    contentType: .image,
                    thumbnailURL: item.image?.thumbnailLink,
                    imageWidth: item.image?.width,
                    imageHeight: item.image?.height,
                    source: "Google Images"
                )
            } ?? []
            
            logger.info("✅ Google Images: \(results.count) Ergebnisse erhalten")
            return results
            
        } catch let error as DecodingError {
            logger.error("❌ Google Images JSON Parsing Error: \(error)")
            throw SearchError.parsingError
        } catch {
            logger.error("❌ Google Images Network Error: \(error)")
            throw SearchError.networkError(error)
        }
    }
    
    /// YouTube Data API
    private func searchYouTubeVideos(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=20&q=\(encodedQuery)&type=video&key=\(APIKeys.youtubeAPIKey)&regionCode=DE&relevanceLanguage=de"
        
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError(NSError(domain: "YouTubeAPI", code: -1, userInfo: nil))
            }
            
            let youtubeResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            
            let results = youtubeResponse.items?.compactMap { item -> SearchResult? in
                guard let videoId = item.id.videoId else { return nil }
                
                let videoURL = "https://www.youtube.com/watch?v=\(videoId)"
                let thumbnailURL = item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.default?.url
                
                return SearchResult(
                    title: item.snippet.title,
                    url: videoURL,
                    description: item.snippet.description,
                    contentType: .video,
                    thumbnailURL: thumbnailURL,
                    duration: nil,
                    source: "YouTube"
                )
            } ?? []
            
            return results
            
        } catch {
            throw SearchError.networkError(error)
        }
    }
    
    // MARK: - Wikipedia Info Access
    
    /// Holt WikipediaInfo für eine gegebene URL
    func getWikipediaInfo(for url: String) -> WikipediaInfo? {
        return wikipediaInfos[url]
    }
    
    /// Wikipedia-Suche über direkte API
    func searchWikipediaDirect(query: String) async throws -> WikipediaInfo? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }
        
        // Demo-Modus: Generiere Demo Wikipedia-Info
        if self.isDemoMode {
            logger.info("📖 Demo-Modus: Wikipedia-Info für \(query)")
            // Simuliere Netzwerk-Delay
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 Sekunden
            return generateDemoWikipediaInfo(query: query)
        }
        
        // Wikipedia OpenSearch API für Suchvorschläge
        let searchURL = "https://de.wikipedia.org/w/api.php?action=opensearch&search=\(encodedQuery)&limit=1&namespace=0&format=json"
        
        guard let url = URL(string: searchURL) else {
            throw SearchError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any],
                  jsonArray.count >= 4,
                  let titles = jsonArray[1] as? [String],
                  let descriptions = jsonArray[2] as? [String],
                  let urls = jsonArray[3] as? [String],
                  !titles.isEmpty else {
                return nil
            }
            
            let title = titles[0]
            let description = descriptions.isEmpty ? "" : descriptions[0]
            let articleURL = urls[0]
            
            // Details über Wikipedia API abrufen
            let pageTitle = title.replacingOccurrences(of: " ", with: "_")
            let detailsURL = "https://de.wikipedia.org/api/rest_v1/page/summary/\(pageTitle)"
            
            guard let detailURL = URL(string: detailsURL) else {
                return WikipediaInfo(
                    title: title,
                    summary: description,
                    imageURL: nil,
                    articleURL: articleURL,
                    infoFields: [],
                    language: "de"
                )
            }
            
            let (detailData, _) = try await session.data(from: detailURL)
            let detailResponse = try JSONDecoder().decode(WikipediaPageSummary.self, from: detailData)
            
            return WikipediaInfo(
                title: detailResponse.title,
                summary: detailResponse.extract ?? description,
                imageURL: detailResponse.thumbnail?.source,
                articleURL: detailResponse.content_urls.desktop.page,
                infoFields: [],
                language: detailResponse.lang
            )
            
        } catch {
            logger.error("⚠️ Wikipedia-Suche fehlgeschlagen: \(error)")
            return nil
        }
    }
}

// MARK: - API Response Models

/// DuckDuckGo Instant Answer API Response
private struct DuckDuckGoResponse: Codable {
    let abstract: String
    let abstractSource: String
    let abstractURL: String
    let heading: String
    let image: String
    let relatedTopics: [DuckDuckGoRelatedTopic]
    
    struct DuckDuckGoRelatedTopic: Codable {
        let text: String
        let firstURL: String
        
        enum CodingKeys: String, CodingKey {
            case text = "Text"
            case firstURL = "FirstURL"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case abstract = "Abstract"
        case abstractSource = "AbstractSource"
        case abstractURL = "AbstractURL"
        case heading = "Heading"
        case image = "Image"
        case relatedTopics = "RelatedTopics"
    }
}


/// Bing Search API Response
private struct BingSearchResponse: Codable {
    let webPages: BingWebPages?
    
    struct BingWebPages: Codable {
        let value: [BingWebResult]?
        
        struct BingWebResult: Codable {
            let name: String
            let url: String
            let snippet: String?
        }
    }
}


/// Wikipedia Page Summary Response
private struct WikipediaPageSummary: Codable {
    let title: String
    let extract: String?
    let content_urls: WikipediaContentURLs
    let thumbnail: WikipediaThumbnail?
    let lang: String
    
    struct WikipediaContentURLs: Codable {
        let desktop: WikipediaDesktopURL
        
        struct WikipediaDesktopURL: Codable {
            let page: String
        }
    }
    
    struct WikipediaThumbnail: Codable {
        let source: String
        let width: Int?
        let height: Int?
    }
}
