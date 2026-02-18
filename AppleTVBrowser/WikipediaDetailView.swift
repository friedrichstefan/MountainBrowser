//
//  WikipediaDetailView.swift
//  AppleTVBrowser
//
//  Detaillierte Wikipedia-Ansicht für den Info-Tab
//

import SwiftUI

struct WikipediaDetailView: View {
    let wikipediaInfo: WikipediaInfo
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    
    var body: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            // Header mit Bild und Titel
            headerSection
            
            // Hauptinhalt
            contentSection
            
            // Info-Felder
            if !wikipediaInfo.infoFields.isEmpty {
                infoFieldsSection
            }
            
            // Action Button
            actionButton
            
            Spacer(minLength: TVOSDesign.Spacing.safeAreaBottom)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            // Wikipedia-Bild (größer als im Panel)
            wikipediaImageView
                .frame(width: 240, height: 240)
            
            // Titel und Attribution
            VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                Text(wikipediaInfo.title)
                    .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Text(wikipediaInfo.attributionText)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                
                Spacer()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: TVOSDesign.Spacing.cardSpacing) {
            // Vollständige Zusammenfassung
            VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                Text("Vollständiger Wikipedia-Artikel")
                    .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(wikipediaInfo.summary)
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
            }
            
            // Zusätzliche Artikel-Informationen
            VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                Text("Artikel-Details")
                    .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: TVOSDesign.Spacing.elementSpacing, alignment: .leading),
                        GridItem(.flexible(), spacing: TVOSDesign.Spacing.elementSpacing, alignment: .leading)
                    ],
                    spacing: TVOSDesign.Spacing.elementSpacing
                ) {
                    // Artikel-URL
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wikipedia-URL")
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text(wikipediaInfo.articleURL)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.accentBlue)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                    
                    // Sprache
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Artikel-Sprache")
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text(wikipediaInfo.language == "de" ? "Deutsch" : "English")
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                    
                    // Zeichenanzahl
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Textlänge")
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text("\(wikipediaInfo.summary.count) Zeichen")
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                    
                    // Attribution erweitert
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quelle")
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text("Wikipedia - Die freie Enzyklopädie")
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Info Fields Section
    
    @ViewBuilder
    private var infoFieldsSection: some View {
        VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
            Text("Informationen")
                .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            // 2-Spalten Grid für Info-Felder
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: TVOSDesign.Spacing.elementSpacing, alignment: .leading),
                    GridItem(.flexible(), spacing: TVOSDesign.Spacing.elementSpacing, alignment: .leading)
                ],
                spacing: TVOSDesign.Spacing.elementSpacing
            ) {
                ForEach(wikipediaInfo.infoFields) { field in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(field.key)
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text(field.value)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(TVOSDesign.Spacing.elementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
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
            HStack(spacing: 16) {
                Image(systemName: "safari")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Vollständigen Artikel auf Wikipedia lesen")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 48)
            .padding(.vertical, 24)
            .frame(maxWidth: 800)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(Color.white)
            )
            .scaleEffect(
                isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0)
            )
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0.2),
                radius: isFocused ? 24 : 12,
                y: isFocused ? 12 : 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        .padding(.top, TVOSDesign.Spacing.cardSpacing)
    }
    
    // MARK: - Wikipedia Image View
    
    @ViewBuilder
    private var wikipediaImageView: some View {
        ZStack {
            // Placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(TVOSDesign.Colors.cardBackground)
                .overlay(
                    Group {
                        if !imageLoaded && !imageError && wikipediaInfo.imageURL != nil {
                            // Loading State
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                .scaleEffect(1.5)
                        } else if imageError || wikipediaInfo.imageURL == nil {
                            // No Image / Error State
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                
                                Text("Wikipedia")
                                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                            }
                        }
                    }
                )
            
            // Wikipedia Bild
            if let imageURL = wikipediaInfo.imageURL, !imageError {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TVOSDesign.Colors.background
            .ignoresSafeArea()
        
        WikipediaDetailView(
            wikipediaInfo: WikipediaInfo.example,
            onTap: {
                print("Wikipedia-Artikel öffnen!")
            }
        )
    }
}