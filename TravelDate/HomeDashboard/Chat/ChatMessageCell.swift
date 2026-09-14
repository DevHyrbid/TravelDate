//
//  ChatMessageCell.swift
//  TravelDate
//
//  Renders one row in the chat: avatar + name (incoming only), a bubble
//  containing an optional attachment (image/video), optional text, and a
//  meta row (time, sent/failed status).
//
//  ==================================================================
//  ROOT CAUSE OF THE LAYOUT BUG (see the attached master prompt)
//  ==================================================================
//  The old flow was:
//    1. attachmentView starts hidden, width constraint inactive.
//    2. UITableView measures the row at its (attachment-less) height.
//    3. Image/thumbnail loads asynchronously.
//    4. attachmentView becomes visible, width/height constraints change.
//    5. tableView.reloadRows(...) forces a re-measure.
//  Row height was fundamentally a function of "did the async load finish
//  yet", which is exactly what produces jumping/overlapping rows,
//  especially under fast scrolling or pagination.
//
//  ==================================================================
//  THE FIX
//  ==================================================================
//  The attachment container is now sized SYNCHRONOUSLY inside
//  configure(with:), before any network/thumbnail call is even made:
//
//    1. If we already have the real pixel size (a locally-picked image,
//       or a synchronously-generated local video thumbnail), use it.
//    2. Else, if we've seen this same media URL before this session
//       (aspectRatioCache, keyed by the message's stable imageURL /
//       videoURL — not by index path, which isn't stable across
//       pagination/reload), reuse that remembered aspect ratio.
//    3. Else, fall back to a fixed 16:9 box. This is a guess, but it's
//       a STABLE, deterministic guess — the row height never depends on
//       whether the network has responded.
//
//  The real image/thumbnail is then loaded asynchronously exactly like
//  before, and just painted into the already-correctly-sized container.
//  Only in the one case where we had to guess (step 3) AND the real
//  aspect ratio turns out meaningfully different do we correct the row
//  — and we cache the real ratio at that point so it never has to guess
//  again for that same media.
//
//  Everything else (avatar/name, bubble direction, status, actions,
//  reuse safety via loadToken) is unchanged in spirit — hardened where
//  the audit found a concrete bug (force-unwrap, URL resolution).
//

import UIKit
import Kingfisher

final class ChatMessageCell: UITableViewCell {

    static let reuseId = "ChatMessageCell"
    private var bubbleWidthConstraint: NSLayoutConstraint!
    // MARK: - Design constants

    private let outgoingColor = UIColor.appBorder
    private let incomingColor = UIColor(white: 1.0, alpha: 0.075)
    private let incomingBorderColor = UIColor(white: 1.0, alpha: 0.10)
    private let secondaryColor = UIColor(white: 1.0, alpha: 0.52)

    private let bubbleMaxWidthRatio: CGFloat = 0.72
    // Bumped from 0.62 per the redesign spec (~65-72% of chat width reads
    // more like a modern messaging app; 0.62 made media look cramped).
    private let attachmentMaxWidthRatio: CGFloat = 0.68
    // Bumped from 240 → within the spec's suggested 280-320pt range.
    private let attachmentMaxHeight: CGFloat = 300
    private let attachmentMinWidth: CGFloat = 180
    private let attachmentMinHeight: CGFloat = 140
    
    

    /// Stable box used the FIRST time we ever see a given media URL, so
    /// the row can be measured before the network responds. 16:9 reads
    /// as a natural "photo/video is loading" shape rather than a square.
    private let fallbackAspectRatio: CGFloat = 16.0 / 9.0

    /// Remembers the real aspect ratio (width / height) of media we've
    /// already loaded once this session, keyed by a stable identifier
    /// (see attachmentKey). Shared across all cells so scrolling a
    /// message back into view never re-guesses its size. Deliberately
    /// simple — an in-memory NSCache, not a persisted store or a
    /// separate service; the media itself is what's cached elsewhere
    /// (Kingfisher / ChatVideoThumbnailLoader), this just remembers the
    /// *shape* so row height is instant on re-appearance.
    private static let aspectRatioCache = NSCache<NSString, NSNumber>()

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
    
    private var attachmentWidthConstraint: NSLayoutConstraint!
    private var attachmentHeightConstraint: NSLayoutConstraint!

    /// The authoritative width every width-dependent calculation in this
    /// cell (bubble max width, text wrap width, attachment max width) is
    /// derived from. FIXED (real bug — see configure(with:availableWidth:)):
    /// this used to be re-derived from `contentView.bounds.width` inside
    /// `layoutSubviews`, which is NOT reliably the real table width during
    /// UITableView's automaticDimension self-sizing probe in this
    /// environment — it was measured too small, and because a multi-line
    /// UILabel's intrinsic (wrap) size depends entirely on
    /// preferredMaxLayoutWidth (there's no frame yet to measure against),
    /// that one bad value cascaded into narrow, many-line-wrapped bubbles
    /// that then stayed narrow every subsequent pass too. Now the VC hands
    /// us the tableView's own width directly at configure() time — a value
    /// that's unambiguous and correct — and that's what drives layout from
    /// the very first pass. layoutSubviews still refines it using
    /// contentView.bounds.width for rotation, but only once that's
    /// actually a sane, non-trivial value.
    private var availableContentWidth: CGFloat = UIScreen.main.bounds.width

    // MARK: - Callbacks

    var onRetryTapped: (() -> Void)?
    var onImageTapped: ((UIImage?) -> Void)?
    var onVideoTapped: ((_ remoteURL: String?, _ localURL: URL?) -> Void)?
    var onImageLongPressed: ((UIImage?) -> Void)?
    /// Only fires on the rare "we guessed 16:9 and were meaningfully
    /// wrong" correction path — NOT on every successful media load.
    var onAttachmentSizeResolved: (() -> Void)?

    // MARK: - State

    private var currentMessageType = 1
    private var currentVideoRemoteURL: String?
    private var currentVideoLocalURL: URL?

    /// Bumped on every configure()/prepareForReuse() so async image/video
    /// callbacks can detect they're stale (cell was reused before they
    /// returned) and bail out instead of applying to the wrong row.
    private var loadToken = 0

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

        // Start hidden, matching prepareForReuse's steady state. Text-only
        // messages (the common case) never need to touch this at all.
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

        statusLabel.isHidden = true

        timeLabel.font = UIFont(name: "Poppins-Regular", size: 10) ?? .systemFont(ofSize: 10)
        timeLabel.textColor = secondaryColor
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
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
        
        // Initial values only — layoutSubviews() keeps these authoritative
        // afterwards using contentView.bounds.width.
        let screenWidth = UIScreen.main.bounds.width
        let maxBubbleWidth = screenWidth * bubbleMaxWidthRatio
        let maxAttachmentWidth = screenWidth * attachmentMaxWidthRatio

        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(
            equalToConstant: 100
        )
        bubbleWidthConstraint.isActive = true
        messageLabel.preferredMaxLayoutWidth = maxBubbleWidth - Self.messageLabelHorizontalInsets

        attachmentWidthConstraint = attachmentView.widthAnchor.constraint(
            equalToConstant: maxAttachmentWidth
        )
        attachmentHeightConstraint = attachmentView.heightAnchor.constraint(equalToConstant: 0)

        // FIXED (real layout bug, not just console noise): these were at
        // .required (1000) priority. UITableView's self-sizing pass
        // temporarily applies its own 'UIView-Encapsulated-Layout-Height'
        // constraint to contentView at the ESTIMATED (smaller) row height
        // while still solving the rest of the required constraint chain
        // below it — two required constraints can't both hold, so Auto
        // Layout has to break one. Sometimes it broke OURS instead of
        // UIKit's temporary one, which meant the row's measured height
        // came out wrong (67/88/176 instead of the real image height) —
        // that's the squished/undersized attachment the screenshots show.
        // Dropping one notch below required means OUR constraint is the
        // one that predictably (and harmlessly) flexes during that one
        // transient measurement pass, while every other pass — including
        // the one whose result actually gets used — still sizes the
        // attachment exactly as computed.
        attachmentWidthConstraint.priority = UILayoutPriority(999)
        attachmentHeightConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            // Avatar
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),

            // Bubble
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Bubble stack
            bubbleStack.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            // Message
            messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -2),

            // Meta
            metaStack.leadingAnchor.constraint(equalTo: metaContainer.leadingAnchor, constant: 14),
            metaStack.trailingAnchor.constraint(equalTo: metaContainer.trailingAnchor, constant: -12),
            metaStack.topAnchor.constraint(equalTo: metaContainer.topAnchor, constant: 2),
            metaStack.bottomAnchor.constraint(equalTo: metaContainer.bottomAnchor, constant: -6),

            // Attachment
            attachmentWidthConstraint,
            attachmentHeightConstraint,

            // Video overlay
            playContainerView.centerXAnchor.constraint(equalTo: attachmentView.centerXAnchor),
            playContainerView.centerYAnchor.constraint(equalTo: attachmentView.centerYAnchor),
            playContainerView.widthAnchor.constraint(equalToConstant: 44),
            playContainerView.heightAnchor.constraint(equalToConstant: 44),
            playIconView.centerXAnchor.constraint(equalTo: playContainerView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: playContainerView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 18),
            playIconView.heightAnchor.constraint(equalToConstant: 18),

            // Duration badge
            durationLabel.trailingAnchor.constraint(equalTo: attachmentView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: attachmentView.bottomAnchor, constant: -8),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),
        ])

        // Direction-dependent (outgoing vs incoming) — toggled per configure.
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(
            equalTo: avatarView.trailingAnchor, constant: 8
        )
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor, constant: -16
        )
        bubbleTopConstraint = bubbleView.topAnchor.constraint(
            equalTo: contentView.topAnchor, constant: 8
        )
        bubbleTopConstraint.isActive = true
    }
}

// MARK: - Layout

extension ChatMessageCell {

    override func layoutSubviews() {
        super.layoutSubviews()

        // Secondary refinement only (e.g. rotation / size class change
        // after the cell is already on screen) — configure(with:
        // availableWidth:) is what makes the FIRST pass correct, so this
        // no longer carries the whole burden. Only trust
        // contentView.bounds.width when it's a real, laid-out value;
        // otherwise keep whatever configure() already gave us.
        let availableWidth = contentView.bounds.width
        guard availableWidth > 1 else { return }
        guard abs(availableWidth - availableContentWidth) > 0.5 else { return }

        availableContentWidth = availableWidth
        applyWidthDependentLayout()
    }

    /// Single source of truth for every width-dependent constraint in this
    /// cell, driven by `availableContentWidth` — never read ad hoc from
    /// contentView.bounds or UIScreen elsewhere. Called from configure()
    /// (with a known-correct width from the table) and from layoutSubviews
    /// (for later refinement, e.g. rotation).
    func applyWidthDependentLayout() {
        guard availableContentWidth > 1 else { return }

        let maxBubbleWidth =
            availableContentWidth * bubbleMaxWidthRatio

        let horizontalPadding =
            Self.messageLabelHorizontalInsets

        let maxTextWidth =
            maxBubbleWidth - horizontalPadding

        messageLabel.preferredMaxLayoutWidth = maxTextWidth

        let text = messageLabel.text ?? ""

        guard !text.isEmpty else {
            bubbleWidthConstraint.constant = 40
            return
        }

        let textSize = messageLabel.sizeThatFits(
            CGSize(
                width: maxTextWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        let textBubbleWidth =
            textSize.width + horizontalPadding

        // Make sure the metadata row also has enough room.
        let metaWidth =
            metaStack.systemLayoutSizeFitting(
                CGSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: 30
                ),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .required
            ).width + 26

        let finalWidth = max(
            textBubbleWidth,
            metaWidth,
            40
        )

        bubbleWidthConstraint.constant =
            min(finalWidth, maxBubbleWidth)
    }
}

// MARK: - Configure

extension ChatMessageCell {

    /// `availableWidth` should be the tableView's own bounds.width — the
    /// VC passes it in directly (see ChatMessageVc.cellForRowAt). This is
    /// what fixed the narrow/character-wrapped bubble bug: text-wrap width
    /// used to come from `contentView.bounds.width` read inside
    /// `layoutSubviews`, which is not a reliable source of the real table
    /// width during UITableView's self-sizing probe — a too-small value
    /// there cascaded into a permanently too-narrow, many-line-wrapped
    /// bubble (see the long comment on `availableContentWidth` above).
    /// Taking the width as an explicit parameter removes that ambiguity
    /// for good: the very first layout pass is already correct.
    func configure(with item: ChatItem, availableWidth: CGFloat) {
        loadToken += 1
        let token = loadToken

        if availableWidth > 1 {
            availableContentWidth = availableWidth
        }

        currentMessageType = item.messageType
        currentVideoRemoteURL = item.videoURL
        currentVideoLocalURL = item.localVideoURL

        timeLabel.text = ChatDate.bubbleTime(item.createdAt)

        configureDirection(item)

        // IMPORTANT:
        // This sets messageLabel.text
        configureContent(item, token: token)

        configureStatus(item)

        // IMPORTANT:
        // Text now exists, so calculate the real bubble width.
        applyWidthDependentLayout()
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

        if let image = item.senderImage, !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ChatImageLoader.load(rawURLString: image, into: avatarView)
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
        // Belt-and-suspenders: UILabel can cache its intrinsic content
        // size across reuse. Setting .text normally invalidates it, but
        // explicitly forcing it here removes any doubt that a reused
        // cell could ever wrap against a stale cached size instead of
        // the preferredMaxLayoutWidth set moments ago in configure().
        messageLabel.invalidateIntrinsicContentSize()

        // Reset to the "no attachment" steady state; hasImage/hasVideo
        // below immediately re-establish a deterministic size — the
        // container is never left in limbo waiting on a network call.
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
        let key = attachmentKey(for: item)

        if let image = item.localImage {
            // Exact size known synchronously (local pick) — no guessing.
            let ratio = safeAspectRatio(image.size)
            Self.aspectRatioCache.setObject(NSNumber(value: Double(ratio)), forKey: key)
            showAttachment(size: computeAttachmentSize(for: ratio))
            attachmentView.image = image
            return
        }

        let initialRatio = cachedAspectRatio(for: key) ?? fallbackAspectRatio
        showAttachment(size: computeAttachmentSize(for: initialRatio))

        guard let url = ChatMediaURL.resolved(item.imageURL) else { return }

        attachmentView.kf.setImage(with: url) { [weak self] result in
            guard let self, self.loadToken == token else { return }
            guard case .success(let value) = result else { return }

            self.attachmentView.image = value.image
            self.reconcileSize(
                for: value.image.size,
                key: key,
                hadCachedRatio: self.cachedAspectRatio(for: key) != nil
            )
        }
    }

    func configureVideo(_ item: ChatItem, token: Int) {
        let key = attachmentKey(for: item)

        if let duration = item.videoDuration {
            durationLabel.isHidden = false
            durationLabel.text = " \(Self.formattedDuration(duration)) "
        }

        if let thumbnail = item.videoThumbnail {
            let ratio = safeAspectRatio(thumbnail.size)
            Self.aspectRatioCache.setObject(NSNumber(value: Double(ratio)), forKey: key)
            showAttachment(size: computeAttachmentSize(for: ratio))
            attachmentView.image = thumbnail
            return
        }

        let initialRatio = cachedAspectRatio(for: key) ?? fallbackAspectRatio
        showAttachment(size: computeAttachmentSize(for: initialRatio))

        let hadCachedRatio = cachedAspectRatio(for: key) != nil

        if let localURL = item.localVideoURL {
            ChatVideoThumbnailLoader.loadLocal(localURL) { [weak self] thumbnail in
                guard let self, self.loadToken == token, let thumbnail else { return }
                self.attachmentView.image = thumbnail
                self.reconcileSize(for: thumbnail.size, key: key, hadCachedRatio: hadCachedRatio)
            }
            return
        }

        if let remoteURL = item.videoURL?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteURL.isEmpty {
            ChatVideoThumbnailLoader.loadRemote(remoteURL) { [weak self] thumbnail in
                guard let self, self.loadToken == token, let thumbnail else { return }
                self.attachmentView.image = thumbnail
                self.reconcileSize(for: thumbnail.size, key: key, hadCachedRatio: hadCachedRatio)
            }
        }
    }
}

// MARK: - Attachment sizing

private extension ChatMessageCell {

    /// Stable identity for a piece of media — used both as the
    /// aspect-ratio cache key and to keep async callbacks honest. Prefers
    /// the media URL (stable across app launches/scroll) and only falls
    /// back to the item id for a not-yet-uploaded local item.
    func attachmentKey(for item: ChatItem) -> NSString {
        if let imageURL = item.imageURL, !imageURL.isEmpty { return "img:\(imageURL)" as NSString }
        if let videoURL = item.videoURL, !videoURL.isEmpty { return "vid:\(videoURL)" as NSString }
        return "item:\(item.id)" as NSString
    }

    func cachedAspectRatio(for key: NSString) -> CGFloat? {
        Self.aspectRatioCache.object(forKey: key).map { CGFloat($0.doubleValue) }
    }

    func safeAspectRatio(_ size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return fallbackAspectRatio }
        return size.width / size.height
    }

    /// Called once the real media dimensions are known. If we already had
    /// a cached/known ratio, the box was already correct — nothing to do.
    /// If we had guessed (fallback), and the real box differs meaningfully,
    /// apply the correction and let the caller know a row re-measure is
    /// needed. Either way, the real ratio is cached so this media never
    /// has to guess again.
    func reconcileSize(for realSize: CGSize, key: NSString, hadCachedRatio: Bool) {
        let realRatio = safeAspectRatio(realSize)
        Self.aspectRatioCache.setObject(NSNumber(value: Double(realRatio)), forKey: key)

        guard !hadCachedRatio else { return }

        let newSize = computeAttachmentSize(for: realRatio)
        let heightDelta = abs(newSize.height - attachmentHeightConstraint.constant)
        guard heightDelta > 4 else { return }

        applyAttachmentConstraints(newSize)
        onAttachmentSizeResolved?()
    }

    func showAttachment(size: CGSize) {
        attachmentView.isHidden = false
        if currentMessageType == 3 {
            playContainerView.isHidden = false
        }
        applyAttachmentConstraints(size)
    }

    func applyAttachmentConstraints(_ size: CGSize) {
        attachmentWidthConstraint.isActive = true
        attachmentWidthConstraint.constant = size.width
        attachmentHeightConstraint.constant = size.height
    }

    /// Pure sizing math — preserves aspect ratio, clamped to the
    /// min/max box. Width is derived from `availableContentWidth` — the
    /// same single authoritative width everything else in this cell uses
    /// (see its declaration) — never read fresh from contentView.bounds
    /// or UIScreen here, for the same reason preferredMaxLayoutWidth no
    /// longer does either.
    func computeAttachmentSize(for aspectRatio: CGFloat) -> CGSize {
        let ratio = aspectRatio > 0 ? aspectRatio : fallbackAspectRatio
        let maxWidth = availableContentWidth * attachmentMaxWidthRatio
        let maxHeight = attachmentMaxHeight

        var width: CGFloat
        var height: CGFloat

        if ratio > 1.25 {
            // Landscape
            width = maxWidth
            height = width / ratio
            if height > maxHeight {
                height = maxHeight
                width = height * ratio
            }

        } else if ratio < 0.80 {
            // Portrait — never let a tall screenshot/photo shrink to
            // nothing, and never let it balloon into a giant vertical bubble.
            height = maxHeight
            width = height * ratio

            if width < attachmentMinWidth {
                width = attachmentMinWidth
                height = width / ratio
            }
            if height > maxHeight {
                height = maxHeight
                width = height * ratio
            }
            if width > maxWidth {
                width = maxWidth
                height = width / ratio
            }

        } else {
            // Square / near-square
            width = min(maxWidth, maxHeight)
            height = width
        }

        // Final safety clamp.
        width = max(attachmentMinWidth, min(width, maxWidth))
        height = min(height, maxHeight)
        if width >= maxWidth {
            height = min(height, width / ratio)
        }
        height = max(attachmentMinHeight, height)

        return CGSize(width: width, height: height)
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
        // Long press should only offer to save an actual image — never a
        // video thumbnail (that's not the real saveable asset).
        guard currentMessageType != 3 else { return }
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
        // Uses whatever availableContentWidth currently holds (set by the
        // last configure() call) rather than re-deriving from
        // contentView.bounds — same reasoning as everywhere else in this
        // file now. It'll be overwritten by the next configure() anyway;
        // this is just a sane transient value between reuse and reconfigure.
        attachmentWidthConstraint.constant = availableContentWidth * attachmentMaxWidthRatio

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
