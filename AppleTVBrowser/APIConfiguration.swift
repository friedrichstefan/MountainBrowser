//
//  APIConfiguration.swift
//  AppleTVBrowser
//
//  Backend-Konfiguration für sichere API-Nutzung
//

import Foundation

/// Konfiguration für API-Zugriff
struct APIConfiguration {
    
    // MARK: - Backend Configuration
    
    /// Backend-Server URL
    static let backendBaseURL = "YOUR_BACKEND_URL"
    
    // MARK: - Direct API Keys
    // ⚠️ WARNUNG: Diese Keys NIEMALS in App Store Builds verwenden!
    
    /// Google API Key für Custom Search und YouTube
    static let googleAPIKey = "AIzaSyDHGL_dvbmPcRtGKJONSCVU7tlIaAikuNU"
    
    /// Google Custom Search Engine ID
    static let googleSearchEngineID = "2375272a6e1b04302"
    
    /// YouTube API Key (gleicher Key wie googleAPIKey)
    static let youtubeAPIKey = "AIzaSyDHGL_dvbmPcRtGKJONSCVU7tlIaAikuNU"
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        /// Google Custom Search API
        static let googleCustomSearch = "https://www.googleapis.com/customsearch/v1"
        
        /// YouTube Data API v3
        static let youtubeSearch = "https://www.googleapis.com/youtube/v3/search"
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
               !googleAPIKey.contains("YOUR_") &&
               !googleSearchEngineID.isEmpty &&
               !googleSearchEngineID.contains("YOUR_")
    }
    
    /// Überprüft, ob YouTube API konfiguriert ist
    static var isYouTubeConfigured: Bool {
        return !youtubeAPIKey.isEmpty &&
               !youtubeAPIKey.contains("YOUR_")
    }
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
