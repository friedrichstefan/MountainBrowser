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
        .focusable(true) { isFocused in
            withAnimation(TVOSDesign.Animation.focusSpring) {
                self.isFocused = isFocused
            }
        }
        .focused($isFocused)
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
    
    private var webPagePlaceholder: some View {
        ZStack {
            // Website-Screenshot Thumbnail via API
            if let thumbnailURL = websiteThumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        fallbackPlaceholder
                    case .empty:
                        ZStack {
                            fallbackPlaceholder
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    @unknown default:
                        fallbackPlaceholder
                    }
                }
            } else {
                fallbackPlaceholder
            }
        }
    }
    
    private var fallbackPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [TVOSDesign.Colors.accentBlue.opacity(0.3), TVOSDesign.Colors.systemPurple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Webseite")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(.white)
                
                if !tab.urlString.isEmpty {
                    Text(shortURL)
                        .font(.system(size: TVOSDesign.Typography.caption))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    /// Generiert eine Thumbnail-URL für die Website-Vorschau
    private var websiteThumbnailURL: URL? {
        guard !tab.urlString.isEmpty,
              let encodedURL = tab.urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Verwende microlink.io Screenshot-Service (kostenlos, keine API-Key nötig)
        // Alternative: screenshot.abstractapi.com, urlbox.io
        let thumbnailURLString = "https://api.microlink.io/?url=\(encodedURL)&screenshot=true&meta=false&embed=screenshot.url"
        
        // Einfachere Alternative: Google PageSpeed Insights Thumbnail
        // Oder: thumbsnap.com
        let simpleThumbURL = "https://image.thum.io/get/width/\(Int(cardWidth * 2))/\(tab.urlString)"
        
        return URL(string: simpleThumbURL)
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
                
                Text("Neuer Tab")
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
            if let faviconURL = tab.faviconURL, !faviconURL.isEmpty {
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
    
    // MARK: - Computed Properties
    
    private var shortURL: String {
        guard let url = URL(string: tab.urlString) else { return tab.urlString }
        return url.host ?? tab.urlString
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
