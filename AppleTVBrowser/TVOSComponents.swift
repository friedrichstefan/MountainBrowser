//
//  TVOSComponents.swift
//  AppleTVBrowser
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
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0),
                radius: TVOSDesign.Focus.shadowRadius,
                y: 8
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        .accessibilityLabel(title)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? Color.white.opacity(0.8) : Color.white
        case .secondary:
            return isPressed ? TVOSDesign.Colors.pressedCardBackground : TVOSDesign.Colors.cardBackground
        case .destructive:
            return isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.black
        case .secondary, .destructive:
            return TVOSDesign.Colors.primaryLabel
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -6 : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.3 : 0),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
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
                                    TVOSDesign.Colors.systemBlue.opacity(0.3),
                                    TVOSDesign.Colors.systemBlue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.systemBlue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1.0 : 0.6)
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? TVOSDesign.Colors.systemBlue : Color.clear,
                        lineWidth: isFocused ? 3 : 0
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.4 : 0.1),
                radius: isFocused ? TVOSDesign.Focus.shadowRadius : 8,
                y: isFocused ? 8 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        .accessibilityLabel("\(title). \(subtitle)")
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                    
                    Text("Video wird geladen...")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if let error = errorMessage {
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Video kann nicht abgespielt werden")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Zurück")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .accessibilityLabel("Videoplayer: \(title)")
    }
    
    private func loadVideo() {
        isLoading = true
        errorMessage = nil
        
        let urlString = url.absoluteString
        
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                isLoading = false
                errorMessage = "YouTube-Videos erfordern die YouTube-App oder einen Browser."
            }
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            isPresented = false
        }
        
        self.player = newPlayer
        isLoading = false
    }
}
