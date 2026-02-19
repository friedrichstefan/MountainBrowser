//
//  ImageResultGridView.swift
//  AppleTVBrowser
//
//  Grid-Layout für Bildsuchergebnisse mit Thumbnails
//

import SwiftUI

struct ImageResultGridView: View {
    let results: [SearchResult]
    let onSelect: (SearchResult) -> Void
    
    // Adaptive Grid für verschiedene Bildgrößen
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: TVOSDesign.Spacing.gridHorizontalSpacing)
    ]
    
    var body: some View {
        ScrollView {
            if results.isEmpty {
                // Empty State für keine Bilder-Ergebnisse
                ImageEmptyStateView()
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: TVOSDesign.Spacing.elementSpacing) {
                    ForEach(results) { result in
                        ImageResultCard(result: result, onTap: {
                            onSelect(result)
                        })
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom)
            }
        }
    }
}

// MARK: - Image Empty State

struct ImageEmptyStateView: View {
    var body: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            
            // Titel
            Text("Keine Bilder gefunden")
                .font(.system(size: TVOSDesign.Typography.title2, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .multilineTextAlignment(.center)
            
            // Beschreibung
            VStack(spacing: 12) {
                Text("Für diese Suchanfrage wurden keine Bilder gefunden.")
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                
                Text("Versuchen Sie es mit anderen Suchbegriffen oder wechseln Sie zu einem anderen Tab.")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 600)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Image Result Card

struct ImageResultCard: View {
    let result: SearchResult
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
            VStack(alignment: .leading, spacing: 12) {
                // Bild-Container mit Aspect Ratio
                ZStack {
                    // Placeholder während dem Laden
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TVOSDesign.Colors.cardBackground)
                        .aspectRatio(result.aspectRatio, contentMode: .fit)
                        .overlay(
                            Group {
                                if !imageLoaded && !imageError {
                                    // Loading State
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                            .scaleEffect(1.5)
                                        
                                        Text("Lade...")
                                            .font(.system(size: TVOSDesign.Typography.footnote))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                    }
                                } else if imageError {
                                    // Error State
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                        
                                        Text("Bild nicht verfügbar")
                                            .font(.system(size: TVOSDesign.Typography.footnote))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                }
                            }
                        )
                    
                    // Tatsächliches Bild
                    if let thumbnailURL = result.thumbnailURL, !imageError {
                        AsyncImage(url: URL(string: thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .onAppear {
                                    withAnimation(.easeIn(duration: 0.3)) {
                                        imageLoaded = true
                                    }
                                }
                        } placeholder: {
                            Color.clear
                        }
                        .onAppear {
                            // Timeout für Bild-Laden
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                if !imageLoaded {
                                    imageError = true
                                }
                            }
                        }
                    }
                    
                    // Dimensions Badge (unten rechts)
                    if let width = result.imageWidth, let height = result.imageHeight {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(width) × \(height)")
                                    .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.7))
                                    )
                                    .padding(8)
                            }
                        }
                    }
                }
                .overlay(
                    // Focus Ring
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 3)
                )
                
                // Titel (gekürzt)
                Text(result.title)
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Domain
                Text(result.displayURL)
                    .font(.system(size: TVOSDesign.Typography.caption))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
        .shadow(
            color: isFocused ? Color.black.opacity(0.4) : Color.black.opacity(0.1),
            radius: isFocused ? 20 : 8,
            y: isFocused ? 10 : 4
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    let sampleImages: [SearchResult] = [
        SearchResult(
            title: "Schöner Sonnenuntergang über dem Meer",
            url: "https://example.com/image1.jpg",
            description: "Ein wunderschöner Sonnenuntergang",
            contentType: .image,
            thumbnailURL: "https://picsum.photos/400/300?random=1",
            imageWidth: 1920,
            imageHeight: 1080
        ),
        SearchResult(
            title: "Berglandschaft mit Schnee",
            url: "https://example.com/image2.jpg",
            description: "Majestätische Berge im Winter",
            contentType: .image,
            thumbnailURL: "https://picsum.photos/300/400?random=2",
            imageWidth: 1080,
            imageHeight: 1440
        ),
        SearchResult(
            title: "Stadtpanorama bei Nacht",
            url: "https://example.com/image3.jpg",
            description: "Glitzernde Skyline",
            contentType: .image,
            thumbnailURL: "https://picsum.photos/500/250?random=3",
            imageWidth: 2560,
            imageHeight: 1280
        )
    ]
    
    return ZStack {
        TVOSDesign.Colors.background
            .ignoresSafeArea()
        
        ImageResultGridView(
            results: sampleImages,
            onSelect: { result in
                print("Bild ausgewählt: \(result.title)")
            }
        )
    }
}