//
//  PremiumManageView.swift
//  MountainBrowser
//
//  Abo-Verwaltungsansicht für Premium-Nutzer: zeigt Abo-Details, Laufzeit, enthaltene Features
//

import SwiftUI
import StoreKit

struct PremiumManageView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @FocusState private var focusedItem: ManageFocusItem?
    
    private var premiumManager = PremiumManager.shared
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    @State private var animateBackground: Bool = false
    
    enum ManageFocusItem: Hashable {
        case backButton
        case changePlan
        case restorePurchases
        case featureCard(Int)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 50) {
                    headerSection
                    thankYouBanner
                    subscriptionDetailsSection
                    includedFeaturesSection
                    actionsSection
                    Spacer(minLength: 120)
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
            // Initiale Fokussierung
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedItem = .backButton
            }
        }
        .onExitCommand {
            isPresented = false
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            // Gold/Premium Orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [TVOSDesign.Colors.systemYellow.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)
                .offset(x: animateBackground ? -150 : -250, y: animateBackground ? -80 : -180)
                .blur(radius: 80)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [TVOSDesign.Colors.systemOrange.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(x: animateBackground ? 250 : 150, y: animateBackground ? 180 : 280)
                .blur(radius: 60)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 24) {
            // Back Button
            Button(action: { isPresented = false }) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                    Text(L10n.General.back)
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
            .animation(TVOSDesign.Animation.focusSpring, value: focusedItem)
            
            Spacer()
            
            // Title
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 12) {
                    Text(L10n.Premium.yourSubscription)
                        .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    
                    PremiumBadge(small: false)
                }
            }
        }
    }
    
    // MARK: - Thank You Banner
    
    private var thankYouBanner: some View {
        VStack(spacing: 16) {
            // Crown Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TVOSDesign.Colors.systemYellow.opacity(0.3),
                                TVOSDesign.Colors.systemOrange.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.systemYellow)
            }
            
            Text(L10n.Premium.thankYou)
                .font(.system(size: TVOSDesign.Typography.titleSize, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(L10n.Premium.thankYouSubtitle)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - Subscription Details Section
    
    private var subscriptionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.Premium.subscriptionDetails, icon: "creditcard.fill")
            
            VStack(spacing: 1) {
                detailRow(
                    label: L10n.Premium.plan,
                    value: premiumManager.activeSubscriptionType.displayName,
                    icon: premiumManager.activeSubscriptionType.icon,
                    iconColor: TVOSDesign.Colors.systemYellow
                )
                
                detailRow(
                    label: L10n.Premium.status,
                    value: L10n.General.active,
                    icon: "checkmark.circle.fill",
                    iconColor: TVOSDesign.Colors.systemGreen
                )
                
                // Preis
                if let product = currentProduct {
                    detailRow(
                        label: L10n.Premium.price,
                        value: "\(product.displayPrice) \(premiumManager.activeSubscriptionType == .monthly ? L10n.Premium.perMonth : L10n.Premium.perYear)",
                        icon: "tag.fill",
                        iconColor: TVOSDesign.Colors.accentBlue
                    )
                }
                
                // Nächste Verlängerung
                if let expDate = premiumManager.subscriptionExpirationDate {
                    let formatter: DateFormatter = {
                        let f = DateFormatter()
                        f.dateStyle = .long
                        f.timeStyle = .none
                        return f
                    }()
                    
                    detailRow(
                        label: L10n.Premium.nextRenewal,
                        value: formatter.string(from: expDate),
                        icon: "calendar.badge.clock",
                        iconColor: TVOSDesign.Colors.systemOrange
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private var currentProduct: Product? {
        switch premiumManager.activeSubscriptionType {
        case .monthly: return premiumManager.monthlyProduct
        case .yearly: return premiumManager.yearlyProduct
        case .none: return nil
        }
    }
    
    private func detailRow(label: String, value: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.25), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
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
    
    // MARK: - Included Features Section
    
    private var includedFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.Premium.includedFeatures, icon: "sparkles")
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ],
                spacing: 20
            ) {
                featureCard(
                    icon: "cursorarrow.click.2",
                    title: L10n.Premium.cursorModeFeature,
                    description: L10n.Premium.cursorModeFeatureDesc,
                    color: TVOSDesign.Colors.systemPurple,
                    index: 0
                )
                
                featureCard(
                    icon: "photo.on.rectangle.angled",
                    title: L10n.Premium.unlimitedImageSearch,
                    description: L10n.Premium.unlimitedImageSearchDesc,
                    color: TVOSDesign.Colors.systemPink,
                    index: 1
                )
                
                featureCard(
                    icon: "arrow.up.circle.fill",
                    title: L10n.Premium.allFutureUpdates,
                    description: L10n.Premium.allFutureUpdatesDesc,
                    color: TVOSDesign.Colors.systemGreen,
                    index: 2
                )
            }
        }
    }
    
    private func featureCard(icon: String, title: String, description: String, color: Color, index: Int) -> some View {
        let isFocused = focusedItem == .featureCard(index)
        
        return Button(action: {}) {
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
                
                // Checkmark badge
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.systemGreen)
                    
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                }
                
                Text(description)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(height: 52)
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
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: .featureCard(index))
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .shadow(
            color: isFocused ? color.opacity(0.25) : Color.clear,
            radius: isFocused ? 20 : 0,
            y: isFocused ? 8 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionLabel(title: L10n.Settings.actions, icon: "slider.horizontal.3")
            
            VStack(spacing: 12) {
                // Hinweis: Abo über Apple TV Einstellungen verwalten
                manageHintRow
                
                // Restore
                actionButton(
                    title: L10n.Premium.restorePurchases,
                    subtitle: premiumManager.isPurchasing ? L10n.General.loading : "",
                    icon: "arrow.clockwise",
                    iconColor: TVOSDesign.Colors.systemTeal,
                    focusItem: .restorePurchases
                ) {
                    Task { await premiumManager.restorePurchases() }
                }
            }
        }
    }
    
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        focusItem: ManageFocusItem,
        action: @escaping () -> Void
    ) -> some View {
        let isFocused = focusedItem == focusItem
        
        return Button(action: action) {
            HStack(spacing: 20) {
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
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                            .foregroundColor(isFocused ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel)
                    }
                }
                
                Spacer()
                
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
                        isFocused ? iconColor.opacity(0.7) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 2.0 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($focusedItem, equals: focusItem)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? iconColor.opacity(0.25) : Color.clear,
            radius: isFocused ? 24 : 0,
            y: isFocused ? 10 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
    
    // MARK: - Manage Hint Row
    
    private var manageHintRow: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [TVOSDesign.Colors.accentBlue.opacity(0.25), TVOSDesign.Colors.accentBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.accentBlue.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Premium.manageInAppStore)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(L10n.Premium.manageInAppStoreSubtitle)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Section Label
    
    private func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.systemYellow)
            
            Text(title)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                .tracking(2.0)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [TVOSDesign.Colors.systemYellow.opacity(0.2), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
    }
}