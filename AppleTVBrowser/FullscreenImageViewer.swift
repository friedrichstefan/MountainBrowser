//
//  FullscreenImageViewer.swift
//  AppleTVBrowser
//
//  Fullscreen Image Viewer für vergrößerte Bild-Anzeige
//

import SwiftUI

struct FullscreenImageViewer: View {
    let imageURL: String
    let title: String
    @Binding var isPresented: Bool
    
    @State private var imageLoaded: Bool = false
    @State private var imageError: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    @FocusState private var backButtonFocused: Bool
    @State private var backButtonPressed: Bool = false
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header mit Titel und Zurück-Button
                headerView
                
                // Bild-Container
                GeometryReader { geometry in
                    ZStack {
                        if !imageLoaded && !imageError {
                            // Loading State
                            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.primaryLabel))
                                    .scaleEffect(2.0)
                                
                                Text("Bild wird geladen...")
                                    .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if imageError {
                            // Error State
                            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 80))
                                    .foregroundColor(TVOSDesign.Colors.systemRed)
                                
                                Text("Bild konnte nicht geladen werden")
                                    .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                
                                Text("Überprüfen Sie Ihre Internetverbindung")
                                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Bild anzeigen (tvOS-optimiert ohne Gesten)
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .onAppear {
                                        withAnimation(.easeIn(duration: 0.3)) {
                                            imageLoaded = true
                                        }
                                    }
                                    // tvOS Focus-basierte Navigation
                                    .focusable()
                                    .onMoveCommand { direction in
                                        if scale > 1.0 {
                                            let moveDistance: CGFloat = 50
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                switch direction {
                                                case .up:
                                                    offset.height -= moveDistance
                                                case .down:
                                                    offset.height += moveDistance
                                                case .left:
                                                    offset.width -= moveDistance
                                                case .right:
                                                    offset.width += moveDistance
                                                @unknown default:
                                                    break
                                                }
                                                
                                                // Bounds checking
                                                let maxOffsetX = (geometry.size.width * (scale - 1)) / 4
                                                let maxOffsetY = (geometry.size.height * (scale - 1)) / 4
                                                
                                                offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                                                offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                                            }
                                        }
                                    }
                                    .onPlayPauseCommand {
                                        // Play/Pause Button zum Zoomen
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if scale > 1.0 {
                                                scale = 1.0
                                                offset = .zero
                                            } else {
                                                scale = 2.0
                                                offset = .zero
                                            }
                                        }
                                    }
                            } placeholder: {
                                Color.clear
                            }
                            .onAppear {
                                // Timeout für Bild-Laden
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                    if !imageLoaded {
                                        imageError = true
                                    }
                                }
                            }
                        }
                    }
                }
                .clipped()
                
                // Footer mit Zoom-Info (nur wenn Bild geladen)
                if imageLoaded && !imageError {
                    footerView
                }
            }
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
            
            // Reset Zoom Button (nur wenn gezoomt)
            if scale > 1.1 {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        scale = 1.0
                        offset = .zero
                    }
                    lastScale = 1.0
                    lastOffset = .zero
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Reset")
                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .semibold))
                    }
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Placeholder für symmetrisches Layout
                Color.clear
                    .frame(width: 120, height: 56)
            }
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.top, TVOSDesign.Spacing.safeAreaTop)
        .padding(.bottom, TVOSDesign.Spacing.elementSpacing)
        .background(
            TVOSDesign.Colors.background
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Footer View
    
    @ViewBuilder
    private var footerView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                Text("Zoom: \(Int(scale * 100))%")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                
                Text("Play/Pause zum Zoomen • Pfeiltasten zum Navigieren")
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            }
            
            Spacer()
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
        .background(
            TVOSDesign.Colors.background
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Preview

#Preview {
    FullscreenImageViewer(
        imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Mona_Lisa.jpg/396px-Mona_Lisa.jpg",
        title: "Wikipedia Bild",
        isPresented: .constant(true)
    )
}