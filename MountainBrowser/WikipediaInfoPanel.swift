//
//  WikipediaInfoPanel.swift
//  MountainBrowser
//
//  Konsolidierte Wikipedia Knowledge Panel Komponente
//  Unterstützt sowohl vollständige als auch kollabierbare Darstellung
//  Glasmorphes Design
//

import SwiftUI

// MARK: - Wikipedia Image Loader (Wiederverwendbar)

struct WikipediaAsyncImage: View {
    let imageURL: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    
    init(imageURL: String?, size: CGFloat, cornerRadius: CGFloat = TVOSDesign.CornerRadius.medium) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            // Placeholder-Hintergrund mit dezentem Gradient
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            TVOSDesign.Colors.tertiaryBackground,
                            TVOSDesign.Colors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Loading / Error / Placeholder
            if !imageLoaded && !imageError && imageURL != nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                    .scaleEffect(size > 80 ? 1.0 : 0.7)
            } else if imageError || imageURL == nil {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: size > 80 ? 32 : 18))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    
                    if size > 80 {
                        Text("Wikipedia")
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    }
                }
            }
            
            // Tatsächliches Bild
            if let imageURL = imageURL, !imageError {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: size - 8, maxHeight: size - 8)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    case .failure:
                        Color.clear
                            .onAppear {
                                imageError = true
                            }
                    case .empty:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .seconds(8))
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Wikipedia Info Panel (Collapsible, Glasmorph)

struct WikipediaInfoPanel: View {
    let wikipediaInfo: WikipediaInfo
    let isExpanded: Bool
    let onTap: () -> Void
    let onExpandToggle: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @FocusState private var expandButtonFocused: Bool
    
    /// Convenience initializer für nicht-kollabierbaren Modus
    init(
        wikipediaInfo: WikipediaInfo,
        onTap: @escaping () -> Void
    ) {
        self.wikipediaInfo = wikipediaInfo
        self.isExpanded = true
        self.onTap = onTap
        self.onExpandToggle = nil
    }
    
    /// Vollständiger Initializer mit Collapse-Support
    init(
        wikipediaInfo: WikipediaInfo,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onExpandToggle: @escaping () -> Void
    ) {
        self.wikipediaInfo = wikipediaInfo
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onExpandToggle = onExpandToggle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                panelContent
            }
            .buttonStyle(TransparentButtonStyle())
            .focused($isFocused)
        }
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                .fill(isFocused ? TVOSDesign.Colors.glassBackgroundHover : TVOSDesign.Colors.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                .strokeBorder(
                    isFocused ? TVOSDesign.Colors.systemIndigo.opacity(0.4) : TVOSDesign.Colors.glassBorder,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                .stroke(
                    LinearGradient(
                        colors: [
                            TVOSDesign.Colors.accentBlue.opacity(isExpanded ? 0.3 : 0.15),
                            TVOSDesign.Colors.systemPurple.opacity(isExpanded ? 0.2 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large))
        .scaleEffect(isFocused ? 1.01 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemIndigo.opacity(0.12) : Color.clear,
            radius: isFocused ? 16 : 0,
            y: isFocused ? 6 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isExpanded)
        .accessibilityLabel("Wikipedia: \(wikipediaInfo.title)")
        .accessibilityHint("Doppeltippen für den vollständigen Wikipedia-Artikel")
        .accessibilityValue(wikipediaInfo.displaySummary)
    }
    
    // MARK: - Panel Content
    
    private var panelContent: some View {
        HStack(alignment: .top, spacing: TVOSDesign.Spacing.elementSpacing) {
            // Wikipedia Bild
            WikipediaAsyncImage(
                imageURL: wikipediaInfo.imageURL,
                size: isExpanded ? 120 : 60,
                cornerRadius: isExpanded ? TVOSDesign.CornerRadius.medium : 10
            )
            
            // Wikipedia Info
            VStack(alignment: .leading, spacing: isExpanded ? 10 : 6) {
                // Header-Zeile: Titel + Badge + Expand
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Wikipedia-Badge
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(wikipediaInfo.attributionText)
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                        }
                        .foregroundColor(TVOSDesign.Colors.accentBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(TVOSDesign.Colors.accentBlue.opacity(0.12))
                        )
                        
                        Text(wikipediaInfo.title)
                            .font(.system(size: isExpanded ? TVOSDesign.Typography.title3 : TVOSDesign.Typography.callout, weight: .bold))
                            .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                            .lineLimit(isExpanded ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)
                    
                    Spacer(minLength: 12)
                    
                    // Expand/Collapse Button
                    if let onExpandToggle = onExpandToggle {
                        Button(action: {
                            withAnimation(TVOSDesign.Animation.focusSpring) {
                                onExpandToggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(expandButtonFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.secondaryLabel)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(TransparentButtonStyle())
                        .focused($expandButtonFocused)
                        .fixedSize()
                    }
                }
                
                // Zusammenfassung (nur wenn expanded)
                if isExpanded {
                    Text(wikipediaInfo.displaySummary)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .lineSpacing(4)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Info-Felder in Chips
                    if !wikipediaInfo.primaryInfoFields.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(wikipediaInfo.primaryInfoFields.prefix(3)) { field in
                                HStack(spacing: 6) {
                                    Text(field.key)
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                    Text(field.value)
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(TVOSDesign.Colors.tertiaryBackground)
                                )
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // "Mehr erfahren"-Hinweis
                    HStack(spacing: 8) {
                        Text("Vollständigen Artikel ansehen")
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.accentBlue)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(TVOSDesign.Colors.accentBlue)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .opacity(isFocused ? 1.0 : 0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Pfeil-Icon (nur im kollabierten Zustand)
            if !isExpanded {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.5)
                    .fixedSize()
            }
        }
        .padding(isExpanded ? 20 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: isExpanded ? nil : 80)
    }
}

// MARK: - Preview

struct WikipediaInfoPanel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                WikipediaInfoPanel(
                    wikipediaInfo: WikipediaInfo.example,
                    isExpanded: true,
                    onTap: { print("Tap!") },
                    onExpandToggle: { print("Toggle!") }
                )
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                
                WikipediaInfoPanel(
                    wikipediaInfo: WikipediaInfo.example,
                    isExpanded: false,
                    onTap: { print("Tap!") },
                    onExpandToggle: { print("Toggle!") }
                )
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}
