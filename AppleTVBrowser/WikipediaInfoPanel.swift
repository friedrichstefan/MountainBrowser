//
//  WikipediaInfoPanel.swift
//  AppleTVBrowser
//
//  Wikipedia Knowledge Panel UI-Komponente (wie bei Google)
//

import SwiftUI

struct WikipediaInfoPanel: View {
    let wikipediaInfo: WikipediaInfo
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
            HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                // Wikipedia Bild (links)
                wikipediaImageView
                
                // Wikipedia Info (rechts)
                VStack(alignment: .leading, spacing: 16) {
                    // Titel + Attribution
                    VStack(alignment: .leading, spacing: 8) {
                        Text(wikipediaInfo.title)
                            .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                            .foregroundColor(TVOSDesign.Colors.primaryLabel)
                            .lineLimit(2)
                        
                        Text(wikipediaInfo.attributionText)
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    }
                    
                    // Zusammenfassung
                    Text(wikipediaInfo.displaySummary)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    
                    // Info-Felder (falls vorhanden)
                    if !wikipediaInfo.primaryInfoFields.isEmpty {
                        wikipediaInfoFieldsView
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Pfeil-Icon (rechts)
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
            }
            .padding(TVOSDesign.Spacing.elementSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 200) // Mindesthöhe für TV-optimierte Darstellung
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                // Focus Ring
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(
                isPressed ? 0.97 : (isFocused ? 1.02 : 1.0)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowOffset
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
    }
    
    // MARK: - Wikipedia Image View
    
    @ViewBuilder
    private var wikipediaImageView: some View {
        ZStack {
            // Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(TVOSDesign.Colors.cardBackground)
                .frame(width: 150, height: 150)
                .overlay(
                    Group {
                        if !imageLoaded && !imageError && wikipediaInfo.imageURL != nil {
                            // Loading State
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                .scaleEffect(1.2)
                        } else if imageError || wikipediaInfo.imageURL == nil {
                            // No Image / Error State
                            VStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                
                                Text("Wikipedia")
                                    .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
        .frame(width: 150, height: 150)
    }
    
    // MARK: - Info Fields View
    
    @ViewBuilder
    private var wikipediaInfoFieldsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Trennlinie
            Rectangle()
                .fill(TVOSDesign.Colors.tertiaryLabel.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: 300)
            
            // Info-Felder in 2-Spalten Layout
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ],
                spacing: 8
            ) {
                ForEach(wikipediaInfo.primaryInfoFields) { field in
                    HStack(alignment: .top, spacing: 8) {
                        Text(field.key + ":")
                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        
                        Text(field.value)
                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
    }
    
    private var shadowColor: Color {
        if isFocused {
            return Color.black.opacity(0.5)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 24 : 12
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 12 : 6
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TVOSDesign.Colors.background
            .ignoresSafeArea()
        
        VStack {
            WikipediaInfoPanel(
                wikipediaInfo: WikipediaInfo.example,
                onTap: {
                    print("Wikipedia-Panel getappt!")
                }
            )
            .padding()
            
            Spacer()
        }
    }
}