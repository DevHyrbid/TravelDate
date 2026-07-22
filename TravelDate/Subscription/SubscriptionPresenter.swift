
//  SubscriptionPresenter.swift
//  Trips
//
//  Created by Coding Zone.
//

import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case weekly  = "com.ios.trips.weekly"
    case monthly = "com.ios.travel.monhtly"
    case yearly  = "com.ios.travel.yearly"

    var serverPlan: String {
        switch self {
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        }
    }

    var duration: String {
        switch self {
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }
}

// MARK: - Subscription Plan

struct SubscriptionPlan {

    let id: String
    let tier: SubscriptionTier
    let title: String
    let badge: String?
    let description: String

    var product: Product?
}

// MARK: - Purchase Result

enum PurchaseResult {

    case success
    case cancelled
    case pending
    case failed(Error)
}

// MARK: - View Protocol

@MainActor
protocol SubscriptionView: AnyObject {

    func showLoading()
    func hideLoading()

    func reloadPlans()

    func updateCTA(title: String)

    func purchaseSucceeded()

    func purchaseFailed(_ message: String)

    func subscriptionStatusChanged(isSubscribed: Bool)
}

// MARK: - Presenter

@MainActor
final class SubscriptionPresenter {

    // MARK: Properties

    weak var view: SubscriptionView?

    private var transactionTask: Task<Void, Never>?

    private let productIDs = SubscriptionTier.allCases.map(\.rawValue)

    private(set) var plans: [SubscriptionPlan] = []

    private(set) var selectedPlan: SubscriptionPlan?

    private(set) var activeSubscription: SubscriptionTier?

    // MARK: Init

    init(view: SubscriptionView? = nil) {

        self.view = view

        createPlans()

        transactionTask = listenForTransactions()
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: Default Plans

    private func createPlans() {

        plans = [

            SubscriptionPlan(
                id: SubscriptionTier.weekly.rawValue,
                tier: .weekly,
                title: "Weekly",
                badge: "Popular",
                description: "Perfect for a quick trip",
                product: nil
            ),

            SubscriptionPlan(
                id: SubscriptionTier.monthly.rawValue,
                tier: .monthly,
                title: "Monthly",
                badge: "30% Off",
                description: "Most flexible option",
                product: nil
            ),

            SubscriptionPlan(
                id: SubscriptionTier.yearly.rawValue,
                tier: .yearly,
                title: "Yearly",
                badge: "50% Off",
                description: "For frequent travelers",
                product: nil
            )
        ]

        selectedPlan = plans.first
    }

    // MARK: Load Products

    func loadProducts() {

        view?.showLoading()

        Task {

            do {

                let storeProducts = try await Product.products(for: productIDs)

                for index in plans.indices {

                    if let product = storeProducts.first(where: {
                        $0.id == plans[index].id
                    }) {

                        plans[index].product = product
                    }
                }

                selectedPlan = plans.first

                view?.reloadPlans()

                updateCTA()

                await checkSubscriptionStatus()

                view?.hideLoading()

            } catch {

                view?.hideLoading()

                view?.purchaseFailed(error.localizedDescription)
            }
        }
    }

    // MARK: Selection

    func selectPlan(at index: Int) {

        guard plans.indices.contains(index) else {
            return
        }

        selectedPlan = plans[index]

        updateCTA()
    }

    // MARK: CTA

    func ctaTitle() -> String {

        guard
            let product = selectedPlan?.product,
            let plan = selectedPlan
        else {
            return "Continue"
        }

        return "Continue - \(formatPrice(product.displayPrice))/ \(plan.tier.duration)"
    }

    private func updateCTA() {

        view?.updateCTA(title: ctaTitle())
    }

    // MARK: Price Formatting

    private func formatPrice(_ price: String) -> String {

        let symbols = ["$", "₹", "€", "£", "¥"]

        for symbol in symbols {

            if price.hasPrefix(symbol) {

                return price.dropFirst() + " \(symbol)"
            }
        }

        return price
    }
    
    // MARK: - Purchase

    func purchaseSelectedPlan() {

        guard let product = selectedPlan?.product else {
            view?.purchaseFailed("Please select a subscription plan.")
            return
        }

        view?.showLoading()

        Task {

            do {

                let result = try await product.purchase()

                switch result {

                case .success(let verification):

                    switch verification {

                    case .verified(let transaction):

                        await transaction.finish()

                        await checkSubscriptionStatus()

                        await syncSubscription()

                        view?.hideLoading()
                        view?.purchaseSucceeded()

                    case .unverified(_, let error):

                        view?.hideLoading()
                        view?.purchaseFailed(error.localizedDescription)
                    }

                case .userCancelled:

                    view?.hideLoading()

                case .pending:

                    view?.hideLoading()
                    view?.purchaseFailed("Purchase is pending approval.")

                @unknown default:

                    view?.hideLoading()
                }

            } catch {

                view?.hideLoading()
                view?.purchaseFailed(error.localizedDescription)
            }
        }
    }

    //
    // MARK: - Restore Purchases
    //

    func restorePurchases() {

        view?.showLoading()

        Task {

            do {

                try await AppStore.sync()

                await checkSubscriptionStatus()

                await syncSubscription()

                view?.hideLoading()

                if activeSubscription != nil {
                    view?.purchaseSucceeded()
                } else {
                    view?.purchaseFailed("No active subscription found.")
                }

            } catch {

                view?.hideLoading()
                view?.purchaseFailed(error.localizedDescription)
            }
        }
    }

    //
    // MARK: - Subscription Status
    //

    func checkSubscriptionStatus() async {

        activeSubscription = nil

        for await result in Transaction.currentEntitlements {

            guard case .verified(let transaction) = result else {
                continue
            }

            guard transaction.productType == .autoRenewable else {
                continue
            }

            // Refunded / Revoked
            if transaction.revocationDate != nil {
                continue
            }

            // Expired
            if let expiration = transaction.expirationDate,
               expiration <= Date() {
                continue
            }

            guard let tier = SubscriptionTier(rawValue: transaction.productID) else {
                continue
            }

            activeSubscription = tier
            break
        }

        view?.subscriptionStatusChanged(isSubscribed: activeSubscription != nil)
    }

    //
    // MARK: - Transaction Listener
    //

    private func listenForTransactions() -> Task<Void, Never> {

        Task(priority: .background) { [weak self] in

            guard let self else { return }

            for await result in Transaction.updates {

                guard case .verified(let transaction) = result else {
                    continue
                }

                await transaction.finish()

                await self.checkSubscriptionStatus()

                await self.syncSubscription()
            }
        }
    }
    
    // MARK: - Backend Sync

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private var lastSyncedPlan: String?
    private var lastSyncedSubscribed: Int?

    @MainActor
    func syncSubscription() async {

        let isSubscribed = activeSubscription != nil

        let plan = activeSubscription?.serverPlan ?? "free"

        var startDate: Date?
        var endDate: Date?

        // Read latest active transaction
        for await result in Transaction.currentEntitlements {

            guard case .verified(let transaction) = result else {
                continue
            }

            guard transaction.productType == .autoRenewable else {
                continue
            }

            if transaction.revocationDate != nil {
                continue
            }

            if let expiry = transaction.expirationDate,
               expiry <= Date() {
                continue
            }

            startDate = transaction.purchaseDate
            endDate = transaction.expirationDate
            break
        }

        // Nothing changed → Don't hit API
        if User.currentUser?.plan == plan &&
            User.currentUser?.isSubscribed == (isSubscribed ? 1 : 0) {

            return
        }

        if lastSyncedPlan == plan &&
            lastSyncedSubscribed == (isSubscribed ? 1 : 0) {

            return
        }

        lastSyncedPlan = plan
        lastSyncedSubscribed = isSubscribed ? 1 : 0

        let request = EditProfileRequest()

        request.plan = plan
        request.isSubscribed = isSubscribed ? 1 : 0

        request.planStartDate = startDate == nil
            ? nil
            : isoFormatter.string(from: startDate!)

        request.planEndDate = endDate == nil
            ? nil
            : isoFormatter.string(from: endDate!)

        await withCheckedContinuation { continuation in

            request.editProfileAPi { _, code in

                if code == 200 {

                    User.currentUser?.plan = plan
                    User.currentUser?.isSubscribed = isSubscribed ? 1 : 0

                    User.currentUser?.planStartDate =
                        request.planStartDate

                    User.currentUser?.planEndDate =
                        request.planEndDate
                }

                continuation.resume()
            }
        }
    }

    //
    // MARK: - Helpers
    //

    func isSubscribed() -> Bool {
        activeSubscription != nil
    }

    func selectedIndex() -> Int {

        guard
            let selectedPlan,
            let index = plans.firstIndex(where: {
                $0.id == selectedPlan.id
            })
        else {
            return 0
        }

        return index
    }

    func plan(at index: Int) -> SubscriptionPlan? {

        guard plans.indices.contains(index) else {
            return nil
        }

        return plans[index]
    }

    func numberOfPlans() -> Int {
        plans.count
    }

    func restoreIfNeeded() {

        Task {

            await checkSubscriptionStatus()

            if activeSubscription != nil {

                await syncSubscription()
            }
        }
    }

    func applicationDidBecomeActive() {

        Task {

            await checkSubscriptionStatus()

            await syncSubscription()
        }
    }
}
