//
//  MainBrowserView.swift
//  AppleTVBrowser
//
//  Hauptansicht der tvOS Browser-App mit Apple tvOS Human Interface Guidelines
//

import SwiftUI
import SwiftData

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
    @FocusState private var isSearchFocused: Bool
    
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
        SearchResultGridView(
            results: searchViewModel.searchResults,
            onSelect: { result in
                print("📱 Suchergebnis ausgewählt: \(result.title)")
                selectedResult = result
            }
        )
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
