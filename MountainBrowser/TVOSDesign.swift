//
//  TVOSDesign.swift
//  MountainBrowser
//
//  Design System für tvOS Browser — Glasmorphes Design
//

import SwiftUI

// MARK: - TVOSDesign System
struct TVOSDesign {
    
    // MARK: - Theme Detection Helper
    private static var isPremiumTheme: Bool {
        UserDefaults.standard.bool(forKey: "browser.usePremiumTheme")
    }
    
    // MARK: - Colors
    struct Colors {
        
        // --- Dynamische Hintergrund-Farben (reagieren auf Premium Theme) ---
        static var background: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.10, green: 0.07, blue: 0.03)    // Warmes Dunkelbraun
                : Color(red: 0.06, green: 0.06, blue: 0.08)     // Kühles Schwarz (Standard)
        }
        static var secondaryBackground: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.14, green: 0.10, blue: 0.05)
                : Color(red: 0.10, green: 0.10, blue: 0.12)
        }
        static var tertiaryBackground: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.18, green: 0.14, blue: 0.08)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
        }
        
        static let cardBackground = Color.white.opacity(0.03)
        static let cardBackgroundHover = Color.white.opacity(0.08)
        static let focusedCardBackground = Color.white.opacity(0.18)
        static let pressedCardBackground = Color.white.opacity(0.06)
        
        // --- Dynamische Label-Farben ---
        static var primaryLabel: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 1.0, green: 0.97, blue: 0.92)      // Warmes Weiß
                : Color.white
        }
        static var primaryText: Color { primaryLabel }
        static var secondaryLabel: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.78, green: 0.72, blue: 0.62)     // Warmes Grau
                : Color(white: 0.7)
        }
        static var secondaryText: Color { secondaryLabel }
        static var tertiaryLabel: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.52, green: 0.46, blue: 0.38)     // Warmes Dunkelgrau
                : Color(white: 0.45)
        }
        
        // --- Dynamische Akzentfarben ---
        static var accent: Color { accentBlue }
        static var accentBlue: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.95, green: 0.75, blue: 0.28)     // Warmes Gold/Amber
                : Color(red: 0.25, green: 0.52, blue: 1.0)      // Kühles Blau
        }
        static let accentOrange = Color.orange
        
        // --- Dynamische System-Farben ---
        static var systemBlue: Color { accentBlue }
        static let systemGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
        static let systemRed = Color(red: 1.0, green: 0.27, blue: 0.23)
        static let systemOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
        static let systemYellow = Color(red: 1.0, green: 0.84, blue: 0.04)
        static var systemPurple: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.82, green: 0.48, blue: 0.35)     // Warmes Terracotta
                : Color(red: 0.69, green: 0.32, blue: 0.87)
        }
        static let systemPink = Color(red: 1.0, green: 0.22, blue: 0.37)
        static var systemTeal: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.72, green: 0.62, blue: 0.45)     // Warmes Sand
                : Color(red: 0.35, green: 0.78, blue: 0.85)
        }
        static var systemIndigo: Color {
            TVOSDesign.isPremiumTheme
                ? Color(red: 0.65, green: 0.42, blue: 0.28)     // Warmes Kupfer
                : Color(red: 0.35, green: 0.34, blue: 0.84)
        }
        
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
        static let error = Color(red: 1.0, green: 0.27, blue: 0.23)
        static let warning = Color(red: 1.0, green: 0.62, blue: 0.04)
        
        static let separator = Color.white.opacity(0.06)
        static var focusHighlight: Color { accentBlue.opacity(0.35) }
        static var focusGlow: Color { accentBlue.opacity(0.45) }
        static let focusBorder = Color.white.opacity(0.6)
        static let cardGlow = Color.white.opacity(0.25)
        static var navbarBackground: Color { background }
        
        // Glasmorphe Karten-Farben
        static let glassBackground = Color.white.opacity(0.03)
        static let glassBorder = Color.white.opacity(0.05)
        static let glassBackgroundHover = Color.white.opacity(0.18)
        static let glassBorderHover = Color.white.opacity(0.25)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let safeAreaHorizontal: CGFloat = 90
        static let safeAreaVertical: CGFloat = 60
        static let safeAreaTop: CGFloat = 60
        static let safeAreaBottom: CGFloat = 60
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 40
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 24
        static let elementSpacing: CGFloat = 16
        static let gridSpacing: CGFloat = 24
        static let gridHorizontalSpacing: CGFloat = 24
        static let gridVerticalSpacing: CGFloat = 24
        static let standardTouchTarget: CGFloat = 66
        static let minTouchTarget: CGFloat = 56
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle: CGFloat = 48
        static let title1: CGFloat = 38
        static let title2: CGFloat = 34
        static let title3: CGFloat = 29
        static let titleSize: CGFloat = 38
        static let headline: CGFloat = 26
        static let subheadline: CGFloat = 24
        static let subtitleSize: CGFloat = 29
        static let body: CGFloat = 24
        static let bodySize: CGFloat = 24
        static let callout: CGFloat = 22
        static let footnote: CGFloat = 20
        static let smallSize: CGFloat = 20
        static let caption: CGFloat = 17
        static let captionSize: CGFloat = 17
    }
    
    // MARK: - CornerRadius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 30
        static let pill: CGFloat = 100
    }
    
    // MARK: - Focus
    struct Focus {
        static let scale: CGFloat = 1.03
        static let cardScale: CGFloat = 1.03
        static let pressScale: CGFloat = 0.97
        static let cardLiftOffset: CGFloat = 6
        static let cornerRadius: CGFloat = 16
        static let glowRadius: CGFloat = 24
        static let shadowRadius: CGFloat = 20
        static let borderWidth: CGFloat = 2.0
    }
    
    // MARK: - Animation
    struct Animation {
        static let standard: Double = 0.25
        static let fast: Double = 0.15
        static let slow: Double = 0.4
        static let focusSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let pressSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.2)
        static let medium = Color.black.opacity(0.3)
        static let heavy = Color.black.opacity(0.5)
    }
}

// MARK: - Transparent Button Style (suppresses tvOS focus highlight)

struct TransparentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - Glassmorphic Background View

struct GlassmorphicBackground: View {
    @State private var animateBackground: Bool = false
    var primaryColor: Color = TVOSDesign.Colors.accentBlue
    var secondaryColor: Color = TVOSDesign.Colors.systemPurple
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryColor.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)
                .offset(
                    x: animateBackground ? -200 : -300,
                    y: animateBackground ? -100 : -200
                )
                .blur(radius: 80)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [secondaryColor.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(
                    x: animateBackground ? 300 : 200,
                    y: animateBackground ? 200 : 300
                )
                .blur(radius: 60)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let isFocused: Bool
    var cornerRadius: CGFloat = TVOSDesign.CornerRadius.large
    var accentColor: Color = TVOSDesign.Colors.accentBlue
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isFocused ? Color.white.opacity(0.18) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ? accentColor.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(
                color: isFocused ? accentColor.opacity(0.25) : Color.clear,
                radius: isFocused ? 24 : 0,
                y: isFocused ? 10 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - Section Label

struct GlassSectionLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.accentBlue)
            
            Text(title)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                .tracking(2.0)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
    }
}

// MARK: - Focus Modifier für KLEINE Buttons/Controls
/// Einheitlicher Glasmorph-Fokus-Stil — hochkontrastreicher farbiger Akzent-Rand.
struct TVOSFocusModifier: ViewModifier {
    let isFocused: Bool
    let isPressed: Bool
    var cornerRadius: CGFloat = TVOSDesign.Focus.cornerRadius
    var useLift: Bool = true
    var accentColor: Color? = nil
    
    private var effectiveAccentColor: Color {
        accentColor ?? TVOSDesign.Colors.accentBlue
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ? effectiveAccentColor.opacity(0.7) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
                    .allowsHitTesting(false)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .offset(y: useLift && isFocused ? -TVOSDesign.Focus.cardLiftOffset : 0)
            .shadow(
                color: isFocused ? effectiveAccentColor.opacity(0.25) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: isFocused ? 8 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - Glow Modifier für GROSSE Kacheln/Cards
struct TVOSCardGlowModifier: ViewModifier {
    let isFocused: Bool
    let isPressed: Bool
    var glowColor: Color = TVOSDesign.Colors.accentBlue
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.cardScale : 1.0))
            .shadow(
                color: isFocused ? glowColor.opacity(0.3) : Color.clear,
                radius: isFocused ? TVOSDesign.Focus.glowRadius : 0,
                y: 0
            )
            .shadow(
                color: isFocused ? Color.black.opacity(0.5) : Color.black.opacity(0.15),
                radius: isFocused ? 20 : 6,
                y: isFocused ? 8 : 3
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func tvOSCard() -> some View {
        self
            .background(TVOSDesign.Colors.cardBackground)
            .cornerRadius(TVOSDesign.CornerRadius.medium)
    }
    
    func tvOSFocusable(isFocused: Bool) -> some View {
        self
            .scaleEffect(isFocused ? TVOSDesign.Focus.scale : 1.0)
            .shadow(color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.35) : .clear, radius: 14)
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    func tvOSFocusEffect(
        isFocused: Bool,
        isPressed: Bool = false,
        cornerRadius: CGFloat = TVOSDesign.Focus.cornerRadius,
        useLift: Bool = true,
        accentColor: Color? = nil
    ) -> some View {
        self.modifier(
            TVOSFocusModifier(
                isFocused: isFocused,
                isPressed: isPressed,
                cornerRadius: cornerRadius,
                useLift: useLift,
                accentColor: accentColor
            )
        )
    }
    
    func tvOSCardGlow(
        isFocused: Bool,
        isPressed: Bool = false,
        glowColor: Color = TVOSDesign.Colors.accentBlue
    ) -> some View {
        self.modifier(
            TVOSCardGlowModifier(
                isFocused: isFocused,
                isPressed: isPressed,
                glowColor: glowColor
            )
        )
    }
    
    func glassCard(isFocused: Bool, cornerRadius: CGFloat = TVOSDesign.CornerRadius.large, accentColor: Color = TVOSDesign.Colors.accentBlue) -> some View {
        self.modifier(GlassCardModifier(isFocused: isFocused, cornerRadius: cornerRadius, accentColor: accentColor))
    }
}
