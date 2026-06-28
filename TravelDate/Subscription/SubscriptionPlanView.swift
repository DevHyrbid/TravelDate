// SubscriptionPlanView.swift
// Trips: Travel & Meet Friends
// Pixel-perfect: badge at top, title + description center, price + per period bottom — all centered

import UIKit

// MARK: - SubscriptionPlanView

final class SubscriptionPlanView: UIView {

    // MARK: - Constants
    private enum C {
        static let cardBg        = UIColor(hex: "#111519")
        static let orangeAccent  = UIColor(hex: "#FF7A00")
        static let textPrimary   = UIColor.white
        static let textSecondary = UIColor(white: 1, alpha: 0.68)
        static let cornerRadius  : CGFloat = 18
        static let borderWidth   : CGFloat = 2
    }

    // MARK: - Subviews

    // Figma: badge pill at very top of card — orange filled when "Popular", orange text when "30% Off"/"50% Off"
    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 16, weight: .bold)
        l.textAlignment = .center
        l.layer.cornerRadius = 11
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // e.g. "1 Week", "1 Month", "1 Year"
    private let planTitleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 19, weight: .bold)
        l.textColor     = C.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // e.g. "Perfect for a quick trip"
    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 14, weight: .regular)
        l.textColor     = C.textSecondary
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // e.g. "9.99 $"
    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 17, weight: .bold)
        l.textColor     = C.textPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // e.g. "Per week"
    private let perPeriodLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 14, weight: .regular)
        l.textColor     = C.textSecondary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let skeletonLayer = CAGradientLayer()

    // MARK: - State
    var isSelectedPlan: Bool = false {
        didSet { updateSelectionState(animated: true) }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup() {
        backgroundColor    = C.cardBg
        layer.cornerRadius = C.cornerRadius
        layer.borderColor  = UIColor.clear.cgColor
        layer.borderWidth  = C.borderWidth
        clipsToBounds      = true
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(badgeLabel)
        addSubview(planTitleLabel)
        addSubview(descriptionLabel)
        addSubview(priceLabel)
        addSubview(perPeriodLabel)

        NSLayoutConstraint.activate([
            // Badge pinned to top center
            badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            badgeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            badgeLabel.heightAnchor.constraint(equalToConstant: 35),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 86),

            // Plan title below badge
            planTitleLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 17),
            planTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            planTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            // Description below title
            descriptionLabel.topAnchor.constraint(equalTo: planTitleLabel.bottomAnchor, constant: 9),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            // Price pinned toward bottom
            priceLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            // Per period below price, pinned to bottom
            perPeriodLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 10),
            perPeriodLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            perPeriodLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            perPeriodLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Configure
    func configure(with plan: SubscriptionPlan) {
        planTitleLabel.text  = "1 \(plan.duration)"  // e.g. "1 Week"
        descriptionLabel.text = plan.description

        // Badge styling: "Popular" = orange filled bg + white text; others = orange text on dark bg
        if let badge = plan.badge, !badge.isEmpty {
            badgeLabel.text    = badge
            badgeLabel.isHidden = false
            if badge == "Popular" {
                // Filled orange pill
                badgeLabel.backgroundColor = C.orangeAccent
                badgeLabel.textColor       = .white
            } else {
                // Orange text on card-colored pill
                badgeLabel.backgroundColor = C.cardBg
                badgeLabel.textColor       = C.orangeAccent
                // Add a subtle border
                badgeLabel.layer.borderColor = C.orangeAccent.withAlphaComponent(0.4).cgColor
                badgeLabel.layer.borderWidth = 1
            }
            // Badge padding via attributed string
            badgeLabel.text = "  \(badge)  "
        } else {
            badgeLabel.isHidden = true
        }

        if let product = plan.product {
            // Figma shows: "9.99 $" format (price then currency symbol)
            priceLabel.text    = formatPrice(product.displayPrice)
            perPeriodLabel.text = "Per \(plan.duration.lowercased())"
            hideSkeleton()
        } else {
            showSkeleton()
        }
    }

    // Format "9.99 $" style — keep displayPrice as-is from StoreKit (already locale-formatted)
    private func formatPrice(_ displayPrice: String) -> String {
        // StoreKit returns "$9.99" — Figma shows "9.99 $"
        // Strip leading currency symbol and append it
        let symbols = ["$", "€", "£", "¥", "₹"]
        for sym in symbols {
            if displayPrice.hasPrefix(sym) {
                return displayPrice.dropFirst().description + " " + sym
            }
        }
        return displayPrice
    }

    // MARK: - Skeleton
    func showSkeleton() {
        priceLabel.text     = ""
        perPeriodLabel.text = ""
        skeletonLayer.removeFromSuperlayer()
        skeletonLayer.frame         = CGRect(x: 0, y: 0, width: 70, height: 18)
        skeletonLayer.cornerRadius  = 6
        skeletonLayer.colors = [
            UIColor(white: 0.22, alpha: 1).cgColor,
            UIColor(white: 0.32, alpha: 1).cgColor,
            UIColor(white: 0.22, alpha: 1).cgColor
        ]
        skeletonLayer.startPoint  = CGPoint(x: 0, y: 0.5)
        skeletonLayer.endPoint    = CGPoint(x: 1, y: 0.5)
        skeletonLayer.locations   = [0, 0.5, 1]
        priceLabel.layer.addSublayer(skeletonLayer)
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue    = [-1.0, -0.5, 0.0]
        anim.toValue      = [1.0,  1.5,  2.0]
        anim.duration     = 1.2
        anim.repeatCount  = .infinity
        skeletonLayer.add(anim, forKey: "shimmer")
    }

    func hideSkeleton() {
        skeletonLayer.removeFromSuperlayer()
    }

    // MARK: - Selection State
    // Figma: selected = orange border + very subtle orange tint bg
    private func updateSelectionState(animated: Bool) {
        let targetBorder = isSelectedPlan ? C.orangeAccent.cgColor : UIColor(white: 1, alpha: 0.1).cgColor
        let targetBg     = isSelectedPlan
            ? C.orangeAccent.withAlphaComponent(0.10)
            : C.cardBg

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseInOut) {
                self.backgroundColor   = targetBg
                self.layer.borderColor = targetBorder
            }
        } else {
            backgroundColor   = targetBg
            layer.borderColor = targetBorder
        }
    }
}
