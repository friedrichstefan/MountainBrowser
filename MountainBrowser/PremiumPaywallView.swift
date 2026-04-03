//
//  PremiumPaywallView.swift
//  MountainBrowser
//
//  Glasmorphe Paywall-Ansicht für Premium-Features
//

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    let feature: PremiumManager.PremiumFeature
    @Binding var isPresented: Bool
    
    private var premiumManager: PremiumManager { PremiumManager.shared }
    @FocusState private var focusedElement: PaywallFocus?
    
    enum PaywallFocus: Hashable {
        case yearly
        case monthly
        case tryFree
        case restore
    }
    
    var body: some View {
        ZStack {
            GlassmorphicBackground(
                primaryColor: TVOSDesign.Colors.systemPurple,
                secondaryColor: TVOSDesign.Colors.accentBlue
            )
            
            if premiumManager.isPurchasing {
                purchasingOverlay
            } else {
                mainContent
            }
        }
        .onExitCommand {
            isPresented = false
        }
        .onAppear {
            if premiumManager.products.isEmpty {
                Task { await premiumManager.loadProducts() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                setInitialFocus()
            }
        }
        .onChange(of: premiumManager.products) { _, newProducts in
            if !newProducts.isEmpty && (focusedElement == nil || focusedElement == .tryFree) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    setInitialFocus()
                }
            }
        }
        .onChange(of: premiumManager.isPremium) { _, newValue in
            if newValue {
                // Nach erfolgreichem Kauf: Paywall automatisch schließen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Focus Helper
    
    private func setInitialFocus() {
        if premiumManager.yearlyProduct != nil {
            focusedElement = .yearly
        } else if premiumManager.monthlyProduct != nil {
            focusedElement = .monthly
        } else {
            focusedElement = .tryFree
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        HStack(spacing: 0) {
            // Linke Seite: Header + Features
            VStack(spacing: 0) {
                Spacer()
                headerSection
                    .padding(.bottom, 28)
                featuresSection
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 60)
            
            // Rechte Seite: Pläne + Buttons
            VStack(spacing: 0) {
                Spacer()
                
                // Plan-Auswahl
                plansSection
                    .focusSection()
                    .padding(.bottom, 24)
                
                // Error
                if let error = premiumManager.purchaseError {
                    Text(error)
                        .font(.system(size: TVOSDesign.Typography.footnote))
                        .foregroundColor(TVOSDesign.Colors.systemRed)
                        .padding(.bottom, 12)
                }
                
                // Schließen-Button
                tryFreeButton
                    .padding(.bottom, 16)
                
                // Restore Button
                restoreButton
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 60)
        }
        .padding(.vertical, TVOSDesign.Spacing.safeAreaTop)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TVOSDesign.Colors.systemYellow.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TVOSDesign.Colors.systemYellow, TVOSDesign.Colors.systemOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(L10n.Premium.unlockPremium)
                .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(L10n.Premium.generalDesc)
                .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 700)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Label
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.systemYellow)
                
                Text(L10n.Premium.everythingIncluded)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .tracking(1.5)
                
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
            
            VStack(spacing: 2) {
                featureRow(
                    icon: "cursorarrow.click.2",
                    title: L10n.Premium.cursorMode,
                    subtitle: L10n.Premium.cursorModeShort,
                    color: TVOSDesign.Colors.accentBlue,
                    position: .top
                )
                featureRow(
                    icon: "photo.on.rectangle.angled",
                    title: L10n.Premium.imageSearch,
                    subtitle: L10n.Premium.imageSearchShort,
                    color: TVOSDesign.Colors.systemPurple,
                    position: .middle
                )
                featureRow(
                    icon: "arrow.up.circle.fill",
                    title: L10n.Premium.allUpdates,
                    subtitle: L10n.Premium.allUpdatesDesc,
                    color: TVOSDesign.Colors.systemGreen,
                    position: .bottom
                )
            }
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    private enum RowPosition {
        case top, middle, bottom
        
        var topRadius: CGFloat {
            switch self {
            case .top: return 20
            default: return 4
            }
        }
        
        var bottomRadius: CGFloat {
            switch self {
            case .bottom: return 20
            default: return 4
            }
        }
    }
    
    private func featureRow(icon: String, title: String, subtitle: String, color: Color, position: RowPosition) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                Text(subtitle)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(color.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: position.topRadius,
                bottomLeadingRadius: position.bottomRadius,
                bottomTrailingRadius: position.bottomRadius,
                topTrailingRadius: position.topRadius
            )
            .fill(Color.white.opacity(0.03))
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: position.topRadius,
                bottomLeadingRadius: position.bottomRadius,
                bottomTrailingRadius: position.bottomRadius,
                topTrailingRadius: position.topRadius
            )
            .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Plans Section (Nebeneinander als edle Kacheln)
    
    private var plansSection: some View {
        VStack(spacing: 20) {
            if premiumManager.isLoadingProducts {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.accentBlue))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if premiumManager.products.isEmpty {
                VStack(spacing: 20) {
                    Text(L10n.Premium.errorLoadingProducts)
                        .font(.system(size: TVOSDesign.Typography.body))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    
                    Button(action: {
                        Task { await premiumManager.loadProducts() }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                            Text(L10n.Premium.retryLoading)
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        }
                        .foregroundColor(TVOSDesign.Colors.accentBlue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(TVOSDesign.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(TransparentButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    // Jahresplan-Kachel
                    if let yearly = premiumManager.yearlyProduct {
                        planCard(
                            product: yearly,
                            planName: L10n.Premium.annualPlan,
                            periodLabel: L10n.Premium.perYear,
                            badgeText: L10n.Premium.bestValue,
                            icon: "diamond.fill",
                            accentColor: TVOSDesign.Colors.systemYellow,
                            focusValue: .yearly,
                            isRecommended: true
                        )
                    }
                    
                    // Monatsplan-Kachel
                    if let monthly = premiumManager.monthlyProduct {
                        planCard(
                            product: monthly,
                            planName: L10n.Premium.monthlyPlan,
                            periodLabel: L10n.Premium.perMonth,
                            badgeText: nil,
                            icon: "calendar.circle.fill",
                            accentColor: TVOSDesign.Colors.accentBlue,
                            focusValue: .monthly,
                            isRecommended: false
                        )
                    }
                }
            }
        }
    }
    
    private func planCard(
        product: Product,
        planName: String,
        periodLabel: String,
        badgeText: String?,
        icon: String,
        accentColor: Color,
        focusValue: PaywallFocus,
        isRecommended: Bool
    ) -> some View {
        let isFocused = focusedElement == focusValue
        
        return Button(action: {
            Task { await premiumManager.purchase(product) }
        }) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(isFocused ? 0.35 : 0.2),
                                    accentColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Plan-Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(planName)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                            .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                        
                        if let badge = badgeText {
                            Text(badge)
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(
                                    isRecommended ? TVOSDesign.Colors.background : accentColor
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            isRecommended
                                                ? AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [TVOSDesign.Colors.systemYellow, TVOSDesign.Colors.systemOrange],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                : AnyShapeStyle(accentColor.opacity(0.15))
                                        )
                                )
                        }
                    }
                    
                    Text(periodLabel)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                        .foregroundColor(isFocused ? Color.white.opacity(0.7) : TVOSDesign.Colors.tertiaryLabel)
                }
                
                Spacer()
                
                // Preis + Pfeil
                HStack(spacing: 12) {
                    Text(product.displayPrice)
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .bold, design: .rounded))
                        .foregroundColor(isFocused ? .white : accentColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isFocused ? .white : accentColor.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isFocused
                            ? Color.white.opacity(0.14)
                            : Color.white.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isFocused
                            ? LinearGradient(
                                colors: [accentColor.opacity(0.8), accentColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : (isRecommended
                                ? LinearGradient(
                                    colors: [accentColor.opacity(0.25), accentColor.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedElement, equals: focusValue)
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .shadow(
            color: isFocused ? accentColor.opacity(0.3) : Color.clear,
            radius: isFocused ? 20 : 0,
            y: isFocused ? 8 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Try Free Button
    
    private var tryFreeButton: some View {
        let isFocused = focusedElement == .tryFree
        
        return Button(action: {
            isPresented = false
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.secondaryLabel)
                
                Text(L10n.Premium.tryItFree)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? Color.white.opacity(0.15) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.7) : Color.white.opacity(0.08),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedElement, equals: .tryFree)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        let isFocused = focusedElement == .restore
        return Button(action: {
            Task { await premiumManager.restorePurchases() }
        }) {
            Text(L10n.Premium.restorePurchases)
                .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.tertiaryLabel)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(isFocused ? Color.white.opacity(0.12) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isFocused ? Color.white.opacity(0.25) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedElement, equals: .restore)
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Purchasing Overlay
    
    private var purchasingOverlay: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.systemYellow))
                .scaleEffect(2.5)
            
            Text(L10n.Premium.processingPurchase)
                .font(.system(size: TVOSDesign.Typography.title3, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inline Paywall Banner (für ImageResultGridView)

struct PremiumInlineBanner: View {
    let feature: PremiumManager.PremiumFeature
    let message: String
    let onUnlock: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onUnlock) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TVOSDesign.Colors.systemYellow.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(TVOSDesign.Colors.systemYellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Premium.unlockPremium)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    Text(message)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.systemYellow : TVOSDesign.Colors.tertiaryLabel)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.5) : Color.white.opacity(0.06),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(color: isFocused ? TVOSDesign.Colors.systemYellow.opacity(0.2) : .clear, radius: 20, y: 8)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var small: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: small ? 10 : 14, weight: .bold))
            if !small {
                Text("PRO")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
            }
        }
        .foregroundColor(TVOSDesign.Colors.systemYellow)
        .padding(.horizontal, small ? 8 : 12)
        .padding(.vertical, small ? 4 : 6)
        .background(
            Capsule()
                .fill(TVOSDesign.Colors.systemYellow.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView(
        feature: .general,
        isPresented: .constant(true)
    )
}
