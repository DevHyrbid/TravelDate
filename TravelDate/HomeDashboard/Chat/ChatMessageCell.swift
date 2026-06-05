//
//
//  ChatMessageCell.swift
//  TravelDate
//
//  Renders incoming and outgoing bubbles with optional image attachments.
//
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
    private let attachmentView  = UIImageView()   // ← image attachment
    private let timeLabel       = UILabel()
    private let failedLabel     = UILabel()

    // MARK: - Toggled constraints
    private var bubbleLeading: NSLayoutConstraint!
    private var bubbleTrailing: NSLayoutConstraint!
    private var bubbleMinLeading: NSLayoutConstraint!
    private var bubbleMaxTrailing: NSLayoutConstraint!
    private var bubbleTopToName: NSLayoutConstraint!
    private var bubbleTopToTop: NSLayoutConstraint!
    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!

    // attachment height — 0 when no image
    private var attachmentHeight: NSLayoutConstraint!

    var onRetryTapped: (() -> Void)?
    var onImageTapped: ((UIImage?) -> Void)?   // ← for full-screen preview

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

        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true

        // Attachment image
        attachmentView.contentMode = .scaleAspectFill
        attachmentView.clipsToBounds = true
        attachmentView.layer.cornerRadius = 12
        attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        attachmentView.isUserInteractionEnabled = true
        attachmentView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        )

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

    // MARK: - Setup constraints

    private func setupConstraints() {
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
            attachmentHeight,   // toggled to 0 or 220

            // Message — below attachment (gap = 0 when no image)
            messageLabel.topAnchor.constraint(equalTo: attachmentView.bottomAnchor, constant: 0),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            // Time
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Failed
            failedLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            failedLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
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
        timeLabel.text = ChatDate.bubbleTime(item.createdAt)

        configureAttachment(item)

        if item.isMine { configureOutgoing() }
        else           { configureIncoming(item) }

        configureStatus(item)
    }

    // MARK: - Attachment

    private func configureAttachment(_ item: ChatItem) {
        let hasImage = item.imageURL != nil || item.localImage != nil
        let hasText  = (((item.content ?? "")?.isEmpty) == nil)
        
        // Show/hide text
        messageLabel.isHidden = !hasText
        messageLabel.text     = item.content

        // Adjust top padding for message when image is above
        let msgTopPad: CGFloat = hasImage && hasText ? 10 : (hasText ? 10 : 0)
        // Update the constant on the existing constraint (it's the topAnchor to attachmentView.bottomAnchor)
        messageLabel.constraints.forEach { c in
            if c.firstAttribute == .top { c.constant = msgTopPad }
        }
        // Also update bottom padding when text-only vs image-only
        messageLabel.constraints.forEach { c in
            if c.firstAttribute == .bottom { c.constant = hasText ? -10 : 0 }
        }

        if hasImage {
            attachmentHeight.constant = 220
            attachmentView.isHidden   = false

            if let local = item.localImage {
                attachmentView.image = local
            } else if let str = item.imageURL, let url = URL(string: str) {
                attachmentView.image = nil
                ChatImageLoader.load(url: url, into: attachmentView)
            }
        } else {
            attachmentHeight.constant = 0
            attachmentView.isHidden   = true
            attachmentView.image      = nil
        }
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
            avatarView.image = UIImage(named: "User")
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
    @objc private func imageTapped() { onImageTapped?(attachmentView.image) }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image          = nil
        attachmentView.image      = nil
        messageLabel.text         = nil
        messageLabel.isHidden     = false
        attachmentHeight.constant = 0
        attachmentView.isHidden   = true
        onRetryTapped = nil
        onImageTapped = nil
        failedLabel.isHidden = true
        bubbleView.alpha = 1.0
    }
}
