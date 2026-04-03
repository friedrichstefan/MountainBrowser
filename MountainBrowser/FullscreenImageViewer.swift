//
//  FullscreenImageViewer.swift
//  MountainBrowser
//
//  Fullscreen Image Viewer für vergrößerte Bild-Anzeige
//  Glasmorphes Design
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
    
    var body: some View {
        ZStack {
            GlassmorphicBackground()
            
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.accentBlue))
                                    .scaleEffect(2.0)
                                
                                Text(L10n.ImageViewer.imageLoading)
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
                                
                                Text(L10n.ImageViewer.imageLoadFailed)
                                    .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                
                                Text(L10n.Network.checkNetworkConnection)
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
                                Task {
                                    try? await Task.sleep(for: .seconds(10))
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
                        .font(.system(size: 24, weight: .semibold))
                    Text(L10n.General.back)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                }
                .foregroundColor(backButtonFocused ? .white : TVOSDesign.Colors.secondaryLabel)
                .padding(.horizontal, 32)
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
                        Text(L10n.Settings.reset)
                            .font(.system(size: TVOSDesign.Typography.footnote, weight: .semibold))
                    }
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(TVOSDesign.Colors.glassBackground)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(TVOSDesign.Colors.glassBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(TransparentButtonStyle())
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
            LinearGradient(
                colors: [
                    TVOSDesign.Colors.background.opacity(0.0),
                    TVOSDesign.Colors.background.opacity(0.8),
                    TVOSDesign.Colors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
