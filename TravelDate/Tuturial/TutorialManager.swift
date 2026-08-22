//
//  TutorialManager.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/08/26.
//

import UIKit

final class TutorialManager {

    static let shared = TutorialManager()

    private init() {}

    // MARK: - Properties

    private var steps: [TutorialStep] = []

    private var currentIndex: Int = 0

    private weak var presentingViewController: UIViewController?

    private var overlayView: TutorialOverlayView?

    private var userId: String?

    // MARK: - Start

    func start(
        from viewController: UIViewController,
        steps: [TutorialStep],
        userId: String
    ) {
//
//        guard !steps.isEmpty else {
//            return
//        }

//        guard !isCompleted(for: userId) else {
//            return
//        }

        self.steps = steps

        self.currentIndex = 0

        self.presentingViewController = viewController

        self.userId = userId

        showOverlay()
    }

    // MARK: - Show Overlay

    private func showOverlay() {

        guard let viewController = presentingViewController else {
            return
        }

        let overlay = TutorialOverlayView(
            frame: viewController.view.bounds
        )

        overlay.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        overlay.onNext = { [weak self] in
            self?.next()
        }

        overlay.onPrevious = { [weak self] in
            self?.previous()
        }

        overlay.onSkip = { [weak self] in
            self?.skip()
        }

        viewController.view.addSubview(overlay)

        self.overlayView = overlay

        overlay.alpha = 0

        UIView.animate(
            withDuration: 0.25
        ) {
            overlay.alpha = 1
        }

        showCurrentStep()
    }

    // MARK: - Current Step

    private func showCurrentStep() {

        guard currentIndex < steps.count else {
            finish()
            return
        }

        let step = steps[currentIndex]

        overlayView?.show(
            step: step,
            index: currentIndex,
            total: steps.count
        )
    }

    // MARK: - Next

    private func next() {

        if currentIndex >= steps.count - 1 {

            finish()

        } else {

            currentIndex += 1

            animateStep()
        }
    }

    // MARK: - Previous

    private func previous() {

        guard currentIndex > 0 else {
            return
        }

        currentIndex -= 1

        animateStep()
    }

    // MARK: - Animation

    private func animateStep() {

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.overlayView?.alpha = 0.3
            },
            completion: { _ in

                self.showCurrentStep()

                UIView.animate(
                    withDuration: 0.2
                ) {
                    self.overlayView?.alpha = 1
                }
            }
        )
    }

    // MARK: - Skip

    private func skip() {

        finish()
    }

    // MARK: - Finish

    private func finish() {

        guard let userId = userId else {
            removeOverlay()
            return
        }

        markCompleted(for: userId)

        removeOverlay()
    }

    // MARK: - Remove

    private func removeOverlay() {

        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.overlayView?.alpha = 0
            },
            completion: { _ in

                self.overlayView?.removeFromSuperview()

                self.overlayView = nil

                self.steps.removeAll()

                self.currentIndex = 0
            }
        )
    }

    // MARK: - UserDefaults

    private func key(for userId: String) -> String {

        return "tripsapp_tutorial_completed_\(userId)"
    }

    private func isCompleted(
        for userId: String
    ) -> Bool {

        return UserDefaults.standard.bool(
            forKey: key(for: userId)
        )
    }

    private func markCompleted(
        for userId: String
    ) {

        UserDefaults.standard.set(
            true,
            forKey: key(for: userId)
        )
    }

    // MARK: - Reset Tutorial

    func reset(for userId: String) {

        UserDefaults.standard.removeObject(
            forKey: key(for: userId)
        )
    }
}
