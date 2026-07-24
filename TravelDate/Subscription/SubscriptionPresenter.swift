//
//  SubscriptionPresenter.swift
//  TravelDate
//
//  MVP — Presenter owns all business logic & StoreKit.
//  ViewController only renders what the presenter tells it to.
//

import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case weekly  = "com.ios.trips.weekly"
    case monthly = "com.ios.travel.monhtly"
    case yearly  = "com.ios.travel.yearly"

    var title: String {
        switch self {
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .yearly:  return "Yearly"
        }
    }

    var duration: String {
        switch self {
        case .weekly:  return "week"
        case .monthly: return "month"
        case .yearly:  return "year"
        }
    }

    var badge: String? {
        self == .yearly ? "BEST VALUE" : nil
    }

    var description: String {
        switch self {
        case .weekly:  return "Try it out, cancel anytime."
        case .monthly: return "Most flexible option."
        case .yearly:  return "Save the most, billed yearly."
        }
    }

    /// How this tier is represented on our backend.
    var serverPlan: String {
        rawValue
    }
}

// MARK: - Subscription Plan (UI model)

struct SubscriptionPlan {
    let tier: SubscriptionTier
    var product: Product?

    var id: String { tier.rawValue }
    var title: String { tier.title }
    var badge: String? { tier.badge }
    var description: String { tier.description }

    var priceText: String {
        guard let product else { return "--" }
        return "\(product.displayPrice) / \(tier.duration)"
    }
}

// MARK: - View Protocol

@MainActor
protocol SubscriptionView: AnyObject {
    func showLoading()
    func hideLoading()
    func reloadPlans()
    func updateCTA(title: String)
    func purchaseSucceeded()
    func purchaseFailed(message: String)
    func subscriptionStatusChanged(isSubscribed: Bool)
}

// MARK: - Presenter

@MainActor
final class SubscriptionPresenter {

    // MARK: Dependencies

    weak var view: SubscriptionView?
    private var lastSyncedPlan: String?
    private var lastSyncedIsSubscribed: Bool?
    // MARK: State

    private(set) var plans: [SubscriptionPlan] = []
    private(set) var selectedIndex = 0
    private(set) var activeTier: SubscriptionTier?

    private let productIDs = SubscriptionTier.allCases.map(\.rawValue)
    private var transactionListenerTask: Task<Void, Never>?

    // Prevents sending the same backend update twice in a row.
    private var isSyncing = false
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: Init

    init(view: SubscriptionView?) {
        self.view = view
        createDefaultPlans()
        transactionListenerTask = observeTransactionUpdates()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Default Plans

    private func createDefaultPlans() {
        plans = SubscriptionTier.allCases.map { SubscriptionPlan(tier: $0, product: nil) }
    }

    // MARK: - Public: Load

    /// Called once when the screen appears.
    func load() {
        Task {
            view?.showLoading()

            await loadProducts()
            await refreshSubscriptionStatus()

            view?.reloadPlans()
            notifyCTA()
            view?.hideLoading()
        }
    }

    /// Called from `viewDidAppear` to catch renewals/refunds that
    /// happened while the app was in the background.
    func applicationDidBecomeActive() {
        Task {
            await refreshSubscriptionStatus()
            view?.reloadPlans()
        }
    }

    // MARK: - Products

    private func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)

            for index in plans.indices {
                let plan = plans[index]
                plans[index].product = storeProducts.first { $0.id == plan.id }
            }
        } catch {
            view?.purchaseFailed(message: error.localizedDescription)
        }
    }

    // MARK: - Plan Selection

    func selectPlan(at index: Int) {
        guard plans.indices.contains(index) else { return }
        selectedIndex = index
        notifyCTA()
    }

    var selectedPlan: SubscriptionPlan {
        plans[selectedIndex]
    }

    // MARK: - CTA

    func ctaTitle() -> String {
        guard let product = selectedPlan.product else {
            return "Continue"
        }
        return "Continue • \(product.displayPrice) / \(selectedPlan.tier.duration)"
    }

    private func notifyCTA() {
        view?.updateCTA(title: ctaTitle())
    }

    // MARK: - Purchase

    func purchaseSelectedPlan() {
        guard let product = selectedPlan.product else {
            view?.purchaseFailed(message: "This plan is not available right now.")
            return
        }

        Task {
            view?.showLoading()
            await purchase(product)
            view?.hideLoading()
        }
    }

    private func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await handlePurchaseVerification(verification)

            case .userCancelled:
                break

            case .pending:
                view?.purchaseFailed(message: "Purchase is pending approval.")

            @unknown default:
                break
            }
        } catch {
            view?.purchaseFailed(message: error.localizedDescription)
        }
    }

    private func handlePurchaseVerification(_ verification: VerificationResult<Transaction>) async {
        switch verification {
        case .verified(let transaction):
            await transaction.finish()
            await refreshSubscriptionStatus()
            view?.purchaseSucceeded()

        case .unverified(_, let error):
            view?.purchaseFailed(message: error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restorePurchases() {
        Task {
            view?.showLoading()

            do {
                try await AppStore.sync()
                await refreshSubscriptionStatus()

                if activeTier != nil {
                    view?.purchaseSucceeded()
                } else {
                    view?.purchaseFailed(message: "No active subscriptions found.")
                }
            } catch {
                view?.purchaseFailed(message: error.localizedDescription)
            }

            view?.hideLoading()
        }
    }

    // MARK: - Subscription Status

    /// Walks current entitlements and figures out the single active tier,
    /// skipping anything expired or refunded. Also syncs the result to
    /// the backend.
    func refreshSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expiry = transaction.expirationDate,
               expiry > Date() {

                syncBackend(
                    plan: transaction.productID,
                    startDate: transaction.purchaseDate,
                    endDate: expiry,
                    isSubscribed: true
                )

                view?.subscriptionStatusChanged(isSubscribed: true)
                return
            }
        }

        syncBackend(
            plan: "free",
            startDate: nil,
            endDate: nil,
            isSubscribed: false
        )

        view?.subscriptionStatusChanged(isSubscribed: false)
    }

    // MARK: - Transaction Updates

    /// Catches renewals, refunds, and purchases made on another device.
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }

                await transaction.finish()
                await self.refreshSubscriptionStatus()
                self.view?.reloadPlans()
            }
        }
    }

    // MARK: - Backend Sync

    private func syncBackend(
        plan: String,
        startDate: Date?,
        endDate: Date?,
        isSubscribed: Bool
    ) {

        guard !isSyncing else { return }

        guard lastSyncedPlan != plan || lastSyncedIsSubscribed != isSubscribed else {
            return
        }

        isSyncing = true

        lastSyncedPlan = plan
        lastSyncedIsSubscribed = isSubscribed

        let request = User.new()
        request.plan = plan
//        request.isSubscribed = isSubscribed ? 1 : 0
        request.planStartDate = startDate.map { isoFormatter.string(from: $0) }
        request.planEndDate = endDate.map { isoFormatter.string(from: $0) }

        request.editProfileAPi { [weak self] response, status in
            guard let self else { return }

            self.isSyncing = false

            print(status, response as Any)

            guard status == 200 else { return }

            User.curentUser?.plan = plan
            User.curentUser?.endDate = request.planEndDate
            User.curentUser?.isSubscribed = isSubscribed ? 1 : 0
        }
    }
}
