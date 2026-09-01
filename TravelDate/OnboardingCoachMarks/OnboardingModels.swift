////
////  OnboardingModels.swift
////  TravelDate Onboarding Coach Marks
////
////  Programmatic UIKit, no storyboards.
////
//
//import UIKit
//
///// Which visual style a step renders as.
//enum OnboardingStepStyle {
//    /// Small bubble with an arrow, pointing at a real view on screen (e.g. a tab bar button),
//    /// with a spotlight "cutout" punched through the dim overlay around that view.
//    /// Matches the "Start investing in 1 click" tooltip.
//    case spotlight(target: () -> UIView?)
//
//    /// Full card floating over a dimmed background with an illustration, title, body copy,
//    /// a page indicator ("1 of 2") and Restart / Done controls.
//    /// Matches the "Hey Joe!" welcome card.
//    case card
//}
//
///// One step in an onboarding sequence.
//struct OnboardingStep {
//    let style: OnboardingStepStyle
//    let illustration: UIImage?
//    let title: String
//    let description: String
//
//    /// Where the spotlight tooltip's arrow + bubble sit relative to the target view.
//    /// Ignored for `.card` style.
//    var tooltipPosition: OnboardingTooltipPosition = .above
//
//    init(style: OnboardingStepStyle,
//         illustration: UIImage? = nil,
//         title: String,
//         description: String,
//         tooltipPosition: OnboardingTooltipPosition = .above) {
//        self.style = style
//        self.illustration = illustration
//        self.title = title
//        self.description = description
//        self.tooltipPosition = tooltipPosition
//    }
//}
//
//enum OnboardingTooltipPosition {
//    case above
//    case below
//}
//
///// Simple UserDefaults-backed "have we shown this flow already" helper.
///// Keeps callers from re-triggering onboarding on every launch.
//enum OnboardingSeenStore {
//    private static func key(for flowID: String) -> String {
//        "onboarding.seen.\(flowID)"
//    }
//
//    static func hasSeen(_ flowID: String) -> Bool {
//        UserDefaults.standard.bool(forKey: key(for: flowID))
//    }
//
//    static func markSeen(_ flowID: String) {
//        UserDefaults.standard.set(true, forKey: key(for: flowID))
//    }
//
//    static func reset(_ flowID: String) {
//        UserDefaults.standard.removeObject(forKey: key(for: flowID))
//    }
//}
