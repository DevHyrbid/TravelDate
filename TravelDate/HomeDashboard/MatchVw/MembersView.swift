import UIKit

// MARK: - Model

// MARK: - MembersProgressView

final class MembersProgressView: UIView {

    // MARK: - Callbacks

    var onAvatarStackTapped: (() -> Void)?
    var onProgressTapped: (() -> Void)?
    var onContainerTapped: (() -> Void)?

    // MARK: - Config

    private let avatarSize: CGFloat = 44
    private let avatarOverlap: CGFloat = 14
    private let maxVisibleAvatars: Int = 4

    // MARK: - Subviews

    private let avatarStackContainer = UIView()
    private var avatarImageViews: [UIImageView] = []
    private let moreLabel = UILabel()

    let progressTrack = UIView()
    let progressFill = UIView()
    let leftLabel = UILabel()
    let progressContainer = UIView()
    private var progressFillWidthConstraint: NSLayoutConstraint?

    // MARK: - State

    private var members: [MemberGroup] = []
    private var totalCount: Int = 0
    private var completedCount: Int = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Public API

    /// Configure the view with members and progress info.
    /// - Parameters:
    ///   - members: Array of MemberModel (can be more than 4; extras shown as "+N more")
    ///   - totalCount: Total slots/tasks
    ///   - completedCount: How many are done (drives progress fill)
    func configure(members: [MemberGroup], totalCount: Int, completedCount: Int) {
        self.members = members
        self.totalCount = max(totalCount, 1)
        self.completedCount = min(completedCount, totalCount)
        refreshAvatars()
        refreshProgress()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
        layer.cornerRadius = 16
        layer.masksToBounds = true

        setupAvatarSection()
        setupProgressSection()
        setupTapGestures()
        setupLayout()
    }

    private func setupAvatarSection() {
        avatarStackContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarStackContainer.isUserInteractionEnabled = true
        addSubview(avatarStackContainer)

        moreLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        moreLabel.textColor = UIColor(white: 0.85, alpha: 1)
        moreLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(moreLabel)
    }

    private func setupProgressSection() {
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.isUserInteractionEnabled = true
        addSubview(progressContainer)

        // Track (gray background)
        progressTrack.backgroundColor = UIColor(white: 1, alpha: 0.12)
        progressTrack.layer.cornerRadius = 5
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(progressTrack)

        // Fill (orange)
        progressFill.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.1, alpha: 1)
        progressFill.layer.cornerRadius = 5
        progressFill.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        // "N left" label
        leftLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        leftLabel.textColor = UIColor(white: 0.85, alpha: 1)
        leftLabel.textAlignment = .right
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(leftLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Avatar stack container — left side
            avatarStackContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarStackContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarStackContainer.heightAnchor.constraint(equalToConstant: avatarSize),

            // "+N more" label — right of avatar stack
            moreLabel.leadingAnchor.constraint(equalTo: avatarStackContainer.trailingAnchor, constant: 12),
            moreLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Progress container — right side
            progressContainer.leadingAnchor.constraint(equalTo: moreLabel.trailingAnchor, constant: 16),
            progressContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressContainer.heightAnchor.constraint(equalToConstant: avatarSize),

            // "N left" label — fixed width, pinned to right of progressContainer
            leftLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            leftLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            leftLabel.widthAnchor.constraint(equalToConstant: 50),

            // Track — leading to container, trailing to left of label
            progressTrack.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: leftLabel.leadingAnchor, constant: -10),
            progressTrack.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressTrack.heightAnchor.constraint(equalToConstant: 10),

            // Fill inside track
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
        ])
    }

    private func setupTapGestures() {
        // Whole container
        let containerTap = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap))
        addGestureRecognizer(containerTap)

        // Avatar stack
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap))
        avatarStackContainer.addGestureRecognizer(avatarTap)

        // Progress
        let progressTap = UITapGestureRecognizer(target: self, action: #selector(handleProgressTap))
        progressContainer.addGestureRecognizer(progressTap)
    }

    // MARK: - Refresh

    private func refreshAvatars() {
        avatarImageViews.forEach { $0.removeFromSuperview() }
        avatarImageViews = []

        let visible = Array(members.prefix(maxVisibleAvatars))
        let extraCount = members.count - visible.count

        var previousAnchor: NSLayoutXAxisAnchor = avatarStackContainer.leadingAnchor
        var totalWidth: CGFloat = 0

        for (i, member) in visible.enumerated() {
            let iv = makeAvatarImageView(image: nil, index: i) // ✅ nil pass karo
            
            // URL se load karo (SDWebImage)
            if let urlStr = member.profileImage, let url = URL(string: urlStr) {
                iv.kf.setImage(with: url, placeholder: UIImage(named: "User"))
            }
            
            avatarStackContainer.addSubview(iv)
            avatarImageViews.append(iv)

            NSLayoutConstraint.activate([
                iv.leadingAnchor.constraint(equalTo: previousAnchor, constant: i == 0 ? 0 : -avatarOverlap),
                iv.centerYAnchor.constraint(equalTo: avatarStackContainer.centerYAnchor),
                iv.widthAnchor.constraint(equalToConstant: avatarSize),
                iv.heightAnchor.constraint(equalToConstant: avatarSize),
            ])

            previousAnchor = iv.trailingAnchor
            totalWidth += (i == 0 ? avatarSize : avatarSize - avatarOverlap)
        }

        avatarStackContainer.constraints
            .filter { $0.firstAttribute == .width }
            .forEach { $0.isActive = false }
        avatarStackContainer.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true

        if extraCount > 0 {
            moreLabel.text = "+\(extraCount) more"
            moreLabel.isHidden = false
        } else {
            moreLabel.text = nil
            moreLabel.isHidden = true
        }
    }

    private func refreshProgress() {
        let ratio = totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0
        let remaining = totalCount - completedCount
        leftLabel.text = "\(remaining) left"

        // Remove old fill width constraint
        progressFillWidthConstraint?.isActive = false

        // Use proportional constraint relative to track width — no manual calculation needed
        progressFillWidthConstraint = progressFill.widthAnchor.constraint(
            equalTo: progressTrack.widthAnchor,
            multiplier: max(0.01, min(ratio, 1.0))
        )
        progressFillWidthConstraint?.isActive = true

        // Round right corners only when fill isn't full
        if ratio >= 0.99 {
            progressFill.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMinXMaxYCorner,
                .layerMaxXMinYCorner, .layerMaxXMaxYCorner
            ]
        } else {
            progressFill.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        }

        // Animate fill
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - Avatar Factory

    private func makeAvatarImageView(image: UIImage?, index: Int) -> UIImageView {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = avatarSize / 2
        iv.layer.borderWidth = 2.5
        iv.layer.borderColor = UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1).cgColor
        iv.backgroundColor = UIColor(white: 0.25, alpha: 1)
        iv.image = image
        iv.layer.zPosition = CGFloat(index)
        return iv
    }

    // MARK: - Tap Handlers

    @objc private func handleContainerTap() {
        animateTap()
        onContainerTapped?()
    }

    @objc private func handleAvatarTap(_ gesture: UITapGestureRecognizer) {
        gesture.view?.mpv_animateTap()
        onAvatarStackTapped?()
    }

    @objc private func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        gesture.view?.mpv_animateTap()
        onProgressTapped?()
    }

    private func animateTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.7
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 72)
    }
}

// MARK: - UIView Tap Animation Helper

private extension UIView {
    func mpv_animateTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
            }
        }
    }
}


// MARK: - Usage Example (ViewController)

/*

class DemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let membersView = MembersProgressView()
        membersView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(membersView)

        NSLayoutConstraint.activate([
            membersView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            membersView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            membersView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            membersView.heightAnchor.constraint(equalToConstant: 72),
        ])

        let members: [MemberModel] = [
            MemberModel(image: UIImage(named: "avatar1")),
            MemberModel(image: UIImage(named: "avatar2")),
            MemberModel(image: UIImage(named: "avatar3")),
            MemberModel(image: UIImage(named: "avatar4")),
            MemberModel(image: UIImage(named: "avatar5")),
            MemberModel(image: UIImage(named: "avatar6")),
        ]

        membersView.configure(members: members, totalCount: 6, completedCount: 4)

        membersView.onAvatarStackTapped = {
            print("Avatar stack tapped — show members list")
        }
        membersView.onProgressTapped = {
            print("Progress bar tapped — show progress details")
        }
        membersView.onContainerTapped = {
            print("Container tapped — open group detail")
        }
    }
}

*/
