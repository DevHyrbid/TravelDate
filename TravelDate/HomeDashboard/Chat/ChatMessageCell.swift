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
    private let attachmentView  = UIImageView()   // ← image OR video-thumbnail attachment
    private let timeLabel       = UILabel()
    private let failedLabel     = UILabel()

    // MARK: - Video overlay (NEW — sits on top of attachmentView, only
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

    // attachment height — 0 when no image
    private var attachmentHeight: NSLayoutConstraint!
    private var attachmentWidth: NSLayoutConstraint!

    var onRetryTapped: (() -> Void)?
    var onImageTapped: ((UIImage?) -> Void)?   // ← for full-screen preview
    var onVideoTapped: ((_ remoteURL: String?, _ localURL: URL?) -> Void)?   // ← NEW, for video playback
    var onImageLongPressed: ((UIImage?) -> Void)?
    // Kept from the last configure(with:) call so the single tap gesture on
    // attachmentView knows whether to fire onImageTapped or onVideoTapped.
    private var currentMessageType = 1
    private var currentVideoRemoteURL: String?
    private var currentVideoLocalURL: URL?

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
        attachmentView.contentMode = .scaleAspectFit
        attachmentView.clipsToBounds = true
        attachmentView.backgroundColor = .clear
        attachmentView.layer.cornerRadius = 16
        attachmentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        attachmentView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed(_:)))
        )

        // Video overlay (NEW) — added on top of attachmentView, hidden by
        // default. Nothing about attachmentView's own setup above changed.
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
    
    private func updateImageSize(_ image: UIImage) {
        let maxWidth: CGFloat  = UIScreen.main.bounds.width * 0.68
        let minWidth: CGFloat  = 140
        let minHeight: CGFloat = 120
        let maxHeight: CGFloat = 320

        guard image.size.width > 0, image.size.height > 0 else {
            attachmentWidth.constant  = maxWidth
            attachmentHeight.constant = minHeight
            return
        }

        let aspectRatio = image.size.width / image.size.height // W / H

        var width = maxHeight * aspectRatio
        width = min(width, maxWidth)
        width = max(width, minWidth)

        var height = width / aspectRatio
        height = min(height, maxHeight)
        height = max(height, minHeight)

        attachmentWidth.constant  = width
        attachmentHeight.constant = height
    }

    // MARK: - Setup constraints

    private func setupConstraints() {
        let maxWidth = UIScreen.main.bounds.width * 0.68

        attachmentWidth = attachmentView.widthAnchor.constraint(equalToConstant: maxWidth)
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

            // Video overlay (NEW) — always-active constraints, nothing toggled.
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
        
        let hasImage = item.imageURL != nil || item.localImage != nil
        let hasVideo = item.videoURL != nil || item.localVideoURL != nil   // NEW
        let hasText  = !(item.content ?? "").isEmpty

        messageLabel.isHidden = !hasText
        messageLabel.text     = hasText ? item.content : nil

        // Video overlay defaults to hidden; only the video branch below turns it on.
        playIconView.isHidden  = true
        durationLabel.isHidden = true

        if hasImage {
            attachmentHeight.constant = 220
            attachmentView.isHidden   = false
            attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)   // reset in case this cell last showed a video

            if let local = item.localImage {
                attachmentView.image = local
                updateImageSize(local)
            } else if let str = item.imageURL, let url = URL(string: "\(APiConstant.base)\(str)") {
                
                attachmentView.image = nil
                print(url,"sksksks")
//               /* ImageLoader.setImageKing(attachmentView, urlString: "\(APiConstant.base)*/\(url.absoluteString)")
                attachmentView.kf.setImage(with: url) { [weak self] result in

                    switch result {

                    case .success(let value):
                        self?.updateImageSize(value.image)

                    case .failure:
                        self?.attachmentHeight.constant = 220
                    }
                }
            }
        } else if hasVideo {
            // Same slot/height as an image attachment — just a thumbnail
            // plus a play icon + duration pill on top.
            attachmentHeight.constant = 220
            attachmentView.isHidden   = false
            attachmentView.backgroundColor = .black
            playIconView.isHidden  = false
            durationLabel.isHidden = (item.videoDuration == nil)
            if let seconds = item.videoDuration {
                durationLabel.text = "  " + Self.formattedDuration(seconds) + "  "
            }

            if let localURL = item.localVideoURL {
                if let thumb = item.videoThumbnail {
                    attachmentView.image = thumb
                } else {
                    attachmentView.image = nil
                    ChatVideoThumbnailLoader.loadLocal(localURL, into: attachmentView)
                }
            } else if let remote = item.videoURL {
                attachmentView.image = nil
                ChatVideoThumbnailLoader.loadRemote(remote, into: attachmentView)
            }
        } else {
            attachmentHeight.constant = 0
            attachmentView.isHidden   = true
            attachmentView.image      = nil
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
        print(item.profile_image,"SHSHSHSSHSH")
        if let str = item.senderImage, let url = URL(string: str) {
//            avatarView.image = UIImage(named: "User")
            
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
        // Same gesture recognizer as before — now branches on message type
        // so video bubbles open the player instead of the image preview.
        if currentMessageType == 3 {
            onVideoTapped?(currentVideoRemoteURL, currentVideoLocalURL)
        } else {
            onImageTapped?(attachmentView.image)
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image          = nil
        attachmentView.image      = nil
        attachmentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        messageLabel.text         = nil
        messageLabel.isHidden     = false
        attachmentHeight.constant = 0
        attachmentView.isHidden   = true
        onRetryTapped = nil
        onImageTapped = nil
        onVideoTapped = nil
        // Video overlay reset (NEW)
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
