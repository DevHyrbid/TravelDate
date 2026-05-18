import UIKit
import Kingfisher

// MARK: - Poppins Font Helper
private extension UIFont {
    static func poppins(_ weight: Weight, size: CGFloat) -> UIFont {
        let name: String
        switch weight {
        case .regular:    name = "Poppins-Regular"
        case .medium:     name = "Poppins-Medium"
        case .semibold:   name = "Poppins-SemiBold"
        case .bold:       name = "Poppins-Bold"
        default:          name = "Poppins-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - MatchCardView
final class MatchCardView: UIView {

    // MARK: - Public API
    private(set) var isFlipped = false

    /// Hit-test frame of the flip toggle button (front face), in card-local coords.
    var flipButtonFrame: CGRect { filterButton.frame }

    // ─────────────────────────────────────────────────────────
    // MARK: Face Containers
    // ─────────────────────────────────────────────────────────
    private let frontView = MatchCardView.makeFaceContainer()
    private let backView: UIView = {
        let v = MatchCardView.makeFaceContainer()
        v.alpha = 0
        v.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
        return v
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: Front — Cover Image
    // ─────────────────────────────────────────────────────────
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: Front — Gradient Overlay
    // ─────────────────────────────────────────────────────────
    private let gradientOverlay: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var frontGradientLayer: CAGradientLayer?

    // ─────────────────────────────────────────────────────────
    // MARK: Front — Top-Left Badge (frosted pill)
    // ─────────────────────────────────────────────────────────
    private let travelStyleBadge: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let badgeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let badgeEmoji: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let badgeTitle: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .poppins(.medium, size: 13)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: Front — Top-Right Flip Button
    // ─────────────────────────────────────────────────────────
    private let filterButton: UIButton = {
        let b = UIButton(type: .system)
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private let filterBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    // ─────────────────────────────────────────────────────────
    // MARK: Front — Bottom Info
    // ─────────────────────────────────────────────────────────
    private let groupIconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let groupIconLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 18)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let groupTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .poppins(.semibold, size: 20)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Pills — Row 1: date | location
    private let datePill      = MatchCardView.makePill()
    private let dateLabel     = MatchCardView.makePillLabel(size: 12)
    private let locationPill  = MatchCardView.makePill()
    private let locationLabel = MatchCardView.makePillLabel(size: 12)

    // Pills — Row 2: travelers | age
    private let travelersPill  = MatchCardView.makePill()
    private let travelersLabel = MatchCardView.makePillLabel(size: 12)
    private let agePill  = MatchCardView.makePill()
    private let ageLabel = MatchCardView.makePillLabel(size: 12)

    // ─────────────────────────────────────────────────────────
    // MARK: Stamps (always on top of both faces)
    // ─────────────────────────────────────────────────────────
    private let likeStampView  = MatchCardView.makeStamp(color: .systemGreen, angle: -0.26)
    private let nopeStampView  = MatchCardView.makeStamp(color: .systemRed,   angle:  0.26)
    private let likeStampLabel = MatchCardView.makeStampLabel(text: "JOIN",  color: .systemGreen)
    private let nopeStampLabel = MatchCardView.makeStampLabel(text: "NOPE",  color: .systemRed)

    // ─────────────────────────────────────────────────────────
    // MARK: Back Face
    // ─────────────────────────────────────────────────────────
    private let backGradient = CAGradientLayer()

    // Back badge mirrors front
    private let backBadge     = UIView()
    private let backBadgeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let backBadgeEmoji: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let backBadgeTitle: UILabel = {
        let l = UILabel(); l.textColor = .white; l.font = .poppins(.medium, size: 13); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    // Back flip-back button
    private let backFlipButton: UIButton = {
        let b = UIButton(type: .system); b.clipsToBounds = true; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let backFlipBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    // ── Members grid — key: use a plain UIView wrapper so we control sizing
    private let gridContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.clipsToBounds = false; return v
    }()
    private lazy var membersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.isScrollEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.register(MemberCell.self, forCellWithReuseIdentifier: MemberCell.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        return cv
    }()

    // ─────────────────────────────────────────────────────────
    // MARK: Model
    // ─────────────────────────────────────────────────────────
    var group: Group? { didSet { configure() } }
    private var members: [MemberGroup] = []

    // ─────────────────────────────────────────────────────────
    // MARK: Init
    // ─────────────────────────────────────────────────────────
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    // ─────────────────────────────────────────────────────────
    // MARK: Layout
    // ─────────────────────────────────────────────────────────
    override func layoutSubviews() {
        super.layoutSubviews()

        frontGradientLayer?.frame = gradientOverlay.bounds
        backGradient.frame = backView.bounds

        // Pill corners (half height)
        [travelStyleBadge, backBadge].forEach { $0.layer.cornerRadius = $0.bounds.height / 2 }
        [filterButton, backFlipButton].forEach { $0.layer.cornerRadius = $0.bounds.height / 2 }
        groupIconCircle.layer.cornerRadius = groupIconCircle.bounds.height / 2

        // ── FIX: Compute cell size from the actual collection view width.
        // This is the only reliable place to do it — bounds are final here.
        if let layout = membersCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let w = membersCollectionView.bounds.width
            let gap: CGFloat = 10
            let side = floor((w - gap) / 2)
            if side > 0 && layout.itemSize.width != side {
                layout.itemSize = CGSize(width: side, height: side * 1.2)
                layout.invalidateLayout()
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Setup
    // ─────────────────────────────────────────────────────────
    private func setup() {
        layer.cornerRadius = 24
        clipsToBounds = true
        backgroundColor = .black

        // Both faces fill the card completely
        [frontView, backView].forEach { face in
            addSubview(face)
            NSLayoutConstraint.activate([
                face.topAnchor.constraint(equalTo: topAnchor),
                face.leadingAnchor.constraint(equalTo: leadingAnchor),
                face.trailingAnchor.constraint(equalTo: trailingAnchor),
                face.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        setupFront()
        setupBack()
        setupStamps()
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Front Face Setup
    // ─────────────────────────────────────────────────────────
    private func setupFront() {
        // Cover image — full bleed
        frontView.addSubview(coverImageView)
        pin(coverImageView, to: frontView)

        // Gradient overlay — full bleed, non-interactive
        frontView.addSubview(gradientOverlay)
        pin(gradientOverlay, to: frontView)

        let gl = CAGradientLayer()
        gl.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor(red: 247/255, green: 102/255, blue: 6/255, alpha: 0.72).cgColor
        ]
        gl.locations   = [0.45, 1.0]
        gl.startPoint  = CGPoint(x: 0.5, y: 0.0)
        gl.endPoint    = CGPoint(x: 0.5, y: 1.0)
        gl.cornerRadius = 24
        gradientOverlay.layer.insertSublayer(gl, at: 0)
        frontGradientLayer = gl

        // ── Travel style badge (top-left)
        frontView.addSubview(travelStyleBadge)
        [badgeBlur, badgeEmoji, badgeTitle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            travelStyleBadge.addSubview($0)
        }
        NSLayoutConstraint.activate([
            // Badge outer
            travelStyleBadge.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 18),
            travelStyleBadge.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            travelStyleBadge.heightAnchor.constraint(equalToConstant: 34),
            // Blur fills badge
            badgeBlur.topAnchor.constraint(equalTo: travelStyleBadge.topAnchor),
            badgeBlur.leadingAnchor.constraint(equalTo: travelStyleBadge.leadingAnchor),
            badgeBlur.trailingAnchor.constraint(equalTo: travelStyleBadge.trailingAnchor),
            badgeBlur.bottomAnchor.constraint(equalTo: travelStyleBadge.bottomAnchor),
            // Emoji
            badgeEmoji.leadingAnchor.constraint(equalTo: travelStyleBadge.leadingAnchor, constant: 10),
            badgeEmoji.centerYAnchor.constraint(equalTo: travelStyleBadge.centerYAnchor),
            // Title
            badgeTitle.leadingAnchor.constraint(equalTo: badgeEmoji.trailingAnchor, constant: 5),
            badgeTitle.centerYAnchor.constraint(equalTo: travelStyleBadge.centerYAnchor),
            badgeTitle.trailingAnchor.constraint(equalTo: travelStyleBadge.trailingAnchor, constant: -10)
        ])

        // ── Flip button (top-right)
        filterBlur.translatesAutoresizingMaskIntoConstraints = false
        filterBlur.isUserInteractionEnabled = false
        frontView.addSubview(filterButton)
        filterButton.insertSubview(filterBlur, at: 0)
        let frontIcon = makeIcon("rectangle.on.rectangle")
        filterButton.addSubview(frontIcon)
        NSLayoutConstraint.activate([
            filterButton.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 18),
            filterButton.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 38),
            filterButton.heightAnchor.constraint(equalToConstant: 38),
            filterBlur.topAnchor.constraint(equalTo: filterButton.topAnchor),
            filterBlur.leadingAnchor.constraint(equalTo: filterButton.leadingAnchor),
            filterBlur.trailingAnchor.constraint(equalTo: filterButton.trailingAnchor),
            filterBlur.bottomAnchor.constraint(equalTo: filterButton.bottomAnchor),
            frontIcon.centerXAnchor.constraint(equalTo: filterButton.centerXAnchor),
            frontIcon.centerYAnchor.constraint(equalTo: filterButton.centerYAnchor),
            frontIcon.widthAnchor.constraint(equalToConstant: 18),
            frontIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
        filterButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)

        // ── Bottom info section
        // Group icon circle
        frontView.addSubview(groupIconCircle)
        groupIconCircle.addSubview(groupIconLabel)
        NSLayoutConstraint.activate([
            groupIconCircle.widthAnchor.constraint(equalToConstant: 40),
            groupIconCircle.heightAnchor.constraint(equalToConstant: 40),
            groupIconLabel.centerXAnchor.constraint(equalTo: groupIconCircle.centerXAnchor),
            groupIconLabel.centerYAnchor.constraint(equalTo: groupIconCircle.centerYAnchor)
        ])

        // Group title
        frontView.addSubview(groupTitleLabel)

        // Pill rows
        let row1 = makePillRow([(datePill, dateLabel), (locationPill, locationLabel)])
        let row2 = makePillRow([(travelersPill, travelersLabel), (agePill, ageLabel)])
        frontView.addSubview(row1)
        frontView.addSubview(row2)

        NSLayoutConstraint.activate([
            // row2 pinned to bottom
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
            groupIconCircle.bottomAnchor.constraint(equalTo: groupTitleLabel.topAnchor, constant: -8)
        ])
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Back Face Setup
    // ─────────────────────────────────────────────────────────
    private func setupBack() {
        // Gradient background
        backGradient.colors = [
            UIColor(red: 1.0,  green: 0.44, blue: 0.09, alpha: 1).cgColor,
            UIColor(red: 0.82, green: 0.17, blue: 0.10, alpha: 1).cgColor
        ]
        backGradient.startPoint  = CGPoint(x: 0, y: 0)
        backGradient.endPoint    = CGPoint(x: 1, y: 1)
        backGradient.cornerRadius = 24
        backView.layer.insertSublayer(backGradient, at: 0)

        // ── Back badge (top-left, mirrors front)
        backBadge.clipsToBounds = true
        backBadge.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(backBadge)
        [backBadgeBlur, backBadgeEmoji, backBadgeTitle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            backBadge.addSubview($0)
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

        // ── Back flip button (top-right)
        backFlipBlur.translatesAutoresizingMaskIntoConstraints = false
        backFlipBlur.isUserInteractionEnabled = false
        backView.addSubview(backFlipButton)
        backFlipButton.insertSubview(backFlipBlur, at: 0)
        let backIcon = makeIcon("rectangle.on.rectangle")
        backFlipButton.addSubview(backIcon)
        NSLayoutConstraint.activate([
            backFlipButton.topAnchor.constraint(equalTo: backView.topAnchor, constant: 18),
            backFlipButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            backFlipButton.widthAnchor.constraint(equalToConstant: 38),
            backFlipButton.heightAnchor.constraint(equalToConstant: 38),
            backFlipBlur.topAnchor.constraint(equalTo: backFlipButton.topAnchor),
            backFlipBlur.leadingAnchor.constraint(equalTo: backFlipButton.leadingAnchor),
            backFlipBlur.trailingAnchor.constraint(equalTo: backFlipButton.trailingAnchor),
            backFlipBlur.bottomAnchor.constraint(equalTo: backFlipButton.bottomAnchor),
            backIcon.centerXAnchor.constraint(equalTo: backFlipButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backFlipButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 18),
            backIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
        backFlipButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)

        // ── Members grid container
        // gridContainer fills backView below the top bar, with padding
        backView.addSubview(gridContainer)
        gridContainer.addSubview(membersCollectionView)
        NSLayoutConstraint.activate([
            gridContainer.topAnchor.constraint(equalTo: backFlipButton.bottomAnchor, constant: 14),
            gridContainer.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 14),
            gridContainer.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -14),
            gridContainer.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -14),
            // CollectionView fills gridContainer exactly
            membersCollectionView.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            membersCollectionView.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
            membersCollectionView.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor),
            membersCollectionView.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor)
        ])
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Stamps Setup
    // ─────────────────────────────────────────────────────────
    private func setupStamps() {
        addSubview(likeStampView); likeStampView.addSubview(likeStampLabel)
        addSubview(nopeStampView); nopeStampView.addSubview(nopeStampLabel)

        [likeStampLabel, nopeStampLabel].forEach {
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: $0.superview!.topAnchor, constant: 8),
                $0.bottomAnchor.constraint(equalTo: $0.superview!.bottomAnchor, constant: -8),
                $0.leadingAnchor.constraint(equalTo: $0.superview!.leadingAnchor, constant: 14),
                $0.trailingAnchor.constraint(equalTo: $0.superview!.trailingAnchor, constant: -14)
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
    // MARK: Configure
    // ─────────────────────────────────────────────────────────
    private func configure() {
        guard let group else { return }

        let title = group.groupTitle ?? "Travel Group"
        groupTitleLabel.text = title

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
        membersCollectionView.reloadData()

        // Reset to front face on reuse
        if isFlipped { flipCard() }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Flip Animation
    // ─────────────────────────────────────────────────────────
    @objc func flipCard() {
        isUserInteractionEnabled = false
        let fromView: UIView = isFlipped ? backView  : frontView
        let toView:   UIView = isFlipped ? frontView : backView
        let dir: CGFloat     = isFlipped ? -1 : 1

        // Phase 1: fold current face out (0 → π/2)
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseIn) {
            fromView.layer.transform = CATransform3DMakeRotation(.pi / 2 * dir, 0, 1, 0)
        } completion: { _ in
            fromView.alpha = 0
            fromView.layer.transform = CATransform3DIdentity
            // Phase 2: unfold new face in (−π/2 → 0)
            toView.layer.transform = CATransform3DMakeRotation(-.pi / 2 * dir, 0, 1, 0)
            toView.alpha = 1
            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
                toView.layer.transform = CATransform3DIdentity
            } completion: { _ in
                self.isFlipped.toggle()
                self.isUserInteractionEnabled = true
                // Trigger layout so collection view sizes cells correctly
                self.membersCollectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Stamp Control
    // ─────────────────────────────────────────────────────────
    func showLikeStamp(_ show: Bool, intensity: CGFloat = 1.0) {
        UIView.animate(withDuration: 0.1) {
            self.likeStampView.alpha = show ? min(intensity * 2, 1.0) : 0
            self.nopeStampView.alpha = 0
        }
    }
    func showNopeStamp(_ show: Bool, intensity: CGFloat = 1.0) {
        UIView.animate(withDuration: 0.1) {
            self.nopeStampView.alpha = show ? min(intensity * 2, 1.0) : 0
            self.likeStampView.alpha = 0
        }
    }
    func hideStamps() {
        UIView.animate(withDuration: 0.15) {
            self.likeStampView.alpha  = 0
            self.nopeStampView.alpha = 0
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: Factory / Helpers
    // ─────────────────────────────────────────────────────────
    private static func makeFaceContainer() -> UIView {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 24
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private static func makePill() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        v.layer.cornerRadius = 14
        v.layer.borderWidth  = 0.5
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.30).cgColor
        v.clipsToBounds = true
        return v
    }

    private static func makePillLabel(size: CGFloat = 12) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .white
        l.font = .poppins(.regular, size: size)
        return l
    }

    private func makePillRow(_ pairs: [(UIView, UILabel)]) -> UIStackView {
        let row = UIStackView()
        row.axis         = .horizontal
        row.spacing      = 8
        row.alignment    = .center
        row.distribution = .fill
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

    private static func makeStamp(color: UIColor, angle: CGFloat) -> UIView {
        let v = UIView()
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 10
        v.layer.borderWidth  = 3.5
        v.layer.borderColor  = color.cgColor
        v.transform = CGAffineTransform(rotationAngle: angle)
        return v
    }

    private static func makeStampLabel(text: String, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.textColor = color
        l.font      = .poppins(.bold, size: 22)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func makeIcon(_ name: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: name))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }

    private func pin(_ view: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parent.topAnchor),
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }

    private func emojiForStyle(_ s: String) -> String {
        let l = s.lowercased()
        if l.contains("party") || l.contains("partygoer") { return "🥂" }
        if l.contains("adven")  { return "🏔️" }
        if l.contains("beach")  { return "🏖️" }
        if l.contains("food")   { return "🍜" }
        if l.contains("hike")   { return "🥾" }
        if l.contains("leisure") { return "🌴" }
        if l.contains("cultur") { return "🏛️" }
        return "✈️"
    }

    private func formatDateRange(_ start: String?, _ end: String?) -> String {
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        func parse(_ raw: String?) -> String {
            guard let raw, let d = iso.date(from: raw) else { return String((start ?? "").prefix(10)) }
            return display.string(from: d)
        }
        return "\(parse(start)) – \(parse(end))"
    }

    static func make() -> MatchCardView { MatchCardView(frame: .zero) }
}

// MARK: - UICollectionView DataSource & Delegate
extension MatchCardView: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        members.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MemberCell.reuseID, for: indexPath) as! MemberCell
        cell.configure(with: members[indexPath.item])
        return cell
    }
}

// MARK: - MemberCell
final class MemberCell: UICollectionViewCell {

    static let reuseID = "MemberCell"

    // Full-bleed photo
    private let photo: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Bottom gradient scrim
    private let scrim = CAGradientLayer()

    // Member name
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .poppins(.semibold, size: 13)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Travel-style icon badge (bottom-right)
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

        // Scrim gradient at bottom
        scrim.colors   = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.72).cgColor]
        scrim.locations = [0.45, 1.0]
        photo.layer.addSublayer(scrim)

        // Name label
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        // Icon badge
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
        nameLabel.text  = member.name  ?? "Traveler"
        iconLabel.text  = ""//emojiForStyle(member.travelStyle ?? "")

        if let url = URL(string: member.profileImage ?? "") {
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
