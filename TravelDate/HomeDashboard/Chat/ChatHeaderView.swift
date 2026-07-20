//
//  ChatHeaderView.swift
//  TravelDate
//

import UIKit

final class ChatHeaderView: UIView {

    // MARK: - Callbacks

    var onBack: (() -> Void)?
    var onProfile: (() -> Void)?
    var onMore: (() -> Void)?

    // MARK: - Subviews

    private let backButton = UIButton(type: .system)

    private let avatarContainerView = UIView()
    private let leftImageView = UIImageView()
    private let rightImageView = UIImageView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let textStack = UIStackView()
    private let separator = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not used")
    }

    // MARK: - Public

    /// Single image chat
    func configure(
        title: String,
        subtitle: String?,
        imageURL: String?,
        showMore: Bool = true
    ) {

        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle?.isEmpty ?? true)
        moreButton.isHidden = !showMore

        leftImageView.isHidden = false
        rightImageView.isHidden = true

        if let str = imageURL, !str.isEmpty {
            ImageLoader.setImageKing(
                leftImageView,
                urlString: "\(APiConstant.base)\(str)"
            )
        } else {
            leftImageView.image = UIImage(named: "User")
        }
        
        leftImageView.layer.cornerRadius = self.leftImageView.frame.height / 2
        
    }

    /// Match chat (2 images)
//    func configure(
//        title: String,
//        subtitle: String?,
//        imageURLs: [String]?,
//        showMore: Bool = true
////    ) {
////
////        titleLabel.text = title
////        subtitleLabel.text = subtitle
////        subtitleLabel.isHidden = (subtitle?.isEmpty ?? true)
////        moreButton.isHidden = !showMore
////
////        leftImageView.image = UIImage(named: "User")
////        rightImageView.image = UIImage(named: "User")
////
////        guard let imageURLs = imageURLs, !imageURLs.isEmpty else {
////            leftImageView.isHidden = false
////            rightImageView.isHidden = true
////            return
////        }
////
////        if imageURLs.count >= 2 {
////
////            leftImageView.isHidden = false
////            rightImageView.isHidden = false
////
////            ImageLoader.setImageKing(
////                leftImageView,
////                urlString: "\(APiConstant.base)\(imageURLs[0])"
////            )
////
////            ImageLoader.setImageKing(
////                rightImageView,
////                urlString: "\(APiConstant.base)\(imageURLs[1])"
////            )
////
////        } else {
////
////            leftImageView.isHidden = false
////            rightImageView.isHidden = true
////
////            ImageLoader.setImageKing(
////                leftImageView,
////                urlString: "\(APiConstant.base)\(imageURLs[0])"
////            )
////        }
////    }

    func updateSubtitle(_ text: String?) {
        subtitleLabel.text = text
        subtitleLabel.isHidden = (text?.isEmpty ?? true)
    }

    // MARK: - Setup

    private func setupViews() {

        backgroundColor = UIColor(
            red: 0.05,
            green: 0.05,
            blue: 0.06,
            alpha: 1
        )

        // Back button

        backButton.setImage(
            UIImage(systemName: "chevron.left"),
            for: .normal
        )
        backButton.tintColor = .white
        backButton.contentEdgeInsets = UIEdgeInsets(
            top: 8,
            left: 4,
            bottom: 8,
            right: 12
        )
        backButton.addTarget(
            self,
            action: #selector(backTapped),
            for: .touchUpInside
        )

        // Avatar container

        avatarContainerView.isUserInteractionEnabled = true
        avatarContainerView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(profileTapped)
            )
        )

        // Left image

        leftImageView.contentMode = .scaleAspectFill
        leftImageView.clipsToBounds = true
        leftImageView.layer.cornerRadius = 16
        leftImageView.layer.borderWidth = 1.5
        leftImageView.layer.borderColor = UIColor.black.cgColor
        leftImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        // Right image

        rightImageView.contentMode = .scaleAspectFill
        rightImageView.clipsToBounds = true
        rightImageView.layer.cornerRadius = 16
        rightImageView.layer.borderWidth = 1.5
        rightImageView.layer.borderColor = UIColor.black.cgColor
        rightImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        // Title

        titleLabel.textColor = .white
        titleLabel.font = UIFont(
            name: "Poppins-SemiBold",
            size: 17
        ) ?? .boldSystemFont(ofSize: 17)

        // Subtitle

        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitleLabel.font = UIFont(
            name: "Poppins-Regular",
            size: 12
        ) ?? .systemFont(ofSize: 12)

        // Text stack

        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        // More button

        moreButton.setImage(
            UIImage(systemName: "ellipsis"),
            for: .normal
        )
        moreButton.tintColor = .white
        moreButton.contentEdgeInsets = UIEdgeInsets(
            top: 8,
            left: 12,
            bottom: 8,
            right: 8
        )
        moreButton.addTarget(
            self,
            action: #selector(moreTapped),
            for: .touchUpInside
        )

        // Separator

        separator.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        // Add views

        [
            backButton,
            avatarContainerView,
            textStack,
            moreButton,
            separator
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        [leftImageView, rightImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            avatarContainerView.addSubview($0)
        }
    }

    private func setupConstraints() {

        let guide = safeAreaLayoutGuide
        let rowCenter = backButton.centerYAnchor

        NSLayoutConstraint.activate([

            // Back

            backButton.leadingAnchor.constraint(
                equalTo: guide.leadingAnchor,
                constant: 8
            ),

            backButton.topAnchor.constraint(
                equalTo: guide.topAnchor,
                constant: 8
            ),

            backButton.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -14
            ),

            // Avatar Container

            avatarContainerView.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor,
                constant: 2
            ),

            avatarContainerView.centerYAnchor.constraint(
                equalTo: rowCenter
            ),

            avatarContainerView.widthAnchor.constraint(
                equalToConstant: 44
            ),

            avatarContainerView.heightAnchor.constraint(
                equalToConstant: 40
            ),

            // Left image

            leftImageView.leadingAnchor.constraint(
                equalTo: avatarContainerView.leadingAnchor
            ),

            leftImageView.centerYAnchor.constraint(
                equalTo: avatarContainerView.centerYAnchor
            ),

            leftImageView.widthAnchor.constraint(
                equalToConstant: 32
            ),

            leftImageView.heightAnchor.constraint(
                equalToConstant: 32
            ),

            // Right image

            rightImageView.trailingAnchor.constraint(
                equalTo: avatarContainerView.trailingAnchor
            ),

            rightImageView.centerYAnchor.constraint(
                equalTo: avatarContainerView.centerYAnchor
            ),

            rightImageView.widthAnchor.constraint(
                equalToConstant: 32
            ),

            rightImageView.heightAnchor.constraint(
                equalToConstant: 32
            ),

            // Text Stack

            textStack.leadingAnchor.constraint(
                equalTo: avatarContainerView.trailingAnchor,
                constant: 12
            ),

            textStack.centerYAnchor.constraint(
                equalTo: rowCenter
            ),

            textStack.trailingAnchor.constraint(
                lessThanOrEqualTo: moreButton.leadingAnchor,
                constant: -8
            ),

            // More

            moreButton.trailingAnchor.constraint(
                equalTo: guide.trailingAnchor,
                constant: -8
            ),

            moreButton.centerYAnchor.constraint(
                equalTo: rowCenter
            ),

            // Separator

            separator.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),

            separator.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),

            separator.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            separator.heightAnchor.constraint(
                equalToConstant: 0.5
            )
        ])

        titleLabel.setContentHuggingPriority(
            .defaultLow,
            for: .horizontal
        )

        backButton.setContentHuggingPriority(
            .required,
            for: .horizontal
        )

        moreButton.setContentHuggingPriority(
            .required,
            for: .horizontal
        )
    }

    // MARK: - Actions

    @objc private func backTapped() {
        onBack?()
    }

    @objc private func profileTapped() {
        onProfile?()
    }

    @objc private func moreTapped() {
        onMore?()
    }
}
