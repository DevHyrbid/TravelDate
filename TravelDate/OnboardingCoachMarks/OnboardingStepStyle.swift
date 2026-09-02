
//
//  OnboardingModels.swift
//  TravelDate Onboarding Coach Marks
//

import UIKit

// MARK: - Step Style

enum OnboardingStepStyle {

    /// Highlights an actual view on screen.
    case spotlight(target: () -> UIView?)

    /// Displays a full onboarding card.
    case card
}

// MARK: - Button Action

enum OnboardingAction {
    case next
    case done
}

// MARK: - Onboarding Step

struct OnboardingStep {

    let style: OnboardingStepStyle
    let illustration: UIImage?
    let title: String
    let description: String
    let tabIndex: Int?
    var tooltipPosition: OnboardingTooltipPosition = .above
    var action: OnboardingAction = .next

    /// Pass this when the target view can be off-screen (inside a scroll view).
    /// Manager will scroll it into view before spotlighting.
    weak var scrollView: UIScrollView?

    init(
        style: OnboardingStepStyle,
        illustration: UIImage? = nil,
        title: String,
        description: String,
        tooltipPosition: OnboardingTooltipPosition = .above,
        action: OnboardingAction = .next,
        tabIndex: Int? = nil,
        scrollView: UIScrollView? = nil
    ) {
        self.style = style
        self.illustration = illustration
        self.title = title
        self.description = description
        self.tooltipPosition = tooltipPosition
        self.action = action
        self.tabIndex = tabIndex
        self.scrollView = scrollView
    }
}

// MARK: - Tooltip Position

enum OnboardingTooltipPosition {
    case above
    case below
}

// MARK: - Seen Store

enum OnboardingSeenStore {

    private static func key(for flowID: String) -> String {
        "onboarding.seen.\(flowID)"
    }

    static func hasSeen(_ flowID: String) -> Bool {
        UserDefaults.standard.bool(forKey: key(for: flowID))
    }

    static func markSeen(_ flowID: String) {
        UserDefaults.standard.set(true, forKey: key(for: flowID))
    }

    static func reset(_ flowID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: flowID))
    }
}

