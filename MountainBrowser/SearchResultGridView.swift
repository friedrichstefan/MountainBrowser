//
//  SearchResultGridView.swift
//  MountainBrowser
//
//  Suchergebnis-Grid mit Apple tvOS Human Interface Guidelines
//  Modernisiertes Design mit Skeleton Loading und Glasmorphismus
//

import SwiftUI

// MARK: - Global Favicon Cache

/// Actor-basierter Cache für Favicons — lädt jede Domain nur einmal
actor FaviconCache {
    static let shared = FaviconCache()
    
    private var cache: [String: UIImage] = [:]
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    
    func favicon(for host: String) async -> UIImage? {
        // 1. Bereits gecacht?
        if let cached = cache[host] {
            return cached
        }
        
        // 2. Bereits ein Request unterwegs?
        if let existing = inFlight[host] {
            return await existing.value
        }
        
        // 3. Neuen Request starten
        let task = Task<UIImage?, Never> {
            let url = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")!
            do {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 5.0
                let session = URLSession(configuration: config)
                let (data, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let image = UIImage(data: data) {
                    return image
                }
            } catch {}
            return nil
        }
        
        inFlight[host] = task
        let result = await task.value
        inFlight[host] = nil
        
        if let image = result {
            cache[host] = image
        }
        
        return result
    }
}

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
                        .accessibilityHint(L10n.Search.doubleTapToOpen)
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100)
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
        .accessibilityLabel(L10n.Search.results)
    }

    func resetScrollState() {
        hasScrolled = false
        onResetScroll?()
    }
    
    private var resultsHeader: some View {
        HStack(alignment: .center, spacing: TVOSDesign.Spacing.elementSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Search.results)
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)

                Text(L10n.Search.resultsFound(results.count))
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            
            Spacer()
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .accessibilityLabel(L10n.Search.resultsFound(results.count))
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
    @State private var faviconLoaded: Bool = false
    
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
            heroSection
            contentSection
        }
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
            
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
    
    // MARK: - Hero Section (replaces slow thumbnail loading)
    
    private var heroSection: some View {
        ZStack {
            // Domain-based gradient background — instant, no network
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Large centered icon + domain
            VStack(spacing: 14) {
                // Favicon or fallback icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    if let favicon = faviconImage {
                        Image(uiImage: favicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.opacity)
                    } else {
                        Image(systemName: iconForResult)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // Domain name
                Text(domainFromURL)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            
            // Dark gradient overlay at bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 50)
            }
            
            // Domain badge bottom-left
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
            if !faviconLoaded {
                faviconLoaded = true
                loadFavicon()
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
    
    // MARK: - Favicon Loading (single fast request via cache)
    
    private func loadFavicon() {
        guard let url = URL(string: result.url), let host = url.host else { return }
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
        else if domain.contains("reddit") { return [Color(hex: "FF4500"), Color(hex: "1A1A1B")] }
        else if domain.contains("stackoverflow") { return [Color(hex: "F48024"), Color(hex: "232629")] }
        else if domain.contains("microsoft") { return [Color(hex: "00A4EF"), Color(hex: "737373")] }
        else if domain.contains("facebook") || domain.contains("meta") { return [Color(hex: "1877F2"), Color(hex: "23272F")] }
        else if domain.contains("instagram") { return [Color(hex: "E1306C"), Color(hex: "833AB4")] }
        else if domain.contains("linkedin") { return [Color(hex: "0A66C2"), Color(hex: "004182")] }
        else if domain.contains("lidl") { return [Color(hex: "0050AA"), Color(hex: "FFF000").opacity(0.6)] }
        else if domain.contains("ebay") { return [Color(hex: "E53238"), Color(hex: "F5AF02")] }
        else {
            // Generate a stable color from the domain hash
            let hash = abs(domain.hashValue)
            let hue1 = Double(hash % 360) / 360.0
            let hue2 = Double((hash / 360) % 360) / 360.0
            return [
                Color(hue: hue1, saturation: 0.5, brightness: 0.6),
                Color(hue: hue2, saturation: 0.4, brightness: 0.3)
            ]
        }
    }
    
    private var iconForResult: String {
        let domain = domainFromURL.lowercased()
        if domain.contains("google") { return "magnifyingglass" }
        else if domain.contains("wikipedia") { return "book.closed.fill" }
        else if domain.contains("youtube") { return "play.rectangle.fill" }
        else if domain.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        else if domain.contains("apple") { return "apple.logo" }
        else if domain.contains("amazon") || domain.contains("ebay") || domain.contains("lidl") { return "cart.fill" }
        else if domain.contains("reddit") { return "bubble.left.and.bubble.right.fill" }
        else if domain.contains("twitter") || domain.contains("x.com") { return "at" }
        else if domain.contains("facebook") || domain.contains("instagram") { return "person.2.fill" }
        else if domain.contains("linkedin") { return "briefcase.fill" }
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
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80, height: 10)
                }
            }
            
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
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0 : 1)
                
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
            Text(L10n.General.open)
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
