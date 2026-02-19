//
//  FullscreenTextViewer.swift
//  AppleTVBrowser
//
//  Fullscreen Text Viewer für vergrößerte Text-Anzeige
//

import SwiftUI

struct FullscreenTextViewer: View {
    let title: String
    let text: String
    @Binding var isPresented: Bool
    
    @FocusState private var isFocused: Bool
    @State private var scrollPosition: CGPoint = .zero
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
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
                                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                                    .fill(TVOSDesign.Colors.cardBackground)
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
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Zurück")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                }
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(TVOSDesign.Colors.cardBackground)
                )
                .scaleEffect(backButtonPressed ? TVOSDesign.Focus.pressScale : (backButtonFocused ? TVOSDesign.Focus.scale : 1.0))
                .shadow(
                    color: Color.black.opacity(backButtonFocused ? 0.4 : 0),
                    radius: backButtonFocused ? 16 : 0,
                    y: backButtonFocused ? 8 : 0
                )
            }
            .buttonStyle(PlainButtonStyle())
            .focused($backButtonFocused)
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    backButtonPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        backButtonPressed = false
                        isPresented = false
                    }
                }
            }
            .animation(TVOSDesign.Animation.focusSpring, value: backButtonFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: backButtonPressed)
            
            Spacer()
            
            // Titel
            Text(title)
                .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Placeholder für symmetrisches Layout
            Color.clear
                .frame(width: 120, height: 56)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
        .padding(.bottom, TVOSDesign.Spacing.elementSpacing)
        .background(
            TVOSDesign.Colors.background
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Focus States
    @FocusState private var backButtonFocused: Bool
    @State private var backButtonPressed: Bool = false
}

// MARK: - Preview

#Preview {
    FullscreenTextViewer(
        title: "Wikipedia Artikel",
        text: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        
        Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.
        
        Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
        """,
        isPresented: .constant(true)
    )
}