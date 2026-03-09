//
//  FullscreenTextViewer.swift
//  MountainBrowser
//
//  Fullscreen Text Viewer für vergrößerte Text-Anzeige
//  Glasmorphes Design
//

import SwiftUI

struct FullscreenTextViewer: View {
    let title: String
    let text: String
    @Binding var isPresented: Bool
    
    @FocusState private var isFocused: Bool
    @FocusState private var backButtonFocused: Bool
    
    var body: some View {
        ZStack {
            GlassmorphicBackground()
            
            VStack(spacing: 0) {
                // Header mit Titel und Zurück-Button
                headerView
                
                // Scrollbarer Text
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: TVOSDesign.Spacing.cardSpacing) {
                        Text(text)
                            .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                            .foregroundColor(TVOSDesign.Colors.primaryLabel)
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                            .padding(TVOSDesign.Spacing.cardSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                    .fill(TVOSDesign.Colors.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                    .strokeBorder(TVOSDesign.Colors.glassBorder, lineWidth: 1)
                            )
                        
                        Spacer(minLength: TVOSDesign.Spacing.safeAreaBottom)
                    }
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
                }
                .focused($isFocused)
            }
        }
        .onAppear {
            isFocused = true
        }
        .onExitCommand {
            isPresented = false
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button
            Button(action: {
                isPresented = false
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                    Text(L10n.General.back)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                }
                .foregroundColor(backButtonFocused ? .white : TVOSDesign.Colors.secondaryLabel)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(backButtonFocused ? TVOSDesign.Colors.glassBackgroundHover : TVOSDesign.Colors.glassBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            backButtonFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : TVOSDesign.Colors.glassBorder,
                            lineWidth: backButtonFocused ? 1.5 : 1
                        )
                )
            }
            .buttonStyle(TransparentButtonStyle())
            .focused($backButtonFocused)
            .scaleEffect(backButtonFocused ? 1.04 : 1.0)
            .animation(TVOSDesign.Animation.focusSpring, value: backButtonFocused)
            
            Spacer()
            
            // Titel
            Text(title)
                .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Placeholder für symmetrisches Layout
            Color.clear
                .frame(width: 120, height: TVOSDesign.Spacing.minTouchTarget)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
        .padding(.bottom, TVOSDesign.Spacing.elementSpacing)
        .background(
            LinearGradient(
                colors: [
                    TVOSDesign.Colors.background.opacity(0.95),
                    TVOSDesign.Colors.background.opacity(0.8),
                    TVOSDesign.Colors.background.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Preview

#Preview {
    FullscreenTextViewer(
        title: "Wikipedia Artikel",
        text: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """,
        isPresented: .constant(true)
    )
}
