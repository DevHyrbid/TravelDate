//
//  OnboardingViewController.swift
//  TravelDate
//

import UIKit

// MARK: - OnboardingViewController

class OnboardingViewController: BaseClassVc {

    // MARK: - UI

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let skipButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Montserrat-SemiBold", size: 14)
                               ?? .systemFont(ofSize: 14, weight: .semibold)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        btn.layer.cornerRadius = 18
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Montserrat-Bold", size: 16)
                               ?? .systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let dotsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var dotViews: [UIView] = []
    private var dotWidthConstraints: [NSLayoutConstraint] = []
    private var nextWidthConstraint: NSLayoutConstraint!

    // MARK: - Data

    struct OnboardingItem {
        let image: String
        let title: NSAttributedString
        let subtitle: String
        let showSkip: Bool
    }

    private var items: [OnboardingItem] = []
    private var currentIndex = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupData()
        setupCollectionView()
        setupBottomBar()
//        setupSkipButton()
        collectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally, animated: true)
        updateUI(for: currentIndex, animated: true)
        self.hideNavigate(true)
        if User.currentUserExists {
            self.pushVC(TripsTabBarController.self, from: .Home)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide navigation bar — removes the "Back" button
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup Data

    private func setupData() {
        items = [
            OnboardingItem(
                image: "onboarding1",
                title: makeTitle(normal: "Discover the ", highlight: "Beauty\nof the World"),
                subtitle: "If you like to travel, this is the place for you.",
                showSkip: true
            ),
            OnboardingItem(
                image: "onboarding2",
                title: makeTitle(normal: "Find Your Perfect\n", highlight: "Travel Group"),
                subtitle: "Match with compatible travelers based on destinations, dates, and shared interests.",
                showSkip: true
            ),
            OnboardingItem(
                image: "onboarding3",
                title: makeTitle(normal: "Your ", highlight: "Next Adventure\n", trailing: "Starts with Them"),
                subtitle: "Travellers are already connecting. Don't miss your chance to be part of it.",
                showSkip: false
            )
        ]
    }

    // MARK: - Setup CollectionView (full screen)

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.id)

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Setup Bottom Bar (dots + next button)

    private func setupBottomBar() {
        view.addSubview(dotsStack)
        view.addSubview(nextButton)

        for _ in 0..<items.count {
            let dot = UIView()
            dot.layer.cornerRadius = 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            dotsStack.addArrangedSubview(dot)
            dotViews.append(dot)

            dot.heightAnchor.constraint(equalToConstant: 4).isActive = true
            let wc = dot.widthAnchor.constraint(equalToConstant: 10)
            wc.isActive = true
            dotWidthConstraints.append(wc)
        }

        nextWidthConstraint = nextButton.widthAnchor.constraint(equalToConstant: 110)

        NSLayoutConstraint.activate([
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 52),
            nextWidthConstraint,

            dotsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            dotsStack.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
        ])

        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Setup Skip Button

    private func setupSkipButton() {
        view.addSubview(skipButton)
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            skipButton.heightAnchor.constraint(equalToConstant: 36),
        ])
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    // MARK: - Update UI

    private func updateUI(for index: Int, animated: Bool) {
        let isLast = index == items.count - 1
        let item   = items[index]

        let skipAlpha: CGFloat = item.showSkip ? 1 : 0
        let title  = isLast ? "Let's Get Started" : "Next"
        let width: CGFloat = isLast ? 200 : 110

        let apply = {
            self.skipButton.alpha = skipAlpha
            self.nextButton.setTitle(title, for: .normal)
            self.nextWidthConstraint.constant = width
            self.updateDots(for: index)
            self.view.layoutIfNeeded()
        }

        animated
            ? UIView.animate(withDuration: 0.25, animations: apply)
            : apply()
    }

    private func updateDots(for index: Int) {
        let orange = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        let gray   = UIColor.white.withAlphaComponent(0.4)
        for (i, dot) in dotViews.enumerated() {
            dot.backgroundColor          = i == index ? orange : gray
            dotWidthConstraints[i].constant = i == index ? 22 : 10
        }
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            collectionView.scrollToItem(
                at: IndexPath(item: currentIndex, section: 0),
                at: .centeredHorizontally, animated: true)
            updateUI(for: currentIndex, animated: true)
        } else {
            goToLogin()
        }
    }

    @objc private func skipTapped() { goToLogin() }

    private func goToLogin() {
        self.pushVC(LoginViewController.self, from: .Main)
    }

    // MARK: - Attributed Title Helper

    private func makeTitle(
        normal: String = "",
        highlight: String,
        trailing: String = ""
    ) -> NSAttributedString {
        let font   = UIFont(name: "Montserrat-ExtraBold", size: 30)
                     ?? UIFont.systemFont(ofSize: 30, weight: .heavy)
        let orange = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        let attr   = NSMutableAttributedString()
        if !normal.isEmpty {
            attr.append(NSAttributedString(string: normal,
                attributes: [.foregroundColor: UIColor.white, .font: font]))
        }
        attr.append(NSAttributedString(string: highlight,
            attributes: [.foregroundColor: orange, .font: font]))
        if !trailing.isEmpty {
            attr.append(NSAttributedString(string: trailing,
                attributes: [.foregroundColor: UIColor.white, .font: font]))
        }
        return attr
    }
}

// MARK: - CollectionView DataSource / Delegate

extension OnboardingViewController: UICollectionViewDelegate,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(
            withReuseIdentifier: OnboardingCell.id, for: indexPath) as! OnboardingCell
        cell.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(_ cv: UICollectionView,
                        layout layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize { cv.frame.size }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.frame.width)
        guard index != currentIndex else { return }
        currentIndex = index
        updateUI(for: index, animated: true)
    }
}

// MARK: - OnboardingCell

class OnboardingCell: UICollectionViewCell {

    static let id = "OnboardingCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// GradientView uses layerClass so its CAGradientLayer always matches bounds automatically
    private let gradientView = GradientView()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = UIFont(name: "Montserrat-Medium", size: 14)
                ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.82)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        contentView.addSubview(imageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        gradientView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Full-bleed image
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Gradient — full cell
            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Subtitle — clears the bottom bar (52 button + 20 padding + 34 safeArea ≈ 115)
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            subtitleLabel.bottomAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -115),

            // Title — 14pt gap above subtitle
            titleLabel.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: subtitleLabel.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: OnboardingViewController.OnboardingItem) {
        imageView.image           = UIImage(named: item.image)
        titleLabel.attributedText = item.title
        subtitleLabel.text        = item.subtitle
    }
}

// MARK: - GradientView
// Uses layerClass so CAGradientLayer resizes automatically with Auto Layout — no layoutSubviews hack needed.

final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradient: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.80).cgColor,
            UIColor.black.withAlphaComponent(0.92).cgColor,
        ]
        gradient.locations = [0.0, 0.35, 0.58, 0.75, 1.0]
    }

    required init?(coder: NSCoder) { fatalError() }
}
