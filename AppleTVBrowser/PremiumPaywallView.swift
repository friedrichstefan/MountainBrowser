//
//  PremiumPaywallView.swift
//  AppleTVBrowser
//
//  Paywall-Ansicht für Premium-Features
//

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Binding var isPresented: Bool
    let feature: PremiumManager.PremiumFeature
    
    private var premiumManager: PremiumManager { PremiumManager.shared }
    
    @FocusState private var focusedProductIndex: Int?
    @FocusState private var restoreFocused: Bool
    @FocusState private var closeFocused: Bool
    
    var body: some View {
        ZStack {
            // Hintergrund
            TVOSDesign.Colors.background
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            TVOSDesign.Colors.systemBlue.opacity(0.15),
                            Color.clear,
                            TVOSDesign.Colors.systemIndigo.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )
            
            VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                            .scaleEffect(closeFocused ? TVOSDesign.Focus.scale : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focused($closeFocused)
                    .animation(TVOSDesign.Animation.focusSpring, value: closeFocused)
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                
                Spacer()
                
                // Feature Icon & Title
                featureHeader
                
                // Feature Beschreibung
                featureDescription
                
                // Produkte
                productsSection
                
                // Wiederherstellen
                restoreButton
                
                // Fehler
                if let error = premiumManager.purchaseError {
                    Text(error)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.systemOrange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                }
                
                Spacer()
            }
            
            // Loading Overlay
            if premiumManager.isPurchasing {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2.0)
                        Text("Kauf wird verarbeitet...")
                            .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onExitCommand {
            isPresented = false
        }
    }
    
    // MARK: - Feature Header
    
    private var featureHeader: some View {
        VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            ZStack {
                Circle()
                    .fill(TVOSDesign.Colors.systemBlue.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Image(systemName: feature.iconName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TVOSDesign.Colors.systemBlue, TVOSDesign.Colors.systemTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Premium freischalten")
                .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
        }
    }
    
    // MARK: - Feature Beschreibung
    
    private var featureDescription: some View {
        VStack(spacing: 16) {
            Text(feature.title)
                .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.systemBlue)
            
            Text(feature.description)
                .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 800)
            
            // Alle Premium-Features auflisten
            HStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                premiumFeatureItem(
                    icon: "cursorarrow.click.2",
                    title: "Cursor-Modus",
                    description: "Links klicken & navigieren"
                )
                
                premiumFeatureItem(
                    icon: "photo.on.rectangle.angled",
                    title: "Bildersuche",
                    description: "Unbegrenzte Bildersuche"
                )
                
                premiumFeatureItem(
                    icon: "sparkles",
                    title: "Alle Updates",
                    description: "Zukünftige Features inklusive"
                )
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    private func premiumFeatureItem(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.systemBlue)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(TVOSDesign.Colors.systemBlue.opacity(0.15))
                )
            
            Text(title)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(description)
                .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        HStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            ForEach(Array(premiumManager.products.enumerated()), id: \.element.id) { index, product in
                ProductCard(
                    product: product,
                    isPopular: index == 1,
                    isFocused: focusedProductIndex == index
                ) {
                    Task {
                        await premiumManager.purchase(product)
                    }
                }
                .focused($focusedProductIndex, equals: index)
            }
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal * 2)
        .padding(.top, TVOSDesign.Spacing.elementSpacing)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button(action: {
            Task { await premiumManager.restorePurchases() }
        }) {
            Text("Käufe wiederherstellen")
                .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                .foregroundColor(restoreFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.tertiaryLabel)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(restoreFocused ? TVOSDesign.Colors.focusedCardBackground : Color.clear)
                )
                .scaleEffect(restoreFocused ? TVOSDesign.Focus.scale : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($restoreFocused)
        .animation(TVOSDesign.Animation.focusSpring, value: restoreFocused)
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isPopular: Bool
    let isFocused: Bool
    let onPurchase: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.pressSpring) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(TVOSDesign.Animation.pressSpring) { isPressed = false }
                onPurchase()
            }
        }) {
            VStack(spacing: 16) {
                if isPopular {
                    Text("BELIEBT")
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(TVOSDesign.Colors.systemBlue)
                        )
                }
                
                Text(product.displayName)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(product.displayPrice)
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.systemBlue)
                
                if let subscription = product.subscription {
                    Text(subscription.subscriptionPeriod.unit == .month ? "pro Monat" : "pro Jahr")
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                }
                
                Text("Abonnieren")
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
            }
            .padding(TVOSDesign.Spacing.cardSpacing)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .stroke(
                        isFocused ? TVOSDesign.Colors.systemBlue : (isPopular ? TVOSDesign.Colors.systemBlue.opacity(0.4) : Color.clear),
                        lineWidth: isFocused ? 3 : 2
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: Color.black.opacity(isFocused ? 0.5 : 0.2),
                radius: isFocused ? TVOSDesign.Focus.shadowRadius : 8,
                y: isFocused ? 10 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView(
        isPresented: .constant(true),
        feature: .cursorMode
    )
}