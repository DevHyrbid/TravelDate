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
    var chatData: [ChatData] = [] // Replace with your actual model type
    private var overlayView: UIView?
    private var overlayType: OverlayType?
    private var groups: [Group] = []
    private var visibleCards: [MatchCardView] = []
    private var currentIndex = 0
    private let maxVisible = 3
    private var panOriginCenter: CGPoint = .zero
    private var blurView: UIVisualEffectView?
    var groupsCount = 0
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navTitleLabel.setFont(.medium, size: 18.0)
        
//         showTestMatchBottomSheet()  // ⚠️ test-only — remove before shipping, was popping a full-screen
        // match sheet on every load and could confuse gesture testing on the swipe screen underneath.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroups()
        checkRequirements()
        self.tripsTabBarController?.showTabBar()
    }

    private var didSetupUI = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didSetupUI else { return }
        didSetupUI = true
        setupStaticUI()
    }
    
    
    private func checkRequirements() {

        let location = User.curentUser?.locationString?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if location.isEmpty {
            overlayType = .missingLocation
            showOverlay()
            return
        }

        if (User.curentUser?.travelStyles ?? []).isEmpty {
            overlayType = .missingTravelStyles
            showOverlay()
            return
        }

        if groups.isEmpty {
            overlayType = .noGroups
            showOverlay()
            return
        }

        overlayType = nil
        hideOverlay()
    }
    
    
    private func showOverlay() {

        guard let type = overlayType else { return }

        cardContainerView.isUserInteractionEnabled = false
        skipButton.isEnabled = false
        likeButton.isEnabled = false

        overlayView?.removeFromSuperview()

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: type.iconName))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = type.title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = type.message
        messageLabel.textColor = .lightGray
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let actionButton = UIButton(type: .system)
        actionButton.setTitle(type.buttonTitle, for: .normal)
        actionButton.backgroundColor = UIColor.systemPink
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 12
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(overlayButtonTapped), for: .touchUpInside)

        blur.contentView.addSubview(container)

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(actionButton)

        view.addSubview(blur)

        NSLayoutConstraint.activate([

            container.centerXAnchor.constraint(equalTo: blur.contentView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: blur.contentView.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -24),

            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])

        overlayView = blur
    }
    
    
    private func hideOverlay() {

        cardContainerView.isUserInteractionEnabled = true
        skipButton.isEnabled = true
        likeButton.isEnabled = true

        overlayView?.removeFromSuperview()
        overlayView = nil
    }
    
    
    @objc private func overlayButtonTapped() {

        guard let type = overlayType else { return }

        switch type {

        case .missingLocation:
            print("Open Location Screen")
            
            
            self.pushVC(EditProfileVc.self, from: .Settings)

        case .missingTravelStyles:
            print("Open Travel Styles Screen")
            // push travel style screen
            
            self.pushVC(ProfileViewController.self, from: .Settings)

        case .noGroups:
            fetchGroups()
        }
    }

    // MARK: - API
    private func fetchGroups() {
         
         

        request.latitude = AppData.shared.latitude
        request.longitude = AppData.shared.longitude
        request.getGroups(1) { [weak self] model, msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                if code == 200 {
                    

                    self.groups = model?.dataGroup ?? []

                    self.groups.forEach { group in
                        group.members = group.members?.filter {
                            $0.id != User.curentUser?.id
                        }
                    }
                       self.lblNoData.isHidden = !self.groups.isEmpty
                       self.buildCardStack()

                       self.checkRequirements()
                } else {
                    print("EERRR", msg as Any, code as Any)
                    self.checkRequirements()
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

        if currentIndex >= groups.count {
            showAllCardsFinishedView()
            return
        }

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
    
    private func showAllCardsFinishedView() {
        
        emptyStateView.isHidden = false
        lblNoData.isHidden = false
        lblNoData.text = "You've seen all available groups 🎉 \n No New Groups available"

        skipButton.isHidden = true
        likeButton.isHidden = true
        cardContainerView.isHidden = true
        // Optional:
        // customView.isHidden = false
    }
    private func showTestMatchBottomSheet() {

        let baseURL = APiConstant.base

        let result = MatchResult(
            groupId: "b7333e2b-ee27-4df2-bfb9-341954fe4b2f",
            swipeId: "f63fdfea-4564-40f4-93d9-711349fbe21b",
            groupTitle: "Weekend Trip",
            matchedStyles: ["Partygoer", "Adventure traveler"],
            message: "Is Ready To Make Some Plans. Why not start the conversation?",
            myGroupImageURL: baseURL + "/uploads/1783600038080-56423482.jpg",
            matchedGroupImageURL: baseURL + "/uploads/1783600182171-623694586.jpg"
        )

        MatchBottomSheetVC.show(
            on: self,
            result: result,
            delegate: self
        )
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
//        performSwipe(isRight: true)
        
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

    // ── PRIMARY FIX: check the actual touched view, not a computed rect.
    // This is consulted BEFORE the pan gesture even starts tracking the touch —
    // far more reliable than a frame/convert()-based hit check, since it can't
    // be thrown off by stale layout timing, rounding, or the card's flip
    // transform. If the touch landed on a UIControl (the flip button, or any
    // future button on the card), the pan gesture never sees it at all.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer is UIPanGestureRecognizer else { return true }

        var v: UIView? = touch.view
        while let current = v {
            if current is UIControl { return false }
            if current is MatchCardView { break } // no need to walk past the card
            v = current.superview
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        guard let pan = gr as? UIPanGestureRecognizer else { return true }

        // Kept as a second safety net — shouldReceive(touch:) above already
        // filters out button taps, so this rarely needs to fire, but costs nothing.
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
        request.swipedId = group.id ?? ""
        request.action  = isRight ? "RIGHT" : "LEFT"

        request.swipeAPi { [weak self] match, msg, errCode in
            guard let self else { return }
            print("Swipe API:", msg)
            DispatchQueue.main.async {
                if errCode == 200 {
                    // Uncomment and use real model data:
                    // guard data.isMatch == 1 else { return }
                    let result = match
                           
                           
                       
                    if match?.message ?? "" == "It is a match!" {
                        let result = MatchResult(
                            groupId:             group.id ?? "",
                            swipeId:             "",
                            groupTitle:          group.title ?? "",
                            matchedStyles:       group.travelStyle ?? [""],
                            message:             "Ready to make some plans? Start a conversation now!",
                            myGroupImage:        result?.myGroupImage ?? "",
                            matchedGroupImage:   nil,
                            myGroupImageURL:    result?.myGroupImage ?? "",
                            matchedGroupImageURL: result?.matchedGroupImage ?? ""
                        )
                        MatchBottomSheetVC.show(on: self, result: result, delegate: self)
                    }
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
    
    

    private func fetchChats(completion: (() -> Void)? = nil) {
        request.getChatsInbox(1) { [weak self] model, msg, code in
            guard let self else { return }

            DispatchQueue.main.async {
                if code == 200 {
                    self.chatData = model?.data ?? []
                    completion?()
                }
            }
        }
    }
    
    func matchSheetDidTapSayHello(groupId: String, swipeId: String) {

        fetchChats { [weak self] in
            guard let self else { return }
            let item = chatData.first {
                print("Comparing '\($0.groupDetails?.group1Id ?? "nil")' == '\(groupId)'")
                return $0.groupDetails?.group1Id == groupId ||
                       $0.groupDetails?.group2Id == groupId
            }

            print(item == nil ? "NOT FOUND" : "FOUND")

            let viewModel = ChatViewModel(
                currentUserId: User.curentUser?.id ?? ""
            )

            let vc = ChatMessageVc(
                viewModel: viewModel,
                participants: item?.members ?? [],
                roomId: item?.chatId,
                roomTitle: item? .name ?? "",
                type: .group
            )

            self.navigationController?.pushViewController(vc, animated: true)
        }
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


// MARK: - Overlay Type
enum OverlayType {
    case missingLocation
    case missingTravelStyles
    case noGroups

    var title: String {
        switch self {
        case .missingLocation:    return "Location Required"
        case .missingTravelStyles: return "Travel Styles Required"
        case .noGroups:           return "No Groups Available"
        }
    }

    var message: String {
        switch self {
        case .missingLocation:    return "Add your location to start discovering travel groups."
        case .missingTravelStyles: return "Select your travel styles to find matching groups."
        case .noGroups:           return "No travel groups available right now."
        }
    }

    var buttonTitle: String {
        switch self {
        case .missingLocation:    return "Add Location"
        case .missingTravelStyles: return "Select Travel Styles"
        case .noGroups:           return "Refresh"
        }
    }

    var iconName: String {
        switch self {
        case .missingLocation:    return "location.fill"
        case .missingTravelStyles: return "figure.travel"
        case .noGroups:           return "arrow.clockwise"
        }
    }
}
