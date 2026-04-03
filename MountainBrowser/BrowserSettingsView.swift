//
//  BrowserSettingsView.swift
//  MountainBrowser
//
//  Einstellungsmenü im modernen glasmorphen Design für Browser-Konfiguration
//

import SwiftUI
import StoreKit

// TransparentButtonStyle is defined in TVOSDesign.swift — no need to redeclare here.

struct BrowserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sessionManager: SessionManager
    @FocusState private var focusedItem: SettingsItem?
    
    @State private var animateBackground: Bool = false
    @State private var showAbout: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showManageView: Bool = false
    private var premiumManager: PremiumManager { PremiumManager.shared }
    
    enum SettingsItem: Hashable {
        case backButton
        case viewMode
        case javaScript
        case cookies
        case popups
        case navigation
        case wikipediaLanguage
        case premiumStatus
        case premiumUpgrade
        case premiumManage
        case premiumRestore
        case premiumTheme
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
                    premiumSection
                    viewModeSection
                    webSettingsSection
                    wikipediaSettingsSection
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
        .fullScreenCover(isPresented: $showPaywall) {
            PremiumPaywallView(
                feature: .general,
                isPresented: $showPaywall
            )
        }
        .fullScreenCover(isPresented: $showManageView) {
            PremiumManageView(
                isPresented: $showManageView
            )
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
                Text(L10n.General.back)
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
            Text(L10n.Settings.title)
                .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(L10n.Settings.subtitle)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
        }
    }
    
    // MARK: - View Mode Section
    
    private var viewModeSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.ViewMode.title, icon: "rectangle.on.rectangle")
            
            viewModeSelector
        }
    }
    
    private var viewModeSelector: some View {
        let isFocused = focusedItem == .viewMode
        let currentMode = sessionManager.preferences.viewMode
        
        return Button(action: {
            withAnimation(TVOSDesign.Animation.focusSpring) {
                let allCases = BrowserViewMode.allCases
                if let currentIndex = allCases.firstIndex(of: currentMode) {
                    let nextIndex = (currentIndex + 1) % allCases.count
                    let nextMode = allCases[nextIndex]
                    // Cursor-Mode benötigt Premium
                    if nextMode == .cursorView && !premiumManager.isPremium {
                        showPaywall = true
                    } else {
                        sessionManager.preferences.viewMode = nextMode
                        sessionManager.savePreferences()
                    }
                }
            }
        }) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.systemPurple.opacity(isFocused ? 0.45 : 0.25), TVOSDesign.Colors.systemPurple.opacity(isFocused ? 0.2 : 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: currentMode == .scrollView ? "arrow.up.arrow.down" : "cursorarrow.rays")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.systemPurple : TVOSDesign.Colors.systemPurple.opacity(0.8))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.ViewMode.selection)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    Text(currentMode.description)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                // Aktueller Modus
                HStack(spacing: 8) {
                    Text(currentMode.displayName)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.systemPurple)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
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
                        isFocused ? TVOSDesign.Colors.systemPurple.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .viewMode)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemPurple.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: currentMode)
    }
    
    // MARK: - Web Settings Section
    
    private var webSettingsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.Settings.webSettings, icon: "globe")
            
            VStack(spacing: 2) {
                settingsToggleRow(
                    title: L10n.Settings.javaScript,
                    subtitle: L10n.Settings.javaScriptSubtitle,
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
                    title: L10n.Settings.cookies,
                    subtitle: L10n.Settings.cookiesSubtitle,
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
                    title: L10n.Settings.popupBlocker,
                    subtitle: L10n.Settings.popupBlockerSubtitle,
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
                    title: L10n.Settings.navigation,
                    subtitle: L10n.Settings.navigationSubtitle,
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
    
    // MARK: - Wikipedia Settings Section
    
    private var wikipediaSettingsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: "WIKIPEDIA", icon: "book.closed")
            
            wikipediaLanguageSelector
        }
    }
    
    private var wikipediaLanguageSelector: some View {
        let isFocused = focusedItem == .wikipediaLanguage
        let currentLanguage = sessionManager.preferences.wikipediaLanguage
        
        return Button(action: {
            // Zur nächsten Sprache wechseln
            withAnimation(TVOSDesign.Animation.focusSpring) {
                let allCases = WikipediaLanguage.allCases
                if let currentIndex = allCases.firstIndex(of: currentLanguage) {
                    let nextIndex = (currentIndex + 1) % allCases.count
                    sessionManager.preferences.wikipediaLanguage = allCases[nextIndex]
                    sessionManager.savePreferences()
                }
            }
        }) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.systemIndigo.opacity(isFocused ? 0.45 : 0.25), TVOSDesign.Colors.systemIndigo.opacity(isFocused ? 0.2 : 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.systemIndigo : TVOSDesign.Colors.systemIndigo.opacity(0.8))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Wikipedia.languageSelection)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    Text(L10n.Wikipedia.languageSelectionSubtitle)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                // Aktuelle Sprache
                HStack(spacing: 8) {
                    Text(currentLanguage.displayName)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.accentBlue)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
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
                        isFocused ? TVOSDesign.Colors.systemIndigo.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .wikipediaLanguage)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemIndigo.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: currentLanguage)
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.Premium.settingsTitle, icon: "crown.fill")
            
            // Status-Anzeige
            premiumStatusRow
            
            // Premium Theme Toggle (nur für Premium-Nutzer)
            if premiumManager.isPremium {
                premiumThemeToggle
            }
            
            // Upgrade oder Verwalten Button
            if premiumManager.isPremium {
                premiumManageRow
            } else {
                premiumUpgradeRow
            }
            
            // Restore Button
            premiumRestoreRow
        }
    }
    
    private var premiumThemeToggle: some View {
        let isFocused = focusedItem == .premiumTheme
        let isOn = sessionManager.preferences.usePremiumTheme
        
        return Button(action: {
            withAnimation(TVOSDesign.Animation.focusSpring) {
                sessionManager.preferences.usePremiumTheme.toggle()
                sessionManager.savePreferences()
            }
        }) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.systemYellow.opacity(isFocused ? 0.45 : 0.25), TVOSDesign.Colors.systemOrange.opacity(isFocused ? 0.2 : 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.systemYellow : TVOSDesign.Colors.systemYellow.opacity(0.8))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Premium.premiumTheme)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    Text(L10n.Premium.premiumThemeSubtitle)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                // Toggle
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(
                            isOn
                                ? LinearGradient(
                                    colors: [TVOSDesign.Colors.systemYellow, TVOSDesign.Colors.systemOrange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: 62, height: 36)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .padding(.horizontal, 4)
                }
                .animation(TVOSDesign.Animation.focusSpring, value: isOn)
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
                        isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .premiumTheme)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: isOn)
    }
    
    private var premiumStatusRow: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: premiumManager.isPremium
                                ? [TVOSDesign.Colors.systemYellow.opacity(0.35), TVOSDesign.Colors.systemOrange.opacity(0.15)]
                                : [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: premiumManager.subscriptionStatusIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(premiumManager.subscriptionStatusColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(premiumManager.subscriptionStatusText)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    if premiumManager.isPremium {
                        PremiumBadge(small: true)
                    }
                }
                
                Text(premiumManager.subscriptionDetailText)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            }
            
            Spacer()
            
            // Abo-Typ Badge rechts
            if premiumManager.isPremium {
                Text(premiumManager.activeSubscriptionType.shortName)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.systemYellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(TVOSDesign.Colors.systemYellow.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(TVOSDesign.Colors.systemYellow.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(premiumManager.isPremium ? TVOSDesign.Colors.systemYellow.opacity(0.04) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    premiumManager.isPremium ? TVOSDesign.Colors.systemYellow.opacity(0.15) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
    
    private var premiumUpgradeRow: some View {
        let isFocused = focusedItem == .premiumUpgrade
        
        return Button(action: {
            showPaywall = true
        }) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.systemYellow.opacity(isFocused ? 0.5 : 0.3), TVOSDesign.Colors.systemOrange.opacity(isFocused ? 0.25 : 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.systemYellow)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Premium.upgradeToPremium)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    Text(L10n.Premium.upgradeToPremiumSubtitle)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.systemYellow : TVOSDesign.Colors.tertiaryLabel)
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
                        isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .premiumUpgrade)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    private var premiumManageRow: some View {
        let isFocused = focusedItem == .premiumManage
        let subType = premiumManager.activeSubscriptionType
        
        // Detaillierten Subtitle erstellen
        let manageSubtitle: String = {
            if let expDate = premiumManager.subscriptionExpirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "\(subType.displayName) · \(L10n.Premium.renewsOn) \(formatter.string(from: expDate))"
            }
            return "\(L10n.Premium.currentPlan): \(subType.displayName)"
        }()
        
        return Button(action: {
            showManageView = true
        }) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.systemYellow.opacity(isFocused ? 0.5 : 0.3), TVOSDesign.Colors.systemOrange.opacity(isFocused ? 0.25 : 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.systemYellow : TVOSDesign.Colors.systemYellow.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Premium.manageSubscription)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    Text(manageSubtitle)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                // Abo-Typ rechts anzeigen
                VStack(alignment: .trailing, spacing: 2) {
                    Text(subType.shortName)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.systemYellow)
                    
                    if let product = subType == .monthly ? premiumManager.monthlyProduct : premiumManager.yearlyProduct {
                        Text(product.displayPrice)
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                            .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.tertiaryLabel)
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
                        isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .premiumManage)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }

    private var premiumRestoreRow: some View {
        let isFocused = focusedItem == .premiumRestore
        
        return Button(action: {
            Task { await premiumManager.restorePurchases() }
        }) {
            SettingsActionRowContent(
                title: L10n.Premium.restorePurchases,
                subtitle: premiumManager.isPurchasing ? L10n.General.loading : "",
                icon: "arrow.clockwise",
                iconColor: TVOSDesign.Colors.accentBlue,
                isFocused: isFocused,
                showChevron: false
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .premiumRestore)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
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
            sectionLabel(title: L10n.Settings.actions, icon: "slider.horizontal.3")
            
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
                title: L10n.Settings.reset,
                subtitle: L10n.Settings.resetSubtitle,
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
                title: L10n.Settings.aboutApp,
                subtitle: L10n.Settings.aboutAppSubtitle,
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
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                        Text(L10n.Settings.title)
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
                    
                    Text(L10n.About.developedForAppleTV)
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
            aboutSectionLabel(title: L10n.About.features, icon: "sparkles")
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ],
                spacing: 20
            ) {
                AboutFeatureCard(
                    icon: "doc.text.fill",
                    title: L10n.About.readerMode,
                    description: L10n.About.readerModeDesc,
                    color: TVOSDesign.Colors.accentBlue,
                    isFocused: focusedItem == .featureCard(0)
                )
                .focused($focusedItem, equals: .featureCard(0))
                
                AboutFeatureCard(
                    icon: "magnifyingglass",
                    title: L10n.About.webSearch,
                    description: L10n.About.webSearchDesc,
                    color: TVOSDesign.Colors.systemGreen,
                    isFocused: focusedItem == .featureCard(1)
                )
                .focused($focusedItem, equals: .featureCard(1))
                
                AboutFeatureCard(
                    icon: "book.closed.fill",
                    title: L10n.About.wikipedia,
                    description: L10n.About.wikipediaDesc,
                    color: TVOSDesign.Colors.systemIndigo,
                    isFocused: focusedItem == .featureCard(2)
                )
                .focused($focusedItem, equals: .featureCard(2))
                
                AboutFeatureCard(
                    icon: "rectangle.stack",
                    title: L10n.About.tabManagement,
                    description: L10n.About.tabManagementDesc,
                    color: TVOSDesign.Colors.systemOrange,
                    isFocused: focusedItem == .featureCard(3)
                )
                .focused($focusedItem, equals: .featureCard(3))
                
                AboutFeatureCard(
                    icon: "photo.on.rectangle",
                    title: L10n.About.imagesAndVideos,
                    description: L10n.About.imagesAndVideosDesc,
                    color: TVOSDesign.Colors.systemPink,
                    isFocused: focusedItem == .featureCard(4)
                )
                .focused($focusedItem, equals: .featureCard(4))
                
                AboutFeatureCard(
                    icon: "link",
                    title: L10n.About.linkNavigation,
                    description: L10n.About.linkNavigationDesc,
                    color: TVOSDesign.Colors.systemTeal,
                    isFocused: focusedItem == .featureCard(5)
                )
                .focused($focusedItem, equals: .featureCard(5))
            }
        }
    }
    
    // MARK: - Technical Section
    
    private var technicalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSectionLabel(title: L10n.About.technicalDetails, icon: "cpu")
            
            VStack(spacing: 1) {
                aboutInfoRow(label: L10n.About.platform, value: "tvOS", icon: "tv")
                aboutInfoRow(label: L10n.About.framework, value: "SwiftUI", icon: "swift")
                aboutInfoRow(label: L10n.About.minimumTvOS, value: "17.0", icon: "gearshape.2")
                aboutInfoRow(label: L10n.About.rendering, value: L10n.About.nativeSwiftUI, icon: "doc.text")
                aboutInfoRow(label: L10n.About.dataStorage, value: L10n.About.dataStorageValue, icon: "internaldrive")
                aboutInfoRow(label: L10n.About.cloudSync, value: L10n.About.disabled, icon: "icloud.slash")
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
            aboutSectionLabel(title: L10n.About.legal, icon: "doc.text")
            
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.About.legalText1)
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineSpacing(4)
                
                Text(L10n.About.legalText2)
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .lineSpacing(4)
                
                Text(L10n.About.copyright)
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
