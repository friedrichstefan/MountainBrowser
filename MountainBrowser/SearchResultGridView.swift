//
//  SearchResultGridView.swift
//  MountainBrowser
//
//  Suchergebnis-Grid mit Apple tvOS Human Interface Guidelines
//  Modernisiertes Design mit Skeleton Loading und Glasmorphismus
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                resultsHeader
                    .padding(.bottom, 60)
                
                LazyVGrid(columns: columns, spacing: TVOSDesign.Spacing.gridVerticalSpacing) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        ModernSearchCard(
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
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100)
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
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

// MARK: - Modern Search Card Component

struct ModernSearchCard: View {
    let result: SearchResult
    @Binding var isFocusedBinding: Bool
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var faviconImage: UIImage? = nil
    @State private var thumbnailImage: UIImage? = nil
    @State private var loadingState: LoadingState = .loading
    @State private var previewLoadAttempted: Bool = false
    
    enum LoadingState {
        case loading
        case loaded
        case failed
    }
    
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
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            isFocusedBinding = newValue
        }
        .scaleEffect(isPressed ? 0.96 : (isFocused ? 1.04 : 1.0))
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.35) : Color.black.opacity(0.15),
            radius: isFocused ? 30 : 8,
            y: isFocused ? 12 : 4
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .zIndex(isFocused ? 100 : 0)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailSection
            contentSection
        }
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var cardBackground: some View {
        ZStack {
            // Base blur background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            isFocused ? Color.white.opacity(0.15) : Color.white.opacity(0.05),
                            isFocused ? Color.white.opacity(0.08) : Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(
                LinearGradient(
                    colors: isFocused
                        ? [TVOSDesign.Colors.accentBlue.opacity(0.8), TVOSDesign.Colors.accentBlue.opacity(0.4)]
                        : [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFocused ? 2.5 : 1
            )
    }
    
    private var thumbnailSection: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            switch loadingState {
            case .loading:
                SkeletonLoadingView()
                
            case .loaded:
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
                
            case .failed:
                FailedLoadPlaceholder(icon: iconForResult, domain: domainFromURL)
            }
            
            // Dark gradient overlay for text readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
            }
            
            // Domain badge
            VStack {
                Spacer()
                HStack {
                    DomainBadge(favicon: faviconImage, icon: iconForResult, domain: domainFromURL)
                    Spacer()
                }
                .padding(14)
            }
        }
        .frame(height: 180)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
        .onAppear {
            if !previewLoadAttempted {
                previewLoadAttempted = true
                loadWebsitePreview()
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if !result.description.isEmpty {
                Text(result.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isFocused ? Color.white.opacity(0.8) : TVOSDesign.Colors.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 8)
            
            HStack {
                Text(truncatedURL)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineLimit(1)
                
                Spacer()
                
                if isFocused {
                    OpenIndicator()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .offset(x: 10)),
                            removal: .opacity
                        ))
                }
            }
        }
        .padding(20)
        .frame(height: 150)
    }
    
    // MARK: - Website Preview Loading
    
    private func loadWebsitePreview() {
        guard let url = URL(string: result.url), let host = url.host else {
            withAnimation(.easeInOut(duration: 0.4)) {
                loadingState = .failed
            }
            return
        }
        
        Task {
            async let thumbnailTask: Void = loadThumbnail(for: host)
            async let faviconTask: Void = loadFavicon(for: host)
            
            _ = await (thumbnailTask, faviconTask)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.4)) {
                    loadingState = thumbnailImage != nil ? .loaded : .failed
                }
            }
        }
    }
    
    private func loadThumbnail(for host: String) async {
        let thumbnailServices = [
            "https://image.thum.io/get/width/600/https://\(host)",
            "https://s0.wp.com/mshots/v1/https://\(host)?w=600&h=400",
            "https://free.pagepeeker.com/v2/thumbs.php?size=l&url=\(host)"
        ]
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0
        config.timeoutIntervalForResource = 15.0
        let session = URLSession(configuration: config)
        
        for serviceURL in thumbnailServices {
            if let url = URL(string: serviceURL) {
                do {
                    let (data, response) = try await session.data(from: url)
                    if let httpResponse = response as? HTTPURLResponse,
                       (200...299).contains(httpResponse.statusCode),
                       let image = UIImage(data: data),
                       image.size.width > 50 && image.size.height > 50 {
                        await MainActor.run {
                            self.thumbnailImage = image
                        }
                        return
                    }
                } catch {
                    continue
                }
            }
        }
    }
    
    private func loadFavicon(for host: String) async {
        let faviconURLs = [
            "https://www.google.com/s2/favicons?domain=\(host)&sz=128",
            "https://\(host)/apple-touch-icon.png",
            "https://\(host)/favicon-32x32.png",
            "https://\(host)/favicon.ico"
        ]
        
        for faviconURLString in faviconURLs {
            if let faviconURL = URL(string: faviconURLString) {
                do {
                    let (data, response) = try await URLSession.shared.data(from: faviconURL)
                    if let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200,
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.faviconImage = image
                        }
                        return
                    }
                } catch {
                    continue
                }
            }
        }
    }
    
    private var gradientColors: [Color] {
        let domain = domainFromURL.lowercased()
        if domain.contains("google") { return [Color(hex: "4285F4"), Color(hex: "34A853")] }
        else if domain.contains("wikipedia") { return [Color(hex: "636466"), Color(hex: "1A1A1A")] }
        else if domain.contains("youtube") { return [Color(hex: "FF0000"), Color(hex: "282828")] }
        else if domain.contains("github") { return [Color(hex: "24292E"), Color(hex: "0D1117")] }
        else if domain.contains("apple") { return [Color(hex: "555555"), Color(hex: "1D1D1F")] }
        else if domain.contains("twitter") || domain.contains("x.com") { return [Color(hex: "1DA1F2"), Color(hex: "14171A")] }
        else if domain.contains("netflix") { return [Color(hex: "E50914"), Color(hex: "141414")] }
        else if domain.contains("amazon") { return [Color(hex: "FF9900"), Color(hex: "232F3E")] }
        else { return [Color(hex: "667EEA"), Color(hex: "764BA2")] }
    }
    
    private var iconForResult: String {
        let domain = domainFromURL.lowercased()
        if domain.contains("google") { return "magnifyingglass" }
        else if domain.contains("wikipedia") { return "book.closed.fill" }
        else if domain.contains("youtube") { return "play.rectangle.fill" }
        else if domain.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        else if domain.contains("apple") { return "apple.logo" }
        else { return "globe" }
    }
    
    private var domainFromURL: String {
        guard let url = URL(string: result.url), let host = url.host else { return result.url }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    private var truncatedURL: String {
        let maxLength = 40
        if result.url.count <= maxLength { return result.url }
        return String(result.url.prefix(maxLength)) + "..."
    }
}

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Base skeleton
            VStack(spacing: 16) {
                // Icon placeholder
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                // Text placeholders
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80, height: 10)
                }
            }
            
            // Shimmer effect
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80)
                    .offset(x: isAnimating ? geometry.size.width : -80)
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Failed Load Placeholder

struct FailedLoadPlaceholder: View {
    let icon: String
    let domain: String
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0 : 1)
                
                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(domain)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Domain Badge

struct DomainBadge: View {
    let favicon: UIImage?
    let icon: String
    let domain: String
    
    var body: some View {
        HStack(spacing: 8) {
            if let favicon = favicon {
                Image(uiImage: favicon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(domain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

// MARK: - Open Indicator

struct OpenIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Öffnen")
                .font(.system(size: 14, weight: .semibold))
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 16))
        }
        .foregroundColor(TVOSDesign.Colors.accentBlue)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Backwards compatibility alias

typealias TVOSSearchCard = ModernSearchCard

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