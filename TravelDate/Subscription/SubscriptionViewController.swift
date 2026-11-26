//
//  SubscriptionViewController.swift
//  TravelDate
//
//  UIKit only. All StoreKit/backend logic lives in SubscriptionPresenter.
//  This file only builds UI and forwards taps to the presenter.
//

import UIKit

// MARK: - Subscription View Controller

@MainActor
final class SubscriptionViewController: UIViewController {

    // MARK: - Config

    /// ⚠️ Apple requires a Privacy Policy link on subscription screens.
    /// Set your real URL here; the button is hidden while this is nil.
    private let privacyPolicyURL: URL? = nil

    // MARK: - Presenter

    private lazy var presenter = SubscriptionPresenter(view: self)

    // MARK: - Colors

    private let backgroundColor = UIColor(hex: "#0B0D0D")
    private let orangeColor = UIColor(hex: "#FF7A00")

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let featuresStackView = UIStackView()
    private let plansStackView = UIStackView()

    private let statusLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let restoreButton = UIButton(type: .system)
    private let legalLabel = UILabel()
    private let termsButton = UIButton(type: .system)
    private let privacyButton = UIButton(type: .system)

    private var planCardViews: [PlanCardView] = []

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Default to the "BEST VALUE" plan on this screen. Done explicitly here
        // (not in the presenter) so the highlighted card always equals what's bought.
        if let yearly = presenter.plans.firstIndex(where: { $0.tier == .yearly }) {
            presenter.selectPlan(at: yearly)
        }

        setupUI()
        presenter.load()

        // Catch renewals/refunds when the app returns from background —
        // instead of re-checking on every viewDidAppear (load() already checked once).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidBecomeActive() {
        presenter.applicationDidBecomeActive()
    }
}

// MARK: - Setup

private extension SubscriptionViewController {

    func setupUI() {
        view.backgroundColor = backgroundColor

        // Close (works whether pushed or presented)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        closeButton.layer.cornerRadius = 18
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Scroll + main stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(closeButton)
        scrollView.addSubview(stackView)

        // Header
        titleLabel.text = "Go Premium"
        titleLabel.font = .boldSystemFont(ofSize: 30)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Match with more travellers and plan more trips."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Features — only list what premium actually unlocks in the app.
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 18
        let features: [(String, String, String)] = [
            ("heart.circle.fill", "Unlimited matching",
             "Swipe and match with every group heading your way."),
            ("map.fill", "Create multiple trips",
             "Plan more than one trip at the same time."),
        ]
        for (icon, title, description) in features {
            let row = FeatureRow()
            row.configure(icon: icon, title: title, description: description)
            featuresStackView.addArrangedSubview(row)
        }

        // Plans
        plansStackView.axis = .vertical
        plansStackView.spacing = 12

        // Status ("You're currently subscribed.")
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = orangeColor
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true

        // Continue
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        continueButton.backgroundColor = orangeColor
        continueButton.layer.cornerRadius = 16
        continueButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(loadingIndicator)

        // Restore (required by App Review)
        restoreButton.setTitle("Restore Purchases", for: .normal)
        restoreButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .normal)
        restoreButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        // Auto-renew disclosure (required by App Review)
        legalLabel.text = "Payment is charged to your Apple ID at confirmation. The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings."
        legalLabel.font = .systemFont(ofSize: 11)
        legalLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        legalLabel.textAlignment = .center
        legalLabel.numberOfLines = 0

        termsButton.setTitle("Terms of Use", for: .normal)
        privacyButton.setTitle("Privacy Policy", for: .normal)
        [termsButton, privacyButton].forEach {
            $0.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        }
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        privacyButton.isHidden = privacyPolicyURL == nil

        let linksStack = UIStackView(arrangedSubviews: [termsButton, privacyButton])
        linksStack.axis = .horizontal
        linksStack.spacing = 24
        linksStack.distribution = .equalCentering
        let linksContainer = UIStackView(arrangedSubviews: [UIView(), linksStack, UIView()])
        linksContainer.distribution = .equalCentering

        // Assemble
        [titleLabel, subtitleLabel, featuresStackView, plansStackView,
         statusLabel, continueButton, restoreButton, legalLabel, linksContainer]
            .forEach { stackView.addArrangedSubview($0) }
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(28, after: subtitleLabel)
        stackView.setCustomSpacing(28, after: featuresStackView)
        stackView.setCustomSpacing(20, after: plansStackView)
        stackView.setCustomSpacing(4, after: continueButton)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            loadingIndicator.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -16),
        ])

        // Initial (pre-StoreKit) cards so the layout isn't empty while loading.
        rebuildPlanViews()
    }
}

// MARK: - Plans

private extension SubscriptionViewController {

    /// Rebuilds the plan cards to match `presenter.plans`.
    func rebuildPlanViews() {
        planCardViews.forEach { $0.removeFromSuperview() }
        planCardViews.removeAll()

        for (index, plan) in presenter.plans.enumerated() {
            let card = PlanCardView()
            card.configure(with: plan)
            card.onTap = { [weak self] in
                self?.selectPlan(at: index)
            }
            plansStackView.addArrangedSubview(card)
            planCardViews.append(card)
        }
        highlightSelectedPlan()
    }

    func highlightSelectedPlan() {
        for (index, card) in planCardViews.enumerated() {
            card.setSelected(index == presenter.selectedIndex)
        }
    }

    func selectPlan(at index: Int) {
        presenter.selectPlan(at: index)
        highlightSelectedPlan()
    }
}

// MARK: - Actions

private extension SubscriptionViewController {

    @objc func continueTapped() {
        presenter.purchaseSelectedPlan()
    }

    @objc func restoreTapped() {
        presenter.restorePurchases()
    }

    @objc func closeTapped() {
        close()
    }

    @objc func termsTapped() {
        let nav = UINavigationController(rootViewController: LegalViewController())
        present(nav, animated: true)
    }

    @objc func privacyTapped() {
        guard let url = privacyPolicyURL else { return }
        UIApplication.shared.open(url)
    }

    /// Pops if pushed, dismisses if presented.
    func close() {
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - Alerts

private extension SubscriptionViewController {

    func showAlert(title: String, message: String, onOK: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOK?() })
        present(alert, animated: true)
    }
}

// MARK: - SubscriptionView

extension SubscriptionViewController: SubscriptionView {

    func showLoading() {
        loadingIndicator.startAnimating()
        continueButton.isEnabled = false
        restoreButton.isEnabled = false
        continueButton.alpha = 0.7
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        continueButton.isEnabled = true
        restoreButton.isEnabled = true
        continueButton.alpha = 1
    }

    func reloadPlans() {
        rebuildPlanViews()
    }

    func updateCTA(title: String) {
        continueButton.setTitle(title, for: .normal)
    }

    func purchaseSucceeded() {
        showAlert(title: "Success", message: "You're all set. Enjoy premium!") { [weak self] in
            self?.close()
        }
    }

    func purchaseFailed(message: String) {
        showAlert(title: "Something went wrong", message: message)
    }

    func purchasePending() {
        showAlert(title: "Waiting for approval",
                  message: "Your purchase needs approval. You'll get premium as soon as it's approved.")
    }

    func subscriptionStatusChanged(isSubscribed: Bool) {
        statusLabel.isHidden = !isSubscribed
        statusLabel.text = isSubscribed ? "You're currently subscribed." : nil
    }
}

// MARK: - Plan Card View

private final class PlanCardView: UIView {

    var onTap: (() -> Void)?

    private let badgeLabel = PaddedLabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let priceLabel = UILabel()
    private let checkImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with plan: SubscriptionPlan) {
        titleLabel.text = plan.title
        descriptionLabel.text = plan.description
        priceLabel.text = plan.priceText
        badgeLabel.text = plan.badge
        badgeLabel.isHidden = plan.badge == nil
        accessibilityLabel = "\(plan.title), \(plan.priceText)"
    }

    func setSelected(_ selected: Bool) {
        layer.borderColor = (selected ? UIColor.systemOrange : UIColor.white.withAlphaComponent(0.12)).cgColor
        layer.borderWidth = selected ? 2 : 1
        backgroundColor = selected
            ? UIColor.systemOrange.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.05)
        checkImageView.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        checkImageView.tintColor = selected ? .systemOrange : .gray
        accessibilityTraits = selected ? [.button, .selected] : .button
    }

    private func setupUI() {
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        isAccessibilityElement = true

        badgeLabel.backgroundColor = UIColor.orange
        badgeLabel.textColor = UIColor.white
        badgeLabel.font = UIFont.systemFont(ofSize: 11)
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.masksToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white

        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.numberOfLines = 2

        priceLabel.font = .boldSystemFont(ofSize: 18)
        priceLabel.textColor = .white
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        checkImageView.contentMode = .scaleAspectFit

        let badgeRow = UIStackView(arrangedSubviews: [badgeLabel, UIView()])
        let leftStack = UIStackView(arrangedSubviews: [badgeRow, titleLabel, descriptionLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [priceLabel, checkImageView])
        rightStack.axis = .vertical
        rightStack.spacing = 8
        rightStack.alignment = .trailing

        let mainStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        mainStack.alignment = .center
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            checkImageView.widthAnchor.constraint(equalToConstant: 26),
            checkImageView.heightAnchor.constraint(equalToConstant: 26),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    @objc private func handleTap() {
        onTap?()
    }
}


// MARK: - Feature Row View

private final class FeatureRow: UIView {

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(icon: String, title: String, description: String) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
        descriptionLabel.text = description
    }

    private func setupUI() {
        iconContainer.backgroundColor = UIColor(hex: "#FF7A00").withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 22
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.tintColor = UIColor(hex: "#FF7A00")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        descriptionLabel.numberOfLines = 3

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            iconContainer.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            iconContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
