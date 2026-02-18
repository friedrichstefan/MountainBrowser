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
        static let safeAreaHorizontal: CGFloat = 80  // tvOS HIG: 80pt horizontal safe area
        static let gridHorizontalSpacing: CGFloat = 40  // tvOS HIG: 40pt horizontal grid spacing
        static let gridVerticalSpacing: CGFloat = 100  // tvOS HIG: 100pt minimum vertical spacing
        static let cardSpacing: CGFloat = 48
        static let elementSpacing: CGFloat = 24
        static let minTouchTarget: CGFloat = 56  // tvOS HIG: Minimum 56x56pt
        static let standardTouchTarget: CGFloat = 66  // tvOS HIG: Standard 66x66pt
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
        
        // System Farben nach Apple Design (tvOS)
        static let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)      // #007AFF
        static let systemGreen = Color(red: 0.205, green: 0.784, blue: 0.349) // #34C759
        static let systemOrange = Color(red: 1.0, green: 0.584, blue: 0.0)    // #FF9500
        static let systemRed = Color(red: 1.0, green: 0.231, blue: 0.188)     // #FF3B30
        static let systemIndigo = Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6
        static let systemTeal = Color(red: 0.357, green: 0.784, blue: 0.98)   // #5AC8FA
        
        // Akzentfarben - System Blue als Primary
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
    
    // Focus-Effekte - optimiert um Überlappen zu vermeiden
    enum Focus {
        static let scale: CGFloat = 1.03  // Reduziert von 1.05 um Überlappen zu vermeiden
        static let pressScale: CGFloat = 0.97
        static let shadowRadius: CGFloat = 20  // Reduziert für bessere Trennung
        static let cornerRadius: CGFloat = 20
        static let cardLiftOffset: CGFloat = 10  // Vertikaler Offset bei Fokus
    }
    
    // Grid-Layout gemäß tvOS HIG
    enum Grid {
        static let columnCount: Int = 3
        static let unfocusedCardWidth: CGFloat = 160  // tvOS HIG: 160pt unfokussierte Breite
        static let cardAspectRatio: CGFloat = 1.2  // Höhe = Breite * 1.2
    }
}

struct MainBrowserView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedResult: SearchResult?
    @State private var selectedContentType: SearchContentType = .web
    @State private var showVideoPlayer: Bool = false
    @State private var videoPlayerURL: URL?
    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedSection: FocusSection?
    
    enum FocusSection: Hashable {
        case searchBar
        case wikipediaPanel
        case searchResults
        case tabBar
    }
    
    var body: some View {
        ZStack {
            // Hintergrund - tvOS Dark Appearance
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Prominente Suchleiste
                EnhancedSearchBar(
                    searchQuery: $searchViewModel.searchQuery,
                    isSearching: $searchViewModel.isSearching,
                    searchHistory: searchViewModel.searchHistory,
                    onSearch: {
                        Task {
                            await searchViewModel.performSearch()
                        }
                    }
                )
                .zIndex(1)
                
                // Hauptinhaltsbereich mit Safe Area
                contentView
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            }
        }
        .onAppear {
            searchViewModel.modelContext = modelContext
        }
        .fullScreenCover(item: $selectedResult) { result in
            // Unterscheide zwischen Video und anderen Inhalten
            if result.contentType == .video, let videoURL = extractVideoURL(from: result) {
                // Native Video Player für Videos
                NativeVideoPlayerView(
                    url: videoURL,
                    title: result.title,
                    isPresented: .init(
                        get: { selectedResult != nil },
                        set: { if !$0 { selectedResult = nil } }
                    )
                )
            } else {
                // WebView für andere Inhalte
                FullscreenWebView(
                    url: result.url,
                    title: result.title,
                    isPresented: .init(
                        get: { selectedResult != nil },
                        set: { if !$0 { selectedResult = nil } }
                    )
                )
            }
        }
    }
    
    // MARK: - Video URL Extraction
    
    /// Extrahiert die Video-URL für den nativen Player
    private func extractVideoURL(from result: SearchResult) -> URL? {
        let urlString = result.url
        
        // YouTube Video ID extrahieren
        if urlString.contains("youtube.com/watch") || urlString.contains("youtu.be") {
            if let videoId = extractYouTubeVideoID(from: urlString) {
                // Verwende YouTube Embed URL für bessere Kompatibilität
                // Hinweis: Direkte YouTube-Streams erfordern youtube-dl oder ähnliches
                // Für tvOS verwenden wir die Embed-URL
                let embedURL = "https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1"
                return URL(string: embedURL)
            }
        }
        
        // Direkte Video-URLs (.mp4, .m3u8, etc.)
        let videoExtensions = [".mp4", ".m3u8", ".mov", ".webm", ".mkv"]
        for ext in videoExtensions {
            if urlString.lowercased().contains(ext) {
                return URL(string: urlString)
            }
        }
        
        // Vimeo
        if urlString.contains("vimeo.com") {
            // Vimeo benötigt API-Zugriff für direkte Video-URL
            return URL(string: urlString)
        }
        
        return nil
    }
    
    /// Extrahiert die YouTube Video ID aus verschiedenen URL-Formaten
    private func extractYouTubeVideoID(from urlString: String) -> String? {
        // Format: youtube.com/watch?v=VIDEO_ID
        if let url = URL(string: urlString),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        
        // Format: youtu.be/VIDEO_ID
        if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                var videoId = parts[1]
                // Entferne Query-Parameter
                if let queryIndex = videoId.firstIndex(of: "?") {
                    videoId = String(videoId[..<queryIndex])
                }
                return videoId
            }
        }
        
        // Format: youtube.com/embed/VIDEO_ID
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
        if searchViewModel.isSearching {
            loadingView
        } else if let error = searchViewModel.errorMessage {
            errorView(error)
        } else if searchViewModel.hasResults || searchViewModel.hasImageResults || searchViewModel.hasVideoResults {
            resultsView
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
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Tab-Leiste für Content-Type Auswahl
            SearchTabBar(
                selectedContentType: $selectedContentType,
                onTabSelected: { contentType in
                    print("📑 Tab ausgewählt: \(contentType.displayName)")
                },
                hasWikipediaInfo: searchViewModel.wikipediaInfo != nil
            )
            
            // Content basierend auf ausgewähltem Tab
            Group {
                switch selectedContentType {
                case .web:
                    // Wikipedia Panel nur im "Alle" Tab inline anzeigen
                    VStack(spacing: 0) {
                        if let wikipediaInfo = searchViewModel.wikipediaInfo {
                            WikipediaInfoPanel(
                                wikipediaInfo: wikipediaInfo,
                                onTap: {
                                    print("📖 Wikipedia-Artikel öffnen: \(wikipediaInfo.articleURL)")
                                    let wikipediaResult = SearchResult(
                                        title: wikipediaInfo.title,
                                        url: wikipediaInfo.articleURL,
                                        description: wikipediaInfo.displaySummary,
                                        contentType: .web
                                    )
                                    selectedResult = wikipediaResult
                                }
                            )
                            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                            .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
                        }
                        
                        SearchResultGridView(
                            results: searchViewModel.searchResults,
                            onSelect: { result in
                                print("🌐 Web-Ergebnis ausgewählt: \(result.title)")
                                selectedResult = result
                            }
                        )
                    }
                    
                case .image:
                    ImageResultGridView(
                        results: searchViewModel.imageResults,
                        onSelect: { result in
                            print("🖼️ Bild-Ergebnis ausgewählt: \(result.title)")
                            selectedResult = result
                        }
                    )
                    
                case .video:
                    VideoResultGridView(
                        results: searchViewModel.videoResults,
                        onSelect: { result in
                            print("🎥 Video-Ergebnis ausgewählt: \(result.title)")
                            selectedResult = result
                        }
                    )
                    
                case .info:
                    // Dedizierter Info-Tab mit WikipediaDetailView in ScrollView
                    if let wikipediaInfo = searchViewModel.wikipediaInfo {
                        ScrollView(.vertical, showsIndicators: false) {
                            WikipediaDetailView(
                                wikipediaInfo: wikipediaInfo,
                                onTap: {
                                    print("📖 Wikipedia-Artikel öffnen: \(wikipediaInfo.articleURL)")
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
                        .padding(.horizontal, -TVOSDesign.Spacing.safeAreaHorizontal) // WikipediaDetailView hat eigenes Padding
                    }
                }
            }
            .padding(.horizontal, -TVOSDesign.Spacing.safeAreaHorizontal) // Entferne doppelte Padding
        }
    }
    
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            // Error Icon mit subtiler Animation
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
            
            // Retry Button mit tvOS Card Style
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
            
            // App-Logo mit Glow-Effekt
            ZStack {
                // Glow Background
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
            
            // Quick-Suggestions mit tvOS Card Style
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
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
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
                // Loading State
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
                // Error State
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
                    
                    Text("YouTube-Videos können auf tvOS nicht direkt abgespielt werden.\nDas Video wird im Browser geöffnet.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    
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
        // Menü-Taste zum Schließen
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            player?.pause()
        }
    }
    
    private func loadVideo() {
        isLoading = true
        errorMessage = nil
        
        // Prüfe ob es eine direkte Video-URL ist
        let urlString = url.absoluteString
        
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            // YouTube-Videos können nicht direkt in AVPlayer abgespielt werden
            // Zeige Fehlermeldung und biete WebView als Alternative
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
                errorMessage = "YouTube-Videos erfordern die YouTube-App oder einen Browser."
            }
            return
        }
        
        // Für direkte Video-URLs (MP4, M3U8, etc.)
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Beobachte den Player-Status
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
                   minHeight: TVOSDesign.Spacing.standardTouchTarget)  // tvOS HIG: Standard 66x66pt
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)  // Lift-Effekt
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0),  // Neutraler Schatten ohne Orange
                radius: TVOSDesign.Focus.shadowRadius,
                y: 8
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)  // Fokussiertes Element weit oben
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
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)  // tvOS HIG: Minimum 56pt Touch Target
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -6 : 0)  // Subtiler Lift-Effekt für Chips
            .shadow(
                color: Color.black.opacity(isFocused ? 0.3 : 0),  // Neutraler Schatten ohne Orange
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)  // Fokussiertes Element weit oben
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    MainBrowserView()
        .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}
