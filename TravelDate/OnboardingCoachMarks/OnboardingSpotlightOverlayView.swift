//
//  OnboardingSpotlightOverlayView.swift
//  TravelDate Onboarding Coach Marks
//

import UIKit

final class OnboardingSpotlightOverlayView: UIView {

    // MARK: - UI

    private let dimLayer = CAShapeLayer()

    private let bubbleView = UIView()
    private let arrowView = UIView()

    private let illustrationView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    private let pageLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    // MARK: - State

    private var targetFrameInSelf: CGRect = .zero

    private var position: OnboardingTooltipPosition = .above

    private var currentPage: Int = 1
    private var totalPages: Int = 1

    private var bubbleFrame: CGRect = .zero

    // MARK: - Callbacks

    var onNext: (() -> Void)?
    var onSkip: (() -> Void)?

    // MARK: - Constants

    private let horizontalPadding: CGFloat = 16
    private let bubbleHorizontalPadding: CGFloat = 20

    private let bubbleCornerRadius: CGFloat = 18

    private let arrowWidth: CGFloat = 20
    private let arrowHeight: CGFloat = 10

    private let targetPadding: CGFloat = 8

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {

        backgroundColor = .clear

        // =========================================================
        // DIM LAYER
        // =========================================================

        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black
            .withAlphaComponent(0.62)
            .cgColor

        layer.addSublayer(dimLayer)

        // =========================================================
        // BUBBLE
        // =========================================================

        bubbleView.backgroundColor = UIColor(
            red: 0.85,
            green: 0.93,
            blue: 1.0,
            alpha: 1.0
        )

        bubbleView.layer.cornerRadius = bubbleCornerRadius

        bubbleView.layer.shadowColor =
            UIColor.black.cgColor

        bubbleView.layer.shadowOpacity = 0.18
        bubbleView.layer.shadowRadius = 12

        bubbleView.layer.shadowOffset =
            CGSize(width: 0, height: 5)

        bubbleView.clipsToBounds = false

        addSubview(bubbleView)

        // =========================================================
        // ARROW
        // =========================================================

        arrowView.backgroundColor =
            bubbleView.backgroundColor

        arrowView.layer.shadowColor =
            UIColor.black.cgColor

        arrowView.layer.shadowOpacity = 0.10
        arrowView.layer.shadowRadius = 4

        arrowView.layer.shadowOffset =
            CGSize(width: 0, height: 2)

        addSubview(arrowView)

        // =========================================================
        // ILLUSTRATION
        // =========================================================

        illustrationView.contentMode = .scaleAspectFit

        illustrationView.clipsToBounds = true

        illustrationView.layer.cornerRadius = 10

        // =========================================================
        // TITLE
        // =========================================================

        titleLabel.font = .systemFont(
            ofSize: 17,
            weight: .bold
        )

        titleLabel.textColor = .label

        titleLabel.numberOfLines = 0

        titleLabel.lineBreakMode = .byWordWrapping

        // =========================================================
        // DESCRIPTION
        // =========================================================

        descriptionLabel.font = .systemFont(
            ofSize: 14,
            weight: .regular
        )

        descriptionLabel.textColor = .darkGray

        descriptionLabel.numberOfLines = 0

        descriptionLabel.lineBreakMode = .byWordWrapping

        // =========================================================
        // PAGE LABEL
        // =========================================================

        pageLabel.font = .systemFont(
            ofSize: 12,
            weight: .medium
        )

        pageLabel.textColor = UIColor(
            white: 0,
            alpha: 0.55
        )

        pageLabel.textAlignment = .center

        // =========================================================
        // SKIP BUTTON
        // =========================================================

        skipButton.setTitle(
            "Skip",
            for: .normal
        )

        skipButton.setTitleColor(
            UIColor.black.withAlphaComponent(0.55),
            for: .normal
        )

        skipButton.titleLabel?.font =
            .systemFont(
                ofSize: 13,
                weight: .medium
            )

        skipButton.addTarget(
            self,
            action: #selector(handleSkip),
            for: .touchUpInside
        )

        // =========================================================
        // NEXT BUTTON
        // =========================================================

        nextButton.setTitle(
            "Next",
            for: .normal
        )

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
            action: #selector(handleNext),
            for: .touchUpInside
        )

        // =========================================================
        // ADD SUBVIEWS
        // =========================================================

        [
            illustrationView,
            titleLabel,
            descriptionLabel,
            pageLabel,
            skipButton,
            nextButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            bubbleView.addSubview($0)
        }

        // =========================================================
        // CONSTRAINTS
        // =========================================================

        NSLayoutConstraint.activate([

            // -----------------------------------------------------
            // Illustration
            // -----------------------------------------------------

            illustrationView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: 16
            ),

            illustrationView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: 16
            ),

            illustrationView.widthAnchor.constraint(
                equalToConstant: 58
            ),

            illustrationView.heightAnchor.constraint(
                equalToConstant: 58
            ),

            // -----------------------------------------------------
            // Title
            // -----------------------------------------------------

            titleLabel.leadingAnchor.constraint(
                equalTo: illustrationView.trailingAnchor,
                constant: 12
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -16
            ),

            titleLabel.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: 16
            ),

            // -----------------------------------------------------
            // Description
            // -----------------------------------------------------

            descriptionLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            descriptionLabel.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 5
            ),

            // -----------------------------------------------------
            // Page
            // -----------------------------------------------------

            pageLabel.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: 16
            ),

            pageLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -14
            ),

            // -----------------------------------------------------
            // Skip
            // -----------------------------------------------------

            skipButton.leadingAnchor.constraint(
                equalTo: pageLabel.trailingAnchor,
                constant: 12
            ),

            skipButton.centerYAnchor.constraint(
                equalTo: pageLabel.centerYAnchor
            ),

            // -----------------------------------------------------
            // Next
            // -----------------------------------------------------

            nextButton.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -16
            ),

            nextButton.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -9
            ),

            nextButton.heightAnchor.constraint(
                equalToConstant: 36
            )
        ])
    }

    // MARK: - Configure

    func configure(
        step: OnboardingStep,
        targetFrame: CGRect,
        currentPage: Int,
        totalPages: Int
    ) {

        illustrationView.image = step.illustration

        illustrationView.isHidden =
            step.illustration == nil

        titleLabel.text = step.title

        descriptionLabel.text =
            step.description

        targetFrameInSelf =
            targetFrame

        position =
            step.tooltipPosition

        self.currentPage =
            currentPage

        self.totalPages =
            totalPages

        pageLabel.text =
            "\(currentPage) of \(totalPages)"

        let isLastPage =
            currentPage == totalPages

        nextButton.setTitle(
            isLastPage ? "Done" : "Next",
            for: .normal
        )

        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Layout

    override func layoutSubviews() {

        super.layoutSubviews()

        guard bounds != .zero else {
            return
        }

        layoutSpotlight()

        layoutBubble()

        layoutArrow()
    }

    // MARK: - Spotlight

    private func layoutSpotlight() {

        let path =
            UIBezierPath(rect: bounds)

        let spotlightRect =
            targetFrameInSelf.insetBy(
                dx: -targetPadding,
                dy: -targetPadding
            )

        // Use rounded rectangle instead of circle.
        let roundedSpotlight =
            UIBezierPath(
                roundedRect: spotlightRect,
                cornerRadius: 14
            )

        path.append(roundedSpotlight)

        dimLayer.path =
            path.cgPath

        dimLayer.frame =
            bounds
    }

    // MARK: - Bubble Layout

    private func layoutBubble() {

        let maxBubbleWidth =
            bounds.width - (
                horizontalPadding * 2
            )

        let bubbleWidth =
            min(340, maxBubbleWidth)

        let bubbleHeight =
            calculateBubbleHeight(
                width: bubbleWidth
            )

        let targetRect =
            targetFrameInSelf.insetBy(
                dx: -targetPadding,
                dy: -targetPadding
            )

        let spaceAbove =
            targetRect.minY

        let spaceBelow =
            bounds.height - targetRect.maxY

        let minimumSpaceNeeded =
            bubbleHeight + arrowHeight + 16

        var finalPosition =
            position

        // Automatically move below if there isn't enough
        // room above.

        if position == .above &&
            spaceAbove < minimumSpaceNeeded &&
            spaceBelow > spaceAbove {

            finalPosition = .below
        }

        // Automatically move above if there isn't enough
        // room below.

        if position == .below &&
            spaceBelow < minimumSpaceNeeded &&
            spaceAbove > spaceBelow {

            finalPosition = .above
        }

        position =
            finalPosition

        // ---------------------------------------------------------
        // Horizontal position
        // ---------------------------------------------------------

        var bubbleX =
            targetRect.midX - bubbleWidth / 2

        bubbleX =
            max(
                horizontalPadding,
                min(
                    bubbleX,
                    bounds.width
                        - bubbleWidth
                        - horizontalPadding
                )
            )

        // ---------------------------------------------------------
        // Vertical position
        // ---------------------------------------------------------

        let bubbleY: CGFloat

        switch finalPosition {

        case .above:

            bubbleY =
                targetRect.minY
                - bubbleHeight
                - arrowHeight
                - 6

        case .below:

            bubbleY =
                targetRect.maxY
                + arrowHeight
                + 6
        }

        let safeTop =
            safeAreaInsets.top + 8

        let safeBottom =
            bounds.height
            - safeAreaInsets.bottom
            - 8

        let finalY =
            max(
                safeTop,
                min(
                    bubbleY,
                    safeBottom - bubbleHeight
                )
            )

        bubbleFrame =
            CGRect(
                x: bubbleX,
                y: finalY,
                width: bubbleWidth,
                height: bubbleHeight
            )

        bubbleView.frame =
            bubbleFrame
    }

    // MARK: - Bubble Height

    private func calculateBubbleHeight(
        width: CGFloat
    ) -> CGFloat {

        let contentWidth =
            width - 32

        let titleWidth =
            contentWidth - 70

        let descriptionWidth =
            titleWidth

        let titleHeight =
            titleLabel.sizeThatFits(
                CGSize(
                    width: titleWidth,
                    height: .greatestFiniteMagnitude
                )
            ).height

        let descriptionHeight =
            descriptionLabel.sizeThatFits(
                CGSize(
                    width: descriptionWidth,
                    height: .greatestFiniteMagnitude
                )
            ).height

        let topPadding: CGFloat = 16

        let titleDescriptionSpacing: CGFloat = 5

        let footerHeight: CGFloat = 36

        let footerTopSpacing: CGFloat = 14

        let bottomPadding: CGFloat = 14

        let textHeight =
            max(
                58,
                titleHeight + titleDescriptionSpacing + descriptionHeight
            )

        let contentHeight =
            topPadding
            + textHeight
            + footerTopSpacing
            + footerHeight
            + bottomPadding

        return max(
            150,
            min(
                contentHeight,
                230
            )
        )
    }

    // MARK: - Arrow

    private func layoutArrow() {

        let targetRect =
            targetFrameInSelf.insetBy(
                dx: -targetPadding,
                dy: -targetPadding
            )

        let arrowCenterX =
            min(
                max(
                    targetRect.midX,
                    bubbleFrame.minX + 25
                ),
                bubbleFrame.maxX - 25
            )

        arrowView.transform =
            CGAffineTransform(
                rotationAngle: .pi / 4
            )

        arrowView.bounds =
            CGRect(
                x: 0,
                y: 0,
                width: arrowWidth,
                height: arrowWidth
            )

        switch position {

        case .above:

            arrowView.center =
                CGPoint(
                    x: arrowCenterX,
                    y: bubbleFrame.maxY
                        - 1
                )

        case .below:

            arrowView.center =
                CGPoint(
                    x: arrowCenterX,
                    y: bubbleFrame.minY
                        + 1
                )
        }
    }

    // MARK: - Actions

    @objc
    private func handleNext() {

        onNext?()
    }

    @objc
    private func handleSkip() {

        onSkip?()
    }
}
