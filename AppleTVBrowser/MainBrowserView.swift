//
//  MainBrowserView.swift
//  AppleTVBrowser
//
//  Hauptansicht der tvOS Browser-App mit allen integrierten Komponenten
//

import SwiftUI
import SwiftData

struct MainBrowserView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showWebView: Bool = false
    @State private var selectedResult: SearchResult?
    
    var body: some View {
        ZStack {
            // Hintergrund - Dunkles Theme laut Spezifikation (#1C1C1E)
            Color(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Prominente Suchleiste (120pt Höhe, 28pt Font)
                EnhancedSearchBar(
                    searchQuery: $searchViewModel.searchQuery,
                    isSearching: $searchViewModel.isSearching,
                    searchHistory: searchViewModel.searchHistory,
                    onSearch: {
                        Task {
                            await searchViewModel.performSearch()
                        }
                    },
                    onVoiceSearch: {
                        // TODO: Siri-Integration
                    }
                )
                .zIndex(1) // Über den Ergebnissen
                
                // Hauptinhaltsbereich
                contentView
            }
            
            // Vollbild-WebView-Overlay
            if showWebView, let result = selectedResult {
                FullscreenWebView(
                    url: result.url,
                    title: result.title,
                    isPresented: $showWebView
                )
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }
        }
        .onAppear {
            searchViewModel.modelContext = modelContext
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if searchViewModel.isSearching {
            loadingView
        } else if let error = searchViewModel.errorMessage {
            errorView(error)
        } else if searchViewModel.hasResults {
            resultsView
        } else {
            emptyStateView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 30) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2.0)
            
            Text("Suche läuft...")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        SearchResultGridView(
            results: searchViewModel.searchResults,
            onSelect: { result in
                selectedResult = result
                withAnimation(.easeInOut(duration: 0.3)) {
                    showWebView = true
                }
            }
        )
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Fehler bei der Suche")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(error)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
            Button(action: {
                Task {
                    await searchViewModel.performSearch()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Erneut versuchen")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 40) {
            // App-Logo oder Icon
            Image(systemName: "network")
                .font(.system(size: 120))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Willkommen beim tvOS Browser")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Gib einen Suchbegriff ein oder verwende Siri für die Sprachsuche")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
            }
            
            // Quick-Suggestions
            if !searchViewModel.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Zuletzt gesucht")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 60)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(searchViewModel.searchHistory.prefix(5), id: \.self) { query in
                                Button(action: {
                                    searchViewModel.searchQuery = query
                                    Task {
                                        await searchViewModel.performSearch()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 18))
                                        Text(query)
                                            .font(.system(size: 20, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 60)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Preview

#Preview {
    MainBrowserView()
        .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}