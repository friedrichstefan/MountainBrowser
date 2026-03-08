//
//  BrowserTab.swift
//  MountainBrowser
//
//  Tab-Management für Safari-ähnliche Browser-Tabs
//

import Foundation
import SwiftData
import UIKit

@Model
final class BrowserTab {
    var id: UUID
    var title: String
    var urlString: String
    var faviconURL: String?
    var previewImageData: Data?
    var dateCreated: Date
    var dateLastAccessed: Date
    var isActive: Bool
    var scrollPosition: Double
    
    // MARK: - Search Properties
    var searchQuery: String?
    var searchResultsData: Data? // JSON encoded [SearchResult]
    var imageResultsData: Data? // JSON encoded [SearchResult]
    var videoResultsData: Data? // JSON encoded [SearchResult]
    var wikipediaInfoData: Data? // JSON encoded WikipediaInfo
    var selectedContentType: String // SearchContentType rawValue
    var isSearchTab: Bool
    var isInfoBoxExpanded: Bool
    
    // FIX: Gecachte Zähler, damit nicht jedes Mal JSON decodiert werden muss
    var webResultsCount: Int
    var imageResultsCount: Int
    var videoResultsCount: Int
    var hasWikipediaInfo: Bool
    
    // MARK: - Transiente Cache-Properties (nicht persistiert)
    /// Diese werden bei jedem App-Neustart zurückgesetzt, vermeiden aber wiederholtes JSON-Decoding
    @Transient private var _cachedSearchResults: [SearchResult]?
    @Transient private var _cachedImageResults: [SearchResult]?
    @Transient private var _cachedVideoResults: [SearchResult]?
    @Transient private var _cachedWikipediaInfo: WikipediaInfo?
    @Transient private var _wikipediaInfoLoaded: Bool = false
    
    init(
        title: String = "Neuer Tab",
        urlString: String = "",
        faviconURL: String? = nil,
        previewImageData: Data? = nil,
        isActive: Bool = false,
        searchQuery: String? = nil,
        isSearchTab: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.faviconURL = faviconURL
        self.previewImageData = previewImageData
        self.dateCreated = Date()
        self.dateLastAccessed = Date()
        self.isActive = isActive
        self.scrollPosition = 0.0
        
        // Search Properties
        self.searchQuery = searchQuery
        self.searchResultsData = nil
        self.imageResultsData = nil
        self.videoResultsData = nil
        self.wikipediaInfoData = nil
        self.selectedContentType = SearchContentType.web.rawValue
        self.isSearchTab = isSearchTab
        self.isInfoBoxExpanded = true
        
        // Gecachte Zähler
        self.webResultsCount = 0
        self.imageResultsCount = 0
        self.videoResultsCount = 0
        self.hasWikipediaInfo = false
    }
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        if isSearchTab, let query = searchQuery, !query.isEmpty {
            return query
        }
        if !title.isEmpty && title != "Neuer Tab" {
            return title
        }
        if let url = URL(string: urlString), let host = url.host {
            return host
        }
        return "Neuer Tab"
    }
    
    var displayURL: String {
        if urlString.isEmpty {
            return ""
        }
        return urlString
    }
    
    /// Kurze URL-Anzeige (nur Domain)
    var shortDisplayURL: String {
        guard let url = URL(string: urlString), let host = url.host else {
            return ""
        }
        var h = host
        if h.hasPrefix("www.") {
            h = String(h.dropFirst(4))
        }
        return h
    }
    
    var previewImage: UIImage? {
        guard let data = previewImageData else { return nil }
        return UIImage(data: data)
    }
    
    var isBlank: Bool {
        return urlString.isEmpty || urlString == "about:blank"
    }
    
    /// Gesamtzahl aller Suchergebnisse
    var totalResultsCount: Int {
        return webResultsCount + imageResultsCount + videoResultsCount
    }
    
    /// Zusammenfassung der Ergebnisse als String
    var resultsSummary: String {
        var parts: [String] = []
        if webResultsCount > 0 { parts.append("\(webResultsCount) Web") }
        if imageResultsCount > 0 { parts.append("\(imageResultsCount) Bilder") }
        if videoResultsCount > 0 { parts.append("\(videoResultsCount) Videos") }
        if parts.isEmpty { return "Keine Ergebnisse" }
        return parts.joined(separator: " · ")
    }
    
    /// Relative Zeitangabe seit letztem Zugriff
    var lastAccessedRelative: String {
        let interval = Date().timeIntervalSince(dateLastAccessed)
        if interval < 60 { return "Gerade eben" }
        if interval < 3600 { return "Vor \(Int(interval / 60)) Min." }
        if interval < 86400 { return "Vor \(Int(interval / 3600)) Std." }
        return "Vor \(Int(interval / 86400)) Tagen"
    }
    
    // MARK: - Methods
    
    func updateContent(title: String?, url: String?) {
        if let title = title, !title.isEmpty {
            self.title = title
        }
        if let url = url, !url.isEmpty {
            self.urlString = url
        }
        self.dateLastAccessed = Date()
    }
    
    func updatePreview(image: UIImage?) {
        if let image = image {
            self.previewImageData = image.jpegData(compressionQuality: 0.7)
        } else {
            self.previewImageData = nil
        }
    }
    
    func activate() {
        self.isActive = true
        self.dateLastAccessed = Date()
    }
    
    func deactivate() {
        self.isActive = false
    }
    
    func updateScrollPosition(_ position: Double) {
        self.scrollPosition = position
    }
}

// MARK: - Search Methods

extension BrowserTab {
    var contentType: SearchContentType {
        return SearchContentType(rawValue: selectedContentType) ?? .web
    }
    
    /// Erstellt einen neuen Such-Tab
    static func createSearchTab(query: String) -> BrowserTab {
        let tab = BrowserTab(
            title: "Suche: \(query)",
            urlString: "",
            isActive: false,
            searchQuery: query,
            isSearchTab: true
        )
        return tab
    }
    
    /// Speichert Suchergebnisse im Tab
    func updateSearchResults(_ results: [SearchResult]) {
        do {
            let encoder = JSONEncoder()
            self.searchResultsData = try encoder.encode(results)
            self.webResultsCount = results.count
            // Cache invalidieren
            self._cachedSearchResults = results
        } catch {
        }
    }
    
    /// Lädt Suchergebnisse aus dem Tab
    func getSearchResults() -> [SearchResult] {
        guard let data = searchResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            return []
        }
    }
    
    /// Speichert Bild-Suchergebnisse im Tab
    func updateImageResults(_ results: [SearchResult]) {
        do {
            let encoder = JSONEncoder()
            self.imageResultsData = try encoder.encode(results)
            self.imageResultsCount = results.count
            // Cache invalidieren
            self._cachedImageResults = results
        } catch {
        }
    }
    
    /// Lädt Bild-Suchergebnisse aus dem Tab
    func getImageResults() -> [SearchResult] {
        guard let data = imageResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            return []
        }
    }
    
    /// Speichert Video-Suchergebnisse im Tab
    func updateVideoResults(_ results: [SearchResult]) {
        do {
            let encoder = JSONEncoder()
            self.videoResultsData = try encoder.encode(results)
            self.videoResultsCount = results.count
            // Cache invalidieren
            self._cachedVideoResults = results
        } catch {
        }
    }
    
    /// Lädt Video-Suchergebnisse aus dem Tab
    func getVideoResults() -> [SearchResult] {
        guard let data = videoResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            return []
        }
    }
    
    /// Speichert Wikipedia-Info im Tab
    func updateWikipediaInfo(_ info: WikipediaInfo?) {
        guard let info = info else {
            self.wikipediaInfoData = nil
            self.hasWikipediaInfo = false
            // Cache invalidieren
            self._cachedWikipediaInfo = nil
            self._wikipediaInfoLoaded = true
            return
        }
        
        do {
            let encoder = JSONEncoder()
            self.wikipediaInfoData = try encoder.encode(info)
            self.hasWikipediaInfo = true
            // Cache invalidieren
            self._cachedWikipediaInfo = info
            self._wikipediaInfoLoaded = true
        } catch {
        }
    }
    
    /// Lädt Wikipedia-Info aus dem Tab
    func getWikipediaInfo() -> WikipediaInfo? {
        guard let data = wikipediaInfoData else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WikipediaInfo.self, from: data)
        } catch {
            return nil
        }
    }
    
    /// Aktualisiert den ausgewählten Content-Type
    func updateSelectedContentType(_ type: SearchContentType) {
        self.selectedContentType = type.rawValue
        self.dateLastAccessed = Date()
    }
    
    /// Aktualisiert den InfoBox-Zustand
    func updateInfoBoxExpanded(_ expanded: Bool) {
        self.isInfoBoxExpanded = expanded
    }
    
    /// Prüft ob der Tab Suchergebnisse hat
    var hasSearchResults: Bool {
        return webResultsCount > 0 ||
               imageResultsCount > 0 ||
               videoResultsCount > 0 ||
               hasWikipediaInfo
    }
    
    // MARK: - Lazy Cached Property Accessors
    
    /// Convenience Property für Wikipedia-Info (gecached)
    var wikipediaInfo: WikipediaInfo? {
        if !_wikipediaInfoLoaded {
            _cachedWikipediaInfo = getWikipediaInfo()
            _wikipediaInfoLoaded = true
        }
        return _cachedWikipediaInfo
    }
    
    /// Convenience Property für Web-Suchergebnisse (gecached)
    var searchResults: [SearchResult] {
        if _cachedSearchResults == nil && searchResultsData != nil {
            _cachedSearchResults = getSearchResults()
        }
        return _cachedSearchResults ?? []
    }
    
    /// Convenience Property für Bild-Suchergebnisse (gecached)
    var imageResults: [SearchResult] {
        if _cachedImageResults == nil && imageResultsData != nil {
            _cachedImageResults = getImageResults()
        }
        return _cachedImageResults ?? []
    }
    
    /// Convenience Property für Video-Suchergebnisse (gecached)
    var videoResults: [SearchResult] {
        if _cachedVideoResults == nil && videoResultsData != nil {
            _cachedVideoResults = getVideoResults()
        }
        return _cachedVideoResults ?? []
    }
    
    /// Löscht alle Suchergebnisse
    func clearSearchResults() {
        self.searchResultsData = nil
        self.imageResultsData = nil
        self.videoResultsData = nil
        self.wikipediaInfoData = nil
        self.searchQuery = nil
        self.isSearchTab = false
        self.title = "Neuer Tab"
        self.webResultsCount = 0
        self.imageResultsCount = 0
        self.videoResultsCount = 0
        self.hasWikipediaInfo = false
        // Caches invalidieren
        self._cachedSearchResults = nil
        self._cachedImageResults = nil
        self._cachedVideoResults = nil
        self._cachedWikipediaInfo = nil
        self._wikipediaInfoLoaded = false
    }
}

// MARK: - Tab State Management

extension BrowserTab {
    static func createNewTab() -> BrowserTab {
        return BrowserTab(title: "Neuer Tab", urlString: "", isActive: false)
    }
    
    static func createTabWithURL(_ url: String, title: String? = nil) -> BrowserTab {
        let tab = BrowserTab(
            title: title ?? "Lädt...",
            urlString: url,
            isActive: false
        )
        return tab
    }
}

