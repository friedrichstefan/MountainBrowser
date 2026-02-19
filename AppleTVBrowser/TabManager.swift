//
//  TabManager.swift
//  AppleTVBrowser
//
//  Tab-Management ViewModel für Safari-ähnliche Browser-Tabs
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - TabManager Search Extension

extension TabManager {
    /// Erstellt einen neuen Such-Tab und führt die Suche aus
    @MainActor
    func createSearchTab(query: String) async -> BrowserTab {
        let searchTab = BrowserTab.createSearchTab(query: query)
        
        // Alte Tabs deaktivieren
        deactivateAllTabs()
        searchTab.activate()
        activeTab = searchTab
        
        tabs.insert(searchTab, at: 0)
        
        // In Datenbank speichern
        if let context = modelContext {
            context.insert(searchTab)
            saveContext()
        }
        
        // Suche ausführen
        await performSearchInTab(searchTab, query: query)
        
        print("✅ Such-Tab erstellt und Suche durchgeführt: \(query)")
        return searchTab
    }
    
    /// Führt eine Suche in einem bestimmten Tab aus
    @MainActor
    func performSearchInTab(_ tab: BrowserTab, query: String) async {
        guard tabs.contains(tab) else { 
            print("❌ Tab nicht gefunden für Suche: \(query)")
            return 
        }
        
        let searchService = SearchService()
        let urlValidator = URLValidator()
        let sanitizedQuery = await urlValidator.sanitizeSearchQuery(query)
        
        do {
            // Parallele Suche für alle Content-Types
            async let webSearchTask: [SearchResult] = {
                do {
                    return try await searchService.search(query: sanitizedQuery)
                } catch {
                    print("⚠️ Web-Suche Fehler: \(error.localizedDescription)")
                    return []
                }
            }()
            
            async let imageSearchTask: [SearchResult] = {
                do {
                    return try await searchService.searchImages(query: sanitizedQuery)
                } catch {
                    print("⚠️ Bilder-Suche Fehler: \(error.localizedDescription)")
                    return []
                }
            }()
            
            async let videoSearchTask: [SearchResult] = {
                if APIConfiguration.isYouTubeConfigured {
                    do {
                        return try await searchService.searchVideos(query: sanitizedQuery)
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
                    return try await searchService.searchWikipedia(query: sanitizedQuery)
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
            
            // Ergebnisse im Tab speichern
            tab.updateSearchResults(webResults)
            tab.updateImageResults(images)
            tab.updateVideoResults(videos)
            tab.updateWikipediaInfo(wiki)
            tab.searchQuery = sanitizedQuery
            tab.isSearchTab = true
            
            // Tab-Titel aktualisieren
            if !webResults.isEmpty || !images.isEmpty || !videos.isEmpty {
                tab.title = "Suche: \(sanitizedQuery)"
            } else {
                tab.title = "Keine Ergebnisse: \(sanitizedQuery)"
            }
            
            saveContext()
            
            print("✅ Suche in Tab abgeschlossen - Web: \(webResults.count), Bilder: \(images.count), Videos: \(videos.count)")
            
        }
    }
    
    /// Aktualisiert den Content-Type eines Such-Tabs
    func updateTabContentType(_ tab: BrowserTab, contentType: SearchContentType) {
        guard tabs.contains(tab), tab.isSearchTab else { return }
        
        tab.updateSelectedContentType(contentType)
        saveContext()
    }
    
    /// Aktualisiert den InfoBox-Zustand eines Such-Tabs  
    func updateTabInfoBoxExpanded(_ tab: BrowserTab, expanded: Bool) {
        guard tabs.contains(tab), tab.isSearchTab else { return }
        
        tab.updateInfoBoxExpanded(expanded)
        saveContext()
    }
    
    /// Gibt alle Such-Tabs zurück
    var searchTabs: [BrowserTab] {
        return tabs.filter { $0.isSearchTab }
    }
    
    /// Prüft ob der aktive Tab ein Such-Tab ist
    var activeTabIsSearchTab: Bool {
        return activeTab?.isSearchTab ?? false
    }
    
    /// Gibt die Suchergebnisse des aktiven Tabs für einen bestimmten Content-Type zurück
    func getActiveTabResults(for contentType: SearchContentType) -> [SearchResult] {
        guard let tab = activeTab, tab.isSearchTab else { return [] }
        
        switch contentType {
        case .web:
            return tab.getSearchResults()
        case .image:
            return tab.getImageResults()
        case .video:
            return tab.getVideoResults()
        case .info:
            return []
        }
    }
    
    /// Gibt die Wikipedia-Info des aktiven Tabs zurück
    var activeTabWikipediaInfo: WikipediaInfo? {
        guard let tab = activeTab, tab.isSearchTab else { return nil }
        return tab.getWikipediaInfo()
    }
    
    /// Aktualisiert den Content-Type des aktiven Tabs
    func updateActiveTabContentType(_ contentType: SearchContentType) {
        guard let tab = activeTab, tab.isSearchTab else { return }
        updateTabContentType(tab, contentType: contentType)
    }
    
    /// Aktualisiert den InfoBox-Zustand des aktiven Tabs
    func updateActiveTabInfoBox(_ expanded: Bool) {
        guard let tab = activeTab, tab.isSearchTab else { return }
        updateTabInfoBoxExpanded(tab, expanded: expanded)
    }
    
    /// Kollabiert die InfoBox des aktiven Tabs
    func collapseInfoBoxForActiveTab() {
        updateActiveTabInfoBox(false)
    }
    
    /// Wechselt den InfoBox-Zustand des aktiven Tabs
    func toggleInfoBoxForActiveTab() {
        guard let tab = activeTab else { return }
        updateActiveTabInfoBox(!tab.isInfoBoxExpanded)
    }
    
    /// Löscht die Suchergebnisse eines Tabs
    func clearTabSearchResults(_ tab: BrowserTab) {
        guard tabs.contains(tab) else { return }
        
        tab.clearSearchResults()
        saveContext()
        
        print("🧹 Suchergebnisse für Tab gelöscht: \(tab.displayTitle)")
    }
}

final class TabManager: ObservableObject {
    // MARK: - Properties
    
    @Published var tabs: [BrowserTab] = []
    @Published var activeTab: BrowserTab?
    var modelContext: ModelContext?
    
    // MARK: - Constants
    
    private let maxTabs = 12 // tvOS Limitation für Performance
    
    // MARK: - Initialization
    
    init() {
        // Tabs werden beim ersten Zugriff auf modelContext geladen
    }
    
    // MARK: - Public Methods
    
    /// Setzt den ModelContext und lädt bestehende Tabs
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTabs()
    }
    
    /// Lädt alle Tabs aus der Datenbank
    func loadTabs() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<BrowserTab>(
                sortBy: [SortDescriptor(\.dateLastAccessed, order: .reverse)]
            )
            self.tabs = try context.fetch(descriptor)
            
            // Aktiven Tab finden oder ersten Tab aktivieren
            if activeTab == nil {
                activeTab = tabs.first { $0.isActive } ?? tabs.first
            }
            
            // Falls keine Tabs vorhanden sind, erstelle einen Standard-Tab
            if tabs.isEmpty {
                createNewTab()
            }
        } catch {
            print("❌ Fehler beim Laden der Tabs: \(error)")
            // Fallback: Erstelle einen neuen Tab
            createNewTab()
        }
    }
    
    /// Erstellt einen neuen Tab
    @discardableResult 
    @MainActor
    func createNewTab(url: String? = nil, title: String? = nil, activate: Bool = true) -> BrowserTab {
        guard tabs.count < maxTabs else {
            print("⚠️ Maximale Anzahl Tabs (\(maxTabs)) erreicht")
            return activeTab ?? tabs.last!
        }
        
        let newTab: BrowserTab
        
        if let url = url {
            newTab = BrowserTab.createTabWithURL(url, title: title)
        } else {
            newTab = BrowserTab.createNewTab()
        }
        
        // Alte Tabs deaktivieren wenn neuer Tab aktiviert werden soll
        if activate {
            deactivateAllTabs()
            newTab.activate()
            activeTab = newTab
        }
        
        tabs.insert(newTab, at: 0) // Neuester Tab an den Anfang
        
        // In Datenbank speichern
        if let context = modelContext {
            context.insert(newTab)
            saveContext()
        }
        
        print("✅ Neuer Tab erstellt: \(newTab.displayTitle)")
        return newTab
    }
    
    /// Aktiviert einen bestimmten Tab
    func activateTab(_ tab: BrowserTab) {
        guard tabs.contains(tab) else { return }
        
        deactivateAllTabs()
        tab.activate()
        activeTab = tab
        
        saveContext()
        
        print("🔄 Tab aktiviert: \(tab.displayTitle)")
    }
    
    /// Schließt einen Tab
    func closeTab(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }
        
        let wasActive = tab.isActive
        
        // Tab aus Array entfernen
        tabs.remove(at: index)
        
        // Aus Datenbank löschen
        if let context = modelContext {
            context.delete(tab)
            saveContext()
        }
        
        // Wenn das der aktive Tab war, einen anderen aktivieren
        if wasActive {
            if tabs.isEmpty {
                // Wenn keine Tabs mehr vorhanden sind, erstelle einen neuen
                createNewTab()
            } else if index < tabs.count {
                // Nächsten Tab aktivieren
                activateTab(tabs[index])
            } else if index > 0 {
                // Vorherigen Tab aktivieren
                activateTab(tabs[index - 1])
            } else {
                // Ersten Tab aktivieren
                activateTab(tabs[0])
            }
        }
        
        print("🗑️ Tab geschlossen: \(tab.displayTitle)")
    }
    
    /// Schließt alle Tabs außer dem angegebenen
    func closeOtherTabs(except keepTab: BrowserTab) {
        let tabsToClose = tabs.filter { $0.id != keepTab.id }
        
        for tab in tabsToClose {
            if let context = modelContext {
                context.delete(tab)
            }
        }
        
        tabs = [keepTab]
        activateTab(keepTab)
        saveContext()
        
        print("🧹 Alle anderen Tabs geschlossen außer: \(keepTab.displayTitle)")
    }
    
    /// Schließt alle Tabs
    func closeAllTabs() {
        for tab in tabs {
            if let context = modelContext {
                context.delete(tab)
            }
        }
        
        tabs.removeAll()
        activeTab = nil
        saveContext()
        
        // Erstelle einen neuen leeren Tab
        createNewTab()
        
        print("🧹 Alle Tabs geschlossen")
    }
    
    /// Aktualisiert den Inhalt eines Tabs
    func updateTab(_ tab: BrowserTab, title: String?, url: String?, previewImage: UIImage? = nil) {
        guard tabs.contains(tab) else { return }
        
        tab.updateContent(title: title, url: url)
        
        if let image = previewImage {
            tab.updatePreview(image: image)
        }
        
        saveContext()
    }
    
    /// Aktualisiert die Scroll-Position eines Tabs
    func updateTabScrollPosition(_ tab: BrowserTab, position: Double) {
        guard tabs.contains(tab) else { return }
        
        tab.updateScrollPosition(position)
        saveContext()
    }
    
    // MARK: - Private Methods
    
    /// Deaktiviert alle Tabs
    private func deactivateAllTabs() {
        for tab in tabs {
            tab.deactivate()
        }
    }
    
    /// Speichert den ModelContext
    private func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ Fehler beim Speichern der Tabs: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var hasMultipleTabs: Bool {
        return tabs.count > 1
    }
    
    var canCreateNewTab: Bool {
        return tabs.count < maxTabs
    }
    
    var tabsCount: Int {
        return tabs.count
    }
    
    var sortedTabs: [BrowserTab] {
        return tabs.sorted { $0.dateLastAccessed > $1.dateLastAccessed }
    }
    
    // MARK: - Tab Navigation
    
    /// Wechselt zum nächsten Tab
    func selectNextTab() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        activateTab(tabs[nextIndex])
    }
    
    /// Wechselt zum vorherigen Tab
    func selectPreviousTab() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }
        
        let previousIndex = currentIndex == 0 ? tabs.count - 1 : currentIndex - 1
        activateTab(tabs[previousIndex])
    }
    
    // MARK: - Utility Methods
    
    /// Findet einen Tab anhand der URL
    func findTab(withURL url: String) -> BrowserTab? {
        return tabs.first { $0.urlString == url }
    }
    
    /// Räumt alte, unbenutzte Tabs auf
    func cleanupOldTabs(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let oldTabs = tabs.filter { 
            !$0.isActive && 
            $0.dateLastAccessed < cutoffDate &&
            $0.isBlank
        }
        
        for tab in oldTabs {
            closeTab(tab)
        }
        
        if !oldTabs.isEmpty {
            print("🧹 \(oldTabs.count) alte Tabs bereinigt")
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension TabManager {
    /// Erstellt Test-Tabs für Development
    func createTestTabs() {
        let testURLs = [
            ("Apple", "https://www.apple.com"),
            ("Wikipedia", "https://de.wikipedia.org"),
            ("GitHub", "https://github.com"),
            ("YouTube", "https://www.youtube.com")
        ]
        
        for (title, url) in testURLs {
            createNewTab(url: url, title: title, activate: false)
        }
        
        // Ersten Tab aktivieren
        if let firstTab = tabs.first {
            activateTab(firstTab)
        }
    }
}
#endif