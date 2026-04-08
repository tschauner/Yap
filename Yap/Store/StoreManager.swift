// StoreManager.swift
// Yap
//
//  Created by Philipp Tschauner on 17.03.26.
//

import Foundation
import StoreKit
import Combine
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {

    enum ProductID {
        static let lifetime = "com.philipptschauner.yap.lifetime"
    }
    
    // MARK: - Published State
    
    @Published private(set) var product: Product?
    @Published private(set) var isLoading: Bool = false
    @AppStorage("isPro") var isPro = false
    @Published var error: String?
    
    // MARK: - Init
    
    func prepare() {
        Task { await loadProducts() }
        Task { await updatePurchaseStatus() }
        Task { await listenForTransactions() }
        
        // Delayed re-check: promo code transactions may not be available immediately at launch
        Task {
            try? await Task.sleep(for: .seconds(2))
            if !isPro { await updatePurchaseStatus() }
        }
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: [ProductID.lifetime])
            self.product = products.first
        } catch {
            self.error = error.localizedDescription
            print("⚠️ StoreKit: Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase() async {
        guard let product else {
            error = "Product not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isPro = true
                (UIApplication.shared.delegate as? AppDelegate)?.registerNotificationActions()
                await transaction.finish()
                await syncProStatus(true)
                print("✅ Purchase successful: \(transaction.productID)")
                
            case .userCancelled:
                break
                
            case .pending:
                // Ask to Buy, etc.
                break
                
            @unknown default:
                break
            }
        } catch {
            self.error = error.localizedDescription
            print("⚠️ Purchase failed: \(error)")
        }
    }
    
    // MARK: - Restore
    
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        
        try? await AppStore.sync()
        await updatePurchaseStatus() // already calls syncProStatus internally
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                isPro = true
                (UIApplication.shared.delegate as? AppDelegate)?.registerNotificationActions()
                await transaction.finish()
                await syncProStatus(true)
            }
        }
    }
    
    // MARK: - Status Check
    
    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == ProductID.lifetime {
                isPro = true
                (UIApplication.shared.delegate as? AppDelegate)?.registerNotificationActions()
                await syncProStatus(true)
                return
            }
        }
        // Kein aktives Entitlement gefunden
        isPro = false
        (UIApplication.shared.delegate as? AppDelegate)?.registerNotificationActions()
        await syncProStatus(isPro)
    }
    
    // MARK: - Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.unverified
        }
    }
    
    // MARK: - Pro Status Sync
    
    /// Syncs the Pro status to the server so edge functions can verify it.
    private func syncProStatus(_ isPro: Bool) async {
        do {
            try await APIClient().rpc(
                function: "sync_pro_status",
                params: .json(["p_is_pro": isPro])
            )
            print("✅ Pro status synced to server: \(isPro)")
        } catch {
            print("⚠️ Pro status sync failed: \(error.localizedDescription)")
        }
    }
    
    enum StoreError: LocalizedError {
        case unverified
        var errorDescription: String? { L10n.StoreError.general }
    }
}
