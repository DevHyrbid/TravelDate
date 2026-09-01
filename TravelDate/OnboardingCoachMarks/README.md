# Onboarding Coach Marks — TravelDate

Drop-in, programmatic UIKit (no storyboards), matches the FinX Stock reference:
1. spotlight tooltip bubble pointing at a tab bar / toolbar button
2. dark welcome card with illustration + "1 of X" + Restart/Done

## Files
- `OnboardingModels.swift` — `OnboardingStep`, style enum, `OnboardingSeenStore` (UserDefaults "seen" flag per flow)
- `OnboardingSpotlightOverlayView.swift` — dim + circular cutout + arrowed bubble
- `OnboardingCardOverlayView.swift` — full welcome card (illustration/title/body/footer)
- `OnboardingCoachMarkManager.swift` — singleton that sequences steps, shows/advances/finishes

## Wire it up (e.g. in HomeViewController.viewDidAppear)

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    let steps: [OnboardingStep] = [
        OnboardingStep(
            style: .spotlight(target: { [weak self] in self?.createTripButton }),
            illustration: UIImage(named: "onboard_create_trip"),
            title: "Start a trip in 1 tap",
            description: "Match with travel groups going your way — tap here to begin.",
            tooltipPosition: .above
        ),
        OnboardingStep(
            style: .card,
            illustration: UIImage(named: "onboard_welcome"),
            title: "Hey Joe!",
            description: "Welcome to your homepage. Your matched groups and trips are right here :)"
        )
    ]

    OnboardingCoachMarkManager.shared.start(
        flowID: "home_v1",     // bump this string whenever you change the flow so it replays
        steps: steps,
        in: self.view.window ?? self.view   // use the window if a step targets the tab bar
    )
}
```

## Notes
- `flowID` is how "seen" state is tracked (`UserDefaults`) — each unique ID only auto-plays once per install. Pass `force: true` to `start(...)` to replay for QA, or call `OnboardingSeenStore.reset("home_v1")`.
- For a step to spot the tab bar item correctly, host it in `view.window` rather than the VC's own `view` (tab bar isn't inside the VC's view). For steps that only need to cover the current screen's content, the VC's `view` is fine.
- The `.card` step's Restart button loops back to step 1; Done advances to the next step (or finishes the flow on the last one).
- Swap `illustration` images for your own assets — sizing is already tuned to roughly match the reference (140×90 in the card, 64pt square in the tooltip).
- Colors are hard-coded close to the mock (light-blue tooltip, navy card). Pull these into your design system's `UIColor` extension if you have one.
