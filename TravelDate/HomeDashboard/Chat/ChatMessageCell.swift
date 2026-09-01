//
//  ChatMessageCell.swift
//  TravelDate
//
//  Production Chat Message Cell
//

import UIKit
import Kingfisher

final class ChatMessageCell: UITableViewCell {

    static let reuseId = "ChatMessageCell"

    // MARK: - Colors

    private let outgoingColor = UIColor.themeOrange

    private let incomingColor = UIColor(
        white: 1.0,
        alpha: 0.075
    )

    private let incomingBorderColor = UIColor(
        white: 1.0,
        alpha: 0.10
    )

    private let secondaryColor = UIColor(
        white: 1.0,
        alpha: 0.52
    )

    // MARK: - Main UI

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

    private let sendingIndicator = UIActivityIndicatorView(
        style: .medium
    )

    private let failedLabel = UILabel()

    // MARK: - Video

    private let playContainerView = UIView()

    private let playIconView = UIImageView()

    private let durationLabel = UILabel()

    // MARK: - Constraints

    private var bubbleLeadingConstraint: NSLayoutConstraint!

    private var bubbleTrailingConstraint: NSLayoutConstraint!

    private var bubbleTopConstraint: NSLayoutConstraint!

    private var attachmentWidthConstraint: NSLayoutConstraint!

    private var attachmentHeightConstraint: NSLayoutConstraint!

    // MARK: - Callbacks

    var onRetryTapped: (() -> Void)?

    var onImageTapped: ((UIImage?) -> Void)?

    var onVideoTapped: (
        (_ remoteURL: String?, _ localURL: URL?) -> Void
    )?

    var onImageLongPressed: ((UIImage?) -> Void)?

    var onAttachmentSizeResolved: (() -> Void)?

    // MARK: - State

    private var currentMessageType = 1

    private var currentVideoRemoteURL: String?

    private var currentVideoLocalURL: URL?

    private var loadToken = 0

    // MARK: - Init

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {

        [
            avatarView,
            nameLabel,
            bubbleView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(bubbleStack)

        bubbleStack.axis = .vertical
        bubbleStack.alignment = .fill
        bubbleStack.distribution = .fill
        bubbleStack.spacing = 0

        [
            attachmentView,
            messageContainer,
            metaContainer
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        bubbleStack.addArrangedSubview(attachmentView)
        bubbleStack.addArrangedSubview(messageContainer)
        bubbleStack.addArrangedSubview(metaContainer)

        // MARK: Avatar

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 16

        avatarView.backgroundColor = UIColor(
            white: 1,
            alpha: 0.08
        )

        // MARK: Name

        nameLabel.font =
            UIFont(
                name: "Poppins-Medium",
                size: 12.5
            )
            ?? .systemFont(
                ofSize: 12.5,
                weight: .medium
            )

        nameLabel.textColor = UIColor(
            white: 1,
            alpha: 0.72
        )

        // MARK: Bubble

        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds = true

        // MARK: Message

        messageContainer.addSubview(messageLabel)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font =
            UIFont(
                name: "Poppins-Regular",
                size: 15
            )
            ?? .systemFont(
                ofSize: 15,
                weight: .regular
            )

        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        // MARK: Attachment

        attachmentView.contentMode = .scaleAspectFill
        attachmentView.clipsToBounds = true
        attachmentView.layer.cornerRadius = 15

        attachmentView.backgroundColor = UIColor(
            white: 1,
            alpha: 0.05
        )

        attachmentView.isUserInteractionEnabled = true

        attachmentView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped)
            )
        )

        attachmentView.addGestureRecognizer(
            UILongPressGestureRecognizer(
                target: self,
                action: #selector(imageLongPressed(_:))
            )
        )

        // MARK: Meta

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

        timeLabel.font =
            UIFont(
                name: "Poppins-Regular",
                size: 10
            )
            ?? .systemFont(
                ofSize: 10
            )

        timeLabel.textColor = secondaryColor

        timeLabel.setContentHuggingPriority(
            .required,
            for: .horizontal
        )

        statusLabel.font =
            UIFont(
                name: "Poppins-Medium",
                size: 10
            )
            ?? .systemFont(
                ofSize: 10,
                weight: .medium
            )

        statusLabel.textColor = secondaryColor

        statusLabel.setContentHuggingPriority(
            .required,
            for: .horizontal
        )

        sendingIndicator.color = UIColor(
            white: 1,
            alpha: 0.65
        )

        sendingIndicator.hidesWhenStopped = true

        failedLabel.font =
            UIFont(
                name: "Poppins-Medium",
                size: 10
            )
            ?? .systemFont(
                ofSize: 10,
                weight: .medium
            )

        failedLabel.textColor = .systemRed

        failedLabel.text = "Failed • Tap to retry"

        failedLabel.isHidden = true

        failedLabel.isUserInteractionEnabled = true

        failedLabel.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(retryTapped)
            )
        )

        // MARK: Video

        playContainerView.translatesAutoresizingMaskIntoConstraints = false

        playContainerView.backgroundColor =
            UIColor.black.withAlphaComponent(0.45)

        playContainerView.layer.cornerRadius = 27
        playContainerView.isHidden = true

        attachmentView.addSubview(playContainerView)

        playIconView.translatesAutoresizingMaskIntoConstraints = false

        playIconView.image = UIImage(
            systemName: "play.fill"
        )

        playIconView.tintColor = .white
        playIconView.contentMode = .scaleAspectFit

        playContainerView.addSubview(playIconView)

        // MARK: Duration

        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        durationLabel.font =
            UIFont(
                name: "Poppins-Medium",
                size: 10
            )
            ?? .systemFont(
                ofSize: 10,
                weight: .medium
            )

        durationLabel.textColor = .white
        durationLabel.textAlignment = .center

        durationLabel.backgroundColor =
            UIColor.black.withAlphaComponent(0.55)

        durationLabel.layer.cornerRadius = 9
        durationLabel.clipsToBounds = true
        durationLabel.isHidden = true

        attachmentView.addSubview(durationLabel)
    }

    // MARK: - Constraints

    private func setupConstraints() {

        let maxBubbleWidth =
            UIScreen.main.bounds.width * 0.72

        attachmentWidthConstraint =
            attachmentView.widthAnchor.constraint(
                equalToConstant: maxBubbleWidth
            )

        attachmentHeightConstraint =
            attachmentView.heightAnchor.constraint(
                equalToConstant: 0
            )

        NSLayoutConstraint.activate([

            // Avatar

            avatarView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),

            avatarView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),

            avatarView.widthAnchor.constraint(
                equalToConstant: 32
            ),

            avatarView.heightAnchor.constraint(
                equalToConstant: 32
            ),

            // Name

            nameLabel.leadingAnchor.constraint(
                equalTo: avatarView.trailingAnchor,
                constant: 8
            ),

            nameLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 7
            ),

            nameLabel.heightAnchor.constraint(
                equalToConstant: 18
            ),

            // Bubble

            bubbleView.widthAnchor.constraint(
                lessThanOrEqualToConstant: maxBubbleWidth
            ),

            bubbleView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -6
            ),

            // Bubble stack

            bubbleStack.topAnchor.constraint(
                equalTo: bubbleView.topAnchor
            ),

            bubbleStack.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor
            ),

            bubbleStack.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor
            ),

            bubbleStack.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor
            ),

            // Message

            messageLabel.topAnchor.constraint(
                equalTo: messageContainer.topAnchor,
                constant: 8
            ),

            messageLabel.leadingAnchor.constraint(
                equalTo: messageContainer.leadingAnchor,
                constant: 14
            ),

            messageLabel.trailingAnchor.constraint(
                equalTo: messageContainer.trailingAnchor,
                constant: -14
            ),

            messageLabel.bottomAnchor.constraint(
                equalTo: messageContainer.bottomAnchor,
                constant: -2
            ),

            // Meta

            metaStack.leadingAnchor.constraint(
                equalTo: metaContainer.leadingAnchor,
                constant: 14
            ),

            metaStack.trailingAnchor.constraint(
                equalTo: metaContainer.trailingAnchor,
                constant: -12
            ),

            metaStack.topAnchor.constraint(
                equalTo: metaContainer.topAnchor,
                constant: 2
            ),

            metaStack.bottomAnchor.constraint(
                equalTo: metaContainer.bottomAnchor,
                constant: -6
            ),

            // Attachment

            attachmentWidthConstraint,
            attachmentHeightConstraint,

            // Video

            playContainerView.centerXAnchor.constraint(
                equalTo: attachmentView.centerXAnchor
            ),

            playContainerView.centerYAnchor.constraint(
                equalTo: attachmentView.centerYAnchor
            ),

            playContainerView.widthAnchor.constraint(
                equalToConstant: 54
            ),

            playContainerView.heightAnchor.constraint(
                equalToConstant: 54
            ),

            playIconView.centerXAnchor.constraint(
                equalTo: playContainerView.centerXAnchor
            ),

            playIconView.centerYAnchor.constraint(
                equalTo: playContainerView.centerYAnchor
            ),

            playIconView.widthAnchor.constraint(
                equalToConstant: 20
            ),

            playIconView.heightAnchor.constraint(
                equalToConstant: 20
            ),

            // Duration

            durationLabel.trailingAnchor.constraint(
                equalTo: attachmentView.trailingAnchor,
                constant: -8
            ),

            durationLabel.bottomAnchor.constraint(
                equalTo: attachmentView.bottomAnchor,
                constant: -8
            ),

            durationLabel.heightAnchor.constraint(
                equalToConstant: 18
            ),

            durationLabel.widthAnchor.constraint(
                greaterThanOrEqualToConstant: 34
            )
        ])

        bubbleLeadingConstraint =
            bubbleView.leadingAnchor.constraint(
                equalTo: avatarView.trailingAnchor,
                constant: 8
            )

        bubbleTrailingConstraint =
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            )

        bubbleTopConstraint =
            bubbleView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            )

        bubbleTopConstraint.isActive = true
    }

    // MARK: - Configure

    func configure(with item: ChatItem) {
        print("========== CHAT ITEM ==========")
           print("content:", item.content as Any)
           print("messageType:", item.messageType)
           print("imageURL:", item.imageURL as Any)
           print("videoURL:", item.videoURL as Any)
           print("senderName:", item.senderName as Any)
           print("senderImage:", item.senderImage as Any)
           print("createdAt:", item.createdAt)
           print("isMine:", item.isMine)
           print("===============================")

        loadToken += 1

        let token = loadToken

        currentMessageType = item.messageType

        currentVideoRemoteURL = item.videoURL
        currentVideoLocalURL = item.localVideoURL

        timeLabel.text =
            ChatDate.bubbleTime(item.createdAt)

        configureDirection(item)

        configureContent(
            item,
            token: token
        )

        configureStatus(item)
    }

    // MARK: - Direction

    private func configureDirection(
        _ item: ChatItem
    ) {

        if item.isMine {
            configureOutgoing()
        } else {
            configureIncoming(item)
        }
    }

    // MARK: - Outgoing

    private func configureOutgoing() {

        avatarView.isHidden = true
        nameLabel.isHidden = true

        bubbleLeadingConstraint.isActive = false
        bubbleTrailingConstraint.isActive = true

        bubbleTopConstraint.constant = 8

        bubbleView.backgroundColor =
            outgoingColor

        bubbleView.layer.borderWidth = 0

        timeLabel.textColor =
            UIColor.white.withAlphaComponent(0.62)

        statusLabel.textColor =
            UIColor.white.withAlphaComponent(0.72)

        metaStack.alignment = .center
    }

    // MARK: - Incoming

    private func configureIncoming(
        _ item: ChatItem
    ) {

        avatarView.isHidden = false
        nameLabel.isHidden = false

        bubbleLeadingConstraint.isActive = true
        bubbleTrailingConstraint.isActive = false

        bubbleTopConstraint.constant = 29

        bubbleView.backgroundColor =
            incomingColor

        bubbleView.layer.borderWidth = 1

        bubbleView.layer.borderColor =
            incomingBorderColor.cgColor

        statusLabel.isHidden = true

        sendingIndicator.stopAnimating()

        if
            let image = item.senderImage,
            let url = URL(string: image)
        {
            ChatImageLoader.load(
                url: url,
                into: avatarView
            )
        } else {
            avatarView.image =
                UIImage(named: "User")
        }

        nameLabel.text = item.senderName
    }

    // MARK: - Content

    private func configureContent(
        _ item: ChatItem,
        token: Int
    ) {

        let hasImage =
            item.imageURL != nil ||
            item.localImage != nil

        let hasVideo =
            item.videoURL != nil ||
            item.localVideoURL != nil

        let hasText =
            !(item.content ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty

        messageContainer.isHidden = !hasText

        messageLabel.text =
            hasText ? item.content : nil

        

        attachmentView.image = nil

        

        attachmentView.isHidden = true
        attachmentWidthConstraint.isActive = false
        attachmentHeightConstraint.constant = 0

        playContainerView.isHidden = true

        durationLabel.isHidden = true

        durationLabel.text = nil

        if hasImage {
            attachmentWidthConstraint.isActive = true
            configureImage(
                item,
                token: token
            )

        } else if hasVideo {
            attachmentWidthConstraint.isActive = true
            configureVideo(
                item,
                token: token
            )
        }
    }

    // MARK: - Image

    private func configureImage(
        _ item: ChatItem,
        token: Int
    ) {

        attachmentView.isHidden = false

        if let image = item.localImage {

            attachmentView.image = image

            applyAttachmentSize(
                image.size,
                notify: false
            )

            return
        }

        guard
            let path = item.imageURL,
            let url = URL(
                string: "\(APiConstant.base)\(path)"
            )
        else {
            return
        }

        attachmentHeightConstraint.constant = 220

        attachmentView.kf.setImage(
            with: url
        ) { [weak self] result in

            guard let self else {
                return
            }

            guard self.loadToken == token else {
                return
            }

            if case .success(let value) = result {

                self.attachmentView.image =
                    value.image

                self.applyAttachmentSize(
                    value.image.size,
                    notify: true
                )
            }
        }
    }

    // MARK: - Video

    private func configureVideo(
        _ item: ChatItem,
        token: Int
    ) {

        attachmentView.isHidden = false

        playContainerView.isHidden = false

        attachmentHeightConstraint.constant = 220

        if let duration = item.videoDuration {

            durationLabel.isHidden = false

            durationLabel.text =
                " \(Self.formattedDuration(duration)) "
        }

        if let thumbnail = item.videoThumbnail {

            attachmentView.image = thumbnail

            applyAttachmentSize(
                thumbnail.size,
                notify: false
            )

            return
        }

        if let localURL = item.localVideoURL {

            ChatVideoThumbnailLoader.loadLocal(
                localURL
            ) { [weak self] thumbnail in

                guard let self else {
                    return
                }

                guard self.loadToken == token else {
                    return
                }

                guard let thumbnail else {
                    return
                }

                self.attachmentView.image =
                    thumbnail

                self.applyAttachmentSize(
                    thumbnail.size,
                    notify: true
                )
            }

            return
        }

        if let remoteURL = item.videoURL {

            ChatVideoThumbnailLoader.loadRemote(
                remoteURL
            ) { [weak self] thumbnail in

                guard let self else {
                    return
                }

                guard self.loadToken == token else {
                    return
                }

                guard let thumbnail else {
                    return
                }

                self.attachmentView.image =
                    thumbnail

                self.applyAttachmentSize(
                    thumbnail.size,
                    notify: true
                )
            }
        }
    }

    // MARK: - Attachment Size

    private func applyAttachmentSize(
        _ originalSize: CGSize,
        notify: Bool
    ) {

        guard
            originalSize.width > 0,
            originalSize.height > 0
        else {
            return
        }

        let maxWidth =
            UIScreen.main.bounds.width * 0.72

        let maxHeight: CGFloat = 300

        let aspect =
            originalSize.width /
            originalSize.height

        var width = maxWidth

        var height = width / aspect

        if height > maxHeight {

            height = maxHeight
            width = height * aspect
        }

        attachmentWidthConstraint.constant = width
        attachmentHeightConstraint.constant = height

        if notify {

            DispatchQueue.main.async { [weak self] in
                self?.onAttachmentSizeResolved?()
            }
        }
    }

    // MARK: - Status

    private func configureStatus(
        _ item: ChatItem
    ) {

        failedLabel.isHidden = true

        statusLabel.isHidden = true

        sendingIndicator.stopAnimating()

        guard item.isMine else {
            return
        }

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

    // MARK: - Actions

    @objc
    private func retryTapped() {
        onRetryTapped?()
    }

    @objc
    private func imageTapped() {

        if currentMessageType == 3 {

            onVideoTapped?(
                currentVideoRemoteURL,
                currentVideoLocalURL
            )

        } else {

            onImageTapped?(
                attachmentView.image
            )
        }
    }

    @objc
    private func imageLongPressed(
        _ gesture: UILongPressGestureRecognizer
    ) {

        guard gesture.state == .began else {
            return
        }

        onImageLongPressed?(
            attachmentView.image
        )
    }

    // MARK: - Duration

    private static func formattedDuration(
        _ seconds: Int
    ) -> String {

        String(
            format: "%d:%02d",
            seconds / 60,
            seconds % 60
        )
    }

    // MARK: - Reuse

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

        attachmentWidthConstraint.constant =
            UIScreen.main.bounds.width * 0.72

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
