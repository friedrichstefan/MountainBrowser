//
//  TVOSDesign.swift
//  AppleTVBrowser
//
//  Design System für tvOS Browser
//

import SwiftUI

// MARK: - TVOSDesign System
/// Zentrale Design-Konstanten und Farben für den tvOS Browser
struct TVOSDesign {
    
    // MARK: - Colors
    struct Colors {
        /// Primäre Hintergrundfarbe (dunkelgrau/schwarz)
        static let background = Color(red: 0.1, green: 0.1, blue: 0.1)
        
        /// Sekundärer Hintergrund (etwas heller)
        static let secondaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
        
        /// Tertiärer Hintergrund
        static let tertiaryBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
        
        /// Kartenfarbe
        static let cardBackground = Color(red: 0.18, green: 0.18, blue: 0.18)
        
        /// Fokussierte Kartenfarbe
        static let focusedCardBackground = Color(red: 0.25, green: 0.25, blue: 0.25)
        
        /// Gedrückte Kartenfarbe
        static let pressedCardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
        
        /// Primäre Textfarbe (Label)
        static let primaryLabel = Color.white
        static let primaryText = Color.white
        
        /// Sekundäre Textfarbe (Label)
        static let secondaryLabel = Color.gray
        static let secondaryText = Color.gray
        
        /// Tertiäre Textfarbe
        static let tertiaryLabel = Color(white: 0.5)
        
        /// Akzentfarbe
        static let accent = Color.blue
        static let accentBlue = Color.blue
        static let accentOrange = Color.orange
        
        /// System Colors
        static let systemBlue = Color.blue
        static let systemGreen = Color.green
        static let systemRed = Color.red
        static let systemOrange = Color.orange
        static let systemYellow = Color.yellow
        static let systemPurple = Color.purple
        static let systemPink = Color.pink
        static let systemTeal = Color.teal
        static let systemIndigo = Color.indigo
        
        /// Erfolgsfarbe
        static let success = Color.green
        
        /// Fehlerfarbe
        static let error = Color.red
        
        /// Warnfarbe
        static let warning = Color.orange
        
        /// Trennlinie
        static let separator = Color.white.opacity(0.1)
        
        /// Hover/Focus-Farbe
        static let focusHighlight = Color.blue.opacity(0.3)
        
        /// Focus Glow
        static let focusGlow = Color.blue.opacity(0.4)
    }
    
    // MARK: - Spacing
    struct Spacing {
        /// Standard Safe Area horizontal (für Navigation Bar etc.)
        static let safeAreaHorizontal: CGFloat = 90
        
        /// Standard Safe Area vertikal
        static let safeAreaVertical: CGFloat = 60
        
        /// Safe Area Top
        static let safeAreaTop: CGFloat = 60
        
        /// Safe Area Bottom
        static let safeAreaBottom: CGFloat = 60
        
        /// Kleine Abstände
        static let small: CGFloat = 8
        
        /// Mittlere Abstände
        static let medium: CGFloat = 16
        
        /// Große Abstände
        static let large: CGFloat = 24
        
        /// Extra große Abstände
        static let extraLarge: CGFloat = 40
        
        /// Standard Card-Padding
        static let cardPadding: CGFloat = 20
        
        /// Card Spacing
        static let cardSpacing: CGFloat = 24
        
        /// Element Spacing
        static let elementSpacing: CGFloat = 16
        
        /// Grid-Spacing
        static let gridSpacing: CGFloat = 24
        
        /// Grid Horizontal Spacing
        static let gridHorizontalSpacing: CGFloat = 24
        
        /// Grid Vertical Spacing
        static let gridVerticalSpacing: CGFloat = 24
        
        /// Standard Touch Target (tvOS HIG)
        static let standardTouchTarget: CGFloat = 66
        
        /// Minimum Touch Target (tvOS HIG)
        static let minTouchTarget: CGFloat = 56
    }
    
    // MARK: - Typography
    struct Typography {
        /// Large Title
        static let largeTitle: CGFloat = 48
        
        /// Title 1
        static let title1: CGFloat = 38
        
        /// Title 2
        static let title2: CGFloat = 34
        
        /// Title 3
        static let title3: CGFloat = 29
        
        /// Titel-Schriftgröße (alias)
        static let titleSize: CGFloat = 38
        
        /// Headline
        static let headline: CGFloat = 26
        
        /// Subheadline
        static let subheadline: CGFloat = 24
        
        /// Untertitel-Schriftgröße (alias)
        static let subtitleSize: CGFloat = 29
        
        /// Body-Schriftgröße
        static let body: CGFloat = 24
        static let bodySize: CGFloat = 24
        
        /// Callout
        static let callout: CGFloat = 22
        
        /// Footnote
        static let footnote: CGFloat = 20
        
        /// Small-Schriftgröße
        static let smallSize: CGFloat = 20
        
        /// Caption
        static let caption: CGFloat = 17
        
        /// Caption-Schriftgröße (alias)
        static let captionSize: CGFloat = 17
    }
    
    // MARK: - CornerRadius
    struct CornerRadius {
        /// Kleine Eckenradius
        static let small: CGFloat = 8
        
        /// Mittlerer Eckenradius
        static let medium: CGFloat = 12
        
        /// Großer Eckenradius
        static let large: CGFloat = 20
        
        /// Extra großer Eckenradius
        static let extraLarge: CGFloat = 30
        
        /// Runder Button
        static let pill: CGFloat = 100
    }
    
    // MARK: - Focus
    struct Focus {
        /// Standard Scale bei Focus
        static let scale: CGFloat = 1.05
        
        /// Press Scale
        static let pressScale: CGFloat = 0.95
        
        /// Card Lift Offset
        static let cardLiftOffset: CGFloat = 10
        
        /// Corner Radius für Focus
        static let cornerRadius: CGFloat = 16
        
        /// Shadow Radius
        static let shadowRadius: CGFloat = 20
    }
    
    // MARK: - Animation
    struct Animation {
        /// Standard-Animationsdauer
        static let standard: Double = 0.25
        
        /// Schnelle Animation
        static let fast: Double = 0.15
        
        /// Langsame Animation
        static let slow: Double = 0.4
        
        /// Focus Spring Animation
        static let focusSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// Press Spring Animation
        static let pressSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)
    }
    
    // MARK: - Shadows
    struct Shadows {
        /// Leichter Schatten
        static let light = Color.black.opacity(0.2)
        
        /// Mittlerer Schatten
        static let medium = Color.black.opacity(0.3)
        
        /// Starker Schatten
        static let heavy = Color.black.opacity(0.5)
    }
}

// MARK: - View Extensions
extension View {
    /// Standard Card-Styling für tvOS
    func tvOSCard() -> some View {
        self
            .background(TVOSDesign.Colors.cardBackground)
            .cornerRadius(TVOSDesign.CornerRadius.medium)
    }
    
    /// Focus-Styling für tvOS
    func tvOSFocusable(isFocused: Bool) -> some View {
        self
            .scaleEffect(isFocused ? TVOSDesign.Focus.scale : 1.0)
            .shadow(color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : .clear, radius: 10)
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}