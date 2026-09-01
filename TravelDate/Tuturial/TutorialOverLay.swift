//
//  TutorialOverLay.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/08/26.
//

import UIKit

final class TutorialOverlayView: UIView {

    // MARK: - UI

    private let dimView = UIView()
    private let spotlightView = UIView()

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    private let nextButton = UIButton(type: .system)
    private let previousButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)

    private let pageLabel = UILabel()

    // MARK: - Callbacks

    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onSkip: (() -> Void)?

    // MARK: - State

    private var currentStep: TutorialStep?
    private var currentIndex = 0
    private var totalSteps = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {

        backgroundColor = .clear

        // MARK: Dim View

        dimView.backgroundColor =
            UIColor.black.withAlphaComponent(0.72)

        dimView.frame = bounds
        dimView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        addSubview(dimView)

        // MARK: Spotlight

        spotlightView.backgroundColor =
            UIColor.white.withAlphaComponent(0.10)

        spotlightView.layer.borderWidth = 2.5
        spotlightView.layer.borderColor =
            UIColor.white.cgColor

        spotlightView.layer.shadowColor =
            UIColor.white.cgColor

        spotlightView.layer.shadowOpacity = 1
        spotlightView.layer.shadowRadius = 10
        spotlightView.layer.shadowOffset = .zero

        spotlightView.isUserInteractionEnabled = false

        addSubview(spotlightView)

        // MARK: Card

        cardView.backgroundColor =
            UIColor.systemBackground.withAlphaComponent(0.97)

        cardView.layer.cornerRadius = 16

        cardView.layer.shadowColor =
            UIColor.black.cgColor

        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowRadius = 10
        cardView.layer.shadowOffset =
            CGSize(width: 0, height: 4)

        cardView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardView)

        // MARK: Title

        titleLabel.font =
            UIFont.boldSystemFont(ofSize: 17)

        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(titleLabel)

        // MARK: Message

        messageLabel.font =
            UIFont.systemFont(ofSize: 14)

        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0

        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(messageLabel)

        // MARK: Page

        pageLabel.font =
            UIFont.systemFont(
                ofSize: 12,
                weight: .medium
            )

        pageLabel.textColor = .secondaryLabel

        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(pageLabel)

        // MARK: Previous

        previousButton.setTitle(
            "Previous",
            for: .normal
        )

        previousButton.titleLabel?.font =
            UIFont.systemFont(
                ofSize: 13,
                weight: .medium
            )

        previousButton.addTarget(
            self,
            action: #selector(previousTapped),
            for: .touchUpInside
        )

        previousButton.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(previousButton)

        // MARK: Next

        nextButton.setTitle(
            "Next",
            for: .normal
        )

        nextButton.titleLabel?.font =
            UIFont.systemFont(
                ofSize: 14,
                weight: .bold
            )

        nextButton.addTarget(
            self,
            action: #selector(nextTapped),
            for: .touchUpInside
        )

        nextButton.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(nextButton)

        // MARK: Skip

        skipButton.setTitle(
            "Skip",
            for: .normal
        )

        skipButton.titleLabel?.font =
            UIFont.systemFont(ofSize: 13)

        skipButton.addTarget(
            self,
            action: #selector(skipTapped),
            for: .touchUpInside
        )

        skipButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(skipButton)

        // MARK: Card Constraints

        NSLayoutConstraint.activate([

            cardView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),

            cardView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),

            cardView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 150
            ),

            titleLabel.topAnchor.constraint(
                equalTo: cardView.topAnchor,
                constant: 16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor,
                constant: 16
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -16
            ),

            messageLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 7
            ),

            messageLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            messageLabel.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            pageLabel.topAnchor.constraint(
                equalTo: messageLabel.bottomAnchor,
                constant: 10
            ),

            pageLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            previousButton.topAnchor.constraint(
                equalTo: pageLabel.bottomAnchor,
                constant: 10
            ),

            previousButton.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            previousButton.bottomAnchor.constraint(
                equalTo: cardView.bottomAnchor,
                constant: -14
            ),

            nextButton.centerYAnchor.constraint(
                equalTo: previousButton.centerYAnchor
            ),

            nextButton.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            skipButton.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 12
            ),

            skipButton.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            )
        ])
    }

    // MARK: - Show Step

    func show(
        step: TutorialStep,
        index: Int,
        total: Int
    ) {

        currentStep = step
        currentIndex = index
        totalSteps = total

        titleLabel.text = step.title
        messageLabel.text = step.message

        pageLabel.text = "\(index + 1) of \(total)"

        previousButton.isHidden = index == 0

        nextButton.setTitle(
            index == total - 1
            ? "Finish"
            : "Next",
            for: .normal
        )

        layoutIfNeeded()

        updateSpotlight(step: step)
    }

    // MARK: - Spotlight

    private func updateSpotlight(
        step: TutorialStep
    ) {

        // No target view
        guard let targetView = step.targetView else {

            if let customFrame = step.customFrame {

                spotlightView.isHidden = false

                spotlightView.frame =
                    customFrame.insetBy(
                        dx: -8,
                        dy: -8
                    )

                spotlightView.layer.cornerRadius = 14

            } else {

                spotlightView.isHidden = true
            }

            positionCardAboveBottom()

            return
        }

        // Convert target button frame
        let convertedFrame = targetView.convert(
            targetView.bounds,
            to: self
        )

        guard !convertedFrame.isEmpty else {
            spotlightView.isHidden = true
            return
        }

        // Make highlight slightly bigger
        let frame = convertedFrame.insetBy(
            dx: -10,
            dy: -8
        )

        spotlightView.isHidden = false
        spotlightView.frame = frame

        spotlightView.layer.cornerRadius = 14

        // Put tooltip above highlighted tab
        positionCardAboveTab(
            targetFrame: frame
        )

        bringSubviewToFront(spotlightView)
        bringSubviewToFront(cardView)
        bringSubviewToFront(skipButton)
    }

    // MARK: - Tooltip Position

    private func positionCardAboveTab(
        targetFrame: CGRect
    ) {

        // Remove constraints temporarily
        cardView.translatesAutoresizingMaskIntoConstraints = true

        let cardWidth =
            bounds.width - 40

        let cardHeight: CGFloat = 155

        let spacing: CGFloat = 14

        var x =
            bounds.midX - cardWidth / 2

        var y =
            targetFrame.minY -
            cardHeight -
            spacing

        // Keep inside screen
        x = max(
            20,
            min(
                x,
                bounds.width - cardWidth - 20
            )
        )

        // If there isn't enough space above,
        // show it above the tab bar area
        if y < safeAreaInsets.top + 50 {

            y = targetFrame.maxY + spacing
        }

        // Prevent going below screen
        if y + cardHeight >
            bounds.height - safeAreaInsets.bottom {

            y =
                bounds.height -
                safeAreaInsets.bottom -
                cardHeight -
                10
        }

        cardView.frame = CGRect(
            x: x,
            y: y,
            width: cardWidth,
            height: cardHeight
        )

        cardView.setNeedsLayout()
        cardView.layoutIfNeeded()
    }

    // MARK: - Bottom Position

    private func positionCardAboveBottom() {

        cardView.translatesAutoresizingMaskIntoConstraints = true

        let width = bounds.width - 40
        let height: CGFloat = 155

        cardView.frame = CGRect(
            x: 20,
            y: bounds.height
                - safeAreaInsets.bottom
                - height
                - 20,
            width: width,
            height: height
        )

        cardView.setNeedsLayout()
        cardView.layoutIfNeeded()
    }

    // MARK: - Actions

    @objc
    private func nextTapped() {
        onNext?()
    }

    @objc
    private func previousTapped() {
        onPrevious?()
    }

    @objc
    private func skipTapped() {
        onSkip?()
    }
}
