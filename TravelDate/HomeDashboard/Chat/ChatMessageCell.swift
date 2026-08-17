import UIKit

final class ChatMessageCell: UITableViewCell {

    static let reuseId = "ChatMessageCell"

    // MARK: - Colors
    private let myBubbleColor    = UIColor.themeOrange
    private let otherBubbleColor = UIColor.white.withAlphaComponent(0.06)

    // MARK: - Views
    private let avatarView      = UIImageView()
    private let nameLabel       = UILabel()
    private let bubbleView      = UIView()
    private let messageLabel    = UILabel()
    private let attachmentView  = UIImageView()   // ← image OR video-thumbnail attachment
    private let timeLabel       = UILabel()
    private let failedLabel     = UILabel()
    private let attachmentSpinner = UIActivityIndicatorView(style: .medium)

    // MARK: - Video overlay (sits on top of attachmentView, only
    // shown when the attachment is a video; image messages never touch these)
    private let playIconView    = UIImageView()
    private let durationLabel   = UILabel()

    // MARK: - Toggled constraints
    private var bubbleLeading: NSLayoutConstraint!
    private var bubbleTrailing: NSLayoutConstraint!
    private var bubbleMinLeading: NSLayoutConstraint!
    private var bubbleMaxTrailing: NSLayoutConstraint!
    private var bubbleTopToName: NSLayoutConstraint!
    private var bubbleTopToTop: NSLayoutConstraint!
    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!

    // attachment height/width — 0 when no image
    private var attachmentHeight: NSLayoutConstraint!
    private var attachmentWidth: NSLayoutConstraint!

    var onRetryTapped: (() -> Void)?
    var onImageTapped: ((UIImage?) -> Void)?
    var onVideoTapped: ((_ remoteURL: String?, _ localURL: URL?) -> Void)?
    var onImageLongPressed: ((UIImage?) -> Void)?

    /// Called whenever the attachment's final size is resolved AFTER an async
    /// load (remote image / remote or local video thumbnail). The table view
    /// should respond to this by recalculating this row's height WITHOUT a
    /// full reloadData — e.g.:
    ///   cell.onAttachmentSizeResolved = { [weak tableView] in
    ///       tableView?.beginUpdates()
    ///       tableView?.endUpdates()
    ///   }
    /// or, if using diffable / async height caching, invalidate just that
    /// index path. Skipping this hookup is why cells looked "stretched"
    /// until the next scroll — the constraint updated but the table view
    /// never knew the row height changed.
    var onAttachmentSizeResolved: (() -> Void)?

    private var currentMessageType = 1
    private var currentVideoRemoteURL: String?
    private var currentVideoLocalURL: URL?

    // Bumped every configure(with:) call. Async load completions capture the
    // token they were started with and bail out if it no longer matches —
    // this is what stops a slow-loading previous cell's image/thumbnail from
    // flashing onto a reused cell that has since scrolled to a new message.
    private var loadToken = 0

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Setup views

    private func setupViews() {
        [avatarView, nameLabel, bubbleView, timeLabel, failedLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        [attachmentView, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            bubbleView.addSubview($0)
        }

        avatarView.layer.cornerRadius = 16
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = .darkGray

        nameLabel.font = UIFont(name: "Poppins-Medium", size: 13) ?? .systemFont(ofSize: 13)
        nameLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        bubbleView.layer.cornerRadius = 10
        bubbleView.clipsToBounds = true

        // Attachment image — aspectFit is safe now because the box we size
        // it to (see attachmentSize(for:)) always matches the image's own
        // aspect ratio, so there's never letterboxing left for the bubble's
        // background color to show through.
        attachmentView.contentMode = .scaleAspectFit
        attachmentView.clipsToBounds = true
        attachmentView.layer.cornerRadius = 10
        attachmentView.layer.borderWidth = 1.2
        attachmentView.layer.borderColor = UIColor(hex: "F76606").cgColor
        attachmentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        attachmentView.isUserInteractionEnabled = true

        // Single tap → image preview or video playback (this was completely
        // missing before, which is why tapping an attachment did nothing).
        attachmentView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        )
        attachmentView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed(_:)))
        )

        // Loading spinner shown while a remote image/thumbnail is fetching,
        // so the user sees "loading" instead of a bare bubble-colored box.
        attachmentSpinner.translatesAutoresizingMaskIntoConstraints = false
        attachmentSpinner.hidesWhenStopped = true
        attachmentSpinner.color = .white
        attachmentView.addSubview(attachmentSpinner)

        // Video overlay — added on top of attachmentView, hidden by default.
        attachmentView.addSubview(playIconView)
        attachmentView.addSubview(durationLabel)
        playIconView.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        playIconView.image = UIImage(systemName: "play.circle.fill")
        playIconView.tintColor = .white
        playIconView.contentMode = .scaleAspectFit
        playIconView.isHidden = true
        playIconView.isUserInteractionEnabled = false // tap is handled by attachmentView's own gesture

        durationLabel.font = UIFont(name: "Poppins-Medium", size: 11) ?? .systemFont(ofSize: 11)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .center
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        durationLabel.layer.cornerRadius = 8
        durationLabel.layer.masksToBounds = true
        durationLabel.isHidden = true

        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont(name: "Poppins-Regular", size: 15) ?? .systemFont(ofSize: 15)

        timeLabel.font = UIFont(name: "Poppins-Regular", size: 11) ?? .systemFont(ofSize: 11)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.5)

        failedLabel.font = UIFont(name: "Poppins-Medium", size: 11) ?? .systemFont(ofSize: 11)
        failedLabel.textColor = .systemRed
        failedLabel.text = "Failed · Tap to retry"
        failedLabel.isUserInteractionEnabled = true
        failedLabel.isHidden = true
        failedLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(retryTapped))
        )
    }

    /// Computes an attachment box that ALWAYS preserves the image's own
    /// aspect ratio. The previous version clamped width to maxWidth and
    /// height to maxHeight independently, which could distort the ratio and
    /// leave gaps around the image (the bubble's orange background showing
    /// through — the "orange border" look in your screenshot).
    private func attachmentSize(for imageSize: CGSize) -> CGSize {
        let maxWidth: CGFloat  = UIScreen.main.bounds.width * 0.68
        let maxHeight: CGFloat = 320
        let minWidth: CGFloat  = 140
        let minHeight: CGFloat = 120

        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: maxWidth, height: minHeight)
        }

        let aspect = imageSize.width / imageSize.height

        // Fit into the max box, preserving aspect ratio.
        var width  = maxWidth
        var height = width / aspect
        if height > maxHeight {
            height = maxHeight
            width  = height * aspect
        }

        // If below minimum, scale UP uniformly (never independently) so the
        // aspect ratio never changes.
        if width < minWidth || height < minHeight {
            let scale = max(minWidth / width, minHeight / height, 1.0)
            width  *= scale
            height *= scale
        }

        return CGSize(width: width, height: height)
    }

    private func applyAttachmentSize(_ size: CGSize, notifyTable: Bool) {
        attachmentWidth.constant  = size.width
        attachmentHeight.constant = size.height
        if notifyTable {
            onAttachmentSizeResolved?()
        }
    }

    // MARK: - Setup constraints

    private func setupConstraints() {
        let maxWidth = UIScreen.main.bounds.width * 0.68

        attachmentWidth  = attachmentView.widthAnchor.constraint(equalToConstant: maxWidth)
        attachmentHeight = attachmentView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Avatar
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),

            // Name
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),

            // Bubble width cap
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),

            // Attachment — top of bubble, full width inside
            attachmentView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            attachmentView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            attachmentView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            attachmentHeight,   // toggled to 0 or the resolved image/video height

            // Message — below attachment (gap = 0 when no image)
            messageLabel.topAnchor.constraint(equalTo: attachmentView.bottomAnchor, constant: 0),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            // Time
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Failed
            failedLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            failedLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),

            // Spinner
            attachmentSpinner.centerXAnchor.constraint(equalTo: attachmentView.centerXAnchor),
            attachmentSpinner.centerYAnchor.constraint(equalTo: attachmentView.centerYAnchor),

            // Video overlay — always-active constraints, nothing toggled.
            // Both views just stay hidden for non-video attachments.
            playIconView.centerXAnchor.constraint(equalTo: attachmentView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: attachmentView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 44),
            playIconView.heightAnchor.constraint(equalToConstant: 44),

            durationLabel.trailingAnchor.constraint(equalTo: attachmentView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: attachmentView.bottomAnchor, constant: -8),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])

        // Toggled (created once)
        bubbleLeading     = bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8)
        bubbleTrailing    = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        bubbleMinLeading  = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
        bubbleMaxTrailing = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
        bubbleTopToName   = bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4)
        bubbleTopToTop    = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
        timeLeading       = timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor)
        timeTrailing      = timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor)
    }

    // MARK: - Configure

    func configure(with item: ChatItem) {
        loadToken += 1
        timeLabel.text = ChatDate.bubbleTime(item.createdAt)

        currentMessageType    = item.messageType
        currentVideoRemoteURL = item.videoURL
        currentVideoLocalURL  = item.localVideoURL

        configureAttachment(item)

        if item.isMine { configureOutgoing() }
        else           { configureIncoming(item) }

        configureStatus(item)
    }

    // MARK: - Attachment

    private func configureAttachment(_ item: ChatItem) {
        let token = loadToken
        let hasImage = item.imageURL != nil || item.localImage != nil
        let hasVideo = item.videoURL != nil || item.localVideoURL != nil
        let hasText  = !(item.content ?? "").isEmpty

        messageLabel.isHidden = !hasText
        messageLabel.text     = hasText ? item.content : nil

        playIconView.isHidden  = true
        durationLabel.isHidden = true
        attachmentSpinner.stopAnimating()

        // Round all four corners when the attachment is the whole bubble
        // (no caption below it); only the top two when text follows it.
        attachmentView.layer.maskedCorners = hasText
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        if hasImage {
            attachmentView.isHidden = false
            attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

            if let local = item.localImage {
                attachmentView.image = local
                applyAttachmentSize(attachmentSize(for: local.size), notifyTable: false)
            } else if let str = item.imageURL, let url = URL(string: "\(APiConstant.base)\(str)") {
                attachmentView.image = nil
                // Placeholder size until the real dimensions come back, so
                // the cell doesn't render at zero height while loading.
                applyAttachmentSize(CGSize(width: UIScreen.main.bounds.width * 0.68, height: 220), notifyTable: false)
                attachmentSpinner.startAnimating()

                attachmentView.kf.setImage(with: url) { [weak self] result in
                    guard let self, self.loadToken == token else { return }
                    self.attachmentSpinner.stopAnimating()
                    switch result {
                    case .success(let value):
                        self.applyAttachmentSize(self.attachmentSize(for: value.image.size), notifyTable: true)
                    case .failure:
                        break // keep placeholder size
                    }
                }
            }
        } else if hasVideo {
            attachmentView.isHidden = false
            attachmentView.backgroundColor = .black
            playIconView.isHidden  = false
            durationLabel.isHidden = (item.videoDuration == nil)
            if let seconds = item.videoDuration {
                durationLabel.text = "  " + Self.formattedDuration(seconds) + "  "
            }
            applyAttachmentSize(CGSize(width: UIScreen.main.bounds.width * 0.68, height: 220), notifyTable: false)

            if let localURL = item.localVideoURL {
                if let thumb = item.videoThumbnail {
                    attachmentView.image = thumb
                    applyAttachmentSize(attachmentSize(for: thumb.size), notifyTable: false)
                } else {
                    attachmentView.image = nil
                    attachmentSpinner.startAnimating()
                    ChatVideoThumbnailLoader.loadLocal(localURL) { [weak self] thumb in
                        guard let self, self.loadToken == token else { return }
                        self.attachmentSpinner.stopAnimating()
                        guard let thumb else { return }
                        self.attachmentView.image = thumb
                        self.applyAttachmentSize(self.attachmentSize(for: thumb.size), notifyTable: true)
                    }
                }
            } else if let remote = item.videoURL {
                attachmentView.image = nil
                attachmentSpinner.startAnimating()
                ChatVideoThumbnailLoader.loadRemote(remote) { [weak self] thumb in
                    guard let self, self.loadToken == token else { return }
                    self.attachmentSpinner.stopAnimating()
                    guard let thumb else { return }
                    self.attachmentView.image = thumb
                    self.applyAttachmentSize(self.attachmentSize(for: thumb.size), notifyTable: true)
                }
            }
        } else {
            applyAttachmentSize(.zero, notifyTable: false)
            attachmentView.isHidden = true
            attachmentView.image    = nil
        }
    }

    @objc private func imageLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        onImageLongPressed?(attachmentView.image)
    }

    private static func formattedDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Direction helpers (unchanged logic)

    private func configureOutgoing() {
        avatarView.isHidden = true
        nameLabel.isHidden  = true

        bubbleView.backgroundColor = myBubbleColor
        messageLabel.textColor     = .white

        bubbleLeading.isActive     = false
        bubbleMaxTrailing.isActive = false
        bubbleTopToName.isActive   = false
        timeLeading.isActive       = false

        bubbleTrailing.isActive   = true
        bubbleMinLeading.isActive = true
        bubbleTopToTop.isActive   = true
        timeTrailing.isActive     = true

        timeLabel.textAlignment = .right
    }

    private func configureIncoming(_ item: ChatItem) {
        avatarView.isHidden = false
        nameLabel.isHidden  = false
        nameLabel.text      = item.senderName

        if let str = item.senderImage, let url = URL(string: str) {
            ChatImageLoader.load(url: url, into: avatarView)
        } else {
            avatarView.image = UIImage(named: "User")
        }

        bubbleView.backgroundColor = otherBubbleColor
        messageLabel.textColor     = .white

        bubbleTrailing.isActive   = false
        bubbleMinLeading.isActive = false
        bubbleTopToTop.isActive   = false
        timeTrailing.isActive     = false

        bubbleLeading.isActive     = true
        bubbleMaxTrailing.isActive = true
        bubbleTopToName.isActive   = true
        timeLeading.isActive       = true

        timeLabel.textAlignment = .left
    }

    private func configureStatus(_ item: ChatItem) {
        switch item.status {
        case .sending:
            bubbleView.alpha     = 0.6
            failedLabel.isHidden = true
        case .sent:
            bubbleView.alpha     = 1.0
            failedLabel.isHidden = true
        case .failed:
            bubbleView.alpha     = 1.0
            failedLabel.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func retryTapped() { onRetryTapped?() }

    @objc private func imageTapped() {
        if currentMessageType == 3 {
            onVideoTapped?(currentVideoRemoteURL, currentVideoLocalURL)
        } else {
            onImageTapped?(attachmentView.image)
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        loadToken += 1 // invalidates any in-flight closures from this cell
        avatarView.image          = nil
        attachmentView.image      = nil
        attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        attachmentSpinner.stopAnimating()
        messageLabel.text         = nil
        messageLabel.isHidden     = false
        attachmentHeight.constant = 0
        attachmentWidth.constant  = UIScreen.main.bounds.width * 0.68
        attachmentView.isHidden   = true
        onRetryTapped = nil
        onImageTapped = nil
        onVideoTapped = nil
        onAttachmentSizeResolved = nil
        playIconView.isHidden     = true
        durationLabel.isHidden    = true
        durationLabel.text        = nil
        currentMessageType        = 1
        currentVideoRemoteURL     = nil
        currentVideoLocalURL      = nil
        failedLabel.isHidden = true
        bubbleView.alpha = 1.0
    }
}
