import UIKit

// MARK: - Match Model
struct MatchResult {
    let groupId: String
    let swipeId: String
    let groupTitle: String
    let matchedStyles: [String]
    let message: String
    var myGroupImage: UIImage?
    var matchedGroupImage: UIImage?
    var myGroupImageURL: String?
    var matchedGroupImageURL: String?
}

// MARK: - Delegate
protocol MatchBottomSheetDelegate: AnyObject {
    func matchSheetDidTapSayHello(groupId: String, swipeId: String)
    func matchSheetDidTapKeepSwiping()
}

// MARK: - MatchBottomSheetVC
final class MatchBottomSheetVC: UIViewController {

    // MARK: - Public
    weak var delegate: MatchBottomSheetDelegate?
    var matchResult: MatchResult?

    // MARK: - UI
    private let dimView        = UIView()
    private let sheetView      = UIView()
    private let dragHandle     = UIView()
    private let titleLabel     = UILabel()
    private let subtitleLabel  = UILabel()
    private let leftImageView  = UIImageView()
    private let rightImageView = UIImageView()
    private let starBadge      = UIView()
    private let starImageView  = UIImageView()
    private let sayHelloBtn    = UIButton(type: .custom)
    private let keepSwipingBtn = UIButton(type: .custom)

    private let leftGradientLayer  = CAGradientLayer()
    private let rightGradientLayer = CAGradientLayer()

    private var sheetHeightConstraint: NSLayoutConstraint?

    // MARK: - Safe show — ALWAYS dispatches to main thread before init/present
    static func show(
        on parent: UIViewController,
        result: MatchResult,
        delegate: MatchBottomSheetDelegate? = nil
    ) {
        // Guarantee main thread — safe to call from any thread/queue
        DispatchQueue.main.async {
            let vc = MatchBottomSheetVC()
            vc.matchResult = result
            vc.delegate = delegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle   = .crossDissolve
            parent.present(vc, animated: false)
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad is always on main thread — safe
        setupDimView()
        setupSheet()
        setupDragHandle()
        setupTitle()
        setupImages()
        setupStarBadge()
        setupSubtitle()
        setupButtons()
        populateData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientBorders()
    }

    // MARK: - Computed height
    private var sheetHeight: CGFloat {
        let bottomSafe = view.safeAreaInsets.bottom
        return 620 + bottomSafe
    }

    // MARK: - Dim View
    private func setupDimView() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDimTap)))
    }

    // MARK: - Sheet
    private func setupSheet() {
        sheetView.backgroundColor = UIColor(red: 0.10, green: 0.07, blue: 0.06, alpha: 1)
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.layer.masksToBounds = false
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        let hc = sheetView.heightAnchor.constraint(equalToConstant: 620) // updated in viewDidLayoutSubviews
        sheetHeightConstraint = hc

        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hc
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetView.addGestureRecognizer(pan)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Update height constraint once safe area is known
        sheetHeightConstraint?.constant = sheetHeight
    }

    // MARK: - Drag Handle
    private func setupDragHandle() {
        dragHandle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        dragHandle.layer.cornerRadius = 2.5
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(dragHandle)
        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 12),
            dragHandle.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5)
        ])
    }

    // MARK: - Title
    private func setupTitle() {
        titleLabel.text = "You Connected"
        titleLabel.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.08, alpha: 1)
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Images
    private func setupImages() {
        let imageContainer = UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.clipsToBounds = false
        sheetView.addSubview(imageContainer)

        let imageSize: CGFloat = 190
        let overlap:   CGFloat = 28

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            imageContainer.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: imageSize * 2 - overlap),
            imageContainer.heightAnchor.constraint(equalToConstant: imageSize)
        ])

        func styleImageView(_ iv: UIImageView) {
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 20
            iv.backgroundColor = UIColor(red: 0.18, green: 0.13, blue: 0.11, alpha: 1)
            iv.translatesAutoresizingMaskIntoConstraints = false
        }

        styleImageView(leftImageView)
        styleImageView(rightImageView)
        imageContainer.addSubview(leftImageView)
        imageContainer.addSubview(rightImageView)

        NSLayoutConstraint.activate([
            leftImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            leftImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            leftImageView.widthAnchor.constraint(equalToConstant: imageSize),
            leftImageView.heightAnchor.constraint(equalToConstant: imageSize),

            rightImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            rightImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            rightImageView.widthAnchor.constraint(equalToConstant: imageSize),
            rightImageView.heightAnchor.constraint(equalToConstant: imageSize)
        ])

        // Gradient border layers — configured here, frames set in viewDidLayoutSubviews
        [leftGradientLayer, rightGradientLayer].forEach { layer in
            layer.colors = [
                UIColor(red: 1.0, green: 0.42, blue: 0.08, alpha: 1).cgColor,
                UIColor(red: 0.95, green: 0.25, blue: 0.35, alpha: 1).cgColor
            ]
            layer.startPoint = CGPoint(x: 0, y: 0)
            layer.endPoint   = CGPoint(x: 1, y: 1)
        }
        leftImageView.layer.addSublayer(leftGradientLayer)
        rightImageView.layer.addSublayer(rightGradientLayer)
    }

    // MARK: - Star Badge
    private func setupStarBadge() {
        let badgeSize: CGFloat = 64
        let orange = UIColor(red: 1.0, green: 0.42, blue: 0.08, alpha: 1)

        starBadge.backgroundColor   = orange
        starBadge.layer.cornerRadius = badgeSize / 2
        starBadge.layer.shadowColor  = orange.cgColor
        starBadge.layer.shadowOffset = CGSize(width: 0, height: 4)
        starBadge.layer.shadowRadius = 16
        starBadge.layer.shadowOpacity = 0.7
        starBadge.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(starBadge)

        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .white
        starImageView.contentMode = .scaleAspectFit
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starBadge.addSubview(starImageView)

        // Centre badge horizontally; pin its top so it overlaps the image bottom edge
        NSLayoutConstraint.activate([
            starBadge.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            // 28 (gap above images) + 190 (imageSize) - 32 (half badge) = sits on bottom edge of images
            starBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28 + 190 - badgeSize / 2),
            starBadge.widthAnchor.constraint(equalToConstant: badgeSize),
            starBadge.heightAnchor.constraint(equalToConstant: badgeSize),

            starImageView.centerXAnchor.constraint(equalTo: starBadge.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: starBadge.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 28),
            starImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    // MARK: - Subtitle
    private func setupSubtitle() {
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: starBadge.bottomAnchor, constant: 24),
            subtitleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Buttons
    private func setupButtons() {
        let orange = UIColor(red: 1.0, green: 0.42, blue: 0.08, alpha: 1)

        sayHelloBtn.setTitle("Say Hello", for: .normal)
        sayHelloBtn.setTitleColor(.white, for: .normal)
        sayHelloBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        sayHelloBtn.backgroundColor = orange
        sayHelloBtn.layer.cornerRadius = 28
        sayHelloBtn.layer.shadowColor   = orange.cgColor
        sayHelloBtn.layer.shadowOffset  = CGSize(width: 0, height: 6)
        sayHelloBtn.layer.shadowRadius  = 16
        sayHelloBtn.layer.shadowOpacity = 0.55
        sayHelloBtn.addTarget(self, action: #selector(sayHelloTapped), for: .touchUpInside)
        sayHelloBtn.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(sayHelloBtn)

        keepSwipingBtn.setTitle("Keep Swiping", for: .normal)
        keepSwipingBtn.setTitleColor(.white, for: .normal)
        keepSwipingBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        keepSwipingBtn.backgroundColor = .clear
        keepSwipingBtn.layer.cornerRadius = 28
        keepSwipingBtn.layer.borderWidth  = 2
        keepSwipingBtn.layer.borderColor  = UIColor.white.withAlphaComponent(0.5).cgColor
        keepSwipingBtn.addTarget(self, action: #selector(keepSwipingTapped), for: .touchUpInside)
        keepSwipingBtn.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(keepSwipingBtn)

        NSLayoutConstraint.activate([
            sayHelloBtn.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            sayHelloBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            sayHelloBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            sayHelloBtn.heightAnchor.constraint(equalToConstant: 56),

            keepSwipingBtn.topAnchor.constraint(equalTo: sayHelloBtn.bottomAnchor, constant: 14),
            keepSwipingBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            keepSwipingBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            keepSwipingBtn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Populate (main thread — called from viewDidLoad)
    private func populateData() {
        guard let result = matchResult else { return }

        subtitleLabel.text = result.message.isEmpty
            ? "Is Ready To Make Some Plans. Why Not Start The Conversation?"
            : result.message

        // Images already available
        if let img = result.myGroupImage      { leftImageView.image  = img }
        if let img = result.matchedGroupImage { rightImageView.image = img }

        // Load from URL if needed — dispatch back to main thread explicitly
        if result.myGroupImage == nil, let urlStr = result.myGroupImageURL {
            loadImage(urlStr: urlStr) { [weak self] image in
                self?.leftImageView.image = image  // already on main thread
            }
        }
        if result.matchedGroupImage == nil, let urlStr = result.matchedGroupImageURL {
            loadImage(urlStr: urlStr) { [weak self] image in
                self?.rightImageView.image = image  // already on main thread
            }
        }
    }

    /// Downloads image and calls completion on the MAIN thread.
    private func loadImage(urlStr: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            DispatchQueue.main.async { completion(image) }   // ← always main thread
        }.resume()
    }

    // MARK: - Gradient Borders (called in viewDidLayoutSubviews — main thread)
    private func updateGradientBorders() {
        applyGradientBorder(to: leftImageView,  gradientLayer: leftGradientLayer)
        applyGradientBorder(to: rightImageView, gradientLayer: rightGradientLayer)
    }

    private func applyGradientBorder(to imageView: UIImageView, gradientLayer: CAGradientLayer) {
        let borderWidth: CGFloat = 3
        let bounds = imageView.bounds
        guard bounds != .zero else { return }

        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = imageView.layer.cornerRadius

        let inner = UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderWidth, dy: borderWidth),
            cornerRadius: imageView.layer.cornerRadius - borderWidth
        )
        let outer = UIBezierPath(roundedRect: bounds, cornerRadius: imageView.layer.cornerRadius)
        outer.append(inner)
        outer.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = outer.cgPath
        maskLayer.fillRule = .evenOdd
        gradientLayer.mask = maskLayer
    }

    // MARK: - Animations
    private func animateIn() {
        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        UIView.animate(
            withDuration: 0.55, delay: 0,
            usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            self.sheetView.transform = .identity
            self.dimView.alpha = 1
        } completion: { _ in
            self.animateBadgePop()
        }
    }

    private func animateBadgePop() {
        starBadge.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(
            withDuration: 0.5, delay: 0,
            usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8
        ) {
            self.starBadge.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.35, delay: 0,
            usingSpringWithDamping: 1.0, initialSpringVelocity: 0
        ) {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
            self.dimView.alpha = 0
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Pan to dismiss
    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        let t = gr.translation(in: view)
        guard t.y >= 0 else { return }

        switch gr.state {
        case .changed:
            sheetView.transform = CGAffineTransform(translationX: 0, y: t.y)
            dimView.alpha = max(0, 1 - t.y / sheetHeight)
        case .ended, .cancelled:
            let velocity = gr.velocity(in: view)
            if t.y > sheetHeight * 0.3 || velocity.y > 800 {
                animateOut { self.dismiss(animated: false) }
            } else {
                UIView.animate(withDuration: 0.3, delay: 1.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                    self.sheetView.transform = .identity
                    self.dimView.alpha = 1
                }
            }
        default: break
        }
    }

    @objc private func handleDimTap() {
        animateOut { self.dismiss(animated: false) }
    }

    // MARK: - Button Actions
    @objc private func sayHelloTapped() {
        guard let result = matchResult else { return }
        animateOut {
            self.dismiss(animated: false) {
                self.delegate?.matchSheetDidTapSayHello(groupId: result.groupId, swipeId: result.swipeId)
            }
        }
    }

    @objc private func keepSwipingTapped() {
        animateOut {
            self.dismiss(animated: false) {
                self.delegate?.matchSheetDidTapKeepSwiping()
            }
        }
    }
}
