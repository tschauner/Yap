// StoreManager.swift
// Yap

import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: ObservableObject {
    
    static let shared = StoreManager()
    
    // MARK: - Product IDs
    
    enum ProductID {
        static let lifetime = "com.philipptschauner.yap.lifetime"
    }
    
    // MARK: - Published State
    
    @Published private(set) var product: Product?
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Init
    
    private init() {
        Task { await loadProducts() }
        Task { await updatePurchaseStatus() }
        Task { await listenForTransactions() }
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
                await transaction.finish()
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
        await updatePurchaseStatus()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                isPro = true
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Status Check
    
    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == ProductID.lifetime {
                isPro = true
                return
            }
        }
        // Kein aktives Entitlement gefunden
        isPro = false
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
    
    enum StoreError: LocalizedError {
        case unverified
        var errorDescription: String? { "Transaction could not be verified." }
    }
}
