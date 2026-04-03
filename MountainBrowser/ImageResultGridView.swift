//
//  ImageResultGridView.swift
//  MountainBrowser
//
//  Grid-Layout für Bildsuchergebnisse mit modernem Design
//  Skeleton Loading und Glasmorphismus für tvOS
//

import SwiftUI

struct ImageResultGridView: View {
    let results: [SearchResult]
    let onSelect: (SearchResult) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 24)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if results.isEmpty {
                ModernImageEmptyStateView()
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(results) { result in
                        ModernImageResultCard(result: result, onTap: {
                            onSelect(result)
                        })
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100)
            }
        }
        .accessibilityLabel(L10n.Search.imageResults)
    }
}

// MARK: - Modern Image Empty State

struct ModernImageEmptyStateView: View {
    @State private var floatAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TVOSDesign.Colors.accentBlue.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Icon container
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .offset(y: floatAnimation ? -8 : 8)
            }
            
            VStack(spacing: 16) {
                Text(L10n.ImageResults.noImages)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .multilineTextAlignment(.center)

                Text(L10n.ImageResults.noImagesMessage)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: 600)
            
            // Suggestion pills
            HStack(spacing: 16) {
                SuggestionPill(text: L10n.Suggestions.otherSearchTerms, icon: "magnifyingglass")
                SuggestionPill(text: L10n.Suggestions.switchTab, icon: "rectangle.stack")
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatAnimation = true
            }
        }
    }
}

// MARK: - Suggestion Pill

struct SuggestionPill: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
            Text(text)
                .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Image Result Card

struct ModernImageResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var loadingState: ImageLoadingState = .loading
    @State private var loadedImage: UIImage? = nil
    
    enum ImageLoadingState {
        case loading
        case loaded
        case failed
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Bild-Container
                imageContainer
                
                // Info Section
                infoSection
            }
            .background(cardBackground)
            .overlay(cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .scaleEffect(isPressed ? 0.96 : (isFocused ? 1.05 : 1.0))
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.4) : Color.black.opacity(0.2),
            radius: isFocused ? 28 : 10,
            y: isFocused ? 14 : 5
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .zIndex(isFocused ? 100 : 0)
        .accessibilityLabel(result.title)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(
                LinearGradient(
                    colors: isFocused
                        ? [TVOSDesign.Colors.accentBlue.opacity(0.8), TVOSDesign.Colors.accentBlue.opacity(0.4)]
                        : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFocused ? 2.5 : 1
            )
    }
    
    private var imageContainer: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "667EEA").opacity(0.5), Color(hex: "764BA2").opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            switch loadingState {
            case .loading:
                ImageSkeletonLoader()
                
            case .loaded:
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
                
            case .failed:
                ImageFailedPlaceholder()
            }
            
            // Resolution badge
            if let width = result.imageWidth, let height = result.imageHeight {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ResolutionBadge(width: width, height: height)
                            .padding(12)
                    }
                }
            }
        }
        .aspectRatio(result.aspectRatio, contentMode: .fit)
        .frame(minHeight: 140, maxHeight: 240)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
        .onAppear {
            loadImage()
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(result.displayURL)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isFocused ? Color.white.opacity(0.7) : TVOSDesign.Colors.tertiaryLabel)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func loadImage() {
        guard let thumbnailURL = result.thumbnailURL,
              let url = URL(string: thumbnailURL) else {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadingState = .failed
            }
            return
        }
        
        Task {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            let session = URLSession(configuration: config)
            
            do {
                let (data, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = image
                        withAnimation(.easeInOut(duration: 0.4)) {
                            loadingState = .loaded
                        }
                    }
                } else {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loadingState = .failed
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        loadingState = .failed
                    }
                }
            }
        }
    }
}

// MARK: - Image Skeleton Loader

struct ImageSkeletonLoader: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Base skeleton elements
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 80, height: 8)
            }
            
            // Shimmer overlay
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 100)
                    .offset(x: shimmerOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                            shimmerOffset = geometry.size.width + 100
                        }
                    }
            }
            .clipped()
        }
    }
}

// MARK: - Image Failed Placeholder

struct ImageFailedPlaceholder: View {
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "photo.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(L10n.ImageResults.imageUnavailable)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Resolution Badge

struct ResolutionBadge: View {
    let width: Int
    let height: Int
    
    var body: some View {
        Text("\(width) × \(height)")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
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
    
    ZStack {
        TVOSDesign.Colors.background
            .ignoresSafeArea()
        
        ImageResultGridView(
            results: sampleImages,
            onSelect: { result in
            }
        )
    }
}