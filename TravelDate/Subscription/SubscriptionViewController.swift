// SubscriptionViewController.swift
// Trips: Travel & Meet Friends
// UIKit | Programmatic | MVVM | StoreKit 2 | iOS 16+
// Pixel-perfect match to Figma — both Free Trial & Plans screens

import UIKit
import StoreKit
import Combine

// MARK: - Screen Mode
enum SubscriptionScreenMode {
    case freeTrial   // Screen 1: timeline onboarding + single CTA
    case plans       // Screen 2: 3-column plan cards + features
}

// MARK: - SubscriptionViewController

@MainActor
final class SubscriptionViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: SubscriptionViewModel
    private var cancellables = Set<AnyCancellable>()
    private var plansPopulated = false

    // Expose mode to switch between Screen 1 and Screen 2
    var mode: SubscriptionScreenMode = .plans

    // MARK: - Constants
    private let bgColor    = UIColor(hex: "#0B0D0D")
    private let cardColor  = UIColor(hex: "#111519")
    private let orangeColor = UIColor(hex: "#FF7A00")
    private static let buttonHeight: CGFloat = 58
    private let bottomGlowLayer = CAGradientLayer()

    // MARK: - Scroll
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .clear
        sv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Shared Header (both screens)
    // Orange left-bar + title + subtitle — left aligned per Figma
    private lazy var orangeBar: UIView = {
        let v = UIView()
        v.backgroundColor = orangeColor
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(white: 1, alpha: 0.72)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Screen 1: Free Trial Timeline
    private lazy var timelineCard: UIView = {
        let v = UIView()
        v.backgroundColor = cardColor
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Screen 2: Plan Cards (horizontal 3-col)
    private var planViews: [SubscriptionPlanView] = []

    private lazy var plansRowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Features Section (both screens share this)
    private lazy var featureSectionTitle: UILabel = {
        let l = UILabel()
        l.text = "Included with Trips"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var featuresCard: UIView = {
        let v = UIView()
        v.backgroundColor = cardColor
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var featuresStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 22
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - CTA Button
    private lazy var ctaButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.backgroundColor = orangeColor
        btn.layer.cornerRadius = Self.buttonHeight / 2
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Footer Labels
    private lazy var freeTrialLabel: UILabel = {
        let l = UILabel()
        l.text = "Free for 3 days, then 9.99 $per week"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.72)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var recurringLabel: UILabel = {
        let l = UILabel()
        l.text = "Recurring billing for same price and duration, cancel anytime"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.72)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Features Data
    private let features: [SubscriptionFeature] = [
        SubscriptionFeature(
            iconName: "person.2",
            title: "Invite friends to your travel groups",
            description: "Create your own group and bring friends along to plan and share experiences together."
        ),
        SubscriptionFeature(
            iconName: "star",
            title: "Unlimited matches",
            description: "preview group photos - unlimited messages."
        ),
        SubscriptionFeature(
            iconName: "eye",
            title: "Preview Photos",
            description: "See group pictures in advance so you know who you'll be connecting with."
        ),
        SubscriptionFeature(
            iconName: "message",
            title: "Unlimited Chat",
            description: "Chat freely with your matches and plan activities without restrictions."
        )
    ]

    // MARK: - Init
    init(viewModel: SubscriptionViewModel, mode: SubscriptionScreenMode = .plans) {
        self.viewModel = viewModel
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        bindViewModel()
        Task { await viewModel.loadProducts() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomGlowLayer.frame = view.bounds
    }

    // MARK: - Navigation
    private func setupNavigation() {
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.isTranslucent = false
//        navigationController?.navigationBar.barTintColor = bgColor
//        navigationController?.navigationBar.backgroundColor = bgColor

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = .white
        backButton.contentHorizontalAlignment = .leading
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 44)

        let titleLabel = UILabel()
        titleLabel.text = "Manage Subscription"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 26, weight: .regular)
        titleLabel.sizeToFit()

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(customView: backButton),
            UIBarButtonItem(customView: titleLabel)
        ]
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = bgColor
        bottomGlowLayer.colors = [
            UIColor.clear.cgColor,
            orangeColor.withAlphaComponent(0.04).cgColor,
            orangeColor.withAlphaComponent(0.12).cgColor
        ]
        bottomGlowLayer.locations = [0.0, 0.72, 1.0]
        bottomGlowLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGlowLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(bottomGlowLayer, at: 0)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        buildSharedHeader()

        switch mode {
        case .freeTrial:
            buildTimelineSection()
        case .plans:
            buildPlansSection()
        }

        buildFeaturesSection()
        buildCTASection()
        buildFooterSection()
    }

    // MARK: - Shared Header
    // Figma: orange left vertical bar | title (bold) + subtitle below, left aligned
    private func buildSharedHeader() {
        contentView.addSubview(orangeBar)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        switch mode {
        case .freeTrial:
            titleLabel.text    = "Connect with endless travel\ncompanions using Trips"
            subtitleLabel.text = nil
        case .plans:
            titleLabel.text    = "Discover who's viewed your profile"
            subtitleLabel.text = "Upgrade to unlock"
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        }

        NSLayoutConstraint.activate([
            // Orange bar: 4pt wide, ~52pt tall, left edge at 20
            orangeBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: mode == .plans ? 31 : 20),
            orangeBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: mode == .plans ? 24 : 20),
            orangeBar.widthAnchor.constraint(equalToConstant: 4),
            orangeBar.heightAnchor.constraint(equalToConstant: mode == .plans ? 21 : 52),

            // Title sits to the right of the bar
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: mode == .plans ? 30 : 20),
            titleLabel.leadingAnchor.constraint(equalTo: orangeBar.trailingAnchor, constant: mode == .plans ? 11 : 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: mode == .plans ? 14 : 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
        ])
    }

    // MARK: - Screen 1: Timeline Card
    // Figma: dark card with 3 timeline steps connected by dashed vertical line
    private func buildTimelineSection() {
        contentView.addSubview(timelineCard)

        // Anchor timeline card below header
        let headerBottom = mode == .freeTrial ? subtitleLabel : subtitleLabel
        NSLayoutConstraint.activate([
            timelineCard.topAnchor.constraint(equalTo: orangeBar.bottomAnchor, constant: 28),
            timelineCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timelineCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])

        let steps: [(icon: String, day: String, title: String, sub: String)] = [
            ("lock.open.fill",   "Today:",  "Start your free trial",  "Get instant access to all premium features"),
            ("map.fill",         "Day 2:",  "Keep exploring!",         "Try out all features completely free"),
            ("calendar.badge.exclamationmark", "Day 3:", "Trial ends", "You'll be charged. Cancel anytime before")
        ]

        var prevDot: UIView? = nil
        var prevStep: UIView? = nil

        for (i, step) in steps.enumerated() {
            let row = buildTimelineRow(icon: step.icon, day: step.day, title: step.title, sub: step.sub)
            timelineCard.addSubview(row)

            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: timelineCard.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: timelineCard.trailingAnchor, constant: -16),
            ])

            if let prev = prevStep {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 0).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: timelineCard.topAnchor, constant: 20).isActive = true
            }

            if i == steps.count - 1 {
                row.bottomAnchor.constraint(equalTo: timelineCard.bottomAnchor, constant: -20).isActive = true
            }

            // Dashed vertical line connecting dots (between step 0→1 and 1→2)
            if let prev = prevDot {
                let dash = buildDashedLine()
                timelineCard.addSubview(dash)
                NSLayoutConstraint.activate([
                    dash.centerXAnchor.constraint(equalTo: prev.centerXAnchor),
                    dash.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 2),
                    // will pin bottom in next iteration — approximate height
                    dash.heightAnchor.constraint(equalToConstant: 28),
                    dash.widthAnchor.constraint(equalToConstant: 2),
                ])
            }

            // Find the dot inside this row (tag = 99)
            if let dot = row.viewWithTag(99) {
                prevDot = dot
            }
            prevStep = row
        }
    }

    private func buildTimelineRow(icon: String, day: String, title: String, sub: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Orange circle dot
        let dot = UIView()
        dot.backgroundColor    = orangeColor
        dot.layer.cornerRadius = 22
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.tag = 99
        container.addSubview(dot)

        let iconIV = UIImageView(image: UIImage(systemName: icon))
        iconIV.tintColor    = .white
        iconIV.contentMode  = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        dot.addSubview(iconIV)

        // Text
        let dayLbl = UILabel()
        dayLbl.text      = day
        dayLbl.font      = .systemFont(ofSize: 13, weight: .semibold)
        dayLbl.textColor = UIColor(white: 1, alpha: 0.55)

        let titleLbl = UILabel()
        titleLbl.text      = title
        titleLbl.font      = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .white

        let dayTitleRow = UIStackView(arrangedSubviews: [dayLbl, titleLbl])
        dayTitleRow.axis    = .horizontal
        dayTitleRow.spacing = 5
        dayTitleRow.alignment = .center

        let subLbl = UILabel()
        subLbl.text          = sub
        subLbl.font          = .systemFont(ofSize: 12, weight: .regular)
        subLbl.textColor     = UIColor(white: 1, alpha: 0.5)
        subLbl.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [dayTitleRow, subLbl])
        textStack.axis    = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            dot.widthAnchor.constraint(equalToConstant: 44),
            dot.heightAnchor.constraint(equalToConstant: 44),
            dot.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12),

            iconIV.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 20),
            iconIV.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.centerYAnchor.constraint(equalTo: dot.centerYAnchor),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 68),
        ])

        return container
    }

    private func buildDashedLine() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear

        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor  = UIColor(white: 1, alpha: 0.2).cgColor
        shapeLayer.lineWidth    = 1.5
        shapeLayer.lineDashPattern = [4, 4]
        shapeLayer.fillColor    = UIColor.clear.cgColor

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 1, y: 0))
        path.addLine(to: CGPoint(x: 1, y: 28))
        shapeLayer.path = path.cgPath
        v.layer.addSublayer(shapeLayer)
        return v
    }

    // MARK: - Screen 2: Plan Cards (horizontal 3-column)
    // Figma: 3 equal-width cards side by side, badge at top of each
    private func buildPlansSection() {
        contentView.addSubview(plansRowStack)

        NSLayoutConstraint.activate([
            plansRowStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            plansRowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            plansRowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            plansRowStack.heightAnchor.constraint(equalToConstant: 193),
        ])

        for _ in 0..<3 {
            let planView = SubscriptionPlanView()
            planView.showSkeleton()
            plansRowStack.addArrangedSubview(planView)
            planViews.append(planView)
        }
    }

    // MARK: - Features Section
    private func buildFeaturesSection() {
        contentView.addSubview(featuresCard)
        featuresCard.addSubview(featureSectionTitle)
        featuresCard.addSubview(featuresStack)

        for feature in features {
            let row = FeatureRowView()
            row.configure(with: feature)
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: mode == .plans ? 56 : 56).isActive = true
            featuresStack.addArrangedSubview(row)
        }

        let sectionTopAnchor: NSLayoutYAxisAnchor
        switch mode {
        case .freeTrial:
            sectionTopAnchor = timelineCard.bottomAnchor
        case .plans:
            sectionTopAnchor = plansRowStack.bottomAnchor
        }

        NSLayoutConstraint.activate([
            featuresCard.topAnchor.constraint(equalTo: sectionTopAnchor, constant: mode == .plans ? 25 : 28),
            featuresCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: mode == .plans ? 24 : 16),
            featuresCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: mode == .plans ? -24 : -16),

            featureSectionTitle.topAnchor.constraint(equalTo: featuresCard.topAnchor, constant: mode == .plans ? 26 : 24),
            featureSectionTitle.leadingAnchor.constraint(equalTo: featuresCard.leadingAnchor, constant: mode == .plans ? 20 : 16),

            featuresStack.topAnchor.constraint(equalTo: featureSectionTitle.bottomAnchor, constant: mode == .plans ? 27 : 20),
            featuresStack.leadingAnchor.constraint(equalTo: featuresCard.leadingAnchor, constant: mode == .plans ? 40 : 16),
            featuresStack.trailingAnchor.constraint(equalTo: featuresCard.trailingAnchor, constant: mode == .plans ? -28 : -16),
            featuresStack.bottomAnchor.constraint(equalTo: featuresCard.bottomAnchor, constant: mode == .plans ? -29 : -20),
        ])
    }

    // MARK: - CTA Button
    private func buildCTASection() {
        ctaButton.addSubview(loadingIndicator)
        contentView.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: ctaButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: ctaButton.centerYAnchor),

            ctaButton.topAnchor.constraint(equalTo: featuresCard.bottomAnchor, constant: mode == .plans ? 25 : 24),
            ctaButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: mode == .plans ? 42 : 16),
            ctaButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: mode == .plans ? -42 : -16),
            ctaButton.heightAnchor.constraint(equalToConstant: Self.buttonHeight),
        ])
    }

    // MARK: - Footer
    private func buildFooterSection() {
        contentView.addSubview(freeTrialLabel)
        contentView.addSubview(recurringLabel)

        NSLayoutConstraint.activate([
            freeTrialLabel.topAnchor.constraint(equalTo: ctaButton.bottomAnchor, constant: mode == .plans ? 20 : 14),
            freeTrialLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            freeTrialLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            recurringLabel.topAnchor.constraint(equalTo: freeTrialLabel.bottomAnchor, constant: mode == .plans ? 22 : 6),
            recurringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recurringLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recurringLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onPurchaseSuccess = { [weak self] in self?.showSuccessAlert() }
        viewModel.onError = { [weak self] msg in self?.showErrorAlert(message: msg) }

        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.handleStateChange(state) }
            .store(in: &cancellables)

        viewModel.$selectedPlan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plan in
                self?.updatePlanSelection(selectedID: plan?.id ?? "")
                self?.updateCTAButton()
            }
            .store(in: &cancellables)
    }

    // MARK: - State Handling
    private func handleStateChange(_ state: SubscriptionViewState) {
        switch state {
        case .loading, .purchasing:
            ctaButton.isEnabled = false
            loadingIndicator.startAnimating()
            ctaButton.setTitle("", for: .normal)

        case .loaded:
            loadingIndicator.stopAnimating()
            ctaButton.isEnabled = true
            populatePlanViews()

        case .error(let message):
            loadingIndicator.stopAnimating()
            ctaButton.isEnabled = true
            showErrorAlert(message: message)
        }
    }

    private func populatePlanViews() {
        guard !plansPopulated, mode == .plans else { return }
        let plans = viewModel.plans
        guard plans.count == planViews.count else { return }
        for (i, plan) in plans.enumerated() {
            planViews[i].configure(with: plan)
            planViews[i].hideSkeleton()
            let tap = UITapGestureRecognizer(target: self, action: #selector(planTapped(_:)))
            planViews[i].tag = i
            planViews[i].addGestureRecognizer(tap)
        }
        plansPopulated = true
    }

    private func updatePlanSelection(selectedID: String) {
        guard mode == .plans else { return }
        let plans = viewModel.plans
        for (i, planView) in planViews.enumerated() {
            guard i < plans.count else { continue }
            planView.isSelectedPlan = (plans[i].id == selectedID)
        }
    }

    private func updateCTAButton() {
        if case .loaded = viewModel.viewState {
            ctaButton.setTitle(viewModel.ctaTitle, for: .normal)
        }
    }

    // MARK: - Actions
    @objc private func planTapped(_ gesture: UITapGestureRecognizer) {
        guard let v = gesture.view, v.tag < viewModel.plans.count else { return }
        viewModel.selectPlan(viewModel.plans[v.tag])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func ctaTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { await viewModel.purchaseSelectedPlan() }
    }

    @objc private func backTapped() {
        self.dismiss(animated: true)
    }

    // MARK: - Alerts
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Subscription Activated",
                                      message: "You now have access to all premium travel features.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default) { [weak self] _ in self?.backTapped() })
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
