//
//  SearchTabBar.swift
//  AppleTVBrowser
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
        .accessibilityLabel("Such-Tabs")
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
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? TVOSDesign.Colors.accentBlue : Color.clear,
                        lineWidth: 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isFocused ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: isFocused && isSelected ? 4 : 3
                    )
            )
            .scaleEffect(
                isPressed ? 0.95 : (isFocused ? 1.05 : 1.0)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .accessibilityLabel("\(contentType.displayName) Tab")
        .accessibilityValue(isSelected ? "Ausgewählt" : "")
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isPressed {
            return isSelected
                ? TVOSDesign.Colors.pressedCardBackground
                : TVOSDesign.Colors.cardBackground.opacity(0.8)
        } else if isFocused {
            return isSelected
                ? TVOSDesign.Colors.focusedCardBackground
                : TVOSDesign.Colors.focusedCardBackground.opacity(0.7)
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
    
    private var shadowColor: Color {
        if isFocused {
            return Color.black.opacity(0.4)
        } else if isSelected {
            return Color.black.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 16 : (isSelected ? 8 : 0)
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 8 : (isSelected ? 4 : 0)
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
                            print("Tab selected: \(type.displayName)")
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
