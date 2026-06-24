// SubscriptionManager.swift
// Trips: Travel & Meet Friends
// StoreKit 2 — iOS 16+

import StoreKit
import Foundation

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case weekly  = "com.ios.trips.weekly"
    case monthly = "com.ios.travel.monhtly"
    case yearly  = "com.ios.travel.yearly"
}

// MARK: - Subscription Plan Model

struct SubscriptionPlan {
    let id: String
    let tier: SubscriptionTier
    let title: String
    let badge: String?
    let duration: String
    let description: String
    var product: Product?

    var localizedPrice: String {
        guard let product else { return "—" }
        return product.displayPrice
    }

    var ctaTitle: String {
        guard let product else { return "Continue" }
        return "Continue – \(product.displayPrice) / \(duration)"
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success(Transaction)
    case cancelled
    case pending
    case failed(Error)
}

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    private let productIDs: [String] = [
        SubscriptionTier.weekly.rawValue,
        SubscriptionTier.monthly.rawValue,
        SubscriptionTier.yearly.rawValue
    ]

    private(set) var products: [Product] = []
    private(set) var activeSubscription: SubscriptionTier? = nil

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactionUpdates()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async throws -> [Product] {
        let fetched = try await Product.products(for: productIDs)
        let order: [String] = productIDs
        products = fetched.sorted {
            (order.firstIndex(of: $0.id) ?? 0) < (order.firstIndex(of: $1.id) ?? 0)
        }
        return products
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> PurchaseResult {
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                await checkSubscriptionStatus()
                return .success(transaction)
            case .unverified(_, let error):
                throw error
            }
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubscriptionStatus()
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        var foundTier: SubscriptionTier? = nil
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let tier = SubscriptionTier(rawValue: transaction.productID) {
                    foundTier = tier
                    break
                }
            case .unverified:
                break
            }
        }
        activeSubscription = foundTier
    }

    func isSubscribed() -> Bool {
        return activeSubscription != nil
    }

    // MARK: - Transaction Update Listener

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                case .unverified:
                    break
                }
            }
        }
    }
}
