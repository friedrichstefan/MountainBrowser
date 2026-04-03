//
//  TabPreviewCard.swift
//  MountainBrowser
//
//  UI-Komponente für individuelle Tab-Vorschauen im Safari-Stil
//

import SwiftUI

struct TabPreviewCard: View {
    let tab: BrowserTab
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var faviconImage: UIImage? = nil
    
    // MARK: - Constants
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 180
    private let cornerRadius: CGFloat = 16
    private let closeButtonSize: CGFloat = 28
    
    var body: some View {
        ZStack {
            // Hauptkarte
            mainCardContent
                .frame(width: cardWidth, height: cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            
            // Close Button (nur sichtbar wenn fokussiert)
            if isFocused {
                closeButton
            }
        }
        .focusable(true)
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            withAnimation(TVOSDesign.Animation.focusSpring) {
                // Focus state is already tracked by @FocusState
            }
        }
        // Tap auf Select-Taste der Siri Remote
        .onTapGesture {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                onSelect()
            }
        }
        // Play/Pause zum Schließen des Tabs
        .onPlayPauseCommand {
            onClose()
        }
        // Glow-Effekt für große Kacheln — kein Ring
        .tvOSCardGlow(isFocused: isFocused, isPressed: isPressed)
        .zIndex(isFocused ? 100 : 0)
        .onAppear {
            loadFavicon()
        }
    }
    
    // MARK: - Main Card Content
    
    private var mainCardContent: some View {
        VStack(spacing: 0) {
            previewImageSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            tabInfoFooter
                .frame(height: 60)
        }
        .clipped()
    }
    
    // MARK: - Preview Image Section
    
    private var previewImageSection: some View {
        Group {
            if let previewImage = tab.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if !tab.isBlank {
                webPagePlaceholder
            } else {
                blankTabPlaceholder
            }
        }
        .overlay(
            activeTabOverlay,
            alignment: .topLeading
        )
    }
    
    /// Fast gradient + favicon placeholder instead of slow thum.io screenshot
    private var webPagePlaceholder: some View {
        ZStack {
            // Domain-based gradient — instant rendering, no network
            LinearGradient(
                colors: gradientColorsForTab,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                // Favicon or fallback icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    if let favicon = faviconImage {
                        Image(uiImage: favicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                if !tab.urlString.isEmpty {
                    Text(shortURL)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var blankTabPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [TVOSDesign.Colors.tertiaryBackground, TVOSDesign.Colors.secondaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                
                Text(L10n.General.newTab)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
        }
    }
    
    private var activeTabOverlay: some View {
        Group {
            if tab.isActive {
                RoundedRectangle(cornerRadius: 6)
                    .fill(TVOSDesign.Colors.accentBlue)
                    .frame(width: 4, height: 30)
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
        }
    }
    
    // MARK: - Tab Info Footer
    
    private var tabInfoFooter: some View {
        HStack(spacing: 12) {
            faviconView
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.displayTitle)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !tab.isBlank {
                    Text(shortURL)
                        .font(.system(size: TVOSDesign.Typography.caption))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            tabStatusIcons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TVOSDesign.Colors.secondaryBackground)
    }
    
    private var faviconView: some View {
        Group {
            if let favicon = faviconImage {
                Image(uiImage: favicon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if let faviconURL = tab.faviconURL, !faviconURL.isEmpty {
                AsyncImage(url: URL(string: faviconURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    defaultFaviconIcon
                }
            } else {
                defaultFaviconIcon
            }
        }
    }
    
    private var defaultFaviconIcon: some View {
        Image(systemName: tab.isBlank ? "plus" : "globe")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            .frame(width: 24, height: 24)
            .background(TVOSDesign.Colors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 4))
    }
    
    private var tabStatusIcons: some View {
        HStack(spacing: 8) {
            if tab.isActive {
                Circle()
                    .fill(TVOSDesign.Colors.accentBlue)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        ZStack {
            Circle()
                .fill(TVOSDesign.Colors.secondaryBackground)
                .frame(width: closeButtonSize, height: closeButtonSize)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
        }
        .position(x: cardWidth - closeButtonSize / 2 - 8, y: closeButtonSize / 2 + 8)
        .allowsHitTesting(false)
    }
    
    // MARK: - Favicon Loading
    
    private func loadFavicon() {
        guard !tab.isBlank,
              let url = URL(string: tab.urlString),
              let host = url.host else { return }
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        
        Task {
            if let image = await FaviconCache.shared.favicon(for: cleanHost) {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.faviconImage = image
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var shortURL: String {
        guard let url = URL(string: tab.urlString) else { return tab.urlString }
        return url.host ?? tab.urlString
    }
    
    /// Generates stable gradient colors from the domain — no network needed
    private var gradientColorsForTab: [Color] {
        guard let url = URL(string: tab.urlString),
              let host = url.host else {
            return [Color(hex: "667EEA"), Color(hex: "764BA2")]
        }
        let domain = host.replacingOccurrences(of: "www.", with: "").lowercased()
        
        // Known brands
        if domain.contains("google") { return [Color(hex: "4285F4"), Color(hex: "34A853")] }
        else if domain.contains("youtube") { return [Color(hex: "FF0000"), Color(hex: "282828")] }
        else if domain.contains("wikipedia") { return [Color(hex: "636466"), Color(hex: "1A1A1A")] }
        else if domain.contains("github") { return [Color(hex: "24292E"), Color(hex: "0D1117")] }
        else if domain.contains("apple") { return [Color(hex: "555555"), Color(hex: "1D1D1F")] }
        else {
            // Stable hash-based color
            let hash = abs(domain.hashValue)
            let hue1 = Double(hash % 360) / 360.0
            let hue2 = Double((hash / 360) % 360) / 360.0
            return [
                Color(hue: hue1, saturation: 0.5, brightness: 0.6),
                Color(hue: hue2, saturation: 0.4, brightness: 0.3)
            ]
        }
    }
}

// MARK: - Preview Provider

#Preview("Single Tab") {
    TabPreviewCard(
        tab: BrowserTab(
            title: "Apple",
            urlString: "https://www.apple.com",
            faviconURL: "https://www.apple.com/favicon.ico",
            isActive: true
        ),
        onSelect: { print("Tab selected") },
        onClose: { print("Tab closed") }
    )
    .padding(50)
    .background(TVOSDesign.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Blank Tab") {
    TabPreviewCard(
        tab: BrowserTab(),
        onSelect: { print("Tab selected") },
        onClose: { print("Tab closed") }
    )
    .padding(50)
    .background(TVOSDesign.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Multiple Tabs") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
        ForEach([
            BrowserTab(title: "Apple", urlString: "https://www.apple.com", isActive: true),
            BrowserTab(title: "Wikipedia", urlString: "https://de.wikipedia.org"),
            BrowserTab(title: "GitHub", urlString: "https://github.com"),
            BrowserTab()
        ], id: \.id) { tab in
            TabPreviewCard(
                tab: tab,
                onSelect: { print("Tab \(tab.displayTitle) selected") },
                onClose: { print("Tab \(tab.displayTitle) closed") }
            )
        }
    }
    .padding(50)
    .background(TVOSDesign.Colors.background)
    .preferredColorScheme(.dark)
}
