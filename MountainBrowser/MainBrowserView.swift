//
//  MainBrowserView.swift
//  MountainBrowser
//
//  Hauptansicht der tvOS Browser-App mit Apple tvOS Human Interface Guidelines
//

import SwiftUI
import SwiftData
import AVKit

// MARK: - Scroll State Reset Callback

/// Ersetzt NotificationCenter-basierte Kommunikation
@Observable
final class ScrollStateManager {
    var shouldReset: Bool = false
    
    func reset() {
        shouldReset = true
        // Auto-reset nach einem Frame
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            shouldReset = false
        }
    }
}

struct MainBrowserView: View {
    @State private var searchViewModel = SearchViewModel()
    @StateObject private var tabManager = TabManager()
    @StateObject private var sessionManager = SessionManager()
    @State private var scrollStateManager = ScrollStateManager()
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedResult: SearchResult?
    @State private var showTabGrid: Bool = false
    @State private var showSettings: Bool = false
    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedSection: FocusSection?
    
    // Tab-basierte Such-Properties - als Bindings
    private var selectedContentType: Binding<SearchContentType> {
        Binding(
            get: { tabManager.activeTab?.contentType ?? .web },
            set: { newValue in
                tabManager.updateActiveTabContentType(newValue)
            }
        )
    }
    
    private var isInfoBoxExpanded: Binding<Bool> {
        Binding(
            get: { tabManager.activeTab?.isInfoBoxExpanded ?? true },
            set: { newValue in
                tabManager.updateActiveTabInfoBox(newValue)
            }
        )
    }
    
    enum FocusSection: Hashable {
        case searchBar
        case wikipediaPanel
        case searchResults
        case tabBar
    }
    
    // MARK: - Computed Properties
    
    private var hasSearchResults: Bool {
        guard let tab = tabManager.activeTab, tab.isSearchTab else { return false }
        return !tab.searchResults.isEmpty
            || !tab.imageResults.isEmpty
            || !tab.videoResults.isEmpty
            || tab.wikipediaInfo != nil
    }
    
    var body: some View {
        @Bindable var searchVM = searchViewModel
        
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                EnhancedSearchBar(
                    searchQuery: $searchVM.searchQuery,
                    isSearching: $searchVM.isSearching,
                    searchHistory: searchViewModel.searchHistory,
                    onSearch: {
                        Task {
                            if !searchViewModel.searchQuery.isEmpty {
                                await tabManager.createSearchTab(query: searchViewModel.searchQuery)
                                await MainActor.run {
                                    searchViewModel.searchQuery = ""
                                }
                            }
                        }
                    },
                    onReset: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            tabManager.createNewTab()
                            searchViewModel.resetToHomeState()
                        }
                    },
                    hasResults: tabManager.activeTabIsSearchTab,
                    onShowTabs: {
                        showTabGrid = true
                    }
                )
                .zIndex(1)
                
                contentView
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            }
        }
        .onAppear {
            searchViewModel.modelContext = modelContext
            tabManager.setModelContext(modelContext)
        }
        .onExitCommand {
            if tabManager.activeTabIsSearchTab {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    tabManager.createNewTab()
                    searchViewModel.resetToHomeState()
                }
            }
        }
        .fullScreenCover(isPresented: $showTabGrid) {
            SimpleBrowserTabView(
                tabManager: tabManager,
                onTabSelect: { tab in
                    tabManager.activateTab(tab)
                    showTabGrid = false
                },
                onNewTab: {
                    let newTab = tabManager.createNewTab()
                    tabManager.activateTab(newTab)
                    showTabGrid = false
                },
                onCloseTab: { tab in
                    tabManager.closeTab(tab)
                }
            )
        }
        .fullScreenCover(item: $selectedResult) { result in
            if result.contentType == .video, let videoURL = extractVideoURL(from: result) {
                NativeVideoPlayerView(
                    url: videoURL,
                    title: result.title,
                    isPresented: .init(
                        get: { selectedResult != nil },
                        set: { if !$0 { selectedResult = nil } }
                    )
                )
            } else {
                FullscreenWebViewWithSession(
                    url: result.url,
                    sessionManager: sessionManager,
                    isPresented: .init(
                        get: { selectedResult != nil },
                        set: { if !$0 { selectedResult = nil } }
                    )
                )
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            BrowserSettingsView(sessionManager: sessionManager)
        }
    }
    
    // MARK: - Video URL Extraction
    
    private func extractVideoURL(from result: SearchResult) -> URL? {
        let urlString = result.url
        
        if urlString.contains("youtube.com/watch") || urlString.contains("youtu.be") {
            if let videoId = extractYouTubeVideoID(from: urlString) {
                let embedURL = "https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1"
                return URL(string: embedURL)
            }
        }
        
        let videoExtensions = [".mp4", ".m3u8", ".mov", ".webm", ".mkv"]
        for ext in videoExtensions {
            if urlString.lowercased().contains(ext) {
                return URL(string: urlString)
            }
        }
        
        if urlString.contains("vimeo.com") {
            return URL(string: urlString)
        }
        
        return nil
    }
    
    private func extractYouTubeVideoID(from urlString: String) -> String? {
        if let url = URL(string: urlString),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        
        if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                var videoId = parts[1]
                if let queryIndex = videoId.firstIndex(of: "?") {
                    videoId = String(videoId[..<queryIndex])
                }
                return videoId
            }
        }
        
        if urlString.contains("youtube.com/embed/") {
            let parts = urlString.components(separatedBy: "youtube.com/embed/")
            if parts.count > 1 {
                var videoId = parts[1]
                if let queryIndex = videoId.firstIndex(of: "?") {
                    videoId = String(videoId[..<queryIndex])
                }
                return videoId
            }
        }
        
        return nil
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if tabManager.activeTabIsSearchTab {
            tabBasedResultsView
        } else if searchViewModel.isSearching {
            loadingView
        } else if let error = searchViewModel.errorMessage {
            errorView(error)
        } else {
            emptyStateView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.systemBlue))
                .scaleEffect(2.5)
            
            Text(L10n.Search.searching)
                .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(L10n.Search.searchAccessibility)
    }
    
    // MARK: - Tab-based Results View
    
    private var tabBasedResultsView: some View {
        VStack(spacing: 0) {
            if let activeTab = tabManager.activeTab {
                SearchTabBar(
                    selectedContentType: .constant(activeTab.contentType),
                    onTabSelected: { contentType in
                        tabManager.updateActiveTabContentType(contentType)
                    },
                    hasWikipediaInfo: activeTab.wikipediaInfo != nil
                )
                
                Group {
                    switch activeTab.contentType {
                    case .web:
                        VStack(spacing: 0) {
                            if let wikipediaInfo = activeTab.wikipediaInfo {
                                WikipediaInfoPanel(
                                    wikipediaInfo: wikipediaInfo,
                                    isExpanded: activeTab.isInfoBoxExpanded,
                                    onTap: {
                                        tabManager.updateActiveTabContentType(.info)
                                    },
                                    onExpandToggle: {
                                        tabManager.toggleInfoBoxForActiveTab()
                                    }
                                )
                                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                                .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
                            }
                            
                            SearchResultGridView(
                                results: activeTab.searchResults,
                                onSelect: { result in
                                    selectedResult = result
                                },
                                onScrollStarted: {
                                    tabManager.collapseInfoBoxForActiveTab()
                                }
                            )
                        }
                        
                    case .image:
                        ImageResultGridView(
                            results: activeTab.imageResults,
                            onSelect: { result in
                                selectedResult = result
                            }
                        )
                        
                    case .video:
                        VideoResultGridView(
                            results: activeTab.videoResults,
                            onSelect: { result in
                                selectedResult = result
                            }
                        )
                        
                    case .info:
                        if let wikipediaInfo = activeTab.wikipediaInfo {
                            ScrollView(.vertical, showsIndicators: false) {
                                WikipediaDetailView(
                                    wikipediaInfo: wikipediaInfo,
                                    onTap: {
                                        let wikipediaResult = SearchResult(
                                            title: wikipediaInfo.title,
                                            url: wikipediaInfo.articleURL,
                                            description: wikipediaInfo.displaySummary,
                                            contentType: .web
                                        )
                                        selectedResult = wikipediaResult
                                    }
                                )
                            }
                            .padding(.horizontal, -TVOSDesign.Spacing.safeAreaHorizontal)
                        }
                    }
                }
                .padding(.horizontal, -TVOSDesign.Spacing.safeAreaHorizontal)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 100))
                .foregroundColor(TVOSDesign.Colors.accentOrange)
                .shadow(color: TVOSDesign.Colors.accentOrange.opacity(0.5), radius: 20)
            
            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Text(L10n.Search.searchError)
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(error)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            }
            
            TVOSButton(
                title: L10n.General.retry,
                icon: "arrow.clockwise",
                style: .primary
            ) {
                Task {
                    await searchViewModel.performSearch()
                }
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("\(L10n.General.error): \(error)")
    }
    
    // MARK: - URL Input State
    @State private var showURLInput: Bool = false
    @State private var urlInputText: String = ""
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                Spacer()
                    .frame(height: 40)
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 140, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                    Text(L10n.Home.welcome)
                        .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    Text(L10n.Home.enterSearchOrURL)
                        .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 800)
                }
                
                // URL-Eingabe Button
                HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                    TVOSButton(
                        title: L10n.Home.enterURL,
                        icon: "link",
                        style: .primary
                    ) {
                        showURLInput = true
                    }
                    
                    TVOSButton(
                        title: L10n.Home.openGoogle,
                        icon: "globe",
                        style: .secondary
                    ) {
                        openDirectURL("https://www.google.com")
                    }
                }
                .padding(.top, TVOSDesign.Spacing.elementSpacing)
                
                if !searchViewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                        Text(L10n.Home.recentSearches)
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                                ForEach(searchViewModel.searchHistory.prefix(5), id: \.self) { query in
                                    TVOSChipButton(
                                        title: query,
                                        icon: "clock.arrow.circlepath"
                                    ) {
                                        searchViewModel.searchQuery = query
                                        Task {
                                            await searchViewModel.performSearch()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, TVOSDesign.Spacing.cardSpacing)
                }
                
                TVOSSettingsButton(
                    title: L10n.Home.settings,
                    subtitle: L10n.Home.configureBrowser,
                    icon: "gearshape.fill"
                ) {
                    showSettings = true
                }
                .padding(.top, TVOSDesign.Spacing.cardSpacing)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
        .accessibilityLabel(L10n.Home.startPageAccessibility)
        .alert(L10n.Home.urlOrSearchPromptTitle, isPresented: $showURLInput) {
            TextField("URL", text: $urlInputText)
            
            Button(L10n.Home.openWebsite) {
                openDirectURL(urlInputText)
                urlInputText = ""
            }
            
            Button(L10n.Home.googleSearch) {
                performGoogleSearch(urlInputText)
                urlInputText = ""
            }
            
            Button(L10n.General.cancel, role: .cancel) {
                urlInputText = ""
            }
        } message: {
            Text(L10n.Home.urlOrSearchPromptMessage)
        }
    }
    
    // MARK: - Direct URL Navigation
    
    private func openDirectURL(_ input: String) {
        var urlString = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !urlString.isEmpty else { return }
        
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "http://\(urlString)"
        }
        
        let directResult = SearchResult(
            title: urlString,
            url: urlString,
            description: L10n.Home.directURL,
            contentType: .web
        )
        selectedResult = directResult
    }
    
    private func performGoogleSearch(_ query: String) {
        var searchQuery = query
        searchQuery = searchQuery.replacingOccurrences(of: " ", with: "+")
        searchQuery = searchQuery.replacingOccurrences(of: ".", with: "+")
        searchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        
        let googleURL = "https://www.google.com/search?q=\(searchQuery)"
        openDirectURL(googleURL)
    }
}

// MARK: - Preview

#Preview {
    MainBrowserView()
        .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}
