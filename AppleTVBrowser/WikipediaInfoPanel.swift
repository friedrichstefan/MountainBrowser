//
//  WikipediaInfoPanel.swift
//  AppleTVBrowser
//
//  Konsolidierte Wikipedia Knowledge Panel Komponente
//  Unterstützt sowohl vollständige als auch kollabierbare Darstellung
//

import SwiftUI

// MARK: - Wikipedia Image Loader (Wiederverwendbar)

struct WikipediaAsyncImage: View {
    let imageURL: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    
    init(imageURL: String?, size: CGFloat, cornerRadius: CGFloat = 16) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(TVOSDesign.Colors.cardBackground)
                .overlay(
                    Group {
                        if !imageLoaded && !imageError && imageURL != nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.secondaryLabel))
                                .scaleEffect(size > 80 ? 1.0 : 0.7)
                        } else if imageError || imageURL == nil {
                            VStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: size > 80 ? 28 : 18))
                                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                
                                if size > 80 {
                                    Text("Wiki")
                                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                }
                            }
                        }
                    }
                )
            
            if let imageURL = imageURL, !imageError {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
                        try? await Task.sleep(for: .seconds(8))
                        if !imageLoaded {
                            imageError = true
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wikipedia Info Panel (Collapsible)

struct WikipediaInfoPanel: View {
    let wikipediaInfo: WikipediaInfo
    let isExpanded: Bool
    let onTap: () -> Void
    let onExpandToggle: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
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
            HStack(alignment: .top, spacing: TVOSDesign.Spacing.elementSpacing) {
                // Wikipedia Bild
                WikipediaAsyncImage(
                    imageURL: wikipediaInfo.imageURL,
                    size: isExpanded ? 120 : 60,
                    cornerRadius: isExpanded ? 16 : 10
                )
                .fixedSize()
                
                // Wikipedia Info
                VStack(alignment: .leading, spacing: isExpanded ? 12 : 6) {
                    // Titel + Attribution + Expand Button
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wikipediaInfo.title)
                                .font(.system(size: isExpanded ? TVOSDesign.Typography.title3 : TVOSDesign.Typography.callout, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .lineLimit(isExpanded ? 2 : 1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(wikipediaInfo.attributionText)
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        }
                        .layoutPriority(1)
                        
                        Spacer(minLength: 16)
                        
                        // Expand/Collapse Button (nur wenn Collapse unterstützt wird)
                        if let onExpandToggle = onExpandToggle {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    onExpandToggle()
                                }
                            }) {
                                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .fixedSize()
                        }
                    }
                    
                    // Zusammenfassung (nur wenn expanded)
                    if isExpanded {
                        Text(wikipediaInfo.displaySummary)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Info-Felder
                        if !wikipediaInfo.primaryInfoFields.isEmpty {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(wikipediaInfo.primaryInfoFields.prefix(2)) { field in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.key)
                                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                        Text(field.value)
                                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pfeil-Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
                    .fixedSize()
            }
            .padding(isExpanded ? TVOSDesign.Spacing.elementSpacing : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isExpanded ? 160 : 80)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.01 : 1.0))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowOffset
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            if newValue, let onExpandToggle = onExpandToggle, !isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onExpandToggle()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .accessibilityLabel("Wikipedia: \(wikipediaInfo.title)")
        .accessibilityHint("Doppeltippen für den vollständigen Wikipedia-Artikel")
        .accessibilityValue(wikipediaInfo.displaySummary)
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
        isFocused ? Color.black.opacity(0.5) : Color.black.opacity(0.2)
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 20 : 10
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 10 : 5
    }
}

// MARK: - Preview

struct WikipediaInfoPanel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Expandiertes Panel
                WikipediaInfoPanel(
                    wikipediaInfo: WikipediaInfo.example,
                    isExpanded: true,
                    onTap: { print("Tap!") },
                    onExpandToggle: { print("Toggle!") }
                )
                .padding()
                
                // Minimiertes Panel
                WikipediaInfoPanel(
                    wikipediaInfo: WikipediaInfo.example,
                    isExpanded: false,
                    onTap: { print("Tap!") },
                    onExpandToggle: { print("Toggle!") }
                )
                .padding()
                
                Spacer()
            }
        }
    }
}
