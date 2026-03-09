//
//  SearchTabBar.swift
//  MountainBrowser
//
//  Tab-Leiste für Content-Type Auswahl (Alle, Bilder, Videos)
//

import SwiftUI

struct SearchTabBar: View {
    @Binding var selectedContentType: SearchContentType
    let onTabSelected: (SearchContentType) -> Void
    let hasWikipediaInfo: Bool
    
    var availableTabs: [SearchContentType] {
        if hasWikipediaInfo {
            return SearchContentType.allCases
        } else {
            return [.web, .image, .video]
        }
    }
    
    var body: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            ForEach(availableTabs, id: \.self) { contentType in
                SearchTab(
                    contentType: contentType,
                    isSelected: selectedContentType == contentType,
                    onTap: {
                        selectedContentType = contentType
                        onTabSelected(contentType)
                    }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
        .background(
            Rectangle()
                .fill(TVOSDesign.Colors.background.opacity(0.95))
                .background(.ultraThinMaterial.opacity(0.5))
        )
        .accessibilityLabel(L10n.Search.searchTabs)
    }
}

// MARK: - Individual Tab

struct SearchTab: View {
    let contentType: SearchContentType
    let isSelected: Bool
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: contentType.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(contentType.displayName)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
            // Einziger Ring — innerer strokeBorder, keine Überlappung
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: TVOSDesign.Focus.borderWidth)
                    .allowsHitTesting(false)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? TVOSDesign.Colors.focusGlow : Color.clear,
                radius: isFocused ? TVOSDesign.Focus.shadowRadius : 0,
                y: isFocused ? 6 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        .animation(TVOSDesign.Animation.focusSpring, value: isSelected)
        .accessibilityLabel("\(contentType.displayName) Tab")
        .accessibilityValue(isSelected ? L10n.General.selected : "")
    }
    
    // MARK: - Computed Properties
    
    /// Ein einziger Ring: blau wenn ausgewählt+fokussiert, weiß wenn nur fokussiert, blau-dünn wenn nur ausgewählt
    private var borderColor: Color {
        if isFocused && isSelected {
            return TVOSDesign.Colors.accentBlue
        } else if isFocused {
            return TVOSDesign.Colors.focusBorder
        } else if isSelected {
            return TVOSDesign.Colors.accentBlue.opacity(0.6)
        }
        return Color.clear
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else if isSelected {
            return TVOSDesign.Colors.cardBackground
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected || isFocused {
            return TVOSDesign.Colors.primaryLabel
        } else {
            return TVOSDesign.Colors.secondaryLabel
        }
    }
    
    private var iconColor: Color {
        if isSelected {
            return TVOSDesign.Colors.accentBlue
        } else if isFocused {
            return TVOSDesign.Colors.primaryLabel
        } else {
            return TVOSDesign.Colors.secondaryLabel
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var selectedType: SearchContentType = .web
        
        var body: some View {
            ZStack {
                TVOSDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Search Tab Bar")
                        .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    SearchTabBar(
                        selectedContentType: $selectedType,
                        onTabSelected: { type in
                        },
                        hasWikipediaInfo: true
                    )
                    
                    Text("Ausgewählt: \(selectedType.displayName)")
                        .font(.system(size: TVOSDesign.Typography.body))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    return PreviewContainer()
}
