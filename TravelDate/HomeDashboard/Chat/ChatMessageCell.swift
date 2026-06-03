//
//  ChatMessageCell.swift
//  TravelDate
//
//  One reusable cell that renders BOTH incoming and outgoing bubbles,
//  matching the existing TravelDate chat UI (orange = me, dark = others).
//

import UIKit

final class ChatMessageCell: UITableViewCell {

    static let reuseId = "ChatMessageCell"

    // MARK: - Colors (match your theme)
    private let myBubbleColor    = UIColor.themeOrange
    private let otherBubbleColor = UIColor.white.withAlphaComponent(0.06)

    // MARK: - Views
    private let avatarView   = UIImageView()
    private let nameLabel    = UILabel()
    private let bubbleView   = UIView()
    private let messageLabel = UILabel()
    private let timeLabel    = UILabel()
    private let failedLabel  = UILabel()

    // MARK: - Toggled constraints (created ONCE, activated per-config)
    private var bubbleLeading: NSLayoutConstraint!     // incoming
    private var bubbleTrailing: NSLayoutConstraint!    // outgoing
    private var bubbleMinLeading: NSLayoutConstraint!  // outgoing: don't go full width
    private var bubbleMaxTrailing: NSLayoutConstraint! // incoming: don't go full width
    private var bubbleTopToName: NSLayoutConstraint!   // incoming
    private var bubbleTopToTop: NSLayoutConstraint!    // outgoing
    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!

    var onRetryTapped: (() -> Void)?

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
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        avatarView.layer.cornerRadius = 16
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = .darkGray

        nameLabel.font = UIFont(name: "Poppins-Medium", size: 13) ?? .systemFont(ofSize: 13)
        nameLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true

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

    // MARK: - Setup constraints (once)

    private func setupConstraints() {
        // Always-on
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),

            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            failedLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            failedLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
        ])

        // Toggled (created once, never re-created)
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
        messageLabel.text = item.content
        timeLabel.text    = ChatDate.bubbleTime(item.createdAt)

        if item.isMine { configureOutgoing() }
        else           { configureIncoming(item) }

        configureStatus(item)
    }

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
            bubbleView.alpha = 0.6
            failedLabel.isHidden = true
        case .sent:
            bubbleView.alpha = 1.0
            failedLabel.isHidden = true
        case .failed:
            bubbleView.alpha = 1.0
            failedLabel.isHidden = false
        }
    }

    @objc private func retryTapped() { onRetryTapped?() }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        onRetryTapped = nil
        failedLabel.isHidden = true
        bubbleView.alpha = 1.0
    }
}
