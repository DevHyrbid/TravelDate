//
//  ChatMessageCell.swift
//  TravelDate
//
//  Production Chat Message Cell.
//
//  Renders one row in the chat: avatar + name (incoming only), a bubble
//  containing an optional attachment (image/video), optional text, and a
//  meta row (time, sent/failed status). Restructured for readability only —
//  no behavior changed from the previous working version.
//

import UIKit
import Kingfisher

final class ChatMessageCell: UITableViewCell {

    static let reuseId = "ChatMessageCell"

    // MARK: - Design constants

    private let outgoingColor = UIColor.appBorder
    private let incomingColor = UIColor(white: 1.0, alpha: 0.075)
    private let incomingBorderColor = UIColor(white: 1.0, alpha: 0.10)
    private let secondaryColor = UIColor(white: 1.0, alpha: 0.52)

    private let bubbleMaxWidthRatio: CGFloat = 0.72
    private let attachmentMaxWidthRatio: CGFloat = 0.68
    private let attachmentMaxHeight: CGFloat = 300
    private let attachmentMinWidth: CGFloat = 180
    private let attachmentMinHeight: CGFloat = 140

    /// messageLabel's leading (14) + trailing (14) insets inside
    /// messageContainer. Shared so setupConstraints/layoutSubviews can
    /// never drift apart when deriving preferredMaxLayoutWidth.
    private static let messageLabelHorizontalInsets: CGFloat = 28

    // MARK: - Subviews

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    private let bubbleView = UIView()
    private let bubbleStack = UIStackView()

    private let attachmentView = UIImageView()

    private let messageContainer = UIView()
    private let messageLabel = UILabel()

    private let metaContainer = UIView()
    private let metaStack = UIStackView()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()
    private let sendingIndicator = UIActivityIndicatorView(style: .medium)
    private let failedLabel = UILabel()

    // Video overlay (drawn on top of attachmentView)
    private let playContainerView = UIView()
    private let playIconView = UIImageView()
    private let durationLabel = UILabel()

    // MARK: - Constraints

    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var bubbleTopConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var attachmentWidthConstraint: NSLayoutConstraint!
    private var attachmentHeightConstraint: NSLayoutConstraint!

    // MARK: - Callbacks

    var onRetryTapped: (() -> Void)?
    var onImageTapped: ((UIImage?) -> Void)?
    var onVideoTapped: ((_ remoteURL: String?, _ localURL: URL?) -> Void)?
    var onImageLongPressed: ((UIImage?) -> Void)?
    var onAttachmentSizeResolved: (() -> Void)?

    // MARK: - State

    private var currentMessageType = 1
    private var currentVideoRemoteURL: String?
    private var currentVideoLocalURL: URL?

    /// Bumped on every configure()/prepareForReuse() so async image/video
    /// callbacks can detect they're stale (cell was reused before they
    /// returned) and bail out instead of applying to the wrong row.
    private var loadToken = 0
    private var availableContentWidth: CGFloat = 0

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View setup

private extension ChatMessageCell {

    func setupViews() {
        setupHierarchy()
        setupAvatarAndName()
        setupBubble()
        setupMessage()
        setupAttachment()
        setupMeta()
        setupVideoOverlay()
        setupDuration()
    }

    func setupHierarchy() {
        [avatarView, nameLabel, bubbleView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(bubbleStack)

        bubbleStack.axis = .vertical
        bubbleStack.alignment = .fill
        bubbleStack.distribution = .fill
        bubbleStack.spacing = 0

        [attachmentView, messageContainer, metaContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        bubbleStack.addArrangedSubview(attachmentView)
        bubbleStack.addArrangedSubview(messageContainer)
        bubbleStack.addArrangedSubview(metaContainer)

        // Start hidden, matching prepareForReuse's steady state. Without
        // this, a brand-new cell's very first configure() (almost always
        // a text-only message) has to flip attachmentView's isHidden
        // false → true. Toggling isHidden on an arranged subview needs an
        // extra UIStackView layout pass to fully drop it from the width
        // negotiation — and that flip landed in the same run-loop turn as
        // UITableView's self-sizing measurement, squeezing messageLabel's
        // share of the width for that one critical pass. Starting hidden
        // means the common case makes no isHidden change at all.
        attachmentView.isHidden = true
    }

    func setupAvatarAndName() {
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 16
        avatarView.backgroundColor = UIColor(white: 1, alpha: 0.08)

        nameLabel.font = UIFont(name: "Poppins-Medium", size: 12.5)
            ?? .systemFont(ofSize: 12.5, weight: .medium)
        nameLabel.textColor = UIColor(white: 1, alpha: 0.72)
    }

    func setupBubble() {
        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds = true
    }

    func setupMessage() {
        messageContainer.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = UIFont(name: "Poppins-Regular", size: 15)
            ?? .systemFont(ofSize: 15, weight: .regular)
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func setupAttachment() {
        attachmentView.contentMode = .scaleAspectFill
        attachmentView.clipsToBounds = true
        attachmentView.layer.cornerRadius = 12
        attachmentView.backgroundColor = UIColor(white: 1, alpha: 0.05)
        attachmentView.isUserInteractionEnabled = true

        attachmentView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        )
        attachmentView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed(_:)))
        )
    }

    func setupMeta() {
        metaContainer.translatesAutoresizingMaskIntoConstraints = false
        metaStack.translatesAutoresizingMaskIntoConstraints = false
        metaContainer.addSubview(metaStack)

        metaStack.axis = .horizontal
        metaStack.alignment = .center
        metaStack.spacing = 5

        metaStack.addArrangedSubview(timeLabel)
        metaStack.addArrangedSubview(statusLabel)
        metaStack.addArrangedSubview(sendingIndicator)
        metaStack.addArrangedSubview(failedLabel)

        // Same isHidden-toggle reasoning as attachmentView: an optimistic
        // ".sending" message on a brand-new cell would otherwise flip
        // statusLabel false → true with no earlier stable state.
        statusLabel.isHidden = true

        timeLabel.font = UIFont(name: "Poppins-Regular", size: 10) ?? .systemFont(ofSize: 10)
        timeLabel.textColor = secondaryColor
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        // Required compression resistance is what stops the timestamp from
        // being squeezed/ellipsized ("5:29…") on short bubbles. messageLabel
        // is both required-hugging and required-compression, so on a short
        // message IT — not metaStack — dictates the bubble's width; without
        // equally strong resistance here, Auto Layout shrinks the timestamp
        // instead of widening the bubble to fit it.
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusLabel.font = UIFont(name: "Poppins-Medium", size: 10)
            ?? .systemFont(ofSize: 10, weight: .medium)
        statusLabel.textColor = secondaryColor
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        sendingIndicator.color = UIColor(white: 1, alpha: 0.65)
        sendingIndicator.hidesWhenStopped = true

        failedLabel.font = UIFont(name: "Poppins-Medium", size: 10)
            ?? .systemFont(ofSize: 10, weight: .medium)
        failedLabel.textColor = .systemRed
        failedLabel.text = "Failed • Tap to retry"
        failedLabel.isHidden = true
        failedLabel.isUserInteractionEnabled = true
        failedLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(retryTapped))
        )
    }

    func setupVideoOverlay() {
        playContainerView.translatesAutoresizingMaskIntoConstraints = false
        playContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        playContainerView.layer.cornerRadius = 22
        playContainerView.isHidden = true
        attachmentView.addSubview(playContainerView)

        playIconView.translatesAutoresizingMaskIntoConstraints = false
        playIconView.image = UIImage(systemName: "play.fill")
        playIconView.tintColor = .white
        playIconView.contentMode = .scaleAspectFit
        playContainerView.addSubview(playIconView)
    }

    func setupDuration() {
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = UIFont(name: "Poppins-Medium", size: 10)
            ?? .systemFont(ofSize: 10, weight: .medium)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .center
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        durationLabel.layer.cornerRadius = 9
        durationLabel.clipsToBounds = true
        durationLabel.isHidden = true
        attachmentView.addSubview(durationLabel)
    }
}

// MARK: - Constraints

private extension ChatMessageCell {

    func setupConstraints() {
        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: 40)
        attachmentWidthConstraint = attachmentView.widthAnchor.constraint(equalToConstant: 1)
        attachmentHeightConstraint = attachmentView.heightAnchor.constraint(equalToConstant: 0)
        bubbleWidthConstraint.isActive = true

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleStack.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -2),
            metaStack.leadingAnchor.constraint(equalTo: metaContainer.leadingAnchor, constant: 14),
            metaStack.trailingAnchor.constraint(equalTo: metaContainer.trailingAnchor, constant: -12),
            metaStack.topAnchor.constraint(equalTo: metaContainer.topAnchor, constant: 2),
            metaStack.bottomAnchor.constraint(equalTo: metaContainer.bottomAnchor, constant: -6),
            attachmentWidthConstraint,
            attachmentHeightConstraint,
            playContainerView.centerXAnchor.constraint(equalTo: attachmentView.centerXAnchor),
            playContainerView.centerYAnchor.constraint(equalTo: attachmentView.centerYAnchor),
            playContainerView.widthAnchor.constraint(equalToConstant: 44),
            playContainerView.heightAnchor.constraint(equalToConstant: 44),
            playIconView.centerXAnchor.constraint(equalTo: playContainerView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: playContainerView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 18),
            playIconView.heightAnchor.constraint(equalToConstant: 18),
            durationLabel.trailingAnchor.constraint(equalTo: attachmentView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: attachmentView.bottomAnchor, constant: -8),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34)
        ])

        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        bubbleTopConstraint = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        bubbleTopConstraint.isActive = true
    }
}

// MARK: - Layout

extension ChatMessageCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard availableContentWidth > 1 else { return }
        let maxBubbleWidth = availableContentWidth * bubbleMaxWidthRatio
        messageLabel.preferredMaxLayoutWidth = max(1, maxBubbleWidth - Self.messageLabelHorizontalInsets)
    }
}

// MARK: - Configure

extension ChatMessageCell {
    func configure(with item: ChatItem, availableWidth: CGFloat) {
        loadToken += 1
        let token = loadToken
        availableContentWidth = max(0, availableWidth)
        currentMessageType = item.messageType
        currentVideoRemoteURL = item.videoURL
        currentVideoLocalURL = item.localVideoURL
        timeLabel.text = ChatDate.bubbleTime(item.createdAt)
        configureDirection(item)
        configureContent(item, token: token)
        configureStatus(item)
        applyDeterministicBubbleWidth()
    }
}

// MARK: - Direction (outgoing / incoming)

private extension ChatMessageCell {

    func configureDirection(_ item: ChatItem) {
        item.isMine ? configureOutgoing() : configureIncoming(item)
    }

    func configureOutgoing() {
        avatarView.isHidden = true
        nameLabel.isHidden = true

        bubbleLeadingConstraint.isActive = false
        bubbleTrailingConstraint.isActive = true
        bubbleTopConstraint.constant = 8

        bubbleView.backgroundColor = outgoingColor
        bubbleView.layer.borderWidth = 0

        timeLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        metaStack.alignment = .center
    }

    func configureIncoming(_ item: ChatItem) {
        avatarView.isHidden = false
        nameLabel.isHidden = false

        bubbleLeadingConstraint.isActive = true
        bubbleTrailingConstraint.isActive = false
        bubbleTopConstraint.constant = 29

        bubbleView.backgroundColor = incomingColor
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = incomingBorderColor.cgColor

        statusLabel.isHidden = true
        sendingIndicator.stopAnimating()

        if let image = item.senderImage,
           !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: image) {
            ChatImageLoader.load(url: url, into: avatarView)
        } else {
            avatarView.image = UIImage(named: "User")
        }

        nameLabel.text = item.senderName
    }
}

// MARK: - Content (text / image / video)

private extension ChatMessageCell {

    func configureContent(_ item: ChatItem, token: Int) {
        let trimmedImageURL = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVideoURL = item.videoURL?.trimmingCharacters(in: .whitespacesAndNewlines)

        let hasImage = !(trimmedImageURL ?? "").isEmpty || item.localImage != nil
        let hasVideo = !(trimmedVideoURL ?? "").isEmpty || item.localVideoURL != nil
        let hasText = !(item.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        messageContainer.isHidden = !hasText
        messageLabel.text = hasText ? item.content : nil

        // No space is reserved for an attachment here. The bubble stays at
        // its text-only size until an image/video actually finishes
        // loading (see applyAttachmentSize) — so a bad or unused
        // imageURL/videoURL never leaves a blank box in the bubble.
        attachmentView.image = nil
        attachmentView.isHidden = true
        attachmentWidthConstraint.isActive = false
        attachmentHeightConstraint.constant = 0
        playContainerView.isHidden = true
        durationLabel.isHidden = true
        durationLabel.text = nil

        if hasImage {
            configureImage(item, token: token)
        } else if hasVideo {
            configureVideo(item, token: token)
        }
    }

    func configureImage(_ item: ChatItem, token: Int) {
        if let image = item.localImage {
            attachmentView.image = image
            applyAttachmentSize(image.size, notify: false)
            return
        }

        guard let path = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty,
              let url = URL(string: "\(APiConstant.base)\(path)")
        else { return }

        attachmentView.kf.setImage(with: url) { [weak self] result in
            guard let self, self.loadToken == token else { return }
            if case .success(let value) = result {
                self.attachmentView.image = value.image
                self.applyAttachmentSize(value.image.size, notify: true)
            }
        }
    }

    func configureVideo(_ item: ChatItem, token: Int) {
        if let duration = item.videoDuration {
            durationLabel.isHidden = false
            durationLabel.text = " \(Self.formattedDuration(duration)) "
        }

        if let thumbnail = item.videoThumbnail {
            attachmentView.image = thumbnail
            applyAttachmentSize(thumbnail.size, notify: false)
            return
        }

        if let localURL = item.localVideoURL {
            ChatVideoThumbnailLoader.loadLocal(localURL) { [weak self] thumbnail in
                guard let self, self.loadToken == token, let thumbnail else { return }
                self.attachmentView.image = thumbnail
                self.applyAttachmentSize(thumbnail.size, notify: true)
            }
            return
        }

        if let remoteURL = item.videoURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !remoteURL.isEmpty {
            ChatVideoThumbnailLoader.loadRemote(remoteURL) { [weak self] thumbnail in
                guard let self, self.loadToken == token, let thumbnail else { return }
                self.attachmentView.image = thumbnail
                self.applyAttachmentSize(thumbnail.size, notify: true)
            }
        }
    }
}

// MARK: - Attachment sizing

private extension ChatMessageCell {

    func applyAttachmentSize(_ originalSize: CGSize, notify: Bool) {
        guard originalSize.width > 0, originalSize.height > 0, availableContentWidth > 1 else { return }

        let maxWidth = availableContentWidth * attachmentMaxWidthRatio
        let maxHeight = attachmentMaxHeight
        let aspectRatio = originalSize.width / originalSize.height

        var width = min(originalSize.width, maxWidth)
        var height = width / aspectRatio

        if height > maxHeight {
            height = maxHeight
            width = height * aspectRatio
        }

        if width < attachmentMinWidth {
            width = min(attachmentMinWidth, maxWidth)
            height = width / aspectRatio
            if height > maxHeight {
                height = maxHeight
                width = height * aspectRatio
            }
        }

        attachmentView.isHidden = false
        playContainerView.isHidden = currentMessageType != 3
        attachmentWidthConstraint.isActive = true
        attachmentWidthConstraint.constant = max(1, width)
        attachmentHeightConstraint.constant = max(1, height)

        applyDeterministicBubbleWidth()

        if notify {
            DispatchQueue.main.async { [weak self] in
                self?.onAttachmentSizeResolved?()
            }
        }
    }

    func applyDeterministicBubbleWidth() {
        guard availableContentWidth > 1 else { return }

        let maxBubbleWidth = availableContentWidth * bubbleMaxWidthRatio
        let horizontalPadding = Self.messageLabelHorizontalInsets
        let maxTextWidth = max(1, maxBubbleWidth - horizontalPadding)
        messageLabel.preferredMaxLayoutWidth = maxTextWidth

        var requiredWidth: CGFloat = 40
        let text = messageLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !text.isEmpty {
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: messageLabel.font as Any],
                context: nil
            )
            requiredWidth = ceil(rect.width) + horizontalPadding
        }

        let metaWidth = metaStack.systemLayoutSizeFitting(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        ).width + 26
        requiredWidth = max(requiredWidth, ceil(metaWidth))

        if attachmentWidthConstraint.isActive {
            requiredWidth = max(requiredWidth, attachmentWidthConstraint.constant)
        }

        bubbleWidthConstraint.constant = min(requiredWidth, maxBubbleWidth)
    }

}

// MARK: - Status (sending / sent / failed)

private extension ChatMessageCell {

    func configureStatus(_ item: ChatItem) {
        failedLabel.isHidden = true
        statusLabel.isHidden = true
        sendingIndicator.stopAnimating()

        guard item.isMine else { return }

        switch item.status {
        case .sending:
            sendingIndicator.startAnimating()
        case .sent:
            statusLabel.isHidden = false
            statusLabel.text = "✓"
        case .failed:
            failedLabel.isHidden = false
        }
    }
}

// MARK: - Actions

private extension ChatMessageCell {

    @objc func retryTapped() {
        onRetryTapped?()
    }

    @objc func imageTapped() {
        if currentMessageType == 3 {
            onVideoTapped?(currentVideoRemoteURL, currentVideoLocalURL)
        } else {
            onImageTapped?(attachmentView.image)
        }
    }

    @objc func imageLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        onImageLongPressed?(attachmentView.image)
    }

    static func formattedDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Reuse

extension ChatMessageCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        loadToken += 1

        avatarView.image = nil
        nameLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
        statusLabel.text = nil
        attachmentView.image = nil

        attachmentHeightConstraint.constant = 0
        attachmentWidthConstraint.isActive = false
        attachmentWidthConstraint.constant = 1
        availableContentWidth = 0
        messageLabel.preferredMaxLayoutWidth = 0
        bubbleWidthConstraint.constant = 40

        avatarView.isHidden = false
        nameLabel.isHidden = false
        messageContainer.isHidden = false
        attachmentView.isHidden = true
        statusLabel.isHidden = true
        failedLabel.isHidden = true
        playContainerView.isHidden = true
        durationLabel.isHidden = true

        sendingIndicator.stopAnimating()

        bubbleView.backgroundColor = .clear
        bubbleView.layer.borderWidth = 0

        bubbleLeadingConstraint.isActive = false
        bubbleTrailingConstraint.isActive = false

        currentMessageType = 1
        currentVideoRemoteURL = nil
        currentVideoLocalURL = nil

        onRetryTapped = nil
        onImageTapped = nil
        onVideoTapped = nil
        onImageLongPressed = nil
        onAttachmentSizeResolved = nil
    }
}
