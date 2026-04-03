//
//  PremiumManager.swift
//  MountainBrowser
//
//  StoreKit 2 Premium-Management für Cursor-Modus und Bildersuche
//

import StoreKit
import SwiftUI
import os.log

@MainActor
@Observable
final class PremiumManager {
    
    static let shared = PremiumManager()
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "MountainBrowser", category: "PremiumManager")
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.mountainbrowser.premium.monthly"
        case yearlyPremium = "com.mountainbrowser.premium.yearly"
    }
    
    // MARK: - Feature Enum (für Paywall-Kontext)
    enum PremiumFeature: String {
        case cursorMode = "cursor_mode"
        case imageSearch = "image_search"
        case general = "general"
        
        var title: String {
            switch self {
            case .cursorMode: return L10n.Premium.cursorMode
            case .imageSearch: return L10n.Premium.imageSearch
            case .general: return L10n.Premium.premium
            }
        }
        
        var description: String {
            switch self {
            case .cursorMode:
                return L10n.Premium.cursorModeDesc
            case .imageSearch:
                return L10n.Premium.imageSearchDesc
            case .general:
                return L10n.Premium.generalDesc
            }
        }
        
        var iconName: String {
            switch self {
            case .cursorMode: return "cursorarrow.click.2"
            case .imageSearch: return "photo.on.rectangle.angled"
            case .general: return "crown.fill"
            }
        }
    }
    
    // MARK: - Subscription Type
    enum SubscriptionType: String {
        case monthly
        case yearly
        case none
        
        var displayName: String {
            switch self {
            case .monthly: return L10n.Premium.subscriptionMonthly
            case .yearly: return L10n.Premium.subscriptionYearly
            case .none: return L10n.Premium.statusFree
            }
        }
        
        var shortName: String {
            switch self {
            case .monthly: return L10n.Premium.monthlyShort
            case .yearly: return L10n.Premium.yearlyShort
            case .none: return ""
            }
        }
        
        var icon: String {
            switch self {
            case .monthly: return "calendar"
            case .yearly: return "calendar.badge.clock"
            case .none: return "person.fill"
            }
        }
    }
    
    // MARK: - State
    var isPremium: Bool = false
    var activeSubscriptionType: SubscriptionType = .none
    var subscriptionExpirationDate: Date?
    var subscriptionProductID: String?
    var products: [Product] = []
    var purchaseError: String?
    var isLoadingProducts: Bool = false
    var isPurchasing: Bool = false

    private var transactionListenerTask: Task<Void, Never>?
    
    // MARK: - Daily Limits für Free-User
    private let maxFreeCursorMinutes: Int = 0  // Cursor nur für Premium
    private let maxFreeImageSearches: Int = 3  // 3 Bildersuchen pro Tag
    private let maxFreeImagePreviews: Int = 3  // 3 Bilder pro Suche sichtbar
    
    private var dailyImageSearchCount: Int = 0
    private var lastResetDate: Date?
    
    // MARK: - Computed Properties
    
    var canUseCursorMode: Bool {
        isPremium
    }
    
    var canSearchImages: Bool {
        isPremium || dailyImageSearchCount < maxFreeImageSearches
    }
    
    var canViewAllImages: Bool {
        isPremium
    }
    
    var freeImagePreviewLimit: Int {
        maxFreeImagePreviews
    }
    
    var remainingFreeImageSearches: Int {
        max(0, maxFreeImageSearches - dailyImageSearchCount)
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }
    }
    
    var subscriptionStatusText: String {
        if isPremium {
            return "\(L10n.Premium.statusActive) – \(activeSubscriptionType.displayName)"
        } else {
            return L10n.Premium.statusFree
        }
    }
    
    var subscriptionDetailText: String {
        if isPremium, let expDate = subscriptionExpirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateStr = formatter.string(from: expDate)
            return "\(L10n.Premium.renewsOn) \(dateStr)"
        } else if isPremium {
            return activeSubscriptionType.displayName
        } else {
            return L10n.Premium.settingsSubtitle
        }
    }
    
    var subscriptionStatusIcon: String {
        if isPremium {
            return activeSubscriptionType.icon
        }
        return "person.fill"
    }
    
    var subscriptionStatusColor: Color {
        isPremium ? TVOSDesign.Colors.systemYellow : TVOSDesign.Colors.secondaryLabel
    }
    
    // MARK: - Init
    
    private init() {
        loadDailyCounts()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }

        transactionListenerTask = Task {
            await listenForTransactions()
        }
    }
    
    // MARK: - Daily Counter Management
    
    func recordImageSearch() {
        resetDailyCountsIfNeeded()
        if !isPremium {
            dailyImageSearchCount += 1
            saveDailyCounts()
        }
    }
    
    private func resetDailyCountsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if lastResetDate != today {
            dailyImageSearchCount = 0
            lastResetDate = today
            saveDailyCounts()
        }
    }
    
    private func loadDailyCounts() {
        dailyImageSearchCount = UserDefaults.standard.integer(forKey: "premium.dailyImageSearchCount")
        if let date = UserDefaults.standard.object(forKey: "premium.lastResetDate") as? Date {
            lastResetDate = date
        }
        resetDailyCountsIfNeeded()
    }
    
    private func saveDailyCounts() {
        UserDefaults.standard.set(dailyImageSearchCount, forKey: "premium.dailyImageSearchCount")
        UserDefaults.standard.set(lastResetDate, forKey: "premium.lastResetDate")
    }
    
    // MARK: - StoreKit 2
    
    func loadProducts() async {
        isLoadingProducts = true
        purchaseError = nil
        defer { isLoadingProducts = false }
        
        do {
            let productIDs = Set(ProductID.allCases.map(\.rawValue))
            logger.info("🔍 Lade Produkte für IDs: \(productIDs.joined(separator: ", "))")
            
            let loadedProducts = try await Product.products(for: productIDs)
            logger.info("📦 Geladene Produkte: \(loadedProducts.count)")
            
            for product in loadedProducts {
                logger.info("  → \(product.id): \(product.displayName) - \(product.displayPrice)")
            }
            
            products = loadedProducts.sorted { $0.price < $1.price }
            
            if products.isEmpty {
                logger.warning("⚠️ Keine Produkte gefunden! StoreKit-Konfiguration prüfen.")
                purchaseError = L10n.Premium.errorLoadingProducts
            } else {
                logger.info("✅ \(self.products.count) Produkte erfolgreich geladen")
            }
        } catch {
            logger.error("❌ Produkte laden fehlgeschlagen: \(error.localizedDescription)")
            purchaseError = "\(L10n.Premium.errorLoadingProducts): \(error.localizedDescription)"
        }
    }
    
    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                logger.info("✅ Kauf erfolgreich: \(product.id)")
                
            case .userCancelled:
                logger.info("ℹ️ Kauf abgebrochen")
                
            case .pending:
                purchaseError = L10n.Premium.purchasePending
                logger.info("⏳ Kauf ausstehend")
                
            @unknown default:
                break
            }
        } catch {
            logger.error("❌ Kauf fehlgeschlagen: \(error.localizedDescription)")
            purchaseError = "\(L10n.Premium.purchaseFailed): \(error.localizedDescription)"
        }
    }
    
    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.info("✅ Käufe wiederhergestellt")
        } catch {
            logger.error("❌ Wiederherstellen fehlgeschlagen: \(error.localizedDescription)")
            purchaseError = L10n.Premium.restoreFailed
        }
    }
    
    // MARK: - Private StoreKit
    
    private func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        var detectedType: SubscriptionType = .none
        var expirationDate: Date?
        var productID: String?
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                    productID = transaction.productID
                    expirationDate = transaction.expirationDate
                    
                    if transaction.productID == ProductID.monthlyPremium.rawValue {
                        detectedType = .monthly
                    } else if transaction.productID == ProductID.yearlyPremium.rawValue {
                        detectedType = .yearly
                    }
                }
            }
        }
        
        isPremium = hasActiveSubscription
        activeSubscriptionType = detectedType
        subscriptionExpirationDate = expirationDate
        subscriptionProductID = productID
        logger.info("📊 Premium-Status: \(self.isPremium ? "AKTIV" : "INAKTIV"), Typ: \(detectedType.rawValue), Ablauf: \(String(describing: expirationDate))")
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreError: LocalizedError {
        case failedVerification
        
        var errorDescription: String? {
            L10n.Premium.verificationFailed
        }
    }
}
