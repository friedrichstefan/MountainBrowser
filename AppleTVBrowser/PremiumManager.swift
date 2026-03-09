//
//  PremiumManager.swift
//  AppleTVBrowser
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
    private let logger = Logger(subsystem: "AppleTVBrowser", category: "PremiumManager")
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.appletv.browser.premium.monthly"
        case yearlyPremium = "com.appletv.browser.premium.yearly"
    }
    
    // MARK: - Feature Enum (für Paywall-Kontext)
    enum PremiumFeature: String {
        case cursorMode = "cursor_mode"
        case imageSearch = "image_search"
        case general = "general"
        
        var title: String {
            switch self {
            case .cursorMode: return "Cursor-Modus"
            case .imageSearch: return "Bildersuche"
            case .general: return "Premium"
            }
        }
        
        var description: String {
            switch self {
            case .cursorMode:
                return "Navigiere frei auf Webseiten mit einem Cursor. Klicke auf Links, Buttons und Formulare."
            case .imageSearch:
                return "Durchsuche das Web nach Bildern ohne Einschränkungen. Zeige alle Ergebnisse in Vollbild an."
            case .general:
                return "Schalte alle Premium-Features frei und nutze den Browser ohne Limits."
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
    
    // MARK: - State
    var isPremium: Bool = false
    var products: [Product] = []
    var purchaseError: String?
    var isLoadingProducts: Bool = false
    var isPurchasing: Bool = false
    
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
    
    // MARK: - Init
    
    private init() {
        // Lade tägliche Zähler aus UserDefaults
        loadDailyCounts()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
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
        defer { isLoadingProducts = false }
        
        do {
            let productIDs = Set(ProductID.allCases.map(\.rawValue))
            products = try await Product.products(for: productIDs)
                .sorted { ($0.price as NSDecimalNumber).doubleValue < ($1.price as NSDecimalNumber).doubleValue }
            logger.info("✅ \(self.products.count) Produkte geladen")
        } catch {
            logger.error("❌ Produkte laden fehlgeschlagen: \(error.localizedDescription)")
            purchaseError = "Produkte konnten nicht geladen werden."
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
                purchaseError = "Kauf wird überprüft..."
                logger.info("⏳ Kauf ausstehend")
                
            @unknown default:
                break
            }
        } catch {
            logger.error("❌ Kauf fehlgeschlagen: \(error.localizedDescription)")
            purchaseError = "Kauf fehlgeschlagen: \(error.localizedDescription)"
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
            purchaseError = "Wiederherstellen fehlgeschlagen."
        }
    }
    
    // MARK: - Private StoreKit
    
    private func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                }
            }
        }
        
        isPremium = hasActiveSubscription
        logger.info("📊 Premium-Status: \(self.isPremium ? "AKTIV" : "INAKTIV")")
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
            "Die Transaktion konnte nicht verifiziert werden."
        }
    }
}