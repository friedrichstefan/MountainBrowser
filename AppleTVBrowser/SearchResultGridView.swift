//
//  SearchResultGridView.swift
//  AppleTVBrowser
//
//  Suchergebnis-Grid mit Apple tvOS Human Interface Guidelines
//

import SwiftUI

struct SearchResultGridView: View {
    let results: [SearchResult]
    let onSelect: (SearchResult) -> Void
    
    @State private var focusedIndex: Int? = nil
    
    // 3-Spalten Grid-Layout gemäß tvOS HIG
    // Horizontal: 40pt Spacing, Vertikal: 100pt Spacing
    private let columns = [
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing),
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing),
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Ergebnis-Header - immer über fokussierten Karten
                resultsHeader
                    .zIndex(2000)  // Header immer über fokussierten Karten (die haben zIndex 1000)
                    .padding(.bottom, 60)  // Mehr Abstand zum Grid (60pt)
                
                // Grid mit Karten - vertikales Spacing 100pt gemäß tvOS HIG
                LazyVGrid(columns: columns, spacing: TVOSDesign.Spacing.gridVerticalSpacing) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        TVOSSearchCard(
                            result: result,
                            isFocusedBinding: Binding(
                                get: { focusedIndex == index },
                                set: { newValue in
                                    if newValue {
                                        focusedIndex = index
                                    } else if focusedIndex == index {
                                        focusedIndex = nil
                                    }
                                }
                            )
                        ) {
                            onSelect(result)
                        }
                        .zIndex(focusedIndex == index ? 1000 : 0)  // Fokussierte Karte ganz oben
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)  // Safe Area für Grid
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom)
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
    }
    
    // MARK: - Results Header
    
    private var resultsHeader: some View {
        HStack(alignment: .center, spacing: TVOSDesign.Spacing.elementSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Suchergebnisse")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text("\(results.count) Ergebnisse gefunden")
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            
            Spacer()
            
            // Sortier-Optionen könnten hier hinzugefügt werden
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)  // Safe Area Padding
    }
}

// MARK: - tvOS Search Card Component

struct TVOSSearchCard: View {
    let result: SearchResult
    @Binding var isFocusedBinding: Bool
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                onSelect()
            }
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            isFocusedBinding = newValue
        }
        // Focus-Effekt: Scale + Lift um Überlappen zu vermeiden
        .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
        .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail/Preview Bereich
            thumbnailSection
            
            // Content Bereich
            contentSection
        }
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)  // tvOS HIG: Standard 66pt Touch Target
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
        )
        .shadow(
            color: Color.black.opacity(isFocused ? 0.5 : 0.2),  // Neutraler Schatten ohne Orange
            radius: isFocused ? TVOSDesign.Focus.shadowRadius : 8,
            y: isFocused ? 12 : 4
        )
    }
    
    // MARK: - Thumbnail Section
    
    private var thumbnailSection: some View {
        ZStack {
            // Hintergrund-Gradient basierend auf URL
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Website-Icon oder Favicon
            VStack(spacing: 12) {
                Image(systemName: iconForResult)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                
                // Domain Badge
                Text(domainFromURL)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
        }
        .frame(height: 160)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: TVOSDesign.Focus.cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: TVOSDesign.Focus.cornerRadius
            )
        )
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Titel
            Text(result.title)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.primaryLabel.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Beschreibung
            if !result.description.isEmpty {
                Text(result.description)
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 8)
            
            // URL und Action Hint
            HStack {
                Text(truncatedURL)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineLimit(1)
                
                Spacer()
                
                if isFocused {
                    HStack(spacing: 6) {
                        Text("Öffnen")
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(TVOSDesign.Colors.accentBlue)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .padding(20)
        .frame(height: 140)
    }
    
    // MARK: - Computed Properties
    
    private var gradientColors: [Color] {
        // Generiere lebendige Farben basierend auf der Domain (Apple System Farben)
        let domain = domainFromURL.lowercased()
        
        if domain.contains("google") {
            return [TVOSDesign.Colors.systemBlue, TVOSDesign.Colors.systemBlue.opacity(0.7)]
        } else if domain.contains("wikipedia") {
            return [TVOSDesign.Colors.systemIndigo, TVOSDesign.Colors.systemIndigo.opacity(0.7)]
        } else if domain.contains("youtube") {
            return [TVOSDesign.Colors.systemRed, TVOSDesign.Colors.systemRed.opacity(0.7)]
        } else if domain.contains("github") {
            return [Color(white: 0.25), Color(white: 0.15)]
        } else if domain.contains("apple") {
            return [Color(white: 0.3), Color(white: 0.18)]
        } else if domain.contains("twitter") || domain.contains("x.com") {
            return [TVOSDesign.Colors.systemTeal, TVOSDesign.Colors.systemTeal.opacity(0.7)]
        } else if domain.contains("netflix") {
            return [TVOSDesign.Colors.systemRed, Color(white: 0.1)]
        } else if domain.contains("amazon") {
            return [TVOSDesign.Colors.systemOrange, TVOSDesign.Colors.systemOrange.opacity(0.7)]
        } else {
            // Default: System Teal für unbekannte Domains (statt langweiliges Weiß)
            return [TVOSDesign.Colors.systemTeal, TVOSDesign.Colors.systemTeal.opacity(0.6)]
        }
    }
    
    private var iconForResult: String {
        let domain = domainFromURL.lowercased()
        
        if domain.contains("google") {
            return "magnifyingglass"
        } else if domain.contains("wikipedia") {
            return "book.closed.fill"
        } else if domain.contains("youtube") {
            return "play.rectangle.fill"
        } else if domain.contains("github") {
            return "chevron.left.forwardslash.chevron.right"
        } else if domain.contains("apple") {
            return "apple.logo"
        } else {
            return "globe"
        }
    }
    
    private var domainFromURL: String {
        guard let url = URL(string: result.url),
              let host = url.host else {
            return result.url
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    private var truncatedURL: String {
        let maxLength = 40
        if result.url.count <= maxLength {
            return result.url
        }
        return String(result.url.prefix(maxLength)) + "..."
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TVOSDesign.Colors.background.ignoresSafeArea()
        
        SearchResultGridView(
            results: SearchResult.examples,
            onSelect: { result in
                print("Selected: \(result.title)")
            }
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
}