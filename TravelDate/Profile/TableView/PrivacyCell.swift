//
//  PrivacyCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 17/07/26.

import UIKit

final class PrivacyHeroCell: UITableViewCell {

    static let identifier = "PrivacyHeroCell"

    // MARK: - Views

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#181818")
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#242424").cgColor
        return view
    }()

    private let iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#352514")
        view.layer.cornerRadius = 18
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "shield") // your asset
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#FF6B00")
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect with Nearby Travelers"
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable location to discover nearby travel groups and let others see you're in the area"
        label.textColor = UIColor.white.withAlphaComponent(0.75)
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 0
        return label
    }()

    private let infoBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#3A2A18")
        view.layer.cornerRadius = 16
        return view
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "Your exact location is never shown only your approximate area"
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {

        super.init(style: style,
                   reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

}

// MARK: - UI

private extension PrivacyHeroCell {

    func setupUI() {

        contentView.addSubview(containerView)

        containerView.addSubview(iconBackground)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(infoBackground)

        iconBackground.addSubview(iconImageView)
        infoBackground.addSubview(infoLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoBackground.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            // Container

            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Icon Background

            iconBackground.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 28),
            iconBackground.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 28),
            iconBackground.widthAnchor.constraint(equalToConstant: 36),
            iconBackground.heightAnchor.constraint(equalToConstant: 36),

            // Icon

            iconImageView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),

            // Title

            titleLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -28),

            // Subtitle

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Info Box

            infoBackground.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 22),
            infoBackground.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoBackground.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            infoBackground.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -26),

            // Info Label

            infoLabel.topAnchor.constraint(equalTo: infoBackground.topAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: infoBackground.leadingAnchor, constant: 18),
            infoLabel.trailingAnchor.constraint(equalTo: infoBackground.trailingAnchor, constant: -18),
            infoLabel.bottomAnchor.constraint(equalTo: infoBackground.bottomAnchor, constant: -16)

        ])

    }

}
