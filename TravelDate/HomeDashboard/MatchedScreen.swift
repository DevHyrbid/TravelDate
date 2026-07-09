import UIKit

// MARK: - Match Model
struct MatchResult {
    let groupId: String
    let swipeId: String
    let groupTitle: String
    let matchedStyles: [String]
    let message: String
    var myGroupImage: String?
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
// NOTE: Figma frame is a FULL-SCREEN celebration overlay (402x875 reference), NOT a
// bottom sheet drawer. There is no separate flat "sheetView" panel in the design —
// everything (title, tilted photos, badge, subtitle, buttons) sits directly on the
// dimmed background with soft glow orbs behind it. Kept the class name unchanged so
// call sites don't break.
final class MatchBottomSheetVC: UIViewController {

    // MARK: - Public
    weak var delegate: MatchBottomSheetDelegate?
    var matchResult: MatchResult?

    // MARK: - Figma reference constants (402 x 875 frame)
    private enum Figma {
        static let refWidth: CGFloat = 402

        // Colors (exact hex pulled from the SVG)
        static let screenBG   = UIColor(hex: "#111211")
        static let dimColor   = UIColor(hex: "#090B0C")
        static let orange     = UIColor(hex: "#F76606")
        static let pink       = UIColor(hex: "#FE294D")
        static let glowGray   = UIColor(hex: "#373737")

        // Photo card geometry (pre-rotation, local space)
        static let photoSize = CGSize(width: 169.26, height: 169.99)
        static let photoCornerRadius: CGFloat = 34

        // Post-rotation top-left position (== SVG matrix "e,f")
        static let leftPhotoOrigin  = CGPoint(x: 27.84, y: 398.21)
        static let rightPhotoOrigin = CGPoint(x: 215.64, y: 378.44)

        // Rotation angles (degrees) — extracted from SVG matrix a,b components
        static let leftPhotoRotationDeg: CGFloat = -4.53
        static let rightPhotoRotationDeg: CGFloat = 5.38

        // Badge — centered on the overlap point of the two photos
        static let badgeFrame = CGRect(x: 166, y: 525.5, width: 76, height: 76)

        // Buttons
        static let sayHelloFrame    = CGRect(x: 29, y: 711.5, width: 354, height: 54)
        static let keepSwipingFrame = CGRect(x: 29.5, y: 778, width: 353, height: 53)

        // Title label top — measured from the rendered SVG glyph ink (cap-top 322.5,
        // baseline 347.5) back-solved for a 34pt bold label's frame top. This is
        // relative to the raw view top (y=0), same coordinate space as everything
        // else — NOT relative to the safe area, since the Figma canvas already
        // includes the status bar region at y=0.
        static let titleTopY: CGFloat = 306.6
    }

    // MARK: - UI
    private let dimView         = UIView()
    private let glowContainer   = UIView()
    private let titleLabel      = UILabel()
    private let subtitleLabel   = UILabel()
    private let leftImageView   = UIImageView()
    private let rightImageView  = UIImageView()
    private let starBadge       = UIView()
    private let badgeGradient   = CAGradientLayer()
    private let starImageView   = UIImageView()
    private let sayHelloBtn     = UIButton(type: .custom)
    private let keepSwipingBtn  = UIButton(type: .custom)

    private let leftGradientLayer  = CAGradientLayer()
    private let rightGradientLayer = CAGradientLayer()

    /// Scale factor between the actual device width and the Figma reference width (402pt).
    /// Lets every hardcoded Figma coordinate scale correctly on smaller/larger phones.
    private var figmaScale: CGFloat {
        view.bounds.width / Figma.refWidth
    }

    // MARK: - Safe show — ALWAYS dispatches to main thread before init/present
    static func show(
        on parent: UIViewController,
        result: MatchResult,
        delegate: MatchBottomSheetDelegate? = nil
    ) {
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
        view.backgroundColor = .clear
        setupDimView()
//        setupGlowOrbs()
        setupTitle()
        setupPhotos()
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
        layoutFigmaPositionedViews()
        updateGradientBorders()
    }

    // MARK: - Dim background
    private func setupDimView() {
        dimView.backgroundColor = Figma.dimColor.withAlphaComponent(0.5)
        // The base screen behind the dim is the app's own dark bg; give the modal
        // the same tone so it doesn't flash a different color while presenting.
        view.backgroundColor = Figma.screenBG
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

    // MARK: - Decorative glow orbs (from the blurred circles in the Figma bg)
    private func setupGlowOrbs() {
        glowContainer.translatesAutoresizingMaskIntoConstraints = false
        glowContainer.isUserInteractionEnabled = false
        view.insertSubview(glowContainer, aboveSubview: dimView)
        NSLayoutConstraint.activate([
            glowContainer.topAnchor.constraint(equalTo: view.topAnchor),
            glowContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            glowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

//        addGlowOrb(color: Figma.glowGray, center: CGPoint(x: 220, y: 111), radius: 49, alpha: 0.5)
//        addGlowOrb(color: Figma.glowGray, center: CGPoint(x: 347, y: 51), radius: 55, alpha: 0.5)
//        addGlowOrb(color: Figma.orange,   center: CGPoint(x: 128, y: 867), radius: 49, alpha: 0.55)
//        addGlowOrb(color: Figma.pink,     center: CGPoint(x: 275, y: 818), radius: 49, alpha: 0.55)
    }

    private func addGlowOrb(color: UIColor, center: CGPoint, radius: CGFloat, alpha: CGFloat) {
        let orb = UIView()
        orb.backgroundColor = color.withAlphaComponent(alpha)
        orb.layer.cornerRadius = radius
        // Soft glow via a large shadow instead of an actual Gaussian blur filter —
        // cheaper and looks equivalent for a solid color orb.
        orb.layer.shadowColor = color.cgColor
        orb.layer.shadowRadius = radius * 1.4
        orb.layer.shadowOpacity = 0.9
        orb.layer.shadowOffset = .zero
        orb.tag = 9911 // marker so we can reposition on layout
        glowContainer.addSubview(orb)
        orb.frame = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        orbLayoutInfo.append((view: orb, figmaCenter: center, radius: radius))
    }

    private var orbLayoutInfo: [(view: UIView, figmaCenter: CGPoint, radius: CGFloat)] = []

    // MARK: - Title
    // Positioned manually (not AutoLayout) so it shares the exact same raw-view
    // coordinate space as the photos/badge/buttons — see layoutFigmaPositionedViews().
    private func setupTitle() {
        titleLabel.text = "You Connected"
        titleLabel.textColor = Figma.orange
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }

    // MARK: - Photos (tilted, overlapping — positioned manually to match Figma matrix)
    private func setupPhotos() {
        func styleImageView(_ iv: UIImageView) {
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = Figma.photoCornerRadius
            iv.backgroundColor = UIColor(red: 0.18, green: 0.13, blue: 0.11, alpha: 1)
            // Rotate around the ORIGIN corner, not the center, to match the SVG
            // matrix (matrix rotates local (0,0) rect then translates by e,f).
            iv.layer.anchorPoint = .zero
        }

        styleImageView(leftImageView)
        styleImageView(rightImageView)
        view.addSubview(leftImageView)
        view.addSubview(rightImageView)

        [leftGradientLayer, rightGradientLayer].forEach { layer in
            // Pink (top) -> Orange (bottom), vertical — matches paint2/paint3.
            layer.colors = [Figma.pink.cgColor, Figma.orange.cgColor]
            layer.startPoint = CGPoint(x: 0.5, y: 0)
            layer.endPoint   = CGPoint(x: 0.5, y: 1)
        }
        leftImageView.layer.addSublayer(leftGradientLayer)
        rightImageView.layer.addSublayer(rightGradientLayer)
    }

    // MARK: - Star Badge (gradient circle at the photo overlap point)
    private func setupStarBadge() {
        starBadge.layer.cornerRadius = Figma.badgeFrame.width / 2
        starBadge.layer.masksToBounds = true
        view.addSubview(starBadge)

        badgeGradient.colors = [Figma.orange.cgColor, Figma.pink.cgColor]
        badgeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        badgeGradient.endPoint   = CGPoint(x: 0.5, y: 1)
        starBadge.layer.insertSublayer(badgeGradient, at: 0)

        starBadge.layer.shadowColor  = Figma.orange.cgColor
        starBadge.layer.shadowOffset = CGSize(width: 0, height: 4)
        starBadge.layer.shadowRadius = 16
        starBadge.layer.shadowOpacity = 0.5

        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .white
        starImageView.contentMode = .scaleAspectFit
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starBadge.addSubview(starImageView)
        NSLayoutConstraint.activate([
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
        view.addSubview(subtitleLabel)
        // Frame set manually in layoutFigmaPositionedViews() once the badge frame is known —
        // keep translatesAutoresizingMaskIntoConstraints at its default (true) so the frame sticks.
    }

    // MARK: - Buttons
    private func setupButtons() {
        sayHelloBtn.setTitle("Say Hello", for: .normal)
        sayHelloBtn.setTitleColor(.white, for: .normal)
        sayHelloBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        sayHelloBtn.backgroundColor = Figma.orange
        sayHelloBtn.layer.cornerRadius = Figma.sayHelloFrame.height / 2
        sayHelloBtn.layer.shadowColor   = Figma.orange.cgColor
        sayHelloBtn.layer.shadowOffset  = CGSize(width: 0, height: 6)
        sayHelloBtn.layer.shadowRadius  = 16
        sayHelloBtn.layer.shadowOpacity = 0.55
        sayHelloBtn.addTarget(self, action: #selector(sayHelloTapped), for: .touchUpInside)
        view.addSubview(sayHelloBtn)

        keepSwipingBtn.setTitle("Keep Swiping", for: .normal)
        keepSwipingBtn.setTitleColor(.white, for: .normal)
        keepSwipingBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        keepSwipingBtn.backgroundColor = .clear
        keepSwipingBtn.layer.cornerRadius = Figma.keepSwipingFrame.height / 2
        keepSwipingBtn.layer.borderWidth  = 1
        keepSwipingBtn.layer.borderColor  = UIColor.white.cgColor
        keepSwipingBtn.addTarget(self, action: #selector(keepSwipingTapped), for: .touchUpInside)
        view.addSubview(keepSwipingBtn)
        // Frames set in layoutFigmaPositionedViews()
    }

    // MARK: - Manual Figma-coordinate layout
    // Everything below is positioned with raw frames (scaled by figmaScale) instead
    // of AutoLayout, since these shapes come straight from Figma's absolute coords
    // and are far easier to keep pixel-accurate that way.
    private func layoutFigmaPositionedViews() {
        let s = figmaScale
        let originX = (view.bounds.width - Figma.refWidth * s) / 2 // centers if device is wider than 402pt

        func scaledRect(_ r: CGRect) -> CGRect {
            CGRect(x: originX + r.origin.x * s, y: r.origin.y * s, width: r.width * s, height: r.height * s)
        }
        func scaledPoint(_ p: CGPoint) -> CGPoint {
            CGPoint(x: originX + p.x * s, y: p.y * s)
        }

        // Title
        let titleWidth = view.bounds.width - 48 * s
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: titleWidth, height: .greatestFiniteMagnitude)).height
        titleLabel.frame = CGRect(x: 24 * s, y: Figma.titleTopY * s, width: titleWidth, height: titleHeight)

        // Photos
        leftImageView.bounds = CGRect(origin: .zero, size: CGSize(width: Figma.photoSize.width * s, height: Figma.photoSize.height * s))
        leftImageView.layer.position = scaledPoint(Figma.leftPhotoOrigin)
        leftImageView.transform = CGAffineTransform(rotationAngle: Figma.leftPhotoRotationDeg * .pi / 180)
        leftImageView.layer.cornerRadius = Figma.photoCornerRadius * s

        rightImageView.bounds = CGRect(origin: .zero, size: CGSize(width: Figma.photoSize.width * s, height: Figma.photoSize.height * s))
        rightImageView.layer.position = scaledPoint(Figma.rightPhotoOrigin)
        rightImageView.transform = CGAffineTransform(rotationAngle: Figma.rightPhotoRotationDeg * .pi / 180)
        rightImageView.layer.cornerRadius = Figma.photoCornerRadius * s

        // Badge — centered on the photo overlap point
        let badgeFrame = scaledRect(Figma.badgeFrame)
        starBadge.frame = badgeFrame

        // Buttons
        sayHelloBtn.frame = scaledRect(Figma.sayHelloFrame)
        keepSwipingBtn.frame = scaledRect(Figma.keepSwipingFrame)

        // Subtitle sits below the badge
        subtitleLabel.frame = CGRect(
            x: 32, y: badgeFrame.maxY + 24 * s,
            width: view.bounds.width - 64,
            height: subtitleLabel.sizeThatFits(CGSize(width: view.bounds.width - 64, height: .greatestFiniteMagnitude)).height
        )

        // Glow orbs
        for orb in orbLayoutInfo {
            let r = orb.radius * s
            orb.view.frame = CGRect(x: 0, y: 0, width: r * 2, height: r * 2)
            orb.view.layer.cornerRadius = r
            orb.view.center = scaledPoint(orb.figmaCenter)
            orb.view.layer.shadowRadius = r * 1.4
        }
    }

    // MARK: - Populate
    private func populateData() {
        guard let result = matchResult else { return }

        subtitleLabel.text = result.message.isEmpty
            ? "Is Ready To Make Some Plans. Why Not Start The Conversation?"
            : result.message

        if let url = result.myGroupImageURL {
            loadImage(urlStr: url) { [weak self] image in
                self?.leftImageView.image = image
            }
        }

        if let url = result.matchedGroupImageURL {
            loadImage(urlStr: url) { [weak self] image in
                self?.rightImageView.image = image
            }
        }
    }

    private func loadImage(urlStr: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlStr) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    // MARK: - Gradient borders / badge gradient frame updates
    private func updateGradientBorders() {
        applyGradientBorder(to: leftImageView,  gradientLayer: leftGradientLayer)
        applyGradientBorder(to: rightImageView, gradientLayer: rightGradientLayer)
        badgeGradient.frame = starBadge.bounds
    }

    private func applyGradientBorder(to imageView: UIImageView, gradientLayer: CAGradientLayer) {
        let borderWidth: CGFloat = 2 * figmaScale
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

    // MARK: - Animations (fade + gentle scale-in — not a bottom-sheet slide anymore)
    private func animateIn() {
        dimView.alpha = 0
        titleLabel.alpha = 0
        [leftImageView, rightImageView].forEach { $0.alpha = 0 }
        subtitleLabel.alpha = 0
        sayHelloBtn.alpha = 0
        keepSwipingBtn.alpha = 0
        starBadge.transform = starBadge.transform.concatenating(CGAffineTransform(scaleX: 0.5, y: 0.5))

        UIView.animate(withDuration: 0.3) {
            self.dimView.alpha = 1
            self.titleLabel.alpha = 1
        }
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.leftImageView.alpha = 1
            self.rightImageView.alpha = 1
        }
        UIView.animate(withDuration: 0.4, delay: 0.25, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
            self.sayHelloBtn.alpha = 1
            self.keepSwipingBtn.alpha = 1
        }
        UIView.animate(
            withDuration: 0.5, delay: 0.3,
            usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8
        ) {
            self.starBadge.transform = self.starBadge.transform.concatenating(CGAffineTransform(scaleX: 2, y: 2))
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0
        }, completion: { _ in completion() })
    }

    @objc private func handleDimTap() {
        // Tapping the empty dim area (not the buttons) dismisses, same as before.
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


