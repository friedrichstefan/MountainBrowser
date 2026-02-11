//
//  SearchViewModel.swift
//  AppleTVBrowser
//

import SwiftUI
import SwiftData
import Observation
import Combine

@Observable
final class SearchViewModel: ObservableObject {
    // MARK: - State
    var searchQuery: String = "" {
        didSet {
            searchQuerySubject.send(searchQuery)
        }
    }
    var searchResults: [SearchResult] = []
    var isSearching: Bool = false
    var errorMessage: String?
    var selectedResult: SearchResult?
    var isWebViewPresented: Bool = false
    var searchHistory: [String] = []
    
    // MARK: - Dependencies
    private let searchService = SearchService()
    private let urlValidator = URLValidator()
    var modelContext: ModelContext?
    
    // MARK: - Performance Optimization
    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var searchCache: [String: [SearchResult]] = [:]
    private let maxCacheSize = 50
    
    // MARK: - Computed Properties
    var hasResults: Bool {
        !searchResults.isEmpty
    }
    
    var showEmptyState: Bool {
        !isSearching && searchResults.isEmpty && errorMessage == nil
    }
    
    var canSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    init() {
        setupSearchDebouncing()
    }
    
    // MARK: - Search Debouncing Setup
    private func setupSearchDebouncing() {
        // Live-Search deaktiviert - nur manuelle Suche via Enter oder Button
        // searchQuerySubject
        //     .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        //     .removeDuplicates()
        //     .map { query in
        //         query.trimmingCharacters(in: .whitespacesAndNewlines)
        //     }
        //     .filter { !$0.isEmpty }
        //     .sink { [weak self] debouncedQuery in
        //         Task {
        //             await self?.performDebouncedSearch(query: debouncedQuery)
        //         }
        //     }
        //     .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @MainActor
    func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        await performDebouncedSearch(query: query)
    }
    
    @MainActor
    private func performDebouncedSearch(query: String) async {
        guard !query.isEmpty else { 
            searchResults = []
            return 
        }
        
        // Sanitize search query
        let sanitizedQuery = await urlValidator.sanitizeSearchQuery(query)
        
        // Check cache first
        if let cachedResults = searchCache[sanitizedQuery.lowercased()] {
            searchResults = cachedResults
            return
        }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
        do {
            let results = try await searchService.search(query: sanitizedQuery)
            searchResults = results
            
            // Cache results
            cacheSearchResults(sanitizedQuery, results: results)
            
            // Add to history only for successful searches
            addToHistory(sanitizedQuery)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    // MARK: - Cache Management
    private func cacheSearchResults(_ query: String, results: [SearchResult]) {
        let cacheKey = query.lowercased()
        searchCache[cacheKey] = results
        
        // Limit cache size (LRU-style - simple implementation)
        if searchCache.count > maxCacheSize {
            let oldestKey = searchCache.keys.randomElement()
            if let key = oldestKey {
                searchCache.removeValue(forKey: key)
            }
        }
    }
    
    func clearCache() {
        searchCache.removeAll()
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
        errorMessage = nil
        // Don't clear cache - keep for better performance
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
