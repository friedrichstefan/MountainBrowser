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
    var onScrollStarted: (() -> Void)? = nil
    var onResetScroll: (() -> Void)? = nil
    
    @State private var focusedIndex: Int? = nil
    @State private var hasScrolled: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing),
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing),
        GridItem(.flexible(), spacing: TVOSDesign.Spacing.gridHorizontalSpacing)
    ]
    
    var body: some View {
        // Auf tvOS: ScrollView scrollt automatisch wenn der Fokus
        // zu einem Element außerhalb des sichtbaren Bereichs wechselt.
        // KEIN GeometryReader verwenden – das kann Größe=0 verursachen.
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                resultsHeader
                    .padding(.bottom, 60)
                
                LazyVGrid(columns: columns, spacing: TVOSDesign.Spacing.gridVerticalSpacing) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        TVOSSearchCard(
                            result: result,
                            isFocusedBinding: Binding(
                                get: { focusedIndex == index },
                                set: { newValue in
                                    if newValue {
                                        focusedIndex = index
                                        if index > 0 && !hasScrolled {
                                            hasScrolled = true
                                            onScrollStarted?()
                                        }
                                    } else if focusedIndex == index {
                                        focusedIndex = nil
                                    }
                                }
                            )
                        ) {
                            onSelect(result)
                        }
                        .zIndex(focusedIndex == index ? 1000 : 0)
                        .accessibilityLabel("\(result.title). \(result.description)")
                        .accessibilityHint("Doppeltippen zum Öffnen")
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100) // Extra Platz am Ende für letzte Reihe
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
        // WICHTIG für tvOS: Fokus-basiertes Scrolling braucht keine explizite Größe.
        // Die ScrollView muss nur genug Platz von der Parent-View bekommen.
        .accessibilityLabel("Suchergebnisse")
    }
    
    func resetScrollState() {
        hasScrolled = false
        onResetScroll?()
    }
    
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
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .accessibilityLabel("\(results.count) Suchergebnisse gefunden")
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
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                onSelect()
            }
        }) {
            cardContent
        }
        .buttonStyle(.card) // tvOS Card Button Style – gibt automatisch Focus-Lift-Effekt
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            isFocusedBinding = newValue
        }
        .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : 1.0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailSection
            contentSection
        }
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
        )
    }
    
    private var thumbnailSection: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Image(systemName: iconForResult)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                
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
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.title)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.primaryLabel.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if !result.description.isEmpty {
                Text(result.description)
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 8)
            
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
    
    private var gradientColors: [Color] {
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
            onSelect: { result in },
            onScrollStarted: { }
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
}
