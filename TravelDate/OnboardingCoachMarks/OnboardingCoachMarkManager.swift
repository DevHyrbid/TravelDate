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

    /// Bumped every time start()/advance()/finish() runs so an
    /// in-flight spotlight-readiness retry can tell if it's stale
    /// (user skipped, flow restarted, etc.) and bail out quietly.
    private var stepToken = 0

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

        stepToken += 1

        guard
            let host = containerView,
            currentIndex < steps.count
        else {
            return
        }

        let step = steps[currentIndex]
        let myToken = stepToken

        switch step.style {

        // MARK: Spotlight

        case .spotlight(let targetProvider):

            showSpotlightStep(
                step: step,
                host: host,
                targetProvider: targetProvider,
                token: myToken,
                retriesLeft: 8
            )

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

    // MARK: - Spotlight (with readiness retry)

    /// Some spotlight targets (e.g. a button whose visibility/frame
    /// depends on an async API response, like a "view groups" icon
    /// that only appears once data loads) can report a stale or
    /// zero frame the instant onboarding starts in viewDidAppear.
    /// Spotlighting that stale frame is what causes the bubble to
    /// render in the wrong place. So instead of grabbing the target
    /// once, we poll briefly until it's actually attached, visible,
    /// and has a real laid-out size — then spotlight it.
    private func showSpotlightStep(
        step: OnboardingStep,
        host: UIView,
        targetProvider: @escaping () -> UIView?,
        token: Int,
        retriesLeft: Int
    ) {

        // Another step started (advance/skip/restart) while we
        // were waiting — drop this attempt.
        guard token == stepToken else {
            return
        }

        guard
            let target = targetProvider(),
            target.window != nil,
            !target.isHidden,
            target.bounds.width > 0,
            target.bounds.height > 0
        else {

            guard retriesLeft > 0 else {
                // Target never became ready in time — skip this
                // step rather than spotlighting garbage coordinates.
                advance()
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.showSpotlightStep(
                    step: step,
                    host: host,
                    targetProvider: targetProvider,
                    token: token,
                    retriesLeft: retriesLeft - 1
                )
            }
            return
        }

        // Auto-scroll the target into view if it lives inside a
        // scroll view (e.g. btnCreateGroup sitting below the fold
        // on scrollVw). No manual wiring needed — we just walk up
        // the target's superview chain.
        if let scrollView = nearestScrollView(above: target) {

            let targetFrameInScroll = target.convert(
                target.bounds,
                to: scrollView
            )

            scrollView.scrollRectToVisible(
                targetFrameInScroll.insetBy(dx: 0, dy: -60),
                animated: false
            )

            scrollView.layoutIfNeeded()
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
    }

    // MARK: - Nearest Scroll View

    private func nearestScrollView(above view: UIView) -> UIScrollView? {

        var current = view.superview

        while let v = current {
            if let scrollView = v as? UIScrollView {
                return scrollView
            }
            current = v.superview
        }

        return nil
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

        stepToken += 1

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
            stepToken += 1
            overlayView?.removeFromSuperview()
            overlayView = nil
        }
    }

    // MARK: - Public Dismiss

    func dismiss() {

        stepToken += 1
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
