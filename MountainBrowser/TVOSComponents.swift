//
//  TVOSComponents.swift
//  MountainBrowser
//
//  Wiederverwendbare tvOS UI-Komponenten (aus MainBrowserView extrahiert)
//

import SwiftUI
import AVKit

// MARK: - tvOS Button Component

struct TVOSButton: View {
    let title: String
    let icon: String
    let style: TVOSButtonStyle
    let action: () -> Void
    
    enum TVOSButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 44)
            .padding(.vertical, 20)
            .frame(minWidth: TVOSDesign.Spacing.standardTouchTarget,
                   minHeight: TVOSDesign.Spacing.standardTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .strokeBorder(
                        isFocused ? focusBorderColor.opacity(0.5) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? focusBorderColor.opacity(0.2) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: isFocused ? 6 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .accessibilityLabel(title)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? TVOSDesign.Colors.accentBlue.opacity(0.8) : TVOSDesign.Colors.accentBlue.opacity(0.9)
        case .secondary:
            return isPressed ? TVOSDesign.Colors.pressedCardBackground : TVOSDesign.Colors.cardBackground
        case .destructive:
            return isPressed ? TVOSDesign.Colors.systemRed.opacity(0.8) : TVOSDesign.Colors.systemRed.opacity(0.9)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel
        case .destructive:
            return .white
        }
    }
    
    private var focusBorderColor: Color {
        switch style {
        case .primary:
            return Color.white
        case .secondary:
            return TVOSDesign.Colors.accentBlue
        case .destructive:
            return Color.white
        }
    }
}

// MARK: - tvOS Chip Button Component

struct TVOSChipButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
            }
            .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: isFocused ? 6 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .accessibilityLabel(title)
    }
}

// MARK: - tvOS Settings Button Component

struct TVOSSettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    TVOSDesign.Colors.accentBlue.opacity(0.3),
                                    TVOSDesign.Colors.accentBlue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.accentBlue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.tertiaryLabel)
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: isFocused ? 6 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Native Video Player View

struct NativeVideoPlayerView: View {
    let url: URL
    let title: String
    @Binding var isPresented: Bool
    
    @State private var player: AVPlayer?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    @State private var endOfVideoObserver: NSObjectProtocol?
    @State private var errorObserver: NSObjectProtocol?
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if isLoading {
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.accentBlue))
                        .scaleEffect(2.0)
                    
                    Text("Video wird geladen...")
                        .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.footnote))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if let error = errorMessage {
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(TVOSDesign.Colors.systemOrange)
                    
                    Text("Video kann nicht abgespielt werden")
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    Text(error)
                        .font(.system(size: TVOSDesign.Typography.footnote))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    TVOSButton(title: "Zurück", icon: "chevron.left", style: .primary) {
                        isPresented = false
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onExitCommand {
            isPresented = false
        }
        .accessibilityLabel("Videoplayer: \(title)")
    }
    
    private func loadVideo() {
        isLoading = true
        errorMessage = nil
        
        let urlString = url.absoluteString
        let directVideoExtensions = [".mp4", ".m3u8", ".mov", ".ts", ".webm"]
        let isDirectVideo = directVideoExtensions.contains(where: { urlString.lowercased().contains($0) })
        
        if isDirectVideo {
            setupPlayer(with: url)
            return
        }
        
        isLoading = false
        errorMessage = "Dieses Video kann nicht direkt abgespielt werden.\n\nÖffne es im Browser, um es anzuschauen."
    }
    
    private func setupPlayer(with videoURL: URL) {
        let playerItem = AVPlayerItem(url: videoURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        endOfVideoObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            isPresented = false
        }
        
        errorObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            errorMessage = error?.localizedDescription ?? "Unbekannter Wiedergabefehler"
            player?.pause()
        }
        
        self.player = newPlayer
        isLoading = false
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        
        if let observer = endOfVideoObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = errorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        endOfVideoObserver = nil
        errorObserver = nil
    }
}
