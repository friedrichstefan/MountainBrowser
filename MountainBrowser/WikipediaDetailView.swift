//
//  WikipediaDetailView.swift
//  MountainBrowser
//
//  Detaillierte Wikipedia-Ansicht für den Info-Tab
//  Glasmorphes Design
//

import SwiftUI

struct WikipediaDetailView: View {
    let wikipediaInfo: WikipediaInfo
    let onTap: () -> Void
    
    @FocusState private var actionButtonFocused: Bool
    @FocusState private var imageFocused: Bool
    @FocusState private var textFocused: Bool
    
    // Fullscreen Viewer States
    @State private var showFullscreenText: Bool = false
    @State private var showFullscreenImage: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            heroHeader
            
            VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                // Artikeltext
                articleSection
                
                // Info-Felder (nur wenn vorhanden)
                if !wikipediaInfo.infoFields.isEmpty {
                    infoFieldsSection
                }
                
                // CTA Button
                actionButton
                
                Spacer(minLength: TVOSDesign.Spacing.safeAreaBottom + 40)
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            .padding(.top, TVOSDesign.Spacing.cardSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showFullscreenText) {
            FullscreenTextViewer(
                title: wikipediaInfo.title,
                text: wikipediaInfo.summary,
                isPresented: $showFullscreenText
            )
        }
        .fullScreenCover(isPresented: $showFullscreenImage) {
            if let imageURL = wikipediaInfo.imageURL {
                FullscreenImageViewer(
                    imageURL: imageURL,
                    title: wikipediaInfo.title,
                    isPresented: $showFullscreenImage
                )
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    TVOSDesign.Colors.accentBlue.opacity(0.15),
                    TVOSDesign.Colors.systemPurple.opacity(0.08),
                    TVOSDesign.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 320)
            
            HStack(alignment: .bottom, spacing: TVOSDesign.Spacing.cardSpacing) {
                // Wikipedia-Bild
                Button(action: {
                    if wikipediaInfo.imageURL != nil {
                        showFullscreenImage = true
                    }
                }) {
                    WikipediaAsyncImage(
                        imageURL: wikipediaInfo.imageURL,
                        size: 200,
                        cornerRadius: TVOSDesign.CornerRadius.large
                    )
                    .shadow(
                        color: Color.black.opacity(imageFocused ? 0.5 : 0.3),
                        radius: imageFocused ? 20 : 10,
                        y: imageFocused ? 10 : 5
                    )
                }
                .buttonStyle(TransparentButtonStyle())
                .focused($imageFocused)
                .scaleEffect(imageFocused ? 1.03 : 1.0)
                .animation(TVOSDesign.Animation.focusSpring, value: imageFocused)
                
                // Titel-Bereich
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(wikipediaInfo.language == "de" ? "Deutsche Wikipedia" : "English Wikipedia")
                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                    .foregroundColor(TVOSDesign.Colors.accentBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(TVOSDesign.Colors.accentBlue.opacity(0.15))
                    )
                    
                    Text(wikipediaInfo.title)
                        .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Kurze Info-Chips direkt unter dem Titel
                    if !wikipediaInfo.primaryInfoFields.isEmpty {
                        HStack(spacing: 10) {
                            ForEach(wikipediaInfo.primaryInfoFields.prefix(3)) { field in
                                HStack(spacing: 4) {
                                    Text(field.key + ":")
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                    Text(field.value)
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(TVOSDesign.Colors.tertiaryBackground)
                                )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            .padding(.bottom, TVOSDesign.Spacing.cardSpacing)
        }
    }
    
    // MARK: - Article Section
    
    private var articleSection: some View {
        Button(action: {
            showFullscreenText = true
        }) {
            VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                Text(wikipediaInfo.summary)
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .lineLimit(12)
                
                if wikipediaInfo.summary.count > 300 {
                    HStack(spacing: 6) {
                        Text("Vollständig lesen")
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(TVOSDesign.Colors.accentBlue)
                }
            }
            .padding(TVOSDesign.Spacing.cardSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                    .fill(textFocused ? TVOSDesign.Colors.glassBackgroundHover : TVOSDesign.Colors.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                    .strokeBorder(
                        textFocused ? TVOSDesign.Colors.accentBlue.opacity(0.4) : TVOSDesign.Colors.glassBorder,
                        lineWidth: textFocused ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($textFocused)
        .scaleEffect(textFocused ? 1.01 : 1.0)
        .shadow(
            color: textFocused ? TVOSDesign.Colors.accentBlue.opacity(0.12) : Color.clear,
            radius: textFocused ? 12 : 0,
            y: textFocused ? 6 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: textFocused)
    }
    
    // MARK: - Info Fields Section
    
    private var infoFieldsSection: some View {
        VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.accentBlue)
                
                Text("Informationen")
                    .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Rectangle()
                    .fill(TVOSDesign.Colors.separator)
                    .frame(height: 1)
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: TVOSDesign.Spacing.medium),
                    GridItem(.flexible(), spacing: TVOSDesign.Spacing.medium)
                ],
                spacing: TVOSDesign.Spacing.medium
            ) {
                ForEach(wikipediaInfo.infoFields) { field in
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(TVOSDesign.Colors.accentBlue)
                            .frame(width: 3)
                            .clipShape(Capsule())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.key)
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Text(field.value)
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(TVOSDesign.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                            .fill(TVOSDesign.Colors.glassBackground)
                    )
                }
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: onTap) {
            HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Image(systemName: "safari")
                    .font(.system(size: 26, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vollständigen Artikel lesen")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                    Text(shortArticleURL)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                        .opacity(0.7)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                TVOSDesign.Colors.accentBlue,
                                TVOSDesign.Colors.accentBlue.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                    .strokeBorder(
                        actionButtonFocused ? Color.white.opacity(0.3) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($actionButtonFocused)
        .scaleEffect(actionButtonFocused ? 1.03 : 1.0)
        .shadow(
            color: TVOSDesign.Colors.accentBlue.opacity(actionButtonFocused ? 0.5 : 0.2),
            radius: actionButtonFocused ? 24 : 8,
            y: actionButtonFocused ? 12 : 4
        )
        .animation(TVOSDesign.Animation.focusSpring, value: actionButtonFocused)
        .padding(.top, TVOSDesign.Spacing.elementSpacing)
    }
    
    // MARK: - Computed Properties
    
    private var shortArticleURL: String {
        guard let url = URL(string: wikipediaInfo.articleURL), let host = url.host else {
            return wikipediaInfo.articleURL
        }
        var h = host
        if h.hasPrefix("www.") { h = String(h.dropFirst(4)) }
        let path = url.path
        if path.count > 30 {
            return "\(h)\(path.prefix(30))…"
        }
        return "\(h)\(path)"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GlassmorphicBackground()
        
        ScrollView {
            WikipediaDetailView(
                wikipediaInfo: WikipediaInfo.example,
                onTap: {
                }
            )
        }
    }
}
