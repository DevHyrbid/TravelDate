import UIKit

class SwipeViewController: BaseClassVc {

    // MARK: - Outlets
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var lblNoData: UILabel!
    @IBOutlet weak var navSubtitleLabel: UILabel!
    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var emptyStateView: UIView!

    // MARK: - Properties
    private var groups: [Group] = []
    private var visibleCards: [MatchCardView] = []
    private var currentIndex = 0
    private let maxVisible = 3
    private var panOriginCenter: CGPoint = .zero

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navTitleLabel.setFont(.medium, size: 18.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroups()
    }

    private var didSetupUI = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didSetupUI else { return }
        didSetupUI = true
        setupStaticUI()
    }

    // MARK: - API
    private func fetchGroups() {
        request.getGroups(1) { [weak self] model, msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                if code == 200 {
                    self.groups = model?.data?.groups ?? []
                    self.lblNoData.isHidden = !self.groups.isEmpty
                    self.buildCardStack()
                } else {
                    print("EERRR", msg as Any, code as Any)
                }
            }
        }
    }

    // MARK: - Card Stack Builder
    private func buildCardStack() {
        visibleCards.forEach { $0.removeFromSuperview() }
        visibleCards.removeAll()
        currentIndex = 0

        guard !groups.isEmpty else {
            emptyStateView.isHidden = false
            return
        }
        emptyStateView.isHidden = true

        let count = min(maxVisible, groups.count)
        for i in stride(from: count - 1, through: 0, by: -1) {
            let card = MatchCardView.make()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.group = groups[i]
            cardContainerView.addSubview(card)
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
                card.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),
                card.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor)
            ])
            visibleCards.insert(card, at: 0)
            applyStackAppearance(to: card, stackPosition: i)
        }

        if let top = visibleCards.first {
            attachPan(to: top)
        }
    }

    // MARK: - Stack Transform
    private func applyStackAppearance(to card: UIView, stackPosition: Int) {
        let scale  = 1.0 - CGFloat(stackPosition) * 0.04
        let yShift = CGFloat(stackPosition) * 14
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3) {
            card.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: 0, y: yShift)
            card.alpha = stackPosition < 3 ? 1.0 : 0.0
        }
    }

    // MARK: - Pan Gesture
    private func attachPan(to card: MatchCardView) {
        card.gestureRecognizers?.forEach { card.removeGestureRecognizer($0) }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        card.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard let card = gr.view as? MatchCardView else { return }

        // ── Block pan entirely when card is showing the members (back face)
        // This lets the collection view scroll freely without triggering a swipe
        guard !card.isFlipped else { return }

        let t = gr.translation(in: cardContainerView)
        let percent = (t.x / cardContainerView.bounds.width).clamped(to: -1...1)

        switch gr.state {
        case .began:
            panOriginCenter = card.center

        case .changed:
            card.center = CGPoint(x: panOriginCenter.x + t.x, y: panOriginCenter.y + t.y * 0.25)
            card.transform = CGAffineTransform(rotationAngle: percent * 0.3)
            if percent > 0.08 {
                card.showLikeStamp(true, intensity: percent)
            } else if percent < -0.08 {
                card.showNopeStamp(true, intensity: abs(percent))
            } else {
                card.hideStamps()
            }
            promoteNextCard(progress: min(abs(percent) * 2, 1.0))

        case .ended, .cancelled:
            let velocity = gr.velocity(in: cardContainerView)
            let isHardSwipe = abs(t.x) > 110 || abs(velocity.x) > 700
            if isHardSwipe {
                animateSwipe(card: card, toRight: t.x > 0)
            } else {
                animateReset(card: card)
            }

        default: break
        }
    }

    // MARK: - Swipe Out
    private func animateSwipe(card: MatchCardView, toRight: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let dir: CGFloat = toRight ? 1 : -1
        let exitX = panOriginCenter.x + dir * (UIScreen.main.bounds.width * 1.5)
        UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.6) {
            card.center = CGPoint(x: exitX, y: card.center.y + 40)
            card.alpha  = 0
        } completion: { _ in
            self.finishSwipe(card: card, joined: toRight)
        }
    }

    // MARK: - Reset
    private func animateReset(card: MatchCardView) {
        card.hideStamps()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            card.center    = self.panOriginCenter
            card.transform = .identity
        }
        for (i, c) in visibleCards.enumerated() where i > 0 {
            applyStackAppearance(to: c, stackPosition: i)
        }
    }

    // MARK: - Promote next card while dragging
    private func promoteNextCard(progress: CGFloat) {
        guard visibleCards.count > 1 else { return }
        let next = visibleCards[1]
        let targetScale = (1.0 - 0.04) + (0.04 * progress)
        let targetY     = 14.0 * (1.0 - progress)
        next.transform  = CGAffineTransform(scaleX: targetScale, y: targetScale).translatedBy(x: 0, y: targetY)
    }

    // MARK: - Post-swipe cleanup
    private func finishSwipe(card: MatchCardView, joined: Bool) {
        guard !visibleCards.isEmpty else { return }

        let swipedGroup = groups[currentIndex]
        if joined { handleJoin(group: swipedGroup) }

        visibleCards.removeFirst()
        card.removeFromSuperview()
        currentIndex += 1

        for (i, c) in visibleCards.enumerated() {
            applyStackAppearance(to: c, stackPosition: i)
        }

        let nextDataIndex = currentIndex + visibleCards.count
        if nextDataIndex < groups.count {
            addCardToBack(groupIndex: nextDataIndex)
        }

        if let top = visibleCards.first {
            attachPan(to: top)
        }

        emptyStateView.isHidden = !visibleCards.isEmpty
    }

    // MARK: - Add card to back
    private func addCardToBack(groupIndex: Int) {
        let card = MatchCardView.make()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.group = groups[groupIndex]
        card.alpha = 0
        cardContainerView.insertSubview(card, at: 0)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            card.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor)
        ])
        visibleCards.append(card)
        applyStackAppearance(to: card, stackPosition: visibleCards.count - 1)
        UIView.animate(withDuration: 0.3) { card.alpha = 1 }
    }

    // MARK: - Join Action
    private func handleJoin(group: Group) {
        guard let groupId = group._id else { return }
        print("Joining group: \(groupId)")
    }

    // MARK: - Static UI
    private func setupStaticUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)

        skipButton.backgroundColor    = .clear
        skipButton.layer.cornerRadius = skipButton.frame.height / 2
        skipButton.layer.borderWidth  = 2
        skipButton.layer.borderColor  = UIColor.white.withAlphaComponent(0.5).cgColor
        skipButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        skipButton.tintColor = .white

        let pink = UIColor(red: 0.95, green: 0.25, blue: 0.35, alpha: 1)
        likeButton.backgroundColor     = pink
        likeButton.layer.cornerRadius  = likeButton.frame.height / 2
        likeButton.layer.shadowColor   = pink.cgColor
        likeButton.layer.shadowOffset  = CGSize(width: 0, height: 6)
        likeButton.layer.shadowRadius  = 12
        likeButton.layer.shadowOpacity = 0.5
        likeButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        likeButton.tintColor = .white

        emptyStateView.isHidden = true
        cardContainerView.backgroundColor = .clear
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SwipeViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        guard let pan = gr as? UIPanGestureRecognizer else { return true }

        // ── Don't start pan if the touch started inside the flip button hit area.
        // This ensures UIButton tap fires cleanly without the pan gesture stealing it.
        if let card = pan.view as? MatchCardView {
            let location = pan.location(in: card)
            if card.flipButtonFrame.contains(location) { return false }
        }

        // Only fire swipe pan when horizontal drag is dominant
        let v = pan.velocity(in: cardContainerView)
        return abs(v.x) > abs(v.y)
    }

    func gestureRecognizer(
        _ gr: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        // Allow tap gestures (flip button) to work simultaneously
        // Block simultaneous pan gestures (would conflict with swipe)
        return !(other is UIPanGestureRecognizer)
    }
}

// MARK: - Button Actions
extension SwipeViewController {

    @IBAction func btnSwipeRight(_ sender: UIButton) {
        performSwipe(isRight: true)
    }

    @IBAction func btnSwipeLeft(_ sender: UIButton) {
        performSwipe(isRight: false)
    }

    func performSwipe(isRight: Bool) {
        guard currentIndex < groups.count else { return }
        let group = groups[currentIndex]

        request.groupId = group.id ?? ""
        request.action  = isRight ? "right" : "left"

        request.swipeAPi { [weak self] msg, errCode in
            guard let self else { return }
            print("Swipe API:", msg)
            DispatchQueue.main.async {
                if errCode == 200 {
                    // Uncomment and use real model data:
                    // guard data.isMatch == 1 else { return }
                    let result = MatchResult(
                        groupId:             group.id ?? "",
                        swipeId:             "",
                        groupTitle:          group.groupTitle ?? "",
                        matchedStyles:       [],
                        message:             "It's a Match!",
                        myGroupImage:        nil,
                        matchedGroupImage:   nil,
                        myGroupImageURL:     nil,
                        matchedGroupImageURL: group.coverImage
                    )
                    MatchBottomSheetVC.show(on: self, result: result, delegate: self)
                }
            }
        }

        guard let top = visibleCards.first else { return }
        panOriginCenter = top.center
        if isRight { top.showLikeStamp(true, intensity: 1.0) }
        else       { top.showNopeStamp(true, intensity: 1.0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.animateSwipe(card: top, toRight: isRight)
        }
    }
}

// MARK: - MatchBottomSheetDelegate
extension SwipeViewController: MatchBottomSheetDelegate {
    func matchSheetDidTapSayHello(groupId: String, swipeId: String) {
        print("Open chat for group: \(groupId)")
    }
    func matchSheetDidTapKeepSwiping() {
        print("Keep swiping")
    }
}

// MARK: - Clamp helper
private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
