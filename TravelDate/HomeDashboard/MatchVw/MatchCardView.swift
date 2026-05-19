import UIKit
import Kingfisher

// MARK: - Poppins Font Helper
private extension UIFont {
    static func poppins(_ weight: Weight, size: CGFloat) -> UIFont {
        let name: String
        switch weight {
        case .regular:  name = "Poppins-Regular"
        case .medium:   name = "Poppins-Medium"
        case .semibold: name = "Poppins-SemiBold"
        case .bold:     name = "Poppins-Bold"
        default:        name = "Poppins-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - MatchCardView
final class MatchCardView: UIView {

    // MARK: Public API (read by SwipeViewController)
    private(set) var isFlipped = false
    var flipButtonFrame: CGRect { filterButton.frame }

    // ─────────────────────────────────────────────────────────
    // MARK: — Face containers
    // ─────────────────────────────────────────────────────────
    private let frontView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 24
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 24
        v.alpha = 0
        // Pre-mirrored so it looks correct after the flip
        v.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: — Front face elements
    // ─────────────────────────────────────────────────────────
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientOverlay: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var frontGradient: CAGradientLayer?

    // Top-left travel style badge
    private let travelStyleBadge: UIView = {
        let v = UIView(); v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let badgeBlur   = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let badgeEmoji  = MatchCardView.makeLabel(font: .systemFont(ofSize: 14))
    private let badgeTitle  = MatchCardView.makeLabel(font: .poppins(.medium, size: 13), color: .white)

    // Top-right flip button
    private let filterButton: UIButton = {
        let b = UIButton(type: .system)
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let filterBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    // Bottom info
    private let groupIconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let groupIconLabel = MatchCardView.makeLabel(font: .systemFont(ofSize: 18), align: .center)
    private let groupTitleLabel = MatchCardView.makeLabel(font: .poppins(.semibold, size: 20), color: .white, lines: 1)

    // Pills
    private let datePill      = MatchCardView.pill()
    private let dateLabel     = MatchCardView.pillLabel()
    private let locationPill  = MatchCardView.pill()
    private let locationLabel = MatchCardView.pillLabel()
    private let travelersPill  = MatchCardView.pill()
    private let travelersLabel = MatchCardView.pillLabel()
    private let agePill  = MatchCardView.pill()
    private let ageLabel = MatchCardView.pillLabel()

    // Stamps
    private let likeStampView  = MatchCardView.stamp(color: .systemGreen, angle: -0.26)
    private let nopeStampView  = MatchCardView.stamp(color: .systemRed,   angle:  0.26)
    private let likeStampLabel = MatchCardView.stampLabel(text: "JOIN",  color: .systemGreen)
    private let nopeStampLabel = MatchCardView.stampLabel(text: "NOPE",  color: .systemRed)

    // ─────────────────────────────────────────────────────────
    // MARK: — Back face elements
    // ─────────────────────────────────────────────────────────
    private let backGradientLayer = CAGradientLayer()

    private let backBadge      = UIView()
    private let backBadgeBlur  = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let backBadgeEmoji = MatchCardView.makeLabel(font: .systemFont(ofSize: 14))
    private let backBadgeTitle = MatchCardView.makeLabel(font: .poppins(.medium, size: 13), color: .white)

    private let backFlipButton: UIButton = {
        let b = UIButton(type: .system); b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let backFlipBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    // ── KEY: members collection view
    // Cell sizing uses UICollectionViewDelegateFlowLayout sizeForItemAt —
    // this is called at data-load time with the ACTUAL collection view bounds,
    // not during the initial layout pass when backView may be hidden (alpha=0).
    private lazy var membersCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection        = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing     = 10
        // Do NOT set itemSize here — delegate method handles it
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(MemberCell.self, forCellWithReuseIdentifier: MemberCell.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        return cv
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: — Model
    // ─────────────────────────────────────────────────────────
    var group: Group? { didSet { configure() } }
    private var members: [MemberGroup] = []

    // ─────────────────────────────────────────────────────────
    // MARK: — Init
    // ─────────────────────────────────────────────────────────
    override init(frame: CGRect)  { super.init(frame: frame);  setup() }
    required init?(coder: NSCoder){ super.init(coder: coder); setup() }

    // ─────────────────────────────────────────────────────────
    // MARK: — layoutSubviews  (CALayer frames only — NO cell sizing here)
    // ─────────────────────────────────────────────────────────
    override func layoutSubviews() {
        super.layoutSubviews()
        frontGradient?.frame      = gradientOverlay.bounds
        backGradientLayer.frame   = backView.bounds

        travelStyleBadge.layer.cornerRadius = travelStyleBadge.bounds.height / 2
        backBadge.layer.cornerRadius        = backBadge.bounds.height / 2
        filterButton.layer.cornerRadius     = filterButton.bounds.height / 2
        backFlipButton.layer.cornerRadius   = backFlipButton.bounds.height / 2
        groupIconCircle.layer.cornerRadius  = groupIconCircle.bounds.height / 2
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Setup
    // ─────────────────────────────────────────────────────────
    private func setup() {
        layer.cornerRadius = 24
        clipsToBounds = true
        backgroundColor = .black

        for face in [frontView, backView] {
            addSubview(face)
            NSLayoutConstraint.activate([
                face.topAnchor.constraint(equalTo: topAnchor),
                face.leadingAnchor.constraint(equalTo: leadingAnchor),
                face.trailingAnchor.constraint(equalTo: trailingAnchor),
                face.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        buildFront()
        buildBack()
        buildStamps()
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Front face
    // ─────────────────────────────────────────────────────────
    private func buildFront() {
        // Cover image — full bleed
        frontView.addSubview(coverImageView)
        pin(coverImageView, to: frontView)

        // Gradient overlay — full bleed, non-interactive
        frontView.addSubview(gradientOverlay)
        pin(gradientOverlay, to: frontView)

        let gl = CAGradientLayer()
        gl.colors     = [UIColor.black.withAlphaComponent(0.0).cgColor,
                         UIColor(red: 247/255, green: 102/255, blue: 6/255, alpha: 0.72).cgColor]
        gl.locations  = [0.45, 1.0]
        gl.startPoint = CGPoint(x: 0.5, y: 0.0)
        gl.endPoint   = CGPoint(x: 0.5, y: 1.0)
        gl.cornerRadius = 24
        gradientOverlay.layer.insertSublayer(gl, at: 0)
        frontGradient = gl

        // Travel style badge (top-left)
        frontView.addSubview(travelStyleBadge)
        for v in [badgeBlur as UIView, badgeEmoji, badgeTitle] {
            v.translatesAutoresizingMaskIntoConstraints = false
            travelStyleBadge.addSubview(v)
        }
        NSLayoutConstraint.activate([
            travelStyleBadge.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 18),
            travelStyleBadge.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            travelStyleBadge.heightAnchor.constraint(equalToConstant: 34),

            badgeBlur.topAnchor.constraint(equalTo: travelStyleBadge.topAnchor),
            badgeBlur.leadingAnchor.constraint(equalTo: travelStyleBadge.leadingAnchor),
            badgeBlur.trailingAnchor.constraint(equalTo: travelStyleBadge.trailingAnchor),
            badgeBlur.bottomAnchor.constraint(equalTo: travelStyleBadge.bottomAnchor),

            badgeEmoji.leadingAnchor.constraint(equalTo: travelStyleBadge.leadingAnchor, constant: 10),
            badgeEmoji.centerYAnchor.constraint(equalTo: travelStyleBadge.centerYAnchor),
            badgeTitle.leadingAnchor.constraint(equalTo: badgeEmoji.trailingAnchor, constant: 5),
            badgeTitle.centerYAnchor.constraint(equalTo: travelStyleBadge.centerYAnchor),
            badgeTitle.trailingAnchor.constraint(equalTo: travelStyleBadge.trailingAnchor, constant: -10)
        ])

        // Flip button (top-right)
        filterBlur.translatesAutoresizingMaskIntoConstraints = false
        filterBlur.isUserInteractionEnabled = false
        frontView.addSubview(filterButton)
        filterButton.insertSubview(filterBlur, at: 0)
        let fIcon = iconView("rectangle.on.rectangle")
        filterButton.addSubview(fIcon)
        NSLayoutConstraint.activate([
            filterButton.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 18),
            filterButton.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 38),
            filterButton.heightAnchor.constraint(equalToConstant: 38),
            filterBlur.topAnchor.constraint(equalTo: filterButton.topAnchor),
            filterBlur.leadingAnchor.constraint(equalTo: filterButton.leadingAnchor),
            filterBlur.trailingAnchor.constraint(equalTo: filterButton.trailingAnchor),
            filterBlur.bottomAnchor.constraint(equalTo: filterButton.bottomAnchor),
            fIcon.centerXAnchor.constraint(equalTo: filterButton.centerXAnchor),
            fIcon.centerYAnchor.constraint(equalTo: filterButton.centerYAnchor),
            fIcon.widthAnchor.constraint(equalToConstant: 18),
            fIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
        filterButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)

        // Bottom info: icon → title → row1 → row2
        frontView.addSubview(groupIconCircle)
        groupIconLabel.translatesAutoresizingMaskIntoConstraints = false
        groupIconCircle.addSubview(groupIconLabel)

        frontView.addSubview(groupTitleLabel)

        let row1 = pillRow([(datePill, dateLabel), (locationPill, locationLabel)])
        let row2 = pillRow([(travelersPill, travelersLabel), (agePill, ageLabel)])
        frontView.addSubview(row1)
        frontView.addSubview(row2)

        NSLayoutConstraint.activate([
            // Pin row2 to bottom
            row2.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            row2.bottomAnchor.constraint(equalTo: frontView.bottomAnchor, constant: -20),
            row2.trailingAnchor.constraint(lessThanOrEqualTo: frontView.trailingAnchor, constant: -16),
            // row1 above row2
            row1.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            row1.bottomAnchor.constraint(equalTo: row2.topAnchor, constant: -8),
            row1.trailingAnchor.constraint(lessThanOrEqualTo: frontView.trailingAnchor, constant: -16),
            // title above row1
            groupTitleLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            groupTitleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -60),
            groupTitleLabel.bottomAnchor.constraint(equalTo: row1.topAnchor, constant: -10),
            // icon above title
            groupIconCircle.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            groupIconCircle.bottomAnchor.constraint(equalTo: groupTitleLabel.topAnchor, constant: -8),
            groupIconCircle.widthAnchor.constraint(equalToConstant: 40),
            groupIconCircle.heightAnchor.constraint(equalToConstant: 40),
            groupIconLabel.centerXAnchor.constraint(equalTo: groupIconCircle.centerXAnchor),
            groupIconLabel.centerYAnchor.constraint(equalTo: groupIconCircle.centerYAnchor)
        ])
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Back face
    // ─────────────────────────────────────────────────────────
    private func buildBack() {
        // Orange → deep-red gradient
        backGradientLayer.colors    = [UIColor(red: 1.0, green: 0.44, blue: 0.09, alpha: 1).cgColor,
                                       UIColor(red: 0.82, green: 0.17, blue: 0.10, alpha: 1).cgColor]
        backGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backGradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        backGradientLayer.cornerRadius = 24
        backView.layer.insertSublayer(backGradientLayer, at: 0)

        // Back badge (top-left)
        backBadge.clipsToBounds = true
        backBadge.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(backBadge)
        for v in [backBadgeBlur as UIView, backBadgeEmoji, backBadgeTitle] {
            v.translatesAutoresizingMaskIntoConstraints = false
            backBadge.addSubview(v)
        }
        NSLayoutConstraint.activate([
            backBadge.topAnchor.constraint(equalTo: backView.topAnchor, constant: 18),
            backBadge.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            backBadge.heightAnchor.constraint(equalToConstant: 34),
            backBadgeBlur.topAnchor.constraint(equalTo: backBadge.topAnchor),
            backBadgeBlur.leadingAnchor.constraint(equalTo: backBadge.leadingAnchor),
            backBadgeBlur.trailingAnchor.constraint(equalTo: backBadge.trailingAnchor),
            backBadgeBlur.bottomAnchor.constraint(equalTo: backBadge.bottomAnchor),
            backBadgeEmoji.leadingAnchor.constraint(equalTo: backBadge.leadingAnchor, constant: 10),
            backBadgeEmoji.centerYAnchor.constraint(equalTo: backBadge.centerYAnchor),
            backBadgeTitle.leadingAnchor.constraint(equalTo: backBadgeEmoji.trailingAnchor, constant: 5),
            backBadgeTitle.centerYAnchor.constraint(equalTo: backBadge.centerYAnchor),
            backBadgeTitle.trailingAnchor.constraint(equalTo: backBadge.trailingAnchor, constant: -10)
        ])

        // Back flip button (top-right)
        backFlipBlur.translatesAutoresizingMaskIntoConstraints = false
        backFlipBlur.isUserInteractionEnabled = false
        backView.addSubview(backFlipButton)
        backFlipButton.insertSubview(backFlipBlur, at: 0)
        let bIcon = iconView("rectangle.on.rectangle")
        backFlipButton.addSubview(bIcon)
        NSLayoutConstraint.activate([
            backFlipButton.topAnchor.constraint(equalTo: backView.topAnchor, constant: 18),
            backFlipButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            backFlipButton.widthAnchor.constraint(equalToConstant: 38),
            backFlipButton.heightAnchor.constraint(equalToConstant: 38),
            backFlipBlur.topAnchor.constraint(equalTo: backFlipButton.topAnchor),
            backFlipBlur.leadingAnchor.constraint(equalTo: backFlipButton.leadingAnchor),
            backFlipBlur.trailingAnchor.constraint(equalTo: backFlipButton.trailingAnchor),
            backFlipBlur.bottomAnchor.constraint(equalTo: backFlipButton.bottomAnchor),
            bIcon.centerXAnchor.constraint(equalTo: backFlipButton.centerXAnchor),
            bIcon.centerYAnchor.constraint(equalTo: backFlipButton.centerYAnchor),
            bIcon.widthAnchor.constraint(equalToConstant: 18),
            bIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
        backFlipButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)

        // ── Members collection view
        // Constrained to fill the back face below the top bar.
        // sizeForItemAt (delegate) computes cell size from cv.bounds at query time.
        backView.addSubview(membersCV)
        NSLayoutConstraint.activate([
            membersCV.topAnchor.constraint(equalTo: backFlipButton.bottomAnchor, constant: 12),
            membersCV.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 12),
            membersCV.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -12),
            membersCV.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -12)
        ])
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Stamps (above both faces)
    // ─────────────────────────────────────────────────────────
    private func buildStamps() {
        addSubview(likeStampView);  likeStampView.addSubview(likeStampLabel)
        addSubview(nopeStampView); nopeStampView.addSubview(nopeStampLabel)

        for (stamp, label) in [(likeStampView, likeStampLabel), (nopeStampView, nopeStampLabel)] {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: stamp.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: stamp.bottomAnchor, constant: -8),
                label.leadingAnchor.constraint(equalTo: stamp.leadingAnchor, constant: 14),
                label.trailingAnchor.constraint(equalTo: stamp.trailingAnchor, constant: -14)
            ])
        }
        NSLayoutConstraint.activate([
            likeStampView.topAnchor.constraint(equalTo: topAnchor, constant: 56),
            likeStampView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nopeStampView.topAnchor.constraint(equalTo: topAnchor, constant: 56),
            nopeStampView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Configure
    // ─────────────────────────────────────────────────────────
    private func configure() {
        guard let group else { return }

        groupTitleLabel.text = group.groupTitle ?? "Travel Group"

        let style = group.travelStyle ?? "Travelers"
        let emoji = emojiForStyle(style)
        badgeEmoji.text  = emoji;  badgeTitle.text  = style
        backBadgeEmoji.text = emoji; backBadgeTitle.text = style
        groupIconLabel.text = emoji

        dateLabel.text      = formatDateRange(group.startDate, group.endDate)
        locationLabel.text  = "📍 \(group.destination ?? "—")"
        let count = group.members?.count ?? 0
        travelersLabel.text = "👥 \(count) traveler\(count == 1 ? "" : "s")"
        ageLabel.text       = "🎂 Avg age: 25–30"

        if let urlStr = group.coverImage, let url = URL(string: urlStr) {
            coverImageView.kf.setImage(with: url,
                                       placeholder: UIImage(named: "User"),
                                       options: [.transition(.fade(0.25)), .cacheOriginalImage])
        }

        members = group.members ?? []
        membersCV.reloadData()

        // Reset to front on reuse
        if isFlipped { flipCard() }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Flip Animation
    // ─────────────────────────────────────────────────────────
    @objc func flipCard() {
        isUserInteractionEnabled = false

        let fromView: UIView = isFlipped ? backView  : frontView
        let toView:   UIView = isFlipped ? frontView : backView
        let dir: CGFloat     = isFlipped ? -1.0 : 1.0

        // Phase 1: fold outgoing face to 90°
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseIn) {
            fromView.layer.transform = CATransform3DMakeRotation(.pi / 2 * dir, 0, 1, 0)
        } completion: { _ in
            fromView.alpha = 0
            fromView.layer.transform = CATransform3DIdentity

            // Phase 2: unfold incoming face from −90°
            toView.layer.transform = CATransform3DMakeRotation(-.pi / 2 * dir, 0, 1, 0)
            toView.alpha = 1

            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
                toView.layer.transform = CATransform3DIdentity
            } completion: { _ in
                self.isFlipped.toggle()
                self.isUserInteractionEnabled = true
                // Force a fresh layout pass so sizeForItemAt gets correct cv.bounds
                self.membersCV.collectionViewLayout.invalidateLayout()
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Stamp Control
    // ─────────────────────────────────────────────────────────
    func showLikeStamp(_ show: Bool, intensity: CGFloat = 1.0) {
        UIView.animate(withDuration: 0.1) {
            self.likeStampView.alpha  = show ? min(intensity * 2, 1.0) : 0
            self.nopeStampView.alpha = 0
        }
    }
    func showNopeStamp(_ show: Bool, intensity: CGFloat = 1.0) {
        UIView.animate(withDuration: 0.1) {
            self.nopeStampView.alpha = show ? min(intensity * 2, 1.0) : 0
            self.likeStampView.alpha  = 0
        }
    }
    func hideStamps() {
        UIView.animate(withDuration: 0.15) {
            self.likeStampView.alpha  = 0
            self.nopeStampView.alpha = 0
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: — Factory helpers
    // ─────────────────────────────────────────────────────────
    private static func makeLabel(font: UIFont,
                                   color: UIColor = .white,
                                   align: NSTextAlignment = .natural,
                                   lines: Int = 0) -> UILabel {
        let l = UILabel()
        l.font = font; l.textColor = color
        l.textAlignment = align; l.numberOfLines = lines
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private static func pill() -> UIView {
        let v = UIView()
        v.backgroundColor  = UIColor.black.withAlphaComponent(0.28)
        v.layer.cornerRadius = 14
        v.layer.borderWidth  = 0.5
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.30).cgColor
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private static func pillLabel() -> UILabel {
        makeLabel(font: .poppins(.regular, size: 12))
    }

    private func pillRow(_ pairs: [(UIView, UILabel)]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 8
        row.alignment = .center; row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        for (pill, label) in pairs {
            pill.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
                label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
                label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12)
            ])
            row.addArrangedSubview(pill)
        }
        return row
    }

    private static func stamp(color: UIColor, angle: CGFloat) -> UIView {
        let v = UIView()
        v.alpha = 0
        v.layer.cornerRadius = 10
        v.layer.borderWidth  = 3.5
        v.layer.borderColor  = color.cgColor
        v.transform = CGAffineTransform(rotationAngle: angle)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private static func stampLabel(text: String, color: UIColor) -> UILabel {
        makeLabel(font: .poppins(.bold, size: 22), color: color)
    }

    private func iconView(_ systemName: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = .white; iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }

    private func pin(_ v: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: parent.topAnchor),
            v.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }

    private func emojiForStyle(_ s: String) -> String {
        let l = s.lowercased()
        if l.contains("party") || l.contains("partygoer") { return "🥂" }
        if l.contains("adven")   { return "🏔️" }
        if l.contains("beach")   { return "🏖️" }
        if l.contains("food")    { return "🍜" }
        if l.contains("hike")    { return "🥾" }
        if l.contains("leisure") { return "🌴" }
        if l.contains("cultur")  { return "🏛️" }
        return "✈️"
    }

    private func formatDateRange(_ start: String?, _ end: String?) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d, yyyy"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        func parse(_ raw: String?) -> String {
            guard let raw, let d = iso.date(from: raw) else { return String((start ?? "").prefix(10)) }
            return fmt.string(from: d)
        }
        return "\(parse(start)) – \(parse(end))"
    }

    static func make() -> MatchCardView { MatchCardView(frame: .zero) }
}

// MARK: - UICollectionViewDataSource
extension MatchCardView: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { members.count }

    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MemberCell.reuseID, for: ip) as! MemberCell
        cell.configure(with: members[ip.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
// ── THE FIX: size is computed here, called lazily when cells are actually needed.
// By this time the collection view has been laid out and bounds are correct.
extension MatchCardView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        let gap: CGFloat = 10   // same as minimumInteritemSpacing
        let w = cv.bounds.width
        guard w > 0 else {
            // Fallback: estimate from card width (superview chain)
            let cardW = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
            let side = floor((cardW - 24 - 10) / 2)   // 24 = 12+12 padding
            return CGSize(width: side, height: side * 1.2)
        }
        let side = floor((w - gap) / 2)
        return CGSize(width: side, height: side * 1.2)
    }
}

// MARK: - MemberCell
final class MemberCell: UICollectionViewCell {

    static let reuseID = "MemberCell"

    private let photo: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let scrim: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors    = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.72).cgColor]
        l.locations = [0.45, 1.0]
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .poppins(.semibold, size: 13)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        v.layer.cornerRadius = 13
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let iconLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 12)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        // Photo fills cell
        contentView.addSubview(photo)
        NSLayoutConstraint.activate([
            photo.topAnchor.constraint(equalTo: contentView.topAnchor),
            photo.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photo.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        photo.layer.addSublayer(scrim)

        // Name label — bottom-left
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        // Icon badge — bottom-right
        iconBadge.addSubview(iconLabel)
        contentView.addSubview(iconBadge)
        NSLayoutConstraint.activate([
            iconBadge.widthAnchor.constraint(equalToConstant: 26),
            iconBadge.heightAnchor.constraint(equalToConstant: 26),
            iconBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            iconBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            iconLabel.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrim.frame = contentView.bounds
    }

    func configure(with member: MemberGroup) {
        nameLabel.text = member.name ??  "Traveler"
        iconLabel.text = "" //emojiForStyle(member.travelStyle ?? "")

        let urlStr = member.profileImage ?? ""
        if let url = URL(string: urlStr) {
            photo.kf.setImage(with: url,
                              placeholder: UIImage(systemName: "person.fill"),
                              options: [.transition(.fade(0.2)), .cacheOriginalImage])
        } else {
            photo.image = UIImage(systemName: "person.fill")
            photo.tintColor = .white
        }
    }

    private func emojiForStyle(_ s: String) -> String {
        let l = s.lowercased()
        if l.contains("party")  { return "🥂" }
        if l.contains("adven")  { return "🏔️" }
        if l.contains("beach")  { return "🏖️" }
        if l.contains("food")   { return "🍜" }
        if l.contains("hike")   { return "🥾" }
        if l.contains("cultur") { return "🏛️" }
        return "✈️"
    }
}
