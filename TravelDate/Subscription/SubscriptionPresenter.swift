//
//  SubscriptionPresenter.swift
//  TravelDate
//
//  MVP — Presenter owns all business logic & StoreKit.
//  ViewController only renders what the presenter tells it to.
//

import Foundation
import StoreKit

// MARK: - Notifications

extension Notification.Name {
    /// Posted (on the main thread) whenever the presenter learns the
    /// subscription state changed — purchase, restore, renewal, expiry, refund.
    /// Screens that gate premium features (e.g. Swipe) can listen and refresh.
    static let subscriptionStatusDidChange = Notification.Name("subscriptionStatusDidChange")
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    // ⚠️ Must match App Store Connect EXACTLY (note "trips" vs "travel" and "monhtly").
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
        return product.displayPrice
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
    func purchasePending()
    func subscriptionStatusChanged(isSubscribed: Bool)
}

extension SubscriptionView {
    /// Default so existing views (e.g. PreiumController) keep compiling.
    func purchasePending() {
        purchaseFailed(message: "Your purchase is waiting for approval. You'll get access once it's approved.")
    }
}

// MARK: - Presenter

@MainActor
final class SubscriptionPresenter {

    // MARK: Dependencies
    weak var view: SubscriptionView?

    // MARK: State
    private(set) var plans: [SubscriptionPlan] = []
    // Stays 0 (weekly): PreiumController highlights Weekly on open WITHOUT calling
    // selectPlan, so changing this default would charge a different plan than shown.
    // Screens that want another default call selectPlan(at:) themselves.
    private(set) var selectedIndex = 0
    private(set) var activeTier: SubscriptionTier?

    private let productIDs = SubscriptionTier.allCases.map(\.rawValue)
    private var transactionListenerTask: Task<Void, Never>?

    // Backend sync de-duplication
    private var isSyncing = false
    private var lastSyncedPlan: String?
    private var lastSyncedIsSubscribed: Bool?
    private var lastSyncedEndDate: Date?
    private var pendingBackendSync: (plan: String, startDate: Date?, endDate: Date?, isSubscribed: Bool)?

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: Init

    init(view: SubscriptionView?) {
        self.view = view
        plans = SubscriptionTier.allCases.map { SubscriptionPlan(tier: $0, product: nil) }
        transactionListenerTask = observeTransactionUpdates()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public: Load

    /// Called once when the screen loads.
    func load() {
        Task {
            view?.showLoading()
            await loadProducts()
            if !isAdminSubscribed {
                await refreshSubscriptionStatus()
            }
            view?.reloadPlans()
            notifyCTA()
            view?.hideLoading()
        }
    }

    /// Re-checks entitlements (renewals / refunds while the app was in background).
    /// Call it when the app becomes active — not on every viewDidAppear.
    func applicationDidBecomeActive() {
        guard !isAdminSubscribed else { return }
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

            // Missing IDs are silently dropped by StoreKit — surface them.
            let missing = Set(productIDs).subtracting(storeProducts.map(\.id))
            if !missing.isEmpty {
                log("❌ Products not found in App Store Connect:", missing.sorted())
            }
            if storeProducts.isEmpty {
                view?.purchaseFailed(message: "Subscriptions are unavailable right now. Please try again later.")
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
        guard let product = selectedPlan.product else { return "Continue" }
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
        // Ties the App Store transaction to OUR user account, so a subscription
        // on a shared Apple ID isn't applied to whoever happens to be logged in.
        var options: Set<Product.PurchaseOption> = []
        if let token = currentUserAccountToken {
            options.insert(.appAccountToken(token))
        }

        do {
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                await handlePurchaseVerification(verification)
            case .userCancelled:
                break
            case .pending:
                view?.purchasePending()
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
                    view?.purchaseFailed(message: "No active subscription found for this account.")
                }
            } catch {
                view?.purchaseFailed(message: error.localizedDescription)
            }
            view?.hideLoading()
        }
    }

    // MARK: - Subscription Status

    /// Finds the active auto-renewable subscription that belongs to the logged-in
    /// user (skipping expired, refunded, upgraded-away, or other-account ones)
    /// and syncs the result to the backend.
    func refreshSubscriptionStatus() async {
        var activeTransaction: Transaction?

        entitlementLoop: for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                log("❌ Unverified transaction skipped")
                continue
            }
            guard transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded,
                  let expiry = transaction.expirationDate,
                  expiry > Date(),
                  belongsToCurrentUser(transaction)
            else { continue }

            activeTransaction = transaction
            break entitlementLoop   // labeled: exits the loop, not just a switch
        }

        if let transaction = activeTransaction {
            activeTier = SubscriptionTier(rawValue: transaction.productID)
            log("🟢 Active:", transaction.productID, "until", transaction.expirationDate as Any)
            syncBackend(
                plan: transaction.productID,
                startDate: transaction.purchaseDate,
                endDate: transaction.expirationDate,
                isSubscribed: true
            )
            view?.subscriptionStatusChanged(isSubscribed: true)
            notifyAppOfStatusChange()
            return
        }

        activeTier = nil
        view?.subscriptionStatusChanged(isSubscribed: isAdminSubscribed)

        // No entitlement on THIS Apple ID. That does not prove the user isn't
        // subscribed (other device / other Apple ID), so only downgrade the
        // backend when the backend's own end date has already passed.
        guard !isAdminSubscribed, backendPlanHasExpired else {
            log("ℹ️ No local entitlement; backend plan left unchanged")
            return
        }
        log("🔴 Backend plan expired — syncing free")
        syncBackend(plan: "free", startDate: nil, endDate: nil, isSubscribed: false)
        notifyAppOfStatusChange()
    }

    // MARK: - Transaction Updates

    /// Catches renewals, refunds, and purchases made on another device.
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                // Resolve `self` per update — never hold it for the whole loop,
                // otherwise the presenter can never be deallocated.
                guard let self else { return }
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self.refreshSubscriptionStatus()
                self.view?.reloadPlans()
            }
        }
    }

    // MARK: - Helpers

    private var isAdminSubscribed: Bool {
        User.curentUser?.isSubscriptionByAdmin == 1
    }

    /// The user's backend id as a UUID (your ids are UUIDs), used as appAccountToken.
    private var currentUserAccountToken: UUID? {
        guard let id = User.curentUser?.id else { return nil }
        return UUID(uuidString: id)
    }

    /// Transactions bought before appAccountToken existed have no token — accept those.
    /// Transactions with a token must match the logged-in user.
    private func belongsToCurrentUser(_ transaction: Transaction) -> Bool {
        guard let token = transaction.appAccountToken else { return true }
        return token == currentUserAccountToken
    }

    /// True when the backend says the user is on a paid plan whose end date has passed
    /// (or is missing).
    private var backendPlanHasExpired: Bool {
        guard let plan = User.curentUser?.plan,
              !plan.isEmpty, plan.lowercased() != "free" else {
            return false // already free — nothing to do
        }
        guard let endString = User.curentUser?.planEndDate,
              let endDate = isoFormatter.date(from: endString)
                ?? ISO8601DateFormatter().date(from: endString) else {
            return true
        }
        return endDate <= Date()
    }

    private func notifyAppOfStatusChange() {
        NotificationCenter.default.post(name: .subscriptionStatusDidChange, object: nil)
    }

    private func log(_ items: Any...) {
        #if DEBUG
        print("[Subscription]", items.map { "\($0)" }.joined(separator: " "))
        #endif
    }

    // MARK: - Backend Sync

    private func syncBackend(plan: String, startDate: Date?, endDate: Date?, isSubscribed: Bool) {
        if lastSyncedPlan == plan,
           lastSyncedIsSubscribed == isSubscribed,
           lastSyncedEndDate == endDate,
           pendingBackendSync == nil {
            return
        }

        guard !isSyncing else {
            pendingBackendSync = (plan, startDate, endDate, isSubscribed)
            return
        }
        isSyncing = true

        let request = User.new()
        request.plan = plan
        request.planStartDate = startDate.map { isoFormatter.string(from: $0) }
        request.planEndDate = endDate.map { isoFormatter.string(from: $0) }

        request.editProfileAPi { [weak self] _, status in
            Task { @MainActor in
                guard let self else { return }

                if status == 200 {
                    self.lastSyncedPlan = plan
                    self.lastSyncedIsSubscribed = isSubscribed
                    self.lastSyncedEndDate = endDate
                    self.log("✅ Backend sync OK:", plan)
                    // editProfileAPi refreshed User.curentUser → hasPaidSubscription changed.
                    self.notifyAppOfStatusChange()
                } else {
                    self.log("❌ Backend sync failed, status:", status)
                }

                self.isSyncing = false

                if let pending = self.pendingBackendSync {
                    self.pendingBackendSync = nil
                    self.syncBackend(
                        plan: pending.plan,
                        startDate: pending.startDate,
                        endDate: pending.endDate,
                        isSubscribed: pending.isSubscribed
                    )
                }
            }
        }
    }
}
