//
//  APIConfiguration.swift
//  MountainBrowser
//
//  Backend-Konfiguration für sichere API-Nutzung
//

import Foundation

/// Konfiguration für API-Zugriff
struct APIConfiguration {
    
    // MARK: - Backend Configuration
    
    /// Backend-Server URL (Netlify Function)
    /// Für Produktion: Ersetze mit deiner Netlify-URL, z.B. "https://your-site.netlify.app/.netlify/functions"
    static let backendBaseURL = "YOUR_BACKEND_URL"
    
    // MARK: - API Key Loading
    
    /// Lädt API-Schlüssel aus einer lokalen Konfigurationsdatei (für Entwicklung)
    /// WICHTIG: Die Datei "APIKeys.plist" darf NICHT ins Git-Repository!
    private static var cachedKeys: [String: String]?
    
    private static func loadAPIKeys() -> [String: String] {
        if let cached = cachedKeys {
            return cached
        }
        
        // Versuche, Keys aus APIKeys.plist zu laden
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let keys = NSDictionary(contentsOfFile: path) as? [String: String] {
            cachedKeys = keys
            return keys
        }
        
        // Fallback: Leeres Dictionary
        cachedKeys = [:]
        return [:]
    }
    
    // MARK: - API Keys (Loaded from secure storage)
    
    /// Google API Key für Custom Search und YouTube
    /// Wird aus APIKeys.plist geladen (nicht im Git!)
    static var googleAPIKey: String {
        loadAPIKeys()["GOOGLE_API_KEY"] ?? ""
    }
    
    /// Google Custom Search Engine ID
    static var googleSearchEngineID: String {
        loadAPIKeys()["GOOGLE_SEARCH_ENGINE_ID"] ?? ""
    }
    
    /// YouTube API Key (kann der gleiche Key wie googleAPIKey sein)
    static var youtubeAPIKey: String {
        loadAPIKeys()["YOUTUBE_API_KEY"] ?? googleAPIKey
    }
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        /// Google Custom Search API
        static let googleCustomSearch = "https://www.googleapis.com/customsearch/v1"
        
        /// YouTube Data API v3
        static let youtubeSearch = "https://www.googleapis.com/youtube/v3/search"
        
        /// Backend Search Endpoint (Netlify Function)
        static var backendSearch: String {
            "\(backendBaseURL)/search"
        }
    }
    
    // MARK: - Configuration Validation
    
    /// Überprüft, ob das Backend konfiguriert ist
    static var isBackendConfigured: Bool {
        return !backendBaseURL.contains("YOUR_") && 
               !backendBaseURL.isEmpty &&
               URL(string: backendBaseURL) != nil
    }
    
    /// Überprüft, ob Google Custom Search API konfiguriert ist
    static var isGoogleSearchConfigured: Bool {
        return !googleAPIKey.isEmpty &&
               !googleSearchEngineID.isEmpty
    }
    
    /// Überprüft, ob YouTube API konfiguriert ist
    static var isYouTubeConfigured: Bool {
        return !youtubeAPIKey.isEmpty
    }
    
    /// Gibt an, ob irgendeine Such-API verfügbar ist
    static var hasAnySearchCapability: Bool {
        return isBackendConfigured || isGoogleSearchConfigured
    }
    
    // MARK: - Debug Info
    
    /// Gibt Konfigurationsstatus aus (nur für Debug)
    #if DEBUG
    static func printConfigurationStatus() {
        print("=== API Configuration Status ===")
        print("Backend configured: \(isBackendConfigured)")
        print("Google Search configured: \(isGoogleSearchConfigured)")
        print("YouTube configured: \(isYouTubeConfigured)")
        print("Has any search capability: \(hasAnySearchCapability)")
        print("================================")
    }
    #endif
}

// MARK: - API Response Models

/// Google Custom Search API Response
struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchItem]?
    let searchInformation: GoogleSearchInformation?
    
    struct GoogleSearchItem: Codable {
        let title: String
        let link: String
        let snippet: String?
        let image: GoogleImageInfo?
        
        struct GoogleImageInfo: Codable {
            let contextLink: String?
            let height: Int?
            let width: Int?
            let byteSize: Int?
            let thumbnailLink: String?
            let thumbnailHeight: Int?
            let thumbnailWidth: Int?
        }
    }
    
    struct GoogleSearchInformation: Codable {
        let totalResults: String?
        let searchTime: Double?
    }
}

/// YouTube Data API v3 Search Response
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]?
    let pageInfo: YouTubePageInfo?
    
    struct YouTubeSearchItem: Codable {
        let id: YouTubeVideoId
        let snippet: YouTubeSnippet
        
        struct YouTubeVideoId: Codable {
            let kind: String
            let videoId: String?
        }
        
        struct YouTubeSnippet: Codable {
            let title: String
            let description: String
            let channelTitle: String
            let publishedAt: String
            let thumbnails: YouTubeThumbnails
            
            struct YouTubeThumbnails: Codable {
                let `default`: YouTubeThumbnail?
                let medium: YouTubeThumbnail?
                let high: YouTubeThumbnail?
                let standard: YouTubeThumbnail?
                let maxres: YouTubeThumbnail?
                
                struct YouTubeThumbnail: Codable {
                    let url: String
                    let width: Int?
                    let height: Int?
                }
            }
        }
    }
    
    struct YouTubePageInfo: Codable {
        let totalResults: Int?
        let resultsPerPage: Int?
    }
}