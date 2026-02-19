//
//  BrowserTab.swift
//  AppleTVBrowser
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
    }
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        if title.isEmpty || title == "Neuer Tab" {
            if let url = URL(string: urlString), let host = url.host {
                return host
            }
            return "Neuer Tab"
        }
        return title
    }
    
    var displayURL: String {
        if urlString.isEmpty {
            return "about:blank"
        }
        return urlString
    }
    
    var previewImage: UIImage? {
        guard let data = previewImageData else { return nil }
        return UIImage(data: data)
    }
    
    var isBlank: Bool {
        return urlString.isEmpty || urlString == "about:blank"
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
        } catch {
            print("❌ Fehler beim Speichern der Suchergebnisse: \(error)")
        }
    }
    
    /// Lädt Suchergebnisse aus dem Tab
    func getSearchResults() -> [SearchResult] {
        guard let data = searchResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            print("❌ Fehler beim Laden der Suchergebnisse: \(error)")
            return []
        }
    }
    
    /// Speichert Bild-Suchergebnisse im Tab
    func updateImageResults(_ results: [SearchResult]) {
        do {
            let encoder = JSONEncoder()
            self.imageResultsData = try encoder.encode(results)
        } catch {
            print("❌ Fehler beim Speichern der Bildergebnisse: \(error)")
        }
    }
    
    /// Lädt Bild-Suchergebnisse aus dem Tab
    func getImageResults() -> [SearchResult] {
        guard let data = imageResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            print("❌ Fehler beim Laden der Bildergebnisse: \(error)")
            return []
        }
    }
    
    /// Speichert Video-Suchergebnisse im Tab
    func updateVideoResults(_ results: [SearchResult]) {
        do {
            let encoder = JSONEncoder()
            self.videoResultsData = try encoder.encode(results)
        } catch {
            print("❌ Fehler beim Speichern der Videoergebnisse: \(error)")
        }
    }
    
    /// Lädt Video-Suchergebnisse aus dem Tab
    func getVideoResults() -> [SearchResult] {
        guard let data = videoResultsData else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            print("❌ Fehler beim Laden der Videoergebnisse: \(error)")
            return []
        }
    }
    
    /// Speichert Wikipedia-Info im Tab
    func updateWikipediaInfo(_ info: WikipediaInfo?) {
        guard let info = info else {
            self.wikipediaInfoData = nil
            return
        }
        
        do {
            let encoder = JSONEncoder()
            self.wikipediaInfoData = try encoder.encode(info)
        } catch {
            print("❌ Fehler beim Speichern der Wikipedia-Info: \(error)")
        }
    }
    
    /// Lädt Wikipedia-Info aus dem Tab
    func getWikipediaInfo() -> WikipediaInfo? {
        guard let data = wikipediaInfoData else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WikipediaInfo.self, from: data)
        } catch {
            print("❌ Fehler beim Laden der Wikipedia-Info: \(error)")
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
        return !getSearchResults().isEmpty || 
               !getImageResults().isEmpty || 
               !getVideoResults().isEmpty || 
               getWikipediaInfo() != nil
    }
    
    // MARK: - Convenience Properties
    
    /// Convenience Property für Wikipedia-Info
    var wikipediaInfo: WikipediaInfo? {
        return getWikipediaInfo()
    }
    
    /// Convenience Property für Web-Suchergebnisse
    var searchResults: [SearchResult] {
        return getSearchResults()
    }
    
    /// Convenience Property für Bild-Suchergebnisse
    var imageResults: [SearchResult] {
        return getImageResults()
    }
    
    /// Convenience Property für Video-Suchergebnisse
    var videoResults: [SearchResult] {
        return getVideoResults()
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

