// SubscriptionViewModel.swift
// Trips: Travel & Meet Friends

import Foundation
import StoreKit
import Combine

// MARK: - View State

enum SubscriptionViewState: Equatable {
    case loading
    case loaded
    case purchasing
    case error(String)
}

// MARK: - SubscriptionViewModel

@MainActor
final class SubscriptionViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var plans: [SubscriptionPlan] = []
    @Published var selectedPlan: SubscriptionPlan?
    @Published private(set) var viewState: SubscriptionViewState = .loading
    @Published private(set) var isSubscribed: Bool = false

    // MARK: - Static Plan Templates

    private let planTemplates: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: SubscriptionTier.weekly.rawValue,
            tier: .weekly,
            title: "Weekly",
            badge: "Popular",
            duration: "Week",
            description: "Perfect for a quick trip"
        ),
        SubscriptionPlan(
            id: SubscriptionTier.monthly.rawValue,
            tier: .monthly,
            title: "Monthly",
            badge: "30% Off",
            duration: "Month",
            description: "Most flexible option"
        ),
        SubscriptionPlan(
            id: SubscriptionTier.yearly.rawValue,
            tier: .yearly,
            title: "Yearly",
            badge: "50% Off",
            duration: "Year",
            description: "For frequent travelers"
        )
    ]

    private let manager: SubscriptionManager

    // MARK: - Callbacks

    var onPurchaseSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Screen Mode
    // Drives CTA title — freeTrial shows "Try for $0.00", plans shows "Continue - 9.99 $/ Week"
    var screenMode: SubscriptionScreenMode = .plans

    // MARK: - Init

    init(manager: SubscriptionManager = .shared) {
        self.manager = manager
    }

    // MARK: - Load

    func loadProducts() async {
        viewState = .loading
        do {
            let products = try await manager.loadProducts()
            var assembled: [SubscriptionPlan] = []
            for var template in planTemplates {
                if let product = products.first(where: { $0.id == template.id }) {
                    template = SubscriptionPlan(
                        id: template.id,
                        tier: template.tier,
                        title: template.title,
                        badge: template.badge,
                        duration: template.duration,
                        description: template.description,
                        product: product
                    )
                }
                assembled.append(template)
            }
            plans = assembled
            selectedPlan = assembled.first
            viewState = .loaded
            await manager.checkSubscriptionStatus()
            isSubscribed = manager.isSubscribed()
        } catch {
            viewState = .error("Failed to load subscription plans. Please check your connection.")
            onError?("Failed to load plans: \(error.localizedDescription)")
        }
    }

    // MARK: - Select Plan

    func selectPlan(_ plan: SubscriptionPlan) {
        guard viewState != .purchasing else { return }
        selectedPlan = plan
    }

    // MARK: - Purchase

    func purchaseSelectedPlan() async {
        guard let plan = selectedPlan, let product = plan.product else {
            onError?("No plan selected.")
            return
        }
        viewState = .purchasing
        do {
            let result = try await manager.purchase(product)
            switch result {
            case .success:
                isSubscribed = true
                viewState = .loaded
                onPurchaseSuccess?()
            case .cancelled:
                viewState = .loaded
            case .pending:
                viewState = .loaded
                onError?("Your purchase is pending approval.")
            case .failed(let error):
                viewState = .error(error.localizedDescription)
                onError?("Purchase failed: \(error.localizedDescription)")
            }
        } catch {
            viewState = .loaded
            onError?("Purchase failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        viewState = .purchasing
        do {
            try await manager.restorePurchases()
            isSubscribed = manager.isSubscribed()
            viewState = .loaded
            if isSubscribed {
                onPurchaseSuccess?()
            } else {
                onError?("No active subscriptions found.")
            }
        } catch {
            viewState = .loaded
            onError?("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - CTA Title
    // Screen 1 (freeTrial): "Try for $0.00"
    // Screen 2 (plans):     "Continue - 9.99 $/ Week" (matches Figma exactly)
    var ctaTitle: String {
        switch screenMode {
        case .freeTrial:
            return "Try for $0.00"
        case .plans:
            guard let plan = selectedPlan else { return "Continue" }
            if let product = plan.product {
                // Figma format: "Continue - 9.99 $/ Week"
                let price = formatFigmaPrice(product.displayPrice)
                return "Continue - \(price)/ \(plan.duration)"
            }
            return "Continue"
        }
    }

    // Converts "$9.99" → "9.99 $" to match Figma
    private func formatFigmaPrice(_ displayPrice: String) -> String {
        let symbols = ["$", "€", "£", "¥", "₹"]
        for sym in symbols {
            if displayPrice.hasPrefix(sym) {
                return displayPrice.dropFirst().description + " \(sym)"
            }
        }
        return displayPrice + " "
    }
}
