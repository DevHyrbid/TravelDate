//
//  ChatHeaderView.swift
//  TravelDate
//
//  Reusable custom top header for the chat screen.
//  Layout:  [ Back ] [ Avatar ] [ Title + Subtitle ] [ More ]
//  Matches the dark messaging-app UI in the screenshots.
//

import UIKit

final class ChatHeaderView: UIView {

    // MARK: - Callbacks
    var onBack:    (() -> Void)?
    var onProfile: (() -> Void)?
    var onMore:    (() -> Void)?

    // MARK: - Subviews
    private let backButton       = UIButton(type: .system)
    private let profileImageView = UIImageView()
    private let titleLabel       = UILabel()
    private let subtitleLabel    = UILabel()
    private let moreButton       = UIButton(type: .system)
    private let textStack        = UIStackView()
    private let separator        = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Public configure

    func configure(title: String,
                   subtitle: String?,
                   imageURL: String?,
                   showMore: Bool = true) {
        titleLabel.text       = title
        subtitleLabel.text    = subtitle
        subtitleLabel.isHidden = (subtitle?.isEmpty ?? true)
        moreButton.isHidden   = !showMore

        if let str = imageURL, let url = URL(string: str) {
            profileImageView.image = UIImage(named: "User")
            ChatImageLoader.load(url: url, into: profileImageView)
        } else {
            profileImageView.image = UIImage(named: "User")
        }
    }

    /// Update just the subtitle (e.g. "Online" / "Last seen recently").
    func updateSubtitle(_ text: String?) {
        subtitleLabel.text = text
        subtitleLabel.isHidden = (text?.isEmpty ?? true)
    }

    // MARK: - Setup

    private func setupViews() {
        // Blend with the dark screen behind it.
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)

        // Back
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        // Expand tappable area
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 12)

        // Avatar
        profileImageView.layer.cornerRadius = 20      // 40x40 → fully circular
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        )

        // Title
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Poppins-SemiBold", size: 17) ?? .boldSystemFont(ofSize: 17)
        titleLabel.lineBreakMode = .byTruncatingTail

        // Subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitleLabel.font = UIFont(name: "Poppins-Regular", size: 12) ?? .systemFont(ofSize: 12)
        subtitleLabel.lineBreakMode = .byTruncatingTail

        // Text stack (title over subtitle)
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        // More
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .white
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        moreButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 8)

        // Hairline separator at the bottom
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        [backButton, profileImageView, textStack, moreButton, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    private func setupConstraints() {
        // Everything aligns to the safe-area top (status bar / notch respected).
        let guide = safeAreaLayoutGuide

        // Vertical center line for the row of controls.
        let rowCenter = backButton.centerYAnchor

        NSLayoutConstraint.activate([
            // Back button
            backButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            // Avatar
            profileImageView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 2),
            profileImageView.centerYAnchor.constraint(equalTo: rowCenter),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),

            // Text stack
            textStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: rowCenter),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),

            // More button
            moreButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -8),
            moreButton.centerYAnchor.constraint(equalTo: rowCenter),

            // Separator
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // Let the title stack take horizontal slack, avatar/buttons stay fixed.
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        backButton.setContentHuggingPriority(.required, for: .horizontal)
        moreButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    // MARK: - Actions

    @objc private func backTapped()    { onBack?() }
    @objc private func profileTapped() { onProfile?() }
    @objc private func moreTapped()    { onMore?() }
}
