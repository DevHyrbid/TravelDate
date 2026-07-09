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

import UIKit
import SDWebImage

// MARK: - MatchCardView (Front + Flip to Members Grid)
final class MatchCardView: UIView {

    // MARK: - Public
    var isFlipped: Bool = false
    var flipButtonFrame: CGRect { flipButton.convert(flipButton.bounds, to: self) }

    var group: Group? { didSet { configure(with: group) } }

    // MARK: - Face containers
    private let frontView = UIView()
    private let backView  = UIView()
    private let coverImageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv
    }()
    private let bottomGradientView = UIView()
    private let topStripsContainer = UIView()
    private var topGlassStrips: [UIVisualEffectView] = []
    
    private let badgeBlurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        v.clipsToBounds = true; v.layer.cornerRadius = 21; return v
    }()
   
    private let badgeIconLabel: UILabel = { let l = UILabel(); l.text = "🏖"; l.font = AppFont.regular(15.0); return l }()
    
    private let badgeTextLabel: UILabel = {
        let l = UILabel(); l.text = "Leisure travelers"; l.textColor = .white
        l.font = AppFont.medium(16.0); return l
    }()

    // Flip button
    private let flipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "rectangle.on.rectangle"), for: .normal)
        b.tintColor = .white; b.clipsToBounds = true; b.layer.cornerRadius = 23
        b.isUserInteractionEnabled = true
        return b
    }()
   
    private let flipButtonBlur: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.layer.cornerRadius = 23
        blur.clipsToBounds = true
        blur.isUserInteractionEnabled = true
        return blur
    }()

    // Category icon
    private let categoryIconBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        v.clipsToBounds = true; v.layer.cornerRadius = 20; return v
    }()
    private let categoryIconLabel: UILabel = {
        let l = UILabel(); l.text = "🏖"; l.font = AppFont.regular(14.0); l.textAlignment = .center; return l
    }()

    // Title + pills
    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "Tokyo Adventure Squad"; l.textColor = .white
        l.font = AppFont.bold(28.0); l.numberOfLines = 2; return l
    }()
    private let pill1 = GlassPill(), pill2 = GlassPill(), pill3 = GlassPill(), pill4 = GlassPill()
    private let pillRow1 = UIStackView(), pillRow2 = UIStackView()


    // Stamps
    private let likeStampLabel = MatchCardView.makeStamp("LIKE", color: .systemGreen)
    private let nopeStampLabel = MatchCardView.makeStamp("NOPE", color: .systemRed)

    private let backGradientView = UIView()
    private var memberCells: [MemberCell] = []

    // MARK: - Init
    override init(frame: CGRect) { super.init(frame: frame); buildUI() }
    required init?(coder: NSCoder) { super.init(coder: coder); buildUI() }
    static func make() -> MatchCardView { MatchCardView(frame: .zero) }

    // MARK: - Build UI
    private func buildUI() {
        layer.cornerRadius = 36
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 0, blue: 0.4, alpha: 0.20).cgColor

        // ── FRONT ──
        frontView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(frontView)

        frontView.addSubview(coverImageView)
        frontView.addSubview(bottomGradientView)
        frontView.addSubview(topStripsContainer)
        buildTopStrips()

        frontView.addSubview(badgeBlurView)
        badgeBlurView.contentView.addSubview(badgeIconLabel)
        badgeBlurView.contentView.addSubview(badgeTextLabel)
        addGlassBorder(to: badgeBlurView)

        frontView.addSubview(flipButtonBlur)
        flipButtonBlur.contentView.addSubview(flipButton)
        addGlassBorder(to: flipButtonBlur)
        flipButton.addTarget(self, action: #selector(flipTapped), for: .touchUpInside)
        // Defensive: guarantee the flip button always sits on top of every other
        // front-face subview, no matter what gets added/reordered later.
        frontView.bringSubviewToFront(flipButtonBlur)

        frontView.addSubview(categoryIconBlur)
        categoryIconBlur.contentView.addSubview(categoryIconLabel)
        addGlassBorder(to: categoryIconBlur)

        frontView.addSubview(titleLabel)

        pillRow1.axis = .horizontal; pillRow1.spacing = 10; pillRow1.alignment = .center
        pillRow1.addArrangedSubview(pill1); pillRow1.addArrangedSubview(pill2)
        pillRow2.axis = .horizontal; pillRow2.spacing = 10; pillRow2.alignment = .center
        pillRow2.addArrangedSubview(pill3); pillRow2.addArrangedSubview(pill4)
        frontView.addSubview(pillRow1); frontView.addSubview(pillRow2)

       

        frontView.addSubview(likeStampLabel); frontView.addSubview(nopeStampLabel)
        likeStampLabel.alpha = 0; nopeStampLabel.alpha = 0
        // Stamps are decorative-only; make sure they never eat touches meant for
        // the flip button or anything else, even though UILabel defaults to
        // isUserInteractionEnabled = false already — explicit is safer here.
        likeStampLabel.isUserInteractionEnabled = false
        nopeStampLabel.isUserInteractionEnabled = false

        pill1.setText("Apr 15 - Apr 25, 2026"); pill2.setText("Avg age: 25 - 30")
        pill3.setText("4 travelers"); pill4.setText("Bali, Japan")

        // ── BACK ──
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backView.alpha = 0
        // Start pre-flipped (hidden behind front)
        backView.layer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 1, 0)
        addSubview(backView)

        backView.addSubview(backGradientView)
        backGradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        for _ in 0..<4 {
            let cell = MemberCell()
            backView.addSubview(cell)
            memberCells.append(cell)
        }
    }

    private func buildTopStrips() {
        for _ in 0..<3 {
            let s = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            s.layer.cornerRadius = 6; s.clipsToBounds = true; s.alpha = 0.18
            topStripsContainer.addSubview(s); topGlassStrips.append(s)
        }
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width, H = bounds.height

        frontView.frame = bounds
        backView.frame  = bounds

        // Cover
        coverImageView.frame = frontView.bounds

        // Bottom gradient
        let gradH = H * 0.52
        bottomGradientView.frame = CGRect(x: 0, y: H - gradH, width: W, height: gradH)
        applyBottomGradient()

        // Top strips
        topStripsContainer.frame = CGRect(x: 0, y: 0, width: W, height: H * 0.18)
        layoutTopStrips()

        // Badge
        let bW: CGFloat = 158, bH: CGFloat = 42
        badgeBlurView.frame = CGRect(x: 16, y: 20, width: bW, height: bH)
        badgeIconLabel.frame = CGRect(x: 10, y: (bH-22)/2, width: 22, height: 22)
        badgeTextLabel.frame = CGRect(x: 38, y: 0, width: bW-48, height: bH)

        // Flip btn
        let btnSz: CGFloat = 46
        flipButtonBlur.frame = CGRect(x: W - btnSz - 16, y: 20, width: btnSz, height: btnSz)
        flipButton.frame = flipButtonBlur.contentView.bounds
        flipButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
        // Re-assert on every layout pass too — cheap, and immune to any future
        // subview insertion order changes.
        frontView.bringSubviewToFront(flipButtonBlur)

        // Pills (bottom up)
        let pH: CGFloat = 36
        let pRow2Y = H - 28 - pH
        pillRow2.frame = CGRect(x: 16, y: pRow2Y, width: W * 0.65, height: pH)
        let pRow1Y = pRow2Y - 10 - pH
        pillRow1.frame = CGRect(x: 16, y: pRow1Y, width: W - 32, height: pH)

        // Title
        let tH: CGFloat = 68
        let tY = pRow1Y - 8 - tH
        titleLabel.frame = CGRect(x: 16, y: tY, width: W - 32, height: tH)

        // Category icon
        let cSz: CGFloat = 40
        categoryIconBlur.frame = CGRect(x: 16, y: tY - 10 - cSz, width: cSz, height: cSz)
        categoryIconLabel.frame = CGRect(x: 0, y: 0, width: cSz, height: cSz)

        // Member pill
       

        // Stamps
        likeStampLabel.frame = CGRect(x: 20, y: 80, width: 120, height: 44)
        likeStampLabel.transform = CGAffineTransform(rotationAngle: -0.35)
        nopeStampLabel.frame = CGRect(x: W - 140, y: 80, width: 120, height: 44)
        nopeStampLabel.transform = CGAffineTransform(rotationAngle: 0.35)



        // ── BACK layout ──
        backGradientView.frame = backView.bounds
        applyBackGradient()
        layoutMemberGrid()
    }

    private func layoutTopStrips() {
        let W = topStripsContainer.bounds.width
        let widths: [CGFloat] = [W*0.92, W*0.76, W*0.60]
        for (i, strip) in topGlassStrips.enumerated() {
            strip.frame = CGRect(x: 8, y: CGFloat(i)*38 + 10, width: widths[i], height: 28)
        }
    }

    private func layoutMemberGrid() {
        let W = backView.bounds.width, H = backView.bounds.height
        let gap: CGFloat = 12, pad: CGFloat = 16
        let cW = (W - pad*2 - gap) / 2
        let cH = (H - pad*2 - gap) / 2
        let origins: [CGPoint] = [
            CGPoint(x: pad,       y: pad),
            CGPoint(x: pad+cW+gap,y: pad),
            CGPoint(x: pad,       y: pad+cH+gap),
            CGPoint(x: pad+cW+gap,y: pad+cH+gap)
        ]
        for (i, cell) in memberCells.enumerated() {
            cell.frame = CGRect(origin: origins[i], size: CGSize(width: cW, height: cH))
            cell.layer.cornerRadius = 20
        }
    }

    // MARK: - Gradients
    private func applyBottomGradient() {
        bottomGradientView.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        let g = CAGradientLayer()
        g.frame = bottomGradientView.bounds
        g.colors = [UIColor.clear.cgColor,
                    UIColor(red:1, green:0.35, blue:0, alpha:0.55).cgColor,
                    UIColor(red:1, green:0.20, blue:0, alpha:0.82).cgColor]
        g.locations = [0, 0.45, 1.0]
        g.startPoint = CGPoint(x: 0.5, y: 0); g.endPoint = CGPoint(x: 0.5, y: 1)
        bottomGradientView.layer.insertSublayer(g, at: 0)
    }

    private func applyBackGradient() {
        backGradientView.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        let g = CAGradientLayer()
        g.frame = backGradientView.bounds
        // Orange-red → deep pink (matches screenshot)
        g.colors = [UIColor(red:1.0, green:0.42, blue:0.0, alpha:1).cgColor,
                    UIColor(red:1.0, green:0.18, blue:0.2, alpha:1).cgColor,
                    UIColor(red:0.85,green:0.05, blue:0.3, alpha:1).cgColor]
        g.locations = [0, 0.5, 1.0]
        g.startPoint = CGPoint(x: 0.5, y: 0); g.endPoint = CGPoint(x: 0.5, y: 1)
        backGradientView.layer.insertSublayer(g, at: 0)
    }

    // MARK: - Configure
    private func configure(with group: Group?) {
        guard let group else { return }
        titleLabel.text = group.title ?? "Travel Group"
        
        ImageLoader.setImageKing(coverImageView, urlString: APiConstant.base + "\(group.coverImage ?? "")")
        let style = group.travelStyle?.first ?? "beach"
        categoryIconLabel.text = iconEmoji(for: style)
        badgeIconLabel.text    = iconEmoji(for: style)
        badgeTextLabel.text    = badgeText(for: style)

        pill1.setText(formatDateRange(from: group.startDate, to: group.endDate))
        pill2.setText("Avg age:25 - 30")
        pill3.setText("\(group.members?.count ?? 0) travelers")
        pill4.setText(group.destination ?? "Bali, Japan")

      
        // Back face: fill member cells
        let members = group.membersUser ?? []
        for (i, cell) in memberCells.enumerated() {
            if i < members.count { cell.configure(with: members[i]); cell.isHidden = false }
            else { cell.isHidden = true }
        }
    }

    // MARK: - Flip
    @objc private func flipTapped() {
        isFlipped.toggle()
        let fromView = isFlipped ? frontView : backView
        let toView   = isFlipped ? backView  : frontView

        var p = CATransform3DIdentity; p.m34 = -1.0 / 800

        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                fromView.layer.transform = CATransform3DConcat(p, CATransform3DMakeRotation(.pi/2, 0, 1, 0))
                fromView.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                toView.layer.transform = CATransform3DConcat(p, CATransform3DMakeRotation(0, 0, 1, 0))
                toView.alpha = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            fromView.layer.transform = CATransform3DConcat(p, CATransform3DMakeRotation(-.pi/2, 0, 1, 0))
        }
    }

    // MARK: - Stamps
    func showLikeStamp(_ show: Bool, intensity: CGFloat) {
        guard !isFlipped else { return }
        likeStampLabel.alpha = show ? min(intensity * 2, 1) : 0; nopeStampLabel.alpha = 0
    }
    func showNopeStamp(_ show: Bool, intensity: CGFloat) {
        guard !isFlipped else { return }
        nopeStampLabel.alpha = show ? min(intensity * 2, 1) : 0; likeStampLabel.alpha = 0
    }
    func hideStamps() { likeStampLabel.alpha = 0; nopeStampLabel.alpha = 0 }

    // MARK: - Helpers
    private func addGlassBorder(to view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
    }

    static func makeGradientAvatar(letter: String) -> UIView {
        let v = UIView(); v.clipsToBounds = true
        let g = CAGradientLayer()
        g.colors = [UIColor.systemPink.cgColor, UIColor.purple.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0); g.endPoint = CGPoint(x: 1, y: 1)
        v.layer.addSublayer(g)
        let l = UILabel(); l.text = letter; l.textColor = .white
        l.font = AppFont.bold(12); l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(l)
        NSLayoutConstraint.activate([l.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                                     l.centerYAnchor.constraint(equalTo: v.centerYAnchor)])
        return v
    }

  

    private static func makeStamp(_ text: String, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = text; l.textColor = color
        l.font = AppFont.semibold(27.0)
        l.layer.borderColor = color.cgColor; l.layer.borderWidth = 3
        l.layer.cornerRadius = 6; l.textAlignment = .center; return l
    }

    private func iconEmoji(for style: String) -> String {
        switch style.lowercased() {
        case "beach", "leisure": return "🏖"
        case "adventure": return "🧗"
        case "city", "urban": return "🏙"
        default: return "✈️"
        }
    }
    private func badgeText(for style: String) -> String {
        switch style.lowercased() {
        case "beach", "leisure": return "Leisure travelers"
        case "adventure": return "Adventure seekers"
        default: return "Travel enthusiasts"
        }
    }
   
    private func formatDateRange(from start: String?, to end: String?) -> String {
        guard let start = start,
              let end = end else {
            return ""
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startDate = isoFormatter.date(from: start),
              let endDate = isoFormatter.date(from: end) else {
            return ""
        }

        let calendar = Calendar.current

        let monthDayFormatter = DateFormatter()
        monthDayFormatter.dateFormat = "MMM d"

        let monthDayYearFormatter = DateFormatter()
        monthDayYearFormatter.dateFormat = "MMM d, yyyy"

        if calendar.component(.year, from: startDate) == calendar.component(.year, from: endDate) {
            let year = calendar.component(.year, from: endDate)
            return "\(monthDayFormatter.string(from: startDate)) - \(monthDayFormatter.string(from: endDate)), \(year)"
        } else {
            return "\(monthDayYearFormatter.string(from: startDate)) - \(monthDayYearFormatter.string(from: endDate))"
        }
    }
}

// MARK: - GlassPill
final class GlassPill: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let label: UILabel = {
        let l = UILabel(); l.textColor = .white
        l.font = AppFont.semibold(13.0); l.textAlignment = .center; return l
    }()
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    private func setup() {
        backgroundColor = UIColor(white: 1, alpha: 0.08); clipsToBounds = true
        layer.cornerRadius = 18; layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        addSubview(blur); blur.contentView.addSubview(label)
    }
    func setText(_ text: String) { label.text = text; invalidateIntrinsicContentSize() }
    override var intrinsicContentSize: CGSize { CGSize(width: label.intrinsicContentSize.width + 28, height: 36) }
    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds; blur.layer.cornerRadius = layer.cornerRadius
        label.frame = bounds.insetBy(dx: 12, dy: 0)
    }
}

// MARK: - MemberCell
final class MemberCell: UIView {

    private let imageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true; iv.backgroundColor = UIColor(white: 0.2, alpha: 1); return iv
    }()
    private let scrimView  = UIView()
    private let nameLabel: UILabel = {
        let l = UILabel(); l.textColor = .white
        l.font = AppFont.semibold(13.0); l.numberOfLines = 1; return l
    }()
    // Pink-purple gradient avatar badge
    private let avatarBadge: UIView = MatchCardView.makeGradientAvatar(letter: "D")
    // Small emoji icon circle
    private let iconCircle: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        v.layer.cornerRadius = 12; v.clipsToBounds = true; return v
    }()
    private let iconLabel: UILabel = {
        let l = UILabel(); l.font = AppFont.regular(13.0); l.textAlignment = .center; return l
    }()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        clipsToBounds = true; layer.cornerRadius = 20
        addSubview(imageView); addSubview(scrimView)
        addSubview(nameLabel); addSubview(avatarBadge)
        addSubview(iconCircle); iconCircle.addSubview(iconLabel)
    }

    func configure(with member: UserMembers) {

        
        ImageLoader.setImageKing(imageView, urlString: APiConstant.base + "\(member.profile_image ?? "")")
        nameLabel.text = member.name ?? "Traveler"
        let letter = String((member.name ?? "D").prefix(1)).uppercased()
        avatarBadge.subviews.compactMap { $0 as? UILabel }.first?.text = letter
        iconLabel.text = styleEmoji(for: member.travelStyles?.first ?? "")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width, H = bounds.height
        imageView.frame = bounds

        // Dark scrim bottom half
        let sH = H * 0.50
        scrimView.frame = CGRect(x: 0, y: H - sH, width: W, height: sH)
        applyScrim()

        // Name label
        let nH: CGFloat = 18
        nameLabel.frame = CGRect(x: 10, y: H - 44, width: W - 20, height: nH)

        // Avatar badge (pink circle, D letter)
        let avSz: CGFloat = 24
        avatarBadge.frame = CGRect(x: 10, y: H - avSz - 10, width: avSz, height: avSz)
        avatarBadge.layer.cornerRadius = avSz / 2
        if let g = avatarBadge.layer.sublayers?.first as? CAGradientLayer { g.frame = avatarBadge.bounds }

        // Icon circle next to avatar
        let icSz: CGFloat = 24
        iconCircle.frame = CGRect(x: 10 + avSz + 6, y: H - icSz - 10, width: icSz, height: icSz)
        iconLabel.frame  = iconCircle.bounds
    }

    private func applyScrim() {
        scrimView.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        let g = CAGradientLayer(); g.frame = scrimView.bounds
        g.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.72).cgColor]
        g.startPoint = CGPoint(x: 0.5, y: 0); g.endPoint = CGPoint(x: 0.5, y: 1)
        scrimView.layer.addSublayer(g)
    }

    private func styleEmoji(for style: String) -> String {
        switch style.lowercased() {
        case "beach": return "🏖"
        case "adventure": return "🧗"
        case "hiking": return "🥾"
        case "city": return "🏙"
        default: return "✈️"
        }
    }
}
