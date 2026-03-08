//
//  BrowserSettingsView.swift
//  MountainBrowser
//
//  Einstellungsmenü im modernen glasmorphen Design für Browser-Konfiguration
//

import SwiftUI

// TransparentButtonStyle is defined in TVOSDesign.swift — no need to redeclare here.

struct BrowserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sessionManager: SessionManager
    @FocusState private var focusedItem: SettingsItem?
    
    @State private var animateBackground: Bool = false
    @State private var showAbout: Bool = false
    
    enum SettingsItem: Hashable {
        case backButton
        case viewMode(BrowserViewMode)
        case javaScript
        case cookies
        case popups
        case navigation
        case reset
        case about
    }
    
    init(sessionManager: SessionManager) {
        self._sessionManager = ObservedObject(wrappedValue: sessionManager)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 60) {
                    headerSection
                    viewModeSection
                    webSettingsSection
                    footerSection
                    Spacer(minLength: TVOSDesign.Spacing.safeAreaBottom + 80)
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.top, TVOSDesign.Spacing.safeAreaTop)
            }
            .scrollClipDisabled()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
        .onExitCommand {
            dismiss()
        }
        .fullScreenCover(isPresented: $showAbout) {
            AboutAppView()
        }
    }
    
    // MARK: - Animierter Hintergrund
    
    private var backgroundView: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            backgroundOrb(
                color: TVOSDesign.Colors.accentBlue,
                opacity: 0.08,
                size: 800,
                endRadius: 400,
                offsetX: animateBackground ? -200 : -300,
                offsetY: animateBackground ? -100 : -200,
                blur: 80
            )
            
            backgroundOrb(
                color: TVOSDesign.Colors.systemPurple,
                opacity: 0.06,
                size: 700,
                endRadius: 350,
                offsetX: animateBackground ? 300 : 200,
                offsetY: animateBackground ? 200 : 300,
                blur: 60
            )
        }
        .ignoresSafeArea()
    }
    
    private func backgroundOrb(color: Color, opacity: Double, size: CGFloat, endRadius: CGFloat, offsetX: CGFloat, offsetY: CGFloat, blur: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: endRadius
                )
            )
            .frame(width: size, height: size)
            .offset(x: offsetX, y: offsetY)
            .blur(radius: blur)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 24) {
            headerBackButton
            Spacer()
            headerTitle
        }
    }
    
    private var headerBackButton: some View {
        let isFocused = focusedItem == .backButton
        return Button(action: { dismiss() }) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                Text("Zurück")
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
            }
            .foregroundColor(isFocused ? .white : TVOSDesign.Colors.secondaryLabel)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(isFocused ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.7) : Color.clear,
                        lineWidth: 2.0
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .backButton)
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.25) : Color.clear,
            radius: isFocused ? 16 : 0,
            y: isFocused ? 6 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: focusedItem)
    }
    
    private var headerTitle: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Einstellungen")
                .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text("Browser konfigurieren")
                .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
        }
    }
    
    // MARK: - View Mode Section
    
    private var viewModeSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: "ANSICHTSMODUS", icon: "rectangle.split.3x1")
            
            HStack(spacing: 24) {
                ForEach(BrowserViewMode.allCases, id: \.self) { mode in
                    SettingsViewModeCard(
                        mode: mode,
                        isSelected: sessionManager.preferences.viewMode == mode,
                        isFocused: focusedItem == .viewMode(mode),
                        onSelect: {
                            withAnimation(TVOSDesign.Animation.focusSpring) {
                                sessionManager.preferences.viewMode = mode
                                sessionManager.savePreferences()
                            }
                        }
                    )
                    .focused($focusedItem, equals: .viewMode(mode))
                }
            }
        }
    }
    
    // MARK: - Web Settings Section
    
    private var webSettingsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: "WEB-EINSTELLUNGEN", icon: "globe")
            
            VStack(spacing: 2) {
                settingsToggleRow(
                    title: "JavaScript",
                    subtitle: "Interaktive Web-Inhalte aktivieren",
                    icon: "swift",
                    iconColor: TVOSDesign.Colors.systemOrange,
                    isOn: sessionManager.preferences.enableJavaScript,
                    focusItem: .javaScript,
                    position: .top
                ) {
                    sessionManager.preferences.enableJavaScript.toggle()
                    sessionManager.savePreferences()
                }
                
                settingsToggleRow(
                    title: "Cookies",
                    subtitle: "Website-Einstellungen speichern",
                    icon: "server.rack",
                    iconColor: TVOSDesign.Colors.systemTeal,
                    isOn: sessionManager.preferences.enableCookies,
                    focusItem: .cookies,
                    position: .middle
                ) {
                    sessionManager.preferences.enableCookies.toggle()
                    sessionManager.savePreferences()
                }
                
                settingsToggleRow(
                    title: "Pop-up Blocker",
                    subtitle: "Unerwünschte Fenster blockieren",
                    icon: "shield.lefthalf.filled",
                    iconColor: TVOSDesign.Colors.systemGreen,
                    isOn: sessionManager.preferences.blockPopups,
                    focusItem: .popups,
                    position: .middle
                ) {
                    sessionManager.preferences.blockPopups.toggle()
                    sessionManager.savePreferences()
                }
                
                settingsToggleRow(
                    title: "Navigation",
                    subtitle: "URL-Leiste und Bedienelemente anzeigen",
                    icon: "safari",
                    iconColor: TVOSDesign.Colors.accentBlue,
                    isOn: sessionManager.preferences.showTopNavigation,
                    focusItem: .navigation,
                    position: .bottom
                ) {
                    sessionManager.preferences.showTopNavigation.toggle()
                    sessionManager.savePreferences()
                }
            }
        }
    }
    
    // MARK: - Row Position
    
    private enum RowPosition {
        case top, middle, bottom, single
        
        var topRadius: CGFloat {
            switch self {
            case .top, .single: return 20
            default: return 4
            }
        }
        
        var bottomRadius: CGFloat {
            switch self {
            case .bottom, .single: return 20
            default: return 4
            }
        }
    }
    
    // MARK: - Settings Toggle Row
    
    private func settingsToggleRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isOn: Bool,
        focusItem: SettingsItem,
        position: RowPosition,
        onToggle: @escaping () -> Void
    ) -> some View {
        let isFocused = focusedItem == focusItem
        
        return Button(action: {
            withAnimation(TVOSDesign.Animation.focusSpring) {
                onToggle()
            }
        }) {
            SettingsToggleRowContent(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconColor: iconColor,
                isOn: isOn,
                isFocused: isFocused,
                topRadius: position.topRadius,
                bottomRadius: position.bottomRadius
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: focusItem)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isOn)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 24) {
            sectionLabel(title: "AKTIONEN", icon: "slider.horizontal.3")
            
            HStack(spacing: 24) {
                resetButton
                    .frame(maxWidth: .infinity)
                
                aboutButton
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        let isFocused = focusedItem == .reset
        
        return Button(action: {
            withAnimation(TVOSDesign.Animation.focusSpring) {
                sessionManager.preferences = BrowserPreferences()
                sessionManager.savePreferences()
            }
        }) {
            SettingsActionRowContent(
                title: "Zurücksetzen",
                subtitle: "Alle Einstellungen auf Standard",
                icon: "arrow.counterclockwise",
                iconColor: TVOSDesign.Colors.systemRed,
                isFocused: isFocused,
                showChevron: true
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .reset)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemRed.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - About Button
    
    private var aboutButton: some View {
        let isFocused = focusedItem == .about
        
        return Button(action: {
            showAbout = true
        }) {
            SettingsActionRowContent(
                title: "Über diese App",
                subtitle: "Info, Version & Credits",
                icon: "info.circle",
                iconColor: TVOSDesign.Colors.systemIndigo,
                isFocused: isFocused,
                showChevron: true
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .about)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemIndigo.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Section Label
    
    private func sectionLabel(title: String, icon: String) -> some View {
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

// MARK: - About App View (Fullscreen)

private struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedItem: AboutFocusItem?
    
    enum AboutFocusItem: Hashable {
        case backButton
        case featureCard(Int)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 50) {
                    aboutHeader
                    featuresSection
                    technicalSection
                    legalSection
                    Spacer(minLength: TVOSDesign.Spacing.safeAreaBottom + 80)
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.top, TVOSDesign.Spacing.safeAreaTop)
            }
            .scrollClipDisabled()
        }
        .onExitCommand {
            dismiss()
        }
    }
    
    // MARK: - Header
    
    private var aboutHeader: some View {
        VStack(spacing: 28) {
            // Zurück
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                        Text("Einstellungen")
                            .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                    }
                    .foregroundColor(focusedItem == .backButton ? .white : TVOSDesign.Colors.secondaryLabel)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(focusedItem == .backButton ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                focusedItem == .backButton ? TVOSDesign.Colors.accentBlue.opacity(0.7) : Color.clear,
                                lineWidth: 2.0
                            )
                    )
                }
                .buttonStyle(TransparentButtonStyle())
                .focused($focusedItem, equals: .backButton)
                .scaleEffect(focusedItem == .backButton ? 1.04 : 1.0)
                .shadow(
                    color: focusedItem == .backButton ? TVOSDesign.Colors.accentBlue.opacity(0.25) : Color.clear,
                    radius: focusedItem == .backButton ? 16 : 0,
                    y: focusedItem == .backButton ? 6 : 0
                )
                .animation(TVOSDesign.Animation.focusSpring, value: focusedItem)
                
                Spacer()
            }
            
            // App Icon + Name
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TVOSDesign.Colors.accentBlue,
                                    TVOSDesign.Colors.systemIndigo,
                                    TVOSDesign.Colors.systemPurple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: TVOSDesign.Colors.accentBlue.opacity(0.3), radius: 30, y: 10)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Mountain Browser")
                        .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    
                    Text("Für Apple TV entwickelt")
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSectionLabel(title: "FUNKTIONEN", icon: "sparkles")
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ],
                spacing: 20
            ) {
                AboutFeatureCard(
                    icon: "cursorarrow.click.2",
                    title: "Cursor-Modus",
                    description: "Navigiere wie mit einer Maus durch Webseiten",
                    color: TVOSDesign.Colors.accentBlue,
                    isFocused: focusedItem == .featureCard(0)
                )
                .focused($focusedItem, equals: .featureCard(0))
                
                AboutFeatureCard(
                    icon: "scroll",
                    title: "Scroll-Modus",
                    description: "Natives tvOS Scrolling mit der Siri Remote",
                    color: TVOSDesign.Colors.systemTeal,
                    isFocused: focusedItem == .featureCard(1)
                )
                .focused($focusedItem, equals: .featureCard(1))
                
                AboutFeatureCard(
                    icon: "magnifyingglass",
                    title: "Web-Suche",
                    description: "Suche im Internet mit integrierten Ergebnissen",
                    color: TVOSDesign.Colors.systemGreen,
                    isFocused: focusedItem == .featureCard(2)
                )
                .focused($focusedItem, equals: .featureCard(2))
                
                AboutFeatureCard(
                    icon: "book.closed.fill",
                    title: "Wikipedia",
                    description: "Integrierte Wikipedia-Infos zu deiner Suche",
                    color: TVOSDesign.Colors.systemIndigo,
                    isFocused: focusedItem == .featureCard(3)
                )
                .focused($focusedItem, equals: .featureCard(3))
                
                AboutFeatureCard(
                    icon: "rectangle.stack",
                    title: "Tab-Verwaltung",
                    description: "Mehrere Tabs gleichzeitig öffnen und verwalten",
                    color: TVOSDesign.Colors.systemOrange,
                    isFocused: focusedItem == .featureCard(4)
                )
                .focused($focusedItem, equals: .featureCard(4))
                
                AboutFeatureCard(
                    icon: "photo.on.rectangle",
                    title: "Bilder & Videos",
                    description: "Bild- und Video-Ergebnisse in eigenen Tabs",
                    color: TVOSDesign.Colors.systemPink,
                    isFocused: focusedItem == .featureCard(5)
                )
                .focused($focusedItem, equals: .featureCard(5))
            }
        }
    }
    
    // MARK: - Technical Section
    
    private var technicalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSectionLabel(title: "TECHNISCHE DETAILS", icon: "cpu")
            
            VStack(spacing: 1) {
                aboutInfoRow(label: "Plattform", value: "tvOS", icon: "tv")
                aboutInfoRow(label: "Framework", value: "SwiftUI", icon: "swift")
                aboutInfoRow(label: "Minimum tvOS", value: "17.0", icon: "gearshape.2")
                aboutInfoRow(label: "Rendering", value: "UIWebView", icon: "globe")
                aboutInfoRow(label: "Datenspeicherung", value: "SwiftData (lokal)", icon: "internaldrive")
                aboutInfoRow(label: "Cloud-Sync", value: "Deaktiviert", icon: "icloud.slash")
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func aboutInfoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.accentBlue)
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            
            Spacer()
            
            Text(value)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSectionLabel(title: "RECHTLICHES", icon: "doc.text")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Diese App ist ein unabhängiges Projekt und steht in keiner Verbindung zu Apple Inc. Apple, Apple TV, tvOS und Safari sind eingetragene Marken der Apple Inc.")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineSpacing(4)
                
                Text("Suchergebnisse werden über externe APIs bereitgestellt. Wikipedia-Inhalte unterliegen der Creative Commons Lizenz (CC BY-SA 3.0).")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineSpacing(4)
                
                Text("© 2025 Mountain Browser")
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Section Label
    
    private func aboutSectionLabel(title: String, icon: String) -> some View {
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

// MARK: - About Feature Card

private struct AboutFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                
                Text(description)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(height: 52)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isFocused ? Color.white.opacity(0.18) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isFocused ? color.opacity(0.7) : Color.white.opacity(0.05),
                    lineWidth: isFocused ? 2.0 : 1
                )
        )
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .shadow(
            color: isFocused ? color.opacity(0.25) : Color.clear,
            radius: isFocused ? 20 : 0,
            y: isFocused ? 8 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - View Mode Card (Extracted)

private struct SettingsViewModeCard: View {
    let mode: BrowserViewMode
    let isSelected: Bool
    let isFocused: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 20) {
                modeIcon
                modeLabels
                modeIndicator
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .overlay(cardBorder)
        }
        .buttonStyle(TransparentButtonStyle())
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .shadow(
            color: focusShadowColor,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isSelected)
    }
    
    private var modeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(iconGradient)
                .frame(width: 100, height: 100)
            
            Image(systemName: iconName)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(isSelected ? .white : TVOSDesign.Colors.secondaryLabel)
        }
    }
    
    private var modeLabels: some View {
        VStack(spacing: 8) {
            Text(mode.displayName)
                .font(.system(size: TVOSDesign.Typography.headline, weight: .bold))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
            
            Text(mode.description)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 40)
        }
    }
    
    private var modeIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? TVOSDesign.Colors.systemGreen : Color.white.opacity(0.15))
            
            Text(isSelected ? "Aktiv" : "Wählen")
                .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
                .foregroundColor(isSelected ? TVOSDesign.Colors.systemGreen : TVOSDesign.Colors.tertiaryLabel)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(backgroundFill)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(borderColor, lineWidth: borderWidth)
    }
    
    private var iconName: String {
        switch mode {
        case .scrollView: return "scroll"
        case .cursorView: return "cursorarrow.click.2"
        }
    }
    
    private var iconGradient: LinearGradient {
        let colors: [Color] = isSelected
            ? [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemIndigo]
            : [Color.white.opacity(0.06), Color.white.opacity(0.02)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var backgroundFill: Color {
        if isFocused && isSelected { return TVOSDesign.Colors.accentBlue.opacity(0.18) }
        if isFocused { return Color.white.opacity(0.18) }
        if isSelected { return TVOSDesign.Colors.accentBlue.opacity(0.06) }
        return Color.white.opacity(0.03)
    }
    
    private var borderColor: Color {
        if isSelected && isFocused {
            return TVOSDesign.Colors.accentBlue.opacity(0.9)
        }
        if isSelected {
            return TVOSDesign.Colors.accentBlue.opacity(0.5)
        }
        if isFocused {
            return TVOSDesign.Colors.accentBlue.opacity(0.7)
        }
        return Color.white.opacity(0.05)
    }
    
    private var borderWidth: CGFloat {
        if isSelected && isFocused { return 2.5 }
        if isSelected || isFocused { return 2 }
        return 1
    }
    
    private var focusShadowColor: Color {
        guard isFocused else { return Color.clear }
        return isSelected ? TVOSDesign.Colors.accentBlue.opacity(0.4) : TVOSDesign.Colors.accentBlue.opacity(0.25)
    }
}

// MARK: - Toggle Row Content (Extracted)

private struct SettingsToggleRowContent: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isOn: Bool
    let isFocused: Bool
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    
    var body: some View {
        HStack(spacing: 20) {
            iconView
            textView
            Spacer()
            toggleView
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(rowBackground)
        .overlay(rowBorder)
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [iconColor.opacity(isFocused ? 0.45 : 0.25), iconColor.opacity(isFocused ? 0.2 : 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isFocused ? iconColor : iconColor.opacity(0.8))
        }
    }
    
    private var textView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
            
            Text(subtitle)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
        }
    }
    
    private var toggleView: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(toggleFill)
                .frame(width: 62, height: 36)
            
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                .padding(.horizontal, 4)
        }
        .animation(TVOSDesign.Animation.focusSpring, value: isOn)
    }
    
    private var toggleFill: some ShapeStyle {
        if isOn {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [TVOSDesign.Colors.systemGreen, TVOSDesign.Colors.systemGreen.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
    
    private var rowShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius
        )
    }
    
    private var rowBackground: some View {
        rowShape.fill(isFocused ? Color.white.opacity(0.18) : Color.white.opacity(0.03))
    }
    
    private var rowBorder: some View {
        rowShape.strokeBorder(
            isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.7) : Color.white.opacity(0.05),
            lineWidth: isFocused ? 2.0 : 1
        )
    }
}

// MARK: - Action Row Content (Extracted)

private struct SettingsActionRowContent: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isFocused: Bool
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            iconView
            textView
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.tertiaryLabel)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isFocused ? Color.white.opacity(0.18) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isFocused ? iconColor.opacity(0.7) : Color.white.opacity(0.05),
                    lineWidth: isFocused ? 2.0 : 1
                )
        )
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [iconColor.opacity(isFocused ? 0.45 : 0.25), iconColor.opacity(isFocused ? 0.2 : 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isFocused ? iconColor : iconColor.opacity(0.8))
        }
    }
    
    private var textView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
            
            Text(subtitle)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
        }
    }
}

// MARK: - Preview

#Preview {
    BrowserSettingsView(sessionManager: SessionManager())
        .preferredColorScheme(.dark)
}
