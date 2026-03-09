//
//  SearchViewModel.swift
//  MountainBrowser
//
//  BEREINIGT: Nur noch für Such-UI-State zuständig.
//  Die eigentlichen Suchergebnisse werden in BrowserTab (via TabManager) gespeichert.
//

import SwiftUI
import SwiftData
import Combine

@Observable
final class SearchViewModel {
    // MARK: - UI State (NUR was TabManager nicht verwaltet)
    var searchQuery: String = ""
    var isSearching: Bool = false
    var errorMessage: String?
    var searchHistory: [String] = []
    
    // MARK: - Dependencies
    var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    var canSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    /// Führt eine Suche aus — die Ergebnisse werden vom TabManager in einen BrowserTab gespeichert.
    /// Diese Methode wird NICHT mehr direkt aufgerufen — stattdessen wird TabManager.createSearchTab() verwendet.
    @MainActor
    func performSearch() async {
        // HINWEIS: Diese Methode existiert nur noch als Fallback.
        // Der primäre Suchweg ist über TabManager.createSearchTab()
    }
    
    // MARK: - History Management
    
    func addToHistory(_ query: String) {
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
        errorMessage = nil
    }
    
    /// Vollständiger Reset zur Startseite
    func resetToHomeState() {
        searchQuery = ""
        errorMessage = nil
        isSearching = false
    }
}
