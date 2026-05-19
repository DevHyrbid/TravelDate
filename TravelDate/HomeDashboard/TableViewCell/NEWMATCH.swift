
//  NewMatchCell.swift
//  TravelDate

import UIKit

class NewMatchCell: UITableViewCell {

    static let reuseId = "NewMatchCell"

    // MARK: - UI
    let cardView      = UIView()
    let imageView_    = UIImageView()
    let matchedLabel  = UILabel()
    let titleLabel    = UILabel()
    let timeLabel     = UILabel()
    let locationLabel = UILabel()
    let startChatBtn  = UIButton(type: .system)
    let saveGroupBtn  = UIButton(type: .system)
    let membersView   = MembersProgressView()
    private let travelersLabel  = UILabel()

    // Glass badge — uses UIVisualEffectView for real frosted glass
    private let badgeBlurView   = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    let badgeLabel              = UILabel()

    var onStartChat: (() -> Void)?
    var onSaveGroup: (() -> Void)?

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    // MARK: - Setup
    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // ── Card ──────────────────────────────────────────────────────────
        // Figma: very dark near-black #191919
        cardView.backgroundColor    = UIColor(red: 0.098, green: 0.098, blue: 0.098, alpha: 1)
        cardView.layer.cornerRadius = 28
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // ── Image ─────────────────────────────────────────────────────────
        imageView_.contentMode   = .scaleAspectFill
        imageView_.clipsToBounds = true
        imageView_.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(imageView_)

        // ── Glass Badge "New Match" ───────────────────────────────────────
        // Figma: frosted glass pill — blur behind it, white 20% border
        badgeBlurView.layer.cornerRadius  = 20
        badgeBlurView.layer.masksToBounds = true
        // White border on glass pill
        badgeBlurView.layer.borderWidth   = 0.8
        badgeBlurView.layer.borderColor   = UIColor.white.withAlphaComponent(0.30).cgColor
        badgeBlurView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(badgeBlurView)

        badgeLabel.text      = "New Match"
        badgeLabel.font      = AppFont.medium(13)
        badgeLabel.textColor = .white
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeBlurView.contentView.addSubview(badgeLabel)

        // Badge label insets inside blur view
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badgeBlurView.topAnchor, constant: 7),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeBlurView.bottomAnchor, constant: -7),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeBlurView.leadingAnchor, constant: 14),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeBlurView.trailingAnchor, constant: -14),
        ])

        // ── "Matched X hours ago (92% Match)" ────────────────────────────
        matchedLabel.font      = AppFont.regular(13)
        matchedLabel.textColor = UIColor(white: 0.55, alpha: 1)
        matchedLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(matchedLabel)

        // ── Title ─────────────────────────────────────────────────────────
        // Figma: very bold, ~22pt
        titleLabel.font          = AppFont.bold(22)
        titleLabel.textColor     = .white
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // ── Date + Location — HORIZONTAL row (Figma: side by side) ───────
        let timeIcon = makeIcon("calendar")
        timeLabel.font      = AppFont.regular(14)
        timeLabel.textColor = UIColor(white: 0.75, alpha: 1)

        let locIcon = makeIcon("mappin.and.ellipse")
        locationLabel.font      = AppFont.regular(14)
        locationLabel.textColor = UIColor(white: 0.75, alpha: 1)

        let timeStack = hStack([timeIcon, timeLabel], spacing: 7)
        let locStack  = hStack([locIcon, locationLabel], spacing: 7)

        // Horizontal: [date]  [location] — date left, location right of center
        let dateLocRow = UIStackView(arrangedSubviews: [timeStack, locStack])
        dateLocRow.axis         = .horizontal
        dateLocRow.spacing      = 24
        dateLocRow.alignment    = .center
        dateLocRow.distribution = .fill
        dateLocRow.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLocRow)

        // ── Members row ───────────────────────────────────────────────────
        // Figma: large avatars ~44pt, orange ring, "6 travelers" far right
        membersView.progressTrack.isHidden = true
        membersView.backgroundColor        = .clear
        membersView.translatesAutoresizingMaskIntoConstraints = false
        membersView.setContentHuggingPriority(.required, for: .horizontal)
        membersView.setContentCompressionResistancePriority(.required, for: .horizontal)

        travelersLabel.font          = AppFont.regular(15)
        travelersLabel.textColor     = UIColor(white: 0.85, alpha: 1)
        travelersLabel.textAlignment = .right
        travelersLabel.setContentHuggingPriority(.required, for: .horizontal)
        travelersLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(travelersLabel)

        cardView.addSubview(membersView)

        // ── Buttons ───────────────────────────────────────────────────────
        styleOutlineBtn(startChatBtn, title: "Start Chat")
        styleFilledBtn(saveGroupBtn,  title: "Save Group")
        startChatBtn.addTarget(self, action: #selector(startChatTapped), for: .touchUpInside)
        saveGroupBtn.addTarget(self, action: #selector(saveGroupTapped), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [startChatBtn, saveGroupBtn])
        btnStack.axis         = .horizontal
        btnStack.spacing      = 14
        btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(btnStack)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Card: 16pt side margins, 6pt vertical gaps
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Image: 55% of card height
            imageView_.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageView_.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageView_.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageView_.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.55),

            // Glass badge: 16pt from top-left of image
            badgeBlurView.topAnchor.constraint(equalTo: imageView_.topAnchor, constant: 16),
            badgeBlurView.leadingAnchor.constraint(equalTo: imageView_.leadingAnchor, constant: 16),

            // Matched label: 20pt below image
            matchedLabel.topAnchor.constraint(equalTo: imageView_.bottomAnchor, constant: 20),
            matchedLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            matchedLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            // Title: 4pt below matched
            titleLabel.topAnchor.constraint(equalTo: matchedLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            // Date+Loc row: 20pt below title (Figma has clear gap here)
            dateLocRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            dateLocRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),

            // Members avatars: 22pt below date row, left-pinned
            membersView.topAnchor.constraint(equalTo: dateLocRow.bottomAnchor, constant: 22),
            membersView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            membersView.heightAnchor.constraint(equalToConstant: 44),

            // "N travelers" — vertically centered with members, far right
            travelersLabel.centerYAnchor.constraint(equalTo: membersView.centerYAnchor),
            travelersLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            // Buttons: 20pt below members, 56pt tall, pinned to bottom
            btnStack.topAnchor.constraint(equalTo: membersView.bottomAnchor, constant: 20),
            btnStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            btnStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            btnStack.heightAnchor.constraint(equalToConstant: 56),
            btnStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Configure
    func configure(with model: Group) {
        titleLabel.text     = model.groupTitle ?? ""
        locationLabel.text  = model.destination ?? ""
        travelersLabel.text = "\(model.members?.count ?? 0) travelers"

        let base = "Matched 2 hours ago "
        let hi   = "(92% Match)"
        let full = base + hi
        let attr = NSMutableAttributedString(
            string: full,
            attributes: [.foregroundColor: UIColor(white: 0.55, alpha: 1),
                         .font: AppFont.regular(13)])
        attr.addAttribute(.foregroundColor,
                          value: UIColor.themeOrange,
                          range: (full as NSString).range(of: hi))
        matchedLabel.attributedText = attr

        membersView.configure(
            members: model.members ?? [],
            totalCount: model.maxGroupSize ?? 0,
            completedCount: model.members?.count ?? 0
        )
    }

    func setTimeText(_ text: String) { timeLabel.text   = text  }
    func setImage(_ image: UIImage?) { imageView_.image = image }

    // MARK: - Helpers
    private func makeIcon(_ name: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: name))
        iv.tintColor   = UIColor(white: 0.55, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 16).isActive  = true
        iv.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return iv
    }

    private func hStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal; s.spacing = spacing; s.alignment = .center
        return s
    }

    private func styleOutlineBtn(_ btn: UIButton, title: String) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font   = AppFont.semibold(16)
        btn.layer.cornerRadius = 28        // 56/2 — full pill
        // Figma: Start Chat bg is the same dark card color
        btn.backgroundColor    = UIColor(red: 0.098, green: 0.098, blue: 0.098, alpha: 1)
        btn.setTitleColor(.themeOrange, for: .normal)
        btn.layer.borderWidth  = 1.5
        btn.layer.borderColor  = UIColor.themeOrange.cgColor
    }

    private func styleFilledBtn(_ btn: UIButton, title: String) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font   = AppFont.semibold(16)
        btn.layer.cornerRadius = 28
        // Figma orange: #F26522 / themeOrange
        btn.backgroundColor    = .themeOrange
        btn.setTitleColor(.white, for: .normal)
    }

    @objc private func startChatTapped() { onStartChat?() }
    @objc private func saveGroupTapped() { onSaveGroup?() }
}

//  SavedGroupCell.swift
//  TravelDate

import UIKit

class SavedGroupCell: UITableViewCell {

    static let reuseId = "SavedGroupCell"

    // MARK: - UI
    let cardView      = UIView()
    let heroImage     = UIImageView()
    let badgeLabel    = PaddedLabel()
    let bookmarkBtn   = UIButton(type: .system)
    let gradientLayer = CAGradientLayer()
    let nameLabel     = UILabel()
    let timeLabel     = UILabel()
    let locationLabel = UILabel()
    let viewGroupBtn  = UIButton(type: .system)
    let membersView   = MembersProgressView()
    private let travelersLabel = UILabel()

    var onViewGroup: (() -> Void)?
    var onBookmark:  (() -> Void)?

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = heroImage.bounds
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // ── Card ──────────────────────────────────────────────────────────
        cardView.layer.cornerRadius = 22
        cardView.clipsToBounds      = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // ── Hero fills entire card ────────────────────────────────────────
        heroImage.contentMode  = .scaleAspectFill
        heroImage.clipsToBounds = true
        heroImage.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(heroImage)

        // ── Gradient: starts mid-card, very dark at bottom 45% ───────────
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.20).cgColor,
            UIColor.black.withAlphaComponent(0.82).cgColor
        ]
        gradientLayer.locations = [0.0, 0.50, 1.0]
        heroImage.layer.addSublayer(gradientLayer)

        // ── "New Strategy" badge — top-left ───────────────────────────────
        badgeLabel.text               = "New Strategy"
        badgeLabel.font               = AppFont.medium(13)
        badgeLabel.textColor          = .white
        badgeLabel.backgroundColor    = UIColor(white: 0.18, alpha: 0.70)
        badgeLabel.layer.cornerRadius = 15
        badgeLabel.clipsToBounds      = true
        badgeLabel.textInsets         = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(badgeLabel)

        // ── Bookmark button — top-right: WHITE circle ─────────────────────
        // Screenshot: clearly solid white circle, bookmark icon inside
        bookmarkBtn.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        bookmarkBtn.tintColor          = UIColor(white: 0.45, alpha: 1) // gray icon on white bg
        bookmarkBtn.backgroundColor    = .white
        bookmarkBtn.layer.cornerRadius = 20   // 40pt / 2
        bookmarkBtn.translatesAutoresizingMaskIntoConstraints = false
        bookmarkBtn.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        cardView.addSubview(bookmarkBtn)

        // ── Name label ────────────────────────────────────────────────────
        nameLabel.font          = AppFont.bold(22)
        nameLabel.textColor     = .white
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)

        // ── Date row (vertical stack below name) ──────────────────────────
        let timeIcon = makeIcon("calendar")
        timeLabel.font      = AppFont.regular(14)
        timeLabel.textColor = UIColor(white: 0.88, alpha: 1)
        let timeRow = hStack([timeIcon, timeLabel], spacing: 8)
        timeRow.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(timeRow)

        // ── Location row ──────────────────────────────────────────────────
        let locIcon = makeIcon("mappin.and.ellipse")
        locationLabel.font      = AppFont.regular(14)
        locationLabel.textColor = UIColor(white: 0.88, alpha: 1)
        let locRow = hStack([locIcon, locationLabel], spacing: 8)
        locRow.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locRow)

        // ── Members row: avatars LEFT, "N travelers" FAR RIGHT ───────────
        membersView.progressTrack.isHidden = true
        membersView.backgroundColor        = .clear
        membersView.translatesAutoresizingMaskIntoConstraints = false
        membersView.setContentHuggingPriority(.required, for: .horizontal)
        membersView.setContentCompressionResistancePriority(.required, for: .horizontal)

        travelersLabel.font          = AppFont.regular(14)
        travelersLabel.textColor     = UIColor(white: 0.88, alpha: 1)
        travelersLabel.textAlignment = .right
        travelersLabel.setContentHuggingPriority(.required, for: .horizontal)
        travelersLabel.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let membersRow = UIStackView(arrangedSubviews: [membersView, spacer, travelersLabel])
        membersRow.axis      = .horizontal
        membersRow.alignment = .center
        membersRow.spacing   = 0
        membersRow.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(membersRow)

        // ── "View Group" button ───────────────────────────────────────────
        // Screenshot: NOT full width — has 16pt margins each side, ~54pt tall
        viewGroupBtn.setTitle("View Group", for: .normal)
        viewGroupBtn.titleLabel?.font   = AppFont.semibold(17)
        viewGroupBtn.backgroundColor    = .themeOrange
        viewGroupBtn.setTitleColor(.white, for: .normal)
        viewGroupBtn.layer.cornerRadius = 27   // 54 / 2
        viewGroupBtn.translatesAutoresizingMaskIntoConstraints = false
        viewGroupBtn.addTarget(self, action: #selector(viewGroupTapped), for: .touchUpInside)
        cardView.addSubview(viewGroupBtn)

        // MARK: Constraints
        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Hero = full card
            heroImage.topAnchor.constraint(equalTo: cardView.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            heroImage.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Badge: 14pt from top-left
            badgeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            badgeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),

            // Bookmark: 12pt from top, 14pt from right — 40×40 WHITE circle
            bookmarkBtn.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            bookmarkBtn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            bookmarkBtn.widthAnchor.constraint(equalToConstant: 40),
            bookmarkBtn.heightAnchor.constraint(equalToConstant: 40),

            // View Group: 20pt from bottom, 16pt margins
            viewGroupBtn.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            viewGroupBtn.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            viewGroupBtn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            viewGroupBtn.heightAnchor.constraint(equalToConstant: 54),

            // Members row: 14pt above View Group
            membersRow.bottomAnchor.constraint(equalTo: viewGroupBtn.topAnchor, constant: -14),
            membersRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            membersRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            membersRow.heightAnchor.constraint(equalToConstant: 38),

            // Location: 10pt above members
            locRow.bottomAnchor.constraint(equalTo: membersRow.topAnchor, constant: -10),
            locRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            // Date: 8pt above location
            timeRow.bottomAnchor.constraint(equalTo: locRow.topAnchor, constant: -8),
            timeRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            // Name: 6pt above date
            nameLabel.bottomAnchor.constraint(equalTo: timeRow.topAnchor, constant: -6),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -60),
        ])
    }

    // MARK: - Configure
    func configure(with model: Group) {
        nameLabel.text      = model.groupTitle ?? ""
        locationLabel.text  = model.destination ?? ""
        travelersLabel.text = "\(model.members?.count ?? 0) travelers"
        membersView.configure(
            members: model.members ?? [],
            totalCount: model.maxGroupSize ?? 0,
            completedCount: model.members?.count ?? 0
        )
    }

    func setImage(_ image: UIImage?)  { heroImage.image = image }
    func setTimeText(_ text: String)  { timeLabel.text  = text  }

    // MARK: - Helpers
    private func makeIcon(_ name: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: name))
        iv.tintColor   = UIColor(white: 0.80, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 16).isActive  = true
        iv.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return iv
    }

    private func hStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal; s.spacing = spacing; s.alignment = .center
        return s
    }

    @objc private func viewGroupTapped() { onViewGroup?() }
    @objc private func bookmarkTapped()  { onBookmark?()  }
}

// PaddedLabel.swift — shared utility (keep in one file)
class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(
            width:  s.width  + textInsets.left + textInsets.right,
            height: s.height + textInsets.top  + textInsets.bottom
        )
    }
}
