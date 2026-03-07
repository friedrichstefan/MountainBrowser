//
//  VideoResultGridView.swift
//  AppleTVBrowser
//
//  Grid-Layout für Videosuchergebnisse mit Thumbnails
//

import SwiftUI

struct VideoResultGridView: View {
    let results: [SearchResult]
    let onSelect: (SearchResult) -> Void
    
    // Adaptive Grid für verschiedene Videogrößen (breiter als Bilder)
    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: TVOSDesign.Spacing.gridHorizontalSpacing)
    ]
    
    var body: some View {
        // tvOS: Kein GeometryReader – ScrollView bekommt Größe von Parent
        ScrollView(.vertical, showsIndicators: false) {
            if results.isEmpty {
                VideoEmptyStateView()
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: TVOSDesign.Spacing.elementSpacing) {
                    ForEach(results) { result in
                        VideoResultCard(result: result, onTap: {
                            onSelect(result)
                        })
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100)
            }
        }
        .accessibilityLabel("Videosuchergebnisse")
    }
}

// MARK: - Video Empty State

struct VideoEmptyStateView: View {
    var body: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            
            Text("Keine Videos gefunden")
                .font(.system(size: TVOSDesign.Typography.title2, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Text("Für diese Suchanfrage wurden keine Videos gefunden.")
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

// MARK: - Video Result Card

struct VideoResultCard: View {
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
            
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Video-Thumbnail Container (16:9 Aspect Ratio)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TVOSDesign.Colors.cardBackground)
                        .aspectRatio(16.0/9.0, contentMode: .fit)
                        .overlay(
                            Group {
                                if !imageLoaded && !imageError {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                            .scaleEffect(1.5)
                                        
                                        Text("Lade Video...")
                                            .font(.system(size: TVOSDesign.Typography.footnote))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                    }
                                } else if imageError {
                                    VStack(spacing: 12) {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                        
                                        Text("Video nicht verfügbar")
                                            .font(.system(size: TVOSDesign.Typography.footnote))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                }
                            }
                        )
                    
                    if let thumbnailURL = result.thumbnailURL, !imageError {
                        AsyncImage(url: URL(string: thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(16.0/9.0, contentMode: .fill)
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
                            Task {
                                try? await Task.sleep(for: .seconds(10))
                                if !imageLoaded {
                                    imageError = true
                                }
                            }
                        }
                    }
                    
                    // Play-Button Overlay
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .offset(x: 2)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    
                    // Duration Badge
                    if let duration = result.duration {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(duration)
                                    .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.8))
                                    )
                                    .padding(8)
                            }
                        }
                    }
                    
                    // Source Badge
                    if let source = result.source {
                        VStack {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: sourceIcon(for: source))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(source)
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(sourceColor(for: source))
                                )
                                .padding(8)
                                
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 3)
                )
                
                // Video Titel
                Text(result.title)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Channel/Domain
                HStack {
                    Text(result.displayURL)
                        .font(.system(size: TVOSDesign.Typography.caption))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let source = result.source {
                        HStack(spacing: 4) {
                            Image(systemName: sourceIcon(for: source))
                                .font(.system(size: 10))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                            
                            Text(source)
                                .font(.system(size: TVOSDesign.Typography.caption))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        }
                    }
                }
            }
        }
        .buttonStyle(.card) // tvOS native Card-Style
        .focused($isFocused)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .accessibilityLabel("\(result.title). \(result.source ?? "Video")")
    }
    
    // MARK: - Helper Methods
    
    private func sourceIcon(for source: String) -> String {
        switch source.lowercased() {
        case "youtube":
            return "play.rectangle.fill"
        case "vimeo":
            return "v.circle.fill"
        case "dailymotion":
            return "d.circle.fill"
        default:
            return "video.circle.fill"
        }
    }
    
    private func sourceColor(for source: String) -> Color {
        switch source.lowercased() {
        case "youtube":
            return Color.red.opacity(0.9)
        case "vimeo":
            return Color.blue.opacity(0.9)
        case "dailymotion":
            return Color.orange.opacity(0.9)
        default:
            return Color.black.opacity(0.7)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleVideos: [SearchResult] = [
        SearchResult(
            title: "SwiftUI Tutorial: Building Amazing Apps",
            url: "https://youtube.com/watch?v=example1",
            description: "Learn SwiftUI from scratch",
            contentType: .video,
            thumbnailURL: "https://picsum.photos/640/360?random=1",
            imageWidth: 1920,
            imageHeight: 1080,
            duration: "15:42",
            source: "YouTube"
        ),
        SearchResult(
            title: "Beautiful Nature Documentary",
            url: "https://vimeo.com/example2",
            description: "Explore the wonders of nature",
            contentType: .video,
            thumbnailURL: "https://picsum.photos/640/360?random=2",
            imageWidth: 1920,
            imageHeight: 1080,
            duration: "1:23:15",
            source: "Vimeo"
        )
    ]
    
    return ZStack {
        TVOSDesign.Colors.background
            .ignoresSafeArea()
        
        VideoResultGridView(
            results: sampleVideos,
            onSelect: { result in
                print("Video ausgewählt: \(result.title)")
            }
        )
    }
}
