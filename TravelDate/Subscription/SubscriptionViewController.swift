
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

    // MARK: - Presenter

    private lazy var presenter = SubscriptionPresenter(view: self)

    // MARK: - Colors

    private let backgroundColor = UIColor(hex: "#0B0D0D")
    private let cardColor = UIColor(hex: "#161A1D")
    private let orangeColor = UIColor(hex: "#FF7A00")

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let plansStackView = UIStackView()
    private let featuresStackView = UIStackView()

    private let continueButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Plan Cards

    private var planCardViews: [PlanCardView] = []

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

       

        presenter.load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.applicationDidBecomeActive()
    }
}

// MARK: - Setup

private extension SubscriptionViewController {

   

    
   
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
}

// MARK: - Alerts

private extension SubscriptionViewController {

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SubscriptionView

extension SubscriptionViewController: SubscriptionView {

    func showLoading() {
        loadingIndicator.startAnimating()
        continueButton.isEnabled = false
        restoreButton.isEnabled = false
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        continueButton.isEnabled = true
        restoreButton.isEnabled = true
    }

    func reloadPlans() {
        rebuildPlanViews()
    }

    func updateCTA(title: String) {
        continueButton.setTitle(title, for: .normal)
    }

    func purchaseSucceeded() {
        showAlert(title: "Success", message: "You're all set. Enjoy premium!")
    }

    func purchaseFailed(message: String) {
        showAlert(title: "Something went wrong", message: message)
    }

    func subscriptionStatusChanged(isSubscribed: Bool) {
        statusLabel.isHidden = !isSubscribed
        statusLabel.text = isSubscribed ? "You're currently subscribed." : nil
    }
}

// MARK: - Plan Card View

/// Small reusable card for a single plan. Kept in this file since only
/// two files were requested for the module.
private final class PlanCardView: UIView {

    var onTap: (() -> Void)?

    private let badgeLabel = UILabel()
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
    }

    func setSelected(_ selected: Bool) {
        layer.borderColor = (selected ? UIColor.systemOrange : UIColor.white.withAlphaComponent(0.12)).cgColor
        layer.borderWidth = selected ? 2 : 1
        backgroundColor = selected
            ? UIColor.systemOrange.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.05)

        checkImageView.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        checkImageView.tintColor = selected ? .systemOrange : .gray
    }

    private func setupUI() {
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 95).isActive = true

        badgeLabel.backgroundColor = .systemOrange
        badgeLabel.textColor = .white
        badgeLabel.font = .boldSystemFont(ofSize: 11)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.masksToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white

        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.numberOfLines = 2

        priceLabel.font = .boldSystemFont(ofSize: 18)
        priceLabel.textColor = .white

        checkImageView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let leftStack = UIStackView(arrangedSubviews: [badgeLabel, textStack])
        leftStack.axis = .vertical
        leftStack.spacing = 8

        let rightStack = UIStackView(arrangedSubviews: [priceLabel, checkImageView])
        rightStack.axis = .vertical
        rightStack.spacing = 8
        rightStack.alignment = .trailing

        let mainStack = UIStackView(arrangedSubviews: [leftStack, UIView(), rightStack])
        mainStack.alignment = .center
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Feature Row View

/// Small reusable row for a single feature bullet.
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
        textStack.spacing = 7
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

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
