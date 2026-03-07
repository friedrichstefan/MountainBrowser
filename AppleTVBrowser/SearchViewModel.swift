//
//  SearchViewModel.swift
//  AppleTVBrowser
//

import SwiftUI
import SwiftData
import Combine

@Observable
final class SearchViewModel {
    // MARK: - State
    var searchQuery: String = ""
    var searchResults: [SearchResult] = []
    var imageResults: [SearchResult] = []
    var videoResults: [SearchResult] = []
    var wikipediaInfo: WikipediaInfo?
    var isSearching: Bool = false
    var errorMessage: String?
    var selectedResult: SearchResult?
    var isWebViewPresented: Bool = false
    var searchHistory: [String] = []
    
    // MARK: - Dependencies
    private let searchService: SearchService
    private let urlValidator = URLValidator()
    var modelContext: ModelContext?
    
    // MARK: - LRU Cache
    private var searchCache: [String: CacheEntry<[SearchResult]>] = [:]
    private var imageCache: [String: CacheEntry<[SearchResult]>] = [:]
    private var videoCache: [String: CacheEntry<[SearchResult]>] = [:]
    private let maxCacheSize = 50
    
    private struct CacheEntry<T> {
        let value: T
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    init(searchService: SearchService = SearchService()) {
        self.searchService = searchService
    }
    
    // MARK: - Computed Properties
    var hasResults: Bool {
        !searchResults.isEmpty
    }
    
    var hasImageResults: Bool {
        !imageResults.isEmpty
    }
    
    var hasVideoResults: Bool {
        !videoResults.isEmpty
    }
    
    var showEmptyState: Bool {
        !isSearching && searchResults.isEmpty && imageResults.isEmpty && videoResults.isEmpty && errorMessage == nil
    }
    
    var canSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Gibt die Ergebnisse für einen bestimmten Content-Type zurück
    func results(for contentType: SearchContentType) -> [SearchResult] {
        switch contentType {
        case .web:
            return searchResults
        case .image:
            return imageResults
        case .video:
            return videoResults
        case .info:
            return []
        }
    }
    
    // MARK: - Actions
    @MainActor
    func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            searchResults = []
            imageResults = []
            videoResults = []
            wikipediaInfo = nil
            return
        }
        
        // Sanitize search query
        let sanitizedQuery = await urlValidator.sanitizeSearchQuery(query)
        let cacheKey = sanitizedQuery.lowercased()
        
        // Check caches first
        let hasCachedWeb = searchCache[cacheKey] != nil
        let hasCachedImages = imageCache[cacheKey] != nil
        let hasCachedVideos = videoCache[cacheKey] != nil
        
        if hasCachedWeb && hasCachedImages && hasCachedVideos {
            searchResults = searchCache[cacheKey]?.value ?? []
            imageResults = imageCache[cacheKey]?.value ?? []
            videoResults = videoCache[cacheKey]?.value ?? []
            return
        }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        imageResults = []
        videoResults = []
        wikipediaInfo = nil
        
        // Parallele Suche für alle Content-Types
        async let webSearchTask: [SearchResult] = {
            if hasCachedWeb {
                return self.searchCache[cacheKey]?.value ?? []
            }
            do {
                return try await self.searchService.search(query: sanitizedQuery)
            } catch {
                print("⚠️ Web-Suche Fehler: \(error.localizedDescription)")
                return []
            }
        }()
        
        async let imageSearchTask: [SearchResult] = {
            if hasCachedImages {
                return self.imageCache[cacheKey]?.value ?? []
            }
            do {
                return try await self.searchService.searchImages(query: sanitizedQuery)
            } catch {
                print("⚠️ Bilder-Suche Fehler: \(error.localizedDescription)")
                return []
            }
        }()
        
        async let videoSearchTask: [SearchResult] = {
            if hasCachedVideos {
                return self.videoCache[cacheKey]?.value ?? []
            }
            if APIConfiguration.isYouTubeConfigured {
                do {
                    return try await self.searchService.searchVideos(query: sanitizedQuery)
                } catch {
                    print("⚠️ Video-Suche Fehler: \(error.localizedDescription)")
                    return []
                }
            } else {
                print("ℹ️ YouTube API nicht konfiguriert - überspringe Video-Suche")
                return []
            }
        }()
        
        async let wikipediaTask: WikipediaInfo? = {
            do {
                return try await self.searchService.searchWikipedia(query: sanitizedQuery)
            } catch {
                print("⚠️ Wikipedia Fehler: \(error.localizedDescription)")
                return nil
            }
        }()
        
        // Warte auf alle Ergebnisse
        let webResults = await webSearchTask
        let images = await imageSearchTask
        let videos = await videoSearchTask
        let wiki = await wikipediaTask
        
        // Update UI mit Ergebnissen
        self.searchResults = webResults
        self.imageResults = images
        self.videoResults = videos
        self.wikipediaInfo = wiki
        
        // Cache alle Ergebnisse mit Zeitstempel (LRU)
        let now = Date()
        if !webResults.isEmpty {
            searchCache[cacheKey] = CacheEntry(value: webResults, timestamp: now)
        }
        if !images.isEmpty {
            imageCache[cacheKey] = CacheEntry(value: images, timestamp: now)
        }
        if !videos.isEmpty {
            videoCache[cacheKey] = CacheEntry(value: videos, timestamp: now)
        }
        
        // Limit cache size using LRU eviction
        limitCacheSize()
        
        // Add to history only for successful searches
        if !webResults.isEmpty || !images.isEmpty || !videos.isEmpty {
            addToHistory(sanitizedQuery)
        }
        
        print("✅ Suche abgeschlossen - Web: \(webResults.count), Bilder: \(images.count), Videos: \(videos.count)")
        
        isSearching = false
    }
    
    // MARK: - Cache Management (LRU)
    private func limitCacheSize() {
        if searchCache.count > maxCacheSize {
            let sortedKeys = searchCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let keysToRemove = sortedKeys.prefix(searchCache.count - maxCacheSize).map(\.key)
            for key in keysToRemove {
                searchCache.removeValue(forKey: key)
                imageCache.removeValue(forKey: key)
                videoCache.removeValue(forKey: key)
            }
        }
    }
    
    func clearCache() {
        searchCache.removeAll()
        imageCache.removeAll()
        videoCache.removeAll()
    }
    
    func selectResult(_ result: SearchResult) {
        selectedResult = result
        isWebViewPresented = true
    }
    
    func dismissWebView() {
        isWebViewPresented = false
        selectedResult = nil
    }
    
    private func addToHistory(_ query: String) {
        // Entferne Duplikate
        searchHistory.removeAll { $0.lowercased() == query.lowercased() }
        searchHistory.insert(query, at: 0)
        
        // Behalte nur die letzten 20 Suchen
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        // Speichere in SwiftData
        if let context = modelContext {
            let entry = HistoryEntry(title: query, urlString: "search://\(query)")
            context.insert(entry)
            try? context.save()
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        imageResults = []
        videoResults = []
        errorMessage = nil
        wikipediaInfo = nil
    }
    
    /// Vollständiger Reset zur Startseite
    func resetToHomeState() {
        searchQuery = ""
        searchResults = []
        imageResults = []
        videoResults = []
        wikipediaInfo = nil
        errorMessage = nil
        isSearching = false
        selectedResult = nil
        isWebViewPresented = false
    }
}
