
//
//  OnboardingCoachMarkManager.swift
//  TravelDate Onboarding Coach Marks
//

import UIKit

final class OnboardingCoachMarkManager: NSObject {

    static let shared = OnboardingCoachMarkManager()

    private override init() {
        super.init()
    }

    private var containerView: UIView?
    private var overlayView: UIView?

    private var steps: [OnboardingStep] = []
    private var currentIndex = 0

    private var flowID = ""
    private var completion: (() -> Void)?

    // MARK: - Start

    func start(
        flowID: String,
        steps: [OnboardingStep],
        in hostView: UIView,
        force: Bool = false,
        completion: (() -> Void)? = nil
    ) {

        guard !steps.isEmpty else {
            return
        }

//        if !force && OnboardingSeenStore.hasSeen(flowID) {
//            return
//        }

        self.flowID = flowID
        self.steps = steps
        self.currentIndex = 0
        self.containerView = hostView
        self.completion = completion

        showCurrentStep()
    }

    // MARK: - Show Current Step

    private func showCurrentStep() {

        overlayView?.removeFromSuperview()

        guard
            let host = containerView,
            currentIndex < steps.count
        else {
            return
        }

        let step = steps[currentIndex]

        switch step.style {

        // MARK: Spotlight

        case .spotlight(let targetProvider):

            guard let target = targetProvider() else {
                advance()
                return
            }

            let spotlight = OnboardingSpotlightOverlayView(
                frame: host.bounds
            )

            spotlight.translatesAutoresizingMaskIntoConstraints = false

            host.addSubview(spotlight)

            NSLayoutConstraint.activate([
                spotlight.topAnchor.constraint(equalTo: host.topAnchor),
                spotlight.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                spotlight.trailingAnchor.constraint(equalTo: host.trailingAnchor),
                spotlight.bottomAnchor.constraint(equalTo: host.bottomAnchor)
            ])

            host.layoutIfNeeded()

            let targetFrame = target.convert(
                target.bounds,
                to: spotlight
            )

            spotlight.configure(
                step: step,
                targetFrame: targetFrame,
                currentPage: currentIndex + 1,
                totalPages: steps.count
            )

            spotlight.onNext = { [weak self] in
                self?.advance()
            }

            spotlight.onSkip = { [weak self] in
                self?.finish()
            }

            overlayView = spotlight

        // MARK: Card

        case .card:

            let card = OnboardingCardOverlayView(
                frame: host.bounds
            )

            card.translatesAutoresizingMaskIntoConstraints = false
            card.delegate = self

            host.addSubview(card)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: host.topAnchor),
                card.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: host.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: host.bottomAnchor)
            ])

            card.configure(
                step: step,
                currentPage: currentIndex + 1,
                totalPages: steps.count
            )

            overlayView = card
        }
    }

    // MARK: - Advance

    private func advance() {

        currentIndex += 1

        if currentIndex >= steps.count {
            finish()
        } else {
            showCurrentStep()
        }
    }

    // MARK: - Finish

    private func finish() {

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.overlayView?.alpha = 0
            },
            completion: { _ in

                self.overlayView?.removeFromSuperview()
                self.overlayView = nil

                OnboardingSeenStore.markSeen(self.flowID)

                self.completion?()
                self.completion = nil
            }
        )
    }

    // MARK: - Public Reset

    func reset(flowID: String) {

        OnboardingSeenStore.reset(flowID)

        if self.flowID == flowID {
            overlayView?.removeFromSuperview()
            overlayView = nil
        }
    }

    // MARK: - Public Dismiss

    func dismiss() {

        overlayView?.removeFromSuperview()
        overlayView = nil
    }
}

// MARK: - Card Delegate

extension OnboardingCoachMarkManager: OnboardingCardOverlayViewDelegate {

    func onboardingCardDidTapRestart(
        _ view: OnboardingCardOverlayView
    ) {
        currentIndex = 0
        showCurrentStep()
    }

    func onboardingCardDidTapNext(
        _ view: OnboardingCardOverlayView
    ) {
        advance()
    }

    func onboardingCardDidTapSkip(
        _ view: OnboardingCardOverlayView
    ) {
        finish()
    }
}


