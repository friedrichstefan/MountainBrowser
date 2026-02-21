//
//  MainBrowserView.swift
//  AppleTVBrowser
//
//  Hauptansicht der tvOS Browser-App mit Apple tvOS Human Interface Guidelines
//

import SwiftUI
import SwiftData
import AVKit

// MARK: - tvOS Design Constants (Apple HIG)

enum TVOSDesign {
    // Typographie gemäß Apple tvOS HIG
    enum Typography {
        static let largeTitle: CGFloat = 76
        static let title1: CGFloat = 48
        static let title2: CGFloat = 38
        static let title3: CGFloat = 31
        static let body: CGFloat = 29
        static let callout: CGFloat = 26
        static let subheadline: CGFloat = 24
        static let footnote: CGFloat = 21
        static let caption: CGFloat = 19
    }
    
    // Spacing gemäß Apple tvOS HIG
    enum Spacing {
        static let safeAreaTop: CGFloat = 60
        static let safeAreaBottom: CGFloat = 60
        static let safeAreaHorizontal: CGFloat = 80
        static let gridHorizontalSpacing: CGFloat = 40
        static let gridVerticalSpacing: CGFloat = 100
        static let cardSpacing: CGFloat = 48
        static let elementSpacing: CGFloat = 24
        static let minTouchTarget: CGFloat = 56
        static let standardTouchTarget: CGFloat = 66
    }
    
    // Farben - tvOS System Farben nach Apple HIG
    enum Colors {
        static let background = Color(white: 0.05)
        static let secondaryBackground = Color(white: 0.1)
        static let tertiaryBackground = Color(white: 0.15)
        static let cardBackground = Color(white: 0.12)
        static let focusedCardBackground = Color(white: 0.18)
        static let pressedCardBackground = Color(white: 0.22)
        
        static let primaryLabel = Color.white
        static let secondaryLabel = Color(white: 0.7)
        static let tertiaryLabel = Color(white: 0.5)
        
        static let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
        static let systemGreen = Color(red: 0.205, green: 0.784, blue: 0.349)
        static let systemOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
        static let systemRed = Color(red: 1.0, green: 0.231, blue: 0.188)
        static let systemIndigo = Color(red: 0.345, green: 0.337, blue: 0.839)
        static let systemTeal = Color(red: 0.357, green: 0.784, blue: 0.98)
        
        static let accentBlue = systemBlue
        static let accentOrange = systemOrange
        static let focusGlow = systemBlue.opacity(0.6)
    }
    
    // Animation gemäß Apple tvOS HIG
    enum Animation {
        static let focusSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let pressSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)
        static let transitionDuration: Double = 0.3
    }
    
    // Focus-Effekte
    enum Focus {
        static let scale: CGFloat = 1.03
        static let pressScale: CGFloat = 0.97
        static let shadowRadius: CGFloat = 20
        static let cornerRadius: CGFloat = 20
        static let cardLiftOffset: CGFloat = 10
    }
    
    // Grid-Layout gemäß tvOS HIG
    enum Grid {
        static let columnCount: Int = 3
        static let unfocusedCardWidth: CGFloat = 160
        static let cardAspectRatio: CGFloat = 1.2
    }
}

struct MainBrowserView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var tabManager = TabManager()
    @StateObject private var sessionManager = SessionManager()
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
        searchViewModel.hasResults || searchViewModel.hasImageResults || searchViewModel.hasVideoResults || searchViewModel.wikipediaInfo != nil
    }
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
            EnhancedSearchBar(
                searchQuery: $searchViewModel.searchQuery,
                isSearching: $searchViewModel.isSearching,
                searchHistory: searchViewModel.searchHistory,
                onSearch: {
                    Task {
                        if !searchViewModel.searchQuery.isEmpty {
                            await tabManager.createSearchTab(query: searchViewModel.searchQuery)
                            // Sofort nach Tab-Erstellung: Query leeren für nächste Suche
                            await MainActor.run {
                                searchViewModel.searchQuery = ""
                            }
                        }
                    }
                },
                onReset: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        // Erstelle neuen Standard-Tab und leere SearchQuery
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
            // tvOS Menu-Button Handler
            if hasSearchResults {
                // Wenn Suchergebnisse vorhanden sind, zurück zur Startseite
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    searchViewModel.resetToHomeState()
                    selectedContentType.wrappedValue = .web
                    isInfoBoxExpanded.wrappedValue = true
                }
            }
            // Wenn keine Suchergebnisse vorhanden sind, standardmäßig App verlassen
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
                    title: result.title,
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
            
            Text("Suche läuft...")
                .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                TabBasedWikipediaPanel(
                                    wikipediaInfo: wikipediaInfo,
                                    isExpanded: activeTab.isInfoBoxExpanded,
                                    onTap: {
                                        // Wechsel zum Info-Tab
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
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            SearchTabBar(
                selectedContentType: selectedContentType,
                onTabSelected: { contentType in
                    selectedContentType.wrappedValue = contentType
                },
                hasWikipediaInfo: searchViewModel.wikipediaInfo != nil
            )
            
            Group {
                switch selectedContentType.wrappedValue {
                case .web:
                    VStack(spacing: 0) {
                        if let wikipediaInfo = searchViewModel.wikipediaInfo {
                            CollapsibleWikipediaPanel(
                                wikipediaInfo: wikipediaInfo,
                                isExpanded: isInfoBoxExpanded,
                                onTap: {
                                    // Wechsel zum Info-Tab
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedContentType.wrappedValue = .info
                                    }
                                }
                            )
                            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                            .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
                        }
                        
                        SearchResultGridView(
                            results: searchViewModel.searchResults,
                            onSelect: { result in
                                selectedResult = result
                            },
                            onScrollStarted: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isInfoBoxExpanded.wrappedValue = false
                                }
                            }
                        )
                    }
                    
                case .image:
                    ImageResultGridView(
                        results: searchViewModel.imageResults,
                        onSelect: { result in
                            selectedResult = result
                        }
                    )
                    
                case .video:
                    VideoResultGridView(
                        results: searchViewModel.videoResults,
                        onSelect: { result in
                            selectedResult = result
                        }
                    )
                    
                case .info:
                    if let wikipediaInfo = searchViewModel.wikipediaInfo {
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
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 100))
                .foregroundColor(TVOSDesign.Colors.accentOrange)
                .shadow(color: TVOSDesign.Colors.accentOrange.opacity(0.5), radius: 20)
            
            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Text("Fehler bei der Suche")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(error)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            }
            
            TVOSButton(
                title: "Erneut versuchen",
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
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Spacer()
            
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
                Text("Willkommen")
                    .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text("Gib einen Suchbegriff ein, um loszulegen")
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 800)
            }
            
            if !searchViewModel.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                    Text("Zuletzt gesucht")
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
            
            // Einstellungsbutton
            TVOSSettingsButton(
                title: "Einstellungen",
                subtitle: "Browser konfigurieren",
                icon: "gearshape.fill"
            ) {
                showSettings = true
            }
            .padding(.top, TVOSDesign.Spacing.cardSpacing)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
    }
}

// MARK: - Collapsible Wikipedia Panel

struct CollapsibleWikipediaPanel: View {
    let wikipediaInfo: WikipediaInfo
    @Binding var isExpanded: Bool
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(alignment: .top, spacing: TVOSDesign.Spacing.elementSpacing) {
                // Wikipedia Bild (kleiner wenn minimiert)
                wikipediaImageView
                    .frame(width: isExpanded ? 120 : 60, height: isExpanded ? 120 : 60)
                    .fixedSize()
                
                // Wikipedia Info - mit flexibler Breite
                VStack(alignment: .leading, spacing: isExpanded ? 12 : 6) {
                    // Titel + Attribution + Expand Button
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wikipediaInfo.title)
                                .font(.system(size: isExpanded ? TVOSDesign.Typography.title3 : TVOSDesign.Typography.callout, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .lineLimit(isExpanded ? 2 : 1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(wikipediaInfo.attributionText)
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        }
                        .layoutPriority(1)
                        
                        Spacer(minLength: 16)
                        
                        // Expand/Collapse Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .fixedSize()
                    }
                    
                    // Zusammenfassung (nur wenn expanded)
                    if isExpanded {
                        Text(wikipediaInfo.displaySummary)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Info-Felder (nur wenn expanded)
                        if !wikipediaInfo.primaryInfoFields.isEmpty {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(wikipediaInfo.primaryInfoFields.prefix(2)) { field in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.key)
                                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                        Text(field.value)
                                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pfeil-Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
                    .fixedSize()
            }
            .padding(isExpanded ? TVOSDesign.Spacing.elementSpacing : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isExpanded ? 160 : 80)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.01 : 1.0))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowOffset
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                // Wenn Panel fokussiert wird -> expandieren
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = true
                }
                // Reset scroll state für saubere Navigation
                NotificationCenter.default.post(name: Notification.Name("ResetScrollState"), object: nil)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Wikipedia Image View
    
    @ViewBuilder
    private var wikipediaImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isExpanded ? 16 : 10)
                .fill(TVOSDesign.Colors.cardBackground)
                .overlay(
                    Group {
                        if !imageLoaded && !imageError && wikipediaInfo.imageURL != nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                .scaleEffect(isExpanded ? 1.0 : 0.7)
                        } else if imageError || wikipediaInfo.imageURL == nil {
                            VStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: isExpanded ? 28 : 18))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                
                                if isExpanded {
                                    Text("Wiki")
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                }
                            }
                        }
                    }
                )
            
            if let imageURL = wikipediaInfo.imageURL, !imageError {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 16 : 10))
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3)) {
                                imageLoaded = true
                            }
                        }
                } placeholder: {
                    Color.clear
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
    }
    
    private var shadowColor: Color {
        isFocused ? Color.black.opacity(0.5) : Color.black.opacity(0.2)
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 20 : 10
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 10 : 5
    }
}

// MARK: - Native Video Player View

struct NativeVideoPlayerView: View {
    let url: URL
    let title: String
    @Binding var isPresented: Bool
    
    @State private var player: AVPlayer?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if isLoading {
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                    
                    Text("Video wird geladen...")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if let error = errorMessage {
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Video kann nicht abgespielt werden")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Zurück")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func loadVideo() {
        isLoading = true
        errorMessage = nil
        
        let urlString = url.absoluteString
        
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
                errorMessage = "YouTube-Videos erfordern die YouTube-App oder einen Browser."
            }
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            isPresented = false
        }
        
        self.player = newPlayer
        isLoading = false
    }
}

// MARK: - tvOS Button Component

struct TVOSButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 44)
            .padding(.vertical, 20)
            .frame(minWidth: TVOSDesign.Spacing.standardTouchTarget,
                   minHeight: TVOSDesign.Spacing.standardTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0),
                radius: TVOSDesign.Focus.shadowRadius,
                y: 8
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? Color.white.opacity(0.8) : Color.white
        case .secondary:
            return isPressed ? TVOSDesign.Colors.pressedCardBackground : TVOSDesign.Colors.cardBackground
        case .destructive:
            return isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.black
        case .secondary, .destructive:
            return TVOSDesign.Colors.primaryLabel
        }
    }
}

// MARK: - tvOS Chip Button Component

struct TVOSChipButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
            }
            .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -6 : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.3 : 0),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - tvOS Settings Button Component

struct TVOSSettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 20) {
                // Icon - kompakter für flaches Design
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    TVOSDesign.Colors.systemBlue.opacity(0.3),
                                    TVOSDesign.Colors.systemBlue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.systemBlue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Pfeil-Icon für bessere Erkennbarkeit
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(height: 120) 
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? TVOSDesign.Colors.systemBlue : Color.clear,
                        lineWidth: isFocused ? 3 : 0
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0.1),
                radius: isFocused ? TVOSDesign.Focus.shadowRadius : 8,
                y: isFocused ? 8 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
    }
}

// MARK: - Tab-based Wikipedia Panel

struct TabBasedWikipediaPanel: View {
    let wikipediaInfo: WikipediaInfo
    let isExpanded: Bool
    let onTap: () -> Void
    let onExpandToggle: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(alignment: .top, spacing: TVOSDesign.Spacing.elementSpacing) {
                // Wikipedia Bild (kleiner wenn minimiert)
                wikipediaImageView
                    .frame(width: isExpanded ? 120 : 60, height: isExpanded ? 120 : 60)
                    .fixedSize()
                
                // Wikipedia Info - mit flexibler Breite
                VStack(alignment: .leading, spacing: isExpanded ? 12 : 6) {
                    // Titel + Attribution + Expand Button
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wikipediaInfo.title)
                                .font(.system(size: isExpanded ? TVOSDesign.Typography.title3 : TVOSDesign.Typography.callout, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .lineLimit(isExpanded ? 2 : 1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(wikipediaInfo.attributionText)
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        }
                        .layoutPriority(1)
                        
                        Spacer(minLength: 16)
                        
                        // Expand/Collapse Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onExpandToggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .fixedSize()
                    }
                    
                    // Zusammenfassung (nur wenn expanded)
                    if isExpanded {
                        Text(wikipediaInfo.displaySummary)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Info-Felder (nur wenn expanded)
                        if !wikipediaInfo.primaryInfoFields.isEmpty {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(wikipediaInfo.primaryInfoFields.prefix(2)) { field in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.key)
                                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                        Text(field.value)
                                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pfeil-Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
                    .fixedSize()
            }
            .padding(isExpanded ? TVOSDesign.Spacing.elementSpacing : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isExpanded ? 160 : 80)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.01 : 1.0))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowOffset
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                // Wenn Panel fokussiert wird -> expandieren
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onExpandToggle()
                }
                // Reset scroll state für saubere Navigation
                NotificationCenter.default.post(name: Notification.Name("ResetScrollState"), object: nil)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Wikipedia Image View
    
    @ViewBuilder
    private var wikipediaImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isExpanded ? 16 : 10)
                .fill(TVOSDesign.Colors.cardBackground)
                .overlay(
                    Group {
                        if !imageLoaded && !imageError && wikipediaInfo.imageURL != nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                .scaleEffect(isExpanded ? 1.0 : 0.7)
                        } else if imageError || wikipediaInfo.imageURL == nil {
                            VStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: isExpanded ? 28 : 18))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                
                                if isExpanded {
                                    Text("Wiki")
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                }
                            }
                        }
                    }
                )
            
            if let imageURL = wikipediaInfo.imageURL, !imageError {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 16 : 10))
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3)) {
                                imageLoaded = true
                            }
                        }
                } placeholder: {
                    Color.clear
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
    }
    
    private var shadowColor: Color {
        isFocused ? Color.black.opacity(0.5) : Color.black.opacity(0.2)
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 20 : 10
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 10 : 5
    }
}

// MARK: - Preview

#Preview {
    MainBrowserView()
        .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}
