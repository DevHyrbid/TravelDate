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

    private var cardBottomConstraint: NSLayoutConstraint!
    private var cardTopConstraint: NSLayoutConstraint!

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

        // ------------------------------------------------
        // DIM VIEW
        // ------------------------------------------------

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dimView)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // ------------------------------------------------
        // SPOTLIGHT
        // ------------------------------------------------

        spotlightView.backgroundColor = .clear
        spotlightView.layer.borderWidth = 2
        spotlightView.layer.borderColor = UIColor.white.cgColor
        spotlightView.layer.shadowColor = UIColor.white.cgColor
        spotlightView.layer.shadowOpacity = 0.9
        spotlightView.layer.shadowRadius = 10
        spotlightView.isUserInteractionEnabled = false

        addSubview(spotlightView)

        // ------------------------------------------------
        // CARD
        // ------------------------------------------------

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.25
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        cardView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardView)

        // ------------------------------------------------
        // TITLE
        // ------------------------------------------------

        titleLabel.font = UIFont.boldSystemFont(ofSize: 21)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(titleLabel)

        // ------------------------------------------------
        // MESSAGE
        // ------------------------------------------------

        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0

        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(messageLabel)

        // ------------------------------------------------
        // PAGE
        // ------------------------------------------------

        pageLabel.font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )

        pageLabel.textColor = .secondaryLabel
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(pageLabel)

        // ------------------------------------------------
        // PREVIOUS
        // ------------------------------------------------

        previousButton.setTitle(
            "Previous",
            for: .normal
        )

        previousButton.titleLabel?.font =
            UIFont.systemFont(
                ofSize: 15,
                weight: .medium
            )

        previousButton.addTarget(
            self,
            action: #selector(previousTapped),
            for: .touchUpInside
        )

        previousButton.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(previousButton)

        // ------------------------------------------------
        // NEXT
        // ------------------------------------------------

        nextButton.setTitle(
            "Next",
            for: .normal
        )

        nextButton.titleLabel?.font =
            UIFont.systemFont(
                ofSize: 16,
                weight: .bold
            )

        nextButton.addTarget(
            self,
            action: #selector(nextTapped),
            for: .touchUpInside
        )

        nextButton.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(nextButton)

        // ------------------------------------------------
        // SKIP
        // ------------------------------------------------

        skipButton.setTitle(
            "Skip",
            for: .normal
        )

        skipButton.titleLabel?.font =
            UIFont.systemFont(ofSize: 14)

        skipButton.addTarget(
            self,
            action: #selector(skipTapped),
            for: .touchUpInside
        )

        skipButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(skipButton)

        // ------------------------------------------------
        // CARD CONSTRAINTS
        // ------------------------------------------------

        cardTopConstraint = cardView.topAnchor.constraint(
            equalTo: safeAreaLayoutGuide.topAnchor,
            constant: 20
        )

        cardBottomConstraint = cardView.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor,
            constant: -20
        )

        cardBottomConstraint.isActive = true

        NSLayoutConstraint.activate([

            cardView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),

            cardView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),

            titleLabel.topAnchor.constraint(
                equalTo: cardView.topAnchor,
                constant: 20
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor,
                constant: 20
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -20
            ),

            messageLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 10
            ),

            messageLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            messageLabel.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            pageLabel.topAnchor.constraint(
                equalTo: messageLabel.bottomAnchor,
                constant: 18
            ),

            pageLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            previousButton.topAnchor.constraint(
                equalTo: pageLabel.bottomAnchor,
                constant: 15
            ),

            previousButton.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            previousButton.bottomAnchor.constraint(
                equalTo: cardView.bottomAnchor,
                constant: -18
            ),

            nextButton.centerYAnchor.constraint(
                equalTo: previousButton.centerYAnchor
            ),

            nextButton.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            skipButton.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 15
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
            index == total - 1 ? "Finish" : "Next",
            for: .normal
        )

        // Make sure layout has happened
        layoutIfNeeded()

        updateSpotlight(step: step)
    }

    // MARK: - Spotlight

    private func updateSpotlight(
        step: TutorialStep
    ) {

        guard let targetView = step.targetView else {

            if let customFrame = step.customFrame {

                spotlightView.isHidden = false

                spotlightView.frame = customFrame.insetBy(
                    dx: -8,
                    dy: -8
                )

            } else {

                spotlightView.isHidden = true
            }

            positionCard(for: nil)

            return
        }

        // IMPORTANT:
        // Convert target coordinates directly
        // into this overlay's coordinate system.

        let convertedFrame = targetView.convert(
            targetView.bounds,
            to: self
        )

        guard !convertedFrame.isEmpty else {
            spotlightView.isHidden = true
            return
        }

        var frame = convertedFrame.insetBy(
            dx: -8,
            dy: -8
        )

        // Keep spotlight inside overlay
        frame.origin.x = max(
            4,
            min(
                frame.origin.x,
                bounds.width - frame.width - 4
            )
        )

        frame.origin.y = max(
            4,
            min(
                frame.origin.y,
                bounds.height - frame.height - 4
            )
        )

        spotlightView.isHidden = false
        spotlightView.frame = frame

        spotlightView.layer.cornerRadius = 12

        positionCard(for: frame)

        bringSubviewToFront(spotlightView)
        bringSubviewToFront(cardView)
        bringSubviewToFront(skipButton)
    }

    // MARK: - Card Position

    private func positionCard(
        for targetFrame: CGRect?
    ) {

        cardTopConstraint.isActive = false
        cardBottomConstraint.isActive = false

        guard let targetFrame else {

            cardBottomConstraint.isActive = true

            layoutIfNeeded()

            return
        }

        let safeTop = safeAreaInsets.top + 70
        let safeBottom = bounds.height - safeAreaInsets.bottom

        let spaceAbove = targetFrame.minY - safeTop
        let spaceBelow = safeBottom - targetFrame.maxY

        if spaceBelow >= 220 {

            cardTopConstraint.isActive = false
            cardBottomConstraint.isActive = true

        } else if spaceAbove >= 220 {

            cardBottomConstraint.isActive = false
            cardTopConstraint.isActive = true

        } else {

            cardBottomConstraint.isActive = true
        }

        layoutIfNeeded()
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
