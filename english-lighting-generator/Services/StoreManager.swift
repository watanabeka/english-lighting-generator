//
//  StoreManager.swift
//  english-lighting-generator
//
//  Manages StoreKit subscription: product loading, purchase, restore, and status.
//

import StoreKit
import SwiftUI

@Observable
final class StoreManager {
    static let shared = StoreManager()

    private let productID = "ai_english_premium"

    var isPremium: Bool = false
    var product: Product? = nil

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProduct() }
        Task { await updateSubscriptionStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Product

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("StoreManager: Failed to load products — \(error)")
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase() async {
        guard let product else {
            print("StoreManager: Product not available")
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("StoreManager: Purchase failed — \(error)")
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Status Check

    func updateSubscriptionStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == productID {
                hasActive = true
                break
            }
        }
        await MainActor.run { isPremium = hasActive }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value):      return value
        }
    }
}
