// AgentPackStore.swift
// Yap
//
// Professional StoreKit 2 store for Agent Pack purchases.
// All product display strings come from App Store Connect localization,
// fetched automatically via Product.products(for:).

import Foundation
import StoreKit
import SwiftUI
import Combine

// MARK: - Error

enum AgentPackStoreError: LocalizedError {
    case productNotFound(String)
    case verificationFailed
    case purchasePending
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "Product \"\(id)\" could not be loaded from the App Store."
        case .verificationFailed:
            return "The transaction could not be verified. Please contact support."
        case .purchasePending:
            return "Your purchase is pending approval (e.g. Ask to Buy)."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Purchase State

enum PackPurchaseState: Equatable {
    case idle
    case loading
    case success(AgentPack)
    case failed(String)
}

// MARK: - Store

final class AgentPackStore: ObservableObject {

    // MARK: - Published

    /// Loaded StoreKit products keyed by product ID.
    @Published private(set) var products: [String: Product] = [:]

    /// Set of currently purchased pack IDs.
    @Published private(set) var purchasedPackIDs: Set<String> = []

    /// UI-facing purchase state.
    @Published var purchaseState: PackPurchaseState = .idle

    @Published var isLoadingProducts = false

    // MARK: - Private

    private var listenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    func prepare() {
        listenerTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
        Task { await restorePurchasedPacks() }
    }

    deinit {
        listenerTask?.cancel()
    }

    // MARK: - Products
    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let ids = AgentPack.allCases.map(\.productID)
        do {
            let loaded = try await Product.products(for: ids)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            print("⚠️ AgentPackStore: Failed to load products: \(error)")
        }
    }

    // MARK: - Accessors

    /// Returns the StoreKit Product for a given pack, if loaded.
    func product(for pack: AgentPack) -> Product? {
        products[pack.productID]
    }

    /// Returns whether the user has purchased a specific pack.
    func isPurchased(_ pack: AgentPack) -> Bool {
        purchasedPackIDs.contains(pack.productID)
    }

    /// Returns all agents the user has unlocked via pack purchases.
    var unlockedPackAgents: Set<Agent> {
        Set(AgentPack.allCases
            .filter { isPurchased($0) }
            .flatMap(\.agents))
    }

    // MARK: - Purchase
    @MainActor
    func purchase(_ pack: AgentPack) async {
        guard let product = product(for: pack) else {
            purchaseState = .failed(AgentPackStoreError.productNotFound(pack.productID).localizedDescription)
            return
        }

        purchaseState = .loading

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                markPurchased(pack.productID)
                await transaction.finish()
                purchaseState = .success(pack)
                print("✅ AgentPackStore: purchased \(pack.productID)")

            case .pending:
                purchaseState = .failed(AgentPackStoreError.purchasePending.localizedDescription)

            case .userCancelled:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }

        } catch {
            purchaseState = .failed(AgentPackStoreError.unknown(error).localizedDescription)
            print("⚠️ AgentPackStore: purchase failed: \(error)")
        }
    }

    // MARK: - Restore
    @MainActor
    func restore() async {
        purchaseState = .loading
        try? await AppStore.sync()
        await restorePurchasedPacks()
        purchaseState = .idle
    }

    // MARK: - Transaction Listener
    @MainActor
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? verify(result) else { continue }
            markPurchased(transaction.productID)
            await transaction.finish()
        }
    }

    @MainActor
    private func restorePurchasedPacks() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verify(result) else { continue }
            markPurchased(transaction.productID)
        }
    }

    // MARK: - Helpers
    @MainActor
    private func markPurchased(_ productID: String) {
        purchasedPackIDs.insert(productID)
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw AgentPackStoreError.verificationFailed
        }
    }
}
