// Neue Datei: PurchaseManager.swift
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    
    private(set) var isPro: Bool = false
    
    static let proProductID = "com.mountainbrowser.pro"
    
    func loadPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                isPro = true
                return
            }
        }
        isPro = false
    }
    
    func purchase() async throws {
        let products = try await Product.products(for: [Self.proProductID])
        guard let product = products.first else { return }
        
        let result = try await product.purchase()
        
        if case .success(let verification) = result,
           case .verified(_) = verification {
            isPro = true
        }
    }
    
    // Convenience-Checks
    var maxTabs: Int { isPro ? 20 : 3 }
    var maxBookmarks: Int { isPro ? .max : 10 }
    var hasBookmarkFolders: Bool { isPro }
    var historyRetentionDays: Int { isPro ? 365 : 7 }
}
