//
//  TabManager.swift
//  MountainBrowser
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
        
        return searchTab
    }
    
    /// Führt eine Suche in einem bestimmten Tab aus
    @MainActor
    func performSearchInTab(_ tab: BrowserTab, query: String) async {
        guard tabs.contains(tab) else { 
            return 
        }
        
        let searchService = SearchService()
        let urlValidator = URLValidator()
        let sanitizedQuery = await urlValidator.sanitizeSearchQuery(query)
        
        // Capture the value before entering closures to avoid actor isolation issues
        let youTubeConfigured = APIConfiguration.isYouTubeConfigured
        
        // Parallele Suche für alle Content-Types
        async let webSearchTask: [SearchResult] = {
            do {
                return try await searchService.search(query: sanitizedQuery)
            } catch {
                return []
            }
        }()
        
        async let imageSearchTask: [SearchResult] = {
            do {
                return try await searchService.searchImages(query: sanitizedQuery)
            } catch {
                return []
            }
        }()
        
        async let videoSearchTask: [SearchResult] = {
            if youTubeConfigured {
                do {
                    return try await searchService.searchVideos(query: sanitizedQuery)
                } catch {
                    return []
                }
            } else {
                return []
            }
        }()
        
        async let wikipediaTask: WikipediaInfo? = {
            do {
                return try await searchService.searchWikipedia(query: sanitizedQuery)
            } catch {
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
            tab.title = L10n.Search.searchPrefix(sanitizedQuery)
        } else {
            tab.title = L10n.Search.noResultsPrefix(sanitizedQuery)
        }
        
        saveContext()
        
        // FIX: Erzwinge UI-Refresh
        objectWillChange.send()
        
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
        
    }
}

@MainActor
final class TabManager: ObservableObject {
    // MARK: - Properties
    
    @Published var tabs: [BrowserTab] = []
    @Published var activeTab: BrowserTab?
    var modelContext: ModelContext?
    
    // MARK: - Constants
    
    private let maxTabs = 8
    
    // FIX: Debounce für saveContext um übermäßige Speichervorgänge zu verhindern
    private var saveDebounceTask: Task<Void, Never>?
    private let saveDebounceInterval: TimeInterval = 0.3 // 300ms Debounce
    
    // MARK: - Initialization
    
    init() {}
    
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
            
            // FIX: Sicherstellen, dass nur EIN Tab aktiv ist
            let activeTabs = tabs.filter { $0.isActive }
            if activeTabs.count > 1 {
                // Nur den neuesten aktiven Tab behalten
                for (index, tab) in activeTabs.enumerated() {
                    if index > 0 {
                        tab.deactivate()
                    }
                }
                saveContext()
            }
            
            // Aktiven Tab finden oder ersten Tab aktivieren
            activeTab = tabs.first(where: { $0.isActive }) ?? tabs.first
            if let activeTab = activeTab, !activeTab.isActive {
                activeTab.activate()
                saveContext()
            }
            
            // Falls keine Tabs vorhanden sind, erstelle einen Standard-Tab
            if tabs.isEmpty {
                createNewTab()
            }
        } catch {
            createNewTab()
        }
    }
    
    /// Erstellt einen neuen Tab
    @discardableResult
    func createNewTab(url: String? = nil, title: String? = nil, activate: Bool = true) -> BrowserTab {
        guard tabs.count < maxTabs else {
            return activeTab ?? tabs.last!
        }
        
        let newTab: BrowserTab
        
        if let url = url {
            newTab = BrowserTab.createTabWithURL(url, title: title)
        } else {
            newTab = BrowserTab.createNewTab()
        }
        
        if activate {
            deactivateAllTabs()
            newTab.activate()
            activeTab = newTab
        }
        
        tabs.insert(newTab, at: 0)
        
        if let context = modelContext {
            context.insert(newTab)
            saveContext()
        }
        
        return newTab
    }
    
    /// Aktiviert einen bestimmten Tab
    func activateTab(_ tab: BrowserTab) {
        guard tabs.contains(tab) else { return }
        
        deactivateAllTabs()
        tab.activate()
        activeTab = tab
        
        saveContext()
        
    }
    
    /// Schließt einen Tab
    func closeTab(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }
        
        let wasActive = tab.isActive
        _ = tab.displayTitle // FIX: Titel vor dem Löschen speichern
        
        tabs.remove(at: index)
        
        if let context = modelContext {
            context.delete(tab)
            // FIX: Sofortiges Speichern bei Tab-Löschung
            saveContextImmediately()
        }
        
        if wasActive {
            if tabs.isEmpty {
                createNewTab()
            } else if index < tabs.count {
                activateTab(tabs[index])
            } else if index > 0 {
                activateTab(tabs[index - 1])
            } else {
                activateTab(tabs[0])
            }
        }
        
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
        // FIX: Sofortiges Speichern bei Batch-Löschung
        saveContextImmediately()
        
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
        // FIX: Sofortiges Speichern bei Batch-Löschung
        saveContextImmediately()
        
        createNewTab()
        
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
    
    func deactivateAllTabs() {
        for tab in tabs {
            tab.deactivate()
        }
    }
    
    /// FIX: Debounced saveContext um Performance zu verbessern
    func saveContext() {
        // Vorherigen Debounce-Task abbrechen
        saveDebounceTask?.cancel()
        
        // Neuen Debounce-Task starten
        saveDebounceTask = Task { [weak self] in
            // FIX: Kurze Verzögerung um mehrere schnelle Änderungen zu bündeln
            try? await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            guard let self = self else { return }
            
            await self.performSave()
        }
    }
    
    /// FIX: Sofortiges Speichern ohne Debounce (für kritische Operationen)
    func saveContextImmediately() {
        saveDebounceTask?.cancel()
        
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
        }
    }
    
    /// Private Speicher-Funktion
    private func performSave() async {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
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
    
    func selectNextTab() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        activateTab(tabs[nextIndex])
    }
    
    func selectPreviousTab() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }
        
        let previousIndex = currentIndex == 0 ? tabs.count - 1 : currentIndex - 1
        activateTab(tabs[previousIndex])
    }
    
    // MARK: - Utility Methods
    
    func findTab(withURL url: String) -> BrowserTab? {
        return tabs.first { $0.urlString == url }
    }
    
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
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension TabManager {
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
        
        if let firstTab = tabs.first {
            activateTab(firstTab)
        }
    }
}
#endif
