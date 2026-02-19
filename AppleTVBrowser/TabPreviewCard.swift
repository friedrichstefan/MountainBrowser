//
//  TabPreviewCard.swift
//  AppleTVBrowser
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
    private let cornerRadius: CGFloat = 12
    private let shadowRadius: CGFloat = 6
    private let closeButtonSize: CGFloat = 28
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Hauptkarte
                mainCardContent
                    .frame(width: cardWidth, height: cardHeight)
                    .background(cardBackground)
                    .cornerRadius(cornerRadius)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
                
                // Close Button (immer sichtbar)
                closeButton
            }
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
    
    // MARK: - Main Card Content
    
    private var mainCardContent: some View {
        VStack(spacing: 0) {
            // Preview Image oder Placeholder
            previewImageSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tab Info Footer
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
                // Fallback für URLs ohne Preview
                webPagePlaceholder
            } else {
                // Placeholder für leere Tabs
                blankTabPlaceholder
            }
        }
        .overlay(
            // Active Tab Indicator
            activeTabOverlay,
            alignment: .topLeading
        )
    }
    
    private var webPagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Webseite")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !tab.urlString.isEmpty {
                    Text(shortURL)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var blankTabPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.gray)
                
                Text("Neuer Tab")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var activeTabOverlay: some View {
        Group {
            if tab.isActive {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.blue)
                    .frame(width: 4, height: 30)
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
        }
    }
    
    // MARK: - Tab Info Footer
    
    private var tabInfoFooter: some View {
        HStack(spacing: 12) {
            // Favicon oder Default Icon
            faviconView
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                // Titel
                Text(tab.displayTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // URL
                if !tab.isBlank {
                    Text(shortURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Tab Status Icons
            tabStatusIcons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
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
            .foregroundColor(.secondary)
            .frame(width: 24, height: 24)
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
    }
    
    private var tabStatusIcons: some View {
        HStack(spacing: 8) {
            if tab.isActive {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                Circle()
                    .fill(.ultraThickMaterial)
                    .frame(width: closeButtonSize, height: closeButtonSize)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: cardWidth - closeButtonSize/2 - 8, y: closeButtonSize/2 + 8)
    }
    
    // MARK: - Computed Properties
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var focusScale: CGFloat {
        if isPressed {
            return 0.95
        } else if isFocused {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    private var shadowColor: Color {
        if isFocused {
            return .black.opacity(0.3)
        } else {
            return .black.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if tab.isActive && isFocused {
            return .blue.opacity(0.8)
        } else if isFocused {
            return .white.opacity(0.3)
        } else if tab.isActive {
            return .blue.opacity(0.5)
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if tab.isActive || isFocused {
            return 2
        } else {
            return 0
        }
    }
    
    private var shortURL: String {
        guard let url = URL(string: tab.urlString) else { return tab.urlString }
        return url.host ?? tab.urlString
    }
}

// MARK: - Preview Provider

#Preview("Single Tab") {
    let tab = BrowserTab(
        title: "Apple",
        urlString: "https://www.apple.com",
        faviconURL: "https://www.apple.com/favicon.ico",
        isActive: true
    )
    
    return TabPreviewCard(
        tab: tab,
        onSelect: { print("Tab selected") },
        onClose: { print("Tab closed") }
    )
    .padding(50)
    .background(.black)
    .preferredColorScheme(.dark)
}

#Preview("Blank Tab") {
    let tab = BrowserTab()
    
    return TabPreviewCard(
        tab: tab,
        onSelect: { print("Tab selected") },
        onClose: { print("Tab closed") }
    )
    .padding(50)
    .background(.black)
    .preferredColorScheme(.dark)
}

#Preview("Multiple Tabs") {
    let tabs = [
        BrowserTab(title: "Apple", urlString: "https://www.apple.com", isActive: true),
        BrowserTab(title: "Wikipedia", urlString: "https://de.wikipedia.org"),
        BrowserTab(title: "GitHub", urlString: "https://github.com"),
        BrowserTab()
    ]
    
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
        ForEach(tabs, id: \.id) { tab in
            TabPreviewCard(
                tab: tab,
                onSelect: { print("Tab \(tab.displayTitle) selected") },
                onClose: { print("Tab \(tab.displayTitle) closed") }
            )
        }
    }
    .padding(50)
    .background(.black)
    .preferredColorScheme(.dark)
}