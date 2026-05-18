// MARK: - ChatBubbleCell.swift
import UIKit

class ChatBubbleCell: UITableViewCell {

    // MARK: Subviews
    private let avatarView   = UIView()
    private let avatarLabel  = UILabel()
    private let senderLabel  = UILabel()
    private let bubbleView   = UIView()
    private let messageLabel = UILabel()
    private let timeLabel    = UILabel()
    private let msgImageView = UIImageView()

    // MARK: Layout constants
    private let avatarSize: CGFloat = 36

    // MARK: Constraints to toggle
    private var outgoingConstraints: [NSLayoutConstraint] = []
    private var incomingConstraints: [NSLayoutConstraint] = []

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Setup
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle  = .none

        // Avatar
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        avatarLabel.textAlignment = .center
        avatarLabel.setFont(.semiBold, size: 15.0)
            //.font          = .systemFont(ofSize: 14, weight: .semibold)
        avatarLabel.textColor     = .white
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)

        // Sender name
        senderLabel.setFont(.semiBold, size: 12.0)
        senderLabel.textColor = .lightGray
        senderLabel.translatesAutoresizingMaskIntoConstraints = false

        // Bubble — NO hugging/compression overrides
        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds      = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        // Message
        messageLabel.numberOfLines = 0
        messageLabel.setFont(.regular, size: 16.0)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Image
        msgImageView.contentMode        = .scaleAspectFill
        msgImageView.clipsToBounds      = true
        msgImageView.layer.cornerRadius = 12
        msgImageView.isHidden           = true
        msgImageView.translatesAutoresizingMaskIntoConstraints = false

        // Time
        timeLabel.setFont(.medium, size: 10.0)
        timeLabel.textColor = UIColor(white: 0.55, alpha: 1)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(senderLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(msgImageView)
        contentView.addSubview(timeLabel)

        // ── Fixed constraints (always active) ──────────────────────
        NSLayoutConstraint.activate([
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),

            // messageLabel inside bubble
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            // msgImageView inside bubble
            msgImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 6),
            msgImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6),
            msgImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 6),
            msgImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -6),
            msgImageView.widthAnchor.constraint(equalToConstant: 200),
            msgImageView.heightAnchor.constraint(equalToConstant: 150),
        ])

        setupIncomingConstraints()
        setupOutgoingConstraints()
    }

    private func setupIncomingConstraints() {
        incomingConstraints = [
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),

            senderLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            senderLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),

            bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            bubbleView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.65),

            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
        ]
    }

    private func setupOutgoingConstraints() {
        outgoingConstraints = [
            avatarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            bubbleView.trailingAnchor.constraint(equalTo: avatarView.leadingAnchor, constant: -8),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 80),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.65),

            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
        ]
    }

    // MARK: Configure
    func configure(msg: MessageModel, currentUserId: String) {
        let isOutgoing = msg.senderId == currentUserId

        NSLayoutConstraint.deactivate(incomingConstraints + outgoingConstraints)
        NSLayoutConstraint.activate(isOutgoing ? outgoingConstraints : incomingConstraints)

        avatarView.isHidden  = isOutgoing
        senderLabel.isHidden = isOutgoing

        if !isOutgoing {
            let name = msg.senderName ?? "?"
            senderLabel.text           = name
            avatarView.backgroundColor = avatarColor(for: name)

            if let imgStr = msg.senderImage, let url = URL(string: imgStr) {
                avatarLabel.isHidden = true
                loadAvatarImage(url: url)
            } else {
                avatarLabel.isHidden = false
                avatarLabel.text     = String(name.prefix(1)).uppercased()
            }
        }

        bubbleView.backgroundColor = isOutgoing
            ? UIColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1)
            : UIColor(white: 0.16, alpha: 1)
        messageLabel.textColor = .white

        let isImage = msg.contentType == "image"
        msgImageView.isHidden = !isImage
        messageLabel.isHidden = isImage

        if isImage, let urlStr = msg.imageUrl, let url = URL(string: urlStr) {
            loadImage(url: url)
        } else {
            messageLabel.text = msg.content
        }

        timeLabel.text = formattedTime(from: msg.createdAt)

        // ── Force layout so constraints apply cleanly ──
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: Image Loaders
    private func loadAvatarImage(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.avatarView.subviews.compactMap { $0 as? UIImageView }.forEach { $0.removeFromSuperview() }
                let iv = UIImageView(frame: self.avatarView.bounds)
                iv.image              = img
                iv.contentMode        = .scaleAspectFill
                iv.clipsToBounds      = true
                iv.layer.cornerRadius = self.avatarSize / 2
                self.avatarView.addSubview(iv)
            }
        }.resume()
    }

    private func loadImage(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.msgImageView.image = img }
        }.resume()
    }

    // MARK: Helpers
    private func avatarColor(for name: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1),
            UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1),
            UIColor(red: 0.91, green: 0.30, blue: 0.24, alpha: 1),
            UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1),
            UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1),
        ]
        return colors[abs(name.hashValue) % colors.count]
    }

    private func formattedTime(from isoString: String?) -> String {
        guard let str = isoString else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: str) else { return str }
        let fmt = DateFormatter()
        fmt.dateFormat = "hh:mm a"
        return fmt.string(from: date)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        msgImageView.image = nil
        messageLabel.text  = nil
        senderLabel.text   = nil
        NSLayoutConstraint.deactivate(incomingConstraints + outgoingConstraints)
    }
}
