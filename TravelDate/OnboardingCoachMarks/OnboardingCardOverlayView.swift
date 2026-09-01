
//
//  OnboardingCardOverlayView.swift
//  TravelDate Onboarding Coach Marks
//

import UIKit

protocol OnboardingCardOverlayViewDelegate: AnyObject {

    func onboardingCardDidTapRestart(
        _ view: OnboardingCardOverlayView
    )

    func onboardingCardDidTapNext(
        _ view: OnboardingCardOverlayView
    )

    func onboardingCardDidTapSkip(
        _ view: OnboardingCardOverlayView
    )
}

final class OnboardingCardOverlayView: UIView {

    weak var delegate: OnboardingCardOverlayViewDelegate?

    private let dimView = UIView()
    private let cardView = UIView()

    private let illustrationView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    private let restartButton = UIButton(type: .system)
    private let pageLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {

        backgroundColor = .clear

        // MARK: Dim

        dimView.backgroundColor = UIColor.black
            .withAlphaComponent(0.55)

        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)

        // MARK: Card

        cardView.backgroundColor = UIColor(
            red: 0.08,
            green: 0.09,
            blue: 0.22,
            alpha: 1.0
        )

        cardView.layer.cornerRadius = 20

        cardView.layer.shadowColor =
            UIColor.black.cgColor

        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowRadius = 18

        cardView.layer.shadowOffset =
            CGSize(width: 0, height: 8)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        // MARK: Illustration

        illustrationView.contentMode = .scaleAspectFit

        // MARK: Title

        titleLabel.font = .systemFont(
            ofSize: 20,
            weight: .bold
        )

        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        // MARK: Description

        descriptionLabel.font = .systemFont(
            ofSize: 14,
            weight: .regular
        )

        descriptionLabel.textColor =
            UIColor.white.withAlphaComponent(0.75)

        descriptionLabel.numberOfLines = 0

        // MARK: Restart

        restartButton.setTitle(
            "Restart",
            for: .normal
        )

        restartButton.setTitleColor(
            UIColor.white.withAlphaComponent(0.8),
            for: .normal
        )

        restartButton.titleLabel?.font =
            .systemFont(
                ofSize: 14,
                weight: .medium
            )

        restartButton.addTarget(
            self,
            action: #selector(tapRestart),
            for: .touchUpInside
        )

        // MARK: Page

        pageLabel.font = .systemFont(
            ofSize: 13,
            weight: .medium
        )

        pageLabel.textColor =
            UIColor.white.withAlphaComponent(0.6)

        pageLabel.textAlignment = .center

        // MARK: Skip

        skipButton.setTitle(
            "Skip",
            for: .normal
        )

        skipButton.setTitleColor(
            UIColor.white.withAlphaComponent(0.7),
            for: .normal
        )

        skipButton.titleLabel?.font =
            .systemFont(
                ofSize: 13,
                weight: .medium
            )

        skipButton.addTarget(
            self,
            action: #selector(tapSkip),
            for: .touchUpInside
        )

        // MARK: Next

        nextButton.setTitleColor(
            .black,
            for: .normal
        )

        nextButton.titleLabel?.font =
            .systemFont(
                ofSize: 14,
                weight: .semibold
            )

        nextButton.backgroundColor = .white
        nextButton.layer.cornerRadius = 18

        nextButton.contentEdgeInsets =
            UIEdgeInsets(
                top: 8,
                left: 20,
                bottom: 8,
                right: 20
            )

        nextButton.addTarget(
            self,
            action: #selector(tapNext),
            for: .touchUpInside
        )

        // MARK: Footer

        let footerStack = UIStackView(
            arrangedSubviews: [
                restartButton,
                pageLabel,
                skipButton,
                nextButton
            ]
        )

        footerStack.axis = .horizontal
        footerStack.alignment = .center
        footerStack.distribution = .equalSpacing
        footerStack.spacing = 8

        // MARK: Add

        [
            illustrationView,
            titleLabel,
            descriptionLabel,
            footerStack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        // MARK: Constraints

        NSLayoutConstraint.activate([

            dimView.topAnchor.constraint(
                equalTo: topAnchor
            ),

            dimView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),

            dimView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),

            dimView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            cardView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),

            cardView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),

            cardView.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -30
            ),

            illustrationView.topAnchor.constraint(
                equalTo: cardView.topAnchor,
                constant: 20
            ),

            illustrationView.centerXAnchor.constraint(
                equalTo: cardView.centerXAnchor
            ),

            illustrationView.heightAnchor.constraint(
                equalToConstant: 90
            ),

            illustrationView.widthAnchor.constraint(
                equalToConstant: 140
            ),

            titleLabel.topAnchor.constraint(
                equalTo: illustrationView.bottomAnchor,
                constant: 16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor,
                constant: 20
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -20
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 8
            ),

            descriptionLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            descriptionLabel.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            footerStack.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 20
            ),

            footerStack.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor,
                constant: 20
            ),

            footerStack.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -20
            ),

            footerStack.bottomAnchor.constraint(
                equalTo: cardView.bottomAnchor,
                constant: -18
            )
        ])
    }

    // MARK: Configure

    func configure(
        step: OnboardingStep,
        currentPage: Int,
        totalPages: Int
    ) {

        illustrationView.image = step.illustration

        illustrationView.isHidden =
            step.illustration == nil

        titleLabel.text = step.title
        descriptionLabel.text = step.description

        pageLabel.text =
            "\(currentPage) of \(totalPages)"

        restartButton.isHidden =
            totalPages <= 1

        let isLastPage =
            currentPage == totalPages

        nextButton.setTitle(
            isLastPage ? "Done" : "Next",
            for: .normal
        )
    }

    // MARK: Actions

    @objc
    private func tapRestart() {
        delegate?.onboardingCardDidTapRestart(self)
    }

    @objc
    private func tapNext() {
        delegate?.onboardingCardDidTapNext(self)
    }

    @objc
    private func tapSkip() {
        delegate?.onboardingCardDidTapSkip(self)
    }
}


