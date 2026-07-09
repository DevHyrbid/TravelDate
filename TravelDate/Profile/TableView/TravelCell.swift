//
//  TravelCell.swift
//  TravelDate
//
//  Measured directly from Figma @3x export (Frame_2147230516.png) — all values
//  below are pixel-measured / 3, not guessed. Programmatic UIKit, no Storyboard/XIB.
//

import UIKit

final class TravelCell: UITableViewCell {

    static let identifier = "TravelCell"

    // MARK: - Views

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 21/255, green: 23/255, blue: 24/255, alpha: 1) // measured card bg
        view.layer.cornerRadius = 26
        view.clipsToBounds = true
        return view
    }()

    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 30/255, green: 34/255, blue: 36/255, alpha: 1) // measured icon bg
        view.layer.cornerRadius = 26 // 52/2 — perfect circle
        return view
    }()

    private let iconImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.tintColor = .white
        return image
    }()

    // MARK: - Title + subtitle
    // Independent trailing constraints (NOT a UIStackView) so a long subtitle
    // can never drag the title down into over-truncation.

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold) // measured cap-height ≈ 20pt
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium) // measured cap-height ≈ 15-16pt
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 30/255, green: 34/255, blue: 36/255, alpha: 1) // same tint as icon bg
        view.layer.cornerRadius = 21 // 42/2 — fully rounded pill
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium) // measured "U" height ≈ 14-15pt
        label.textColor = .white
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - setupViews

    private func setupViews() {
        contentView.addSubview(containerView)

        containerView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)

        statusContainer.addSubview(statusLabel)
        containerView.addSubview(statusContainer)

        [containerView, iconBackgroundView, iconImageView,
         titleLabel, subtitleLabel, statusContainer, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - setupConstraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([

            // Cell container — 110pt tall (measured), 8pt vertical inset for list rhythm
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(equalToConstant: 100),

            // Leading icon — 52x52, leading 26, vertically centered (matches measured design)
            iconBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 26),
            iconBackgroundView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 52),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 52),

            // Icon glyph — centered inside icon background
            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),

            // Title — leading 15 from icon, independent trailing constraint against
            // the pill so a long subtitle can't force extra truncation on this label.
            titleLabel.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusContainer.leadingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -5),

            // Subtitle — same leading edge, 10pt below title (measured baseline gap),
            // own independent trailing constraint.
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusContainer.leadingAnchor, constant: -12),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            // Status pill — trailing 26 (matches icon's leading margin), height 42,
            // hugs its own label content padded 24pt each side.
            statusContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -26),
            statusContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusContainer.heightAnchor.constraint(equalToConstant: 42),

            // Status label — centered, driving the pill's width via its own padding
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Configure

    func configure(title: String,
                   month: String,
                   icon: UIImage?,
                   status: String) {

        titleLabel.text = title
        subtitleLabel.text = month
        iconImageView.image = icon
        statusLabel.text = status
    }
}
