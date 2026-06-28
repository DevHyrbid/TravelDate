// FeatureRowView.swift
// Trips: Travel & Meet Friends
// Pixel-perfect match to Figma features section

import UIKit

// MARK: - Feature Model
struct SubscriptionFeature {
    let iconName: String
    let title: String
    let description: String
}

// MARK: - FeatureRowView

final class FeatureRowView: UIView {

    // MARK: - UI
    // Figma: dark brownish-orange circle with orange icon, 44x44
    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#FF7A00").withAlphaComponent(0.12)
        v.layer.cornerRadius = 22
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor    = UIColor(hex: "#FF7A00")
        iv.contentMode  = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Figma: title is white semibold, description is gray/55% alpha
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor     = .white
        l.numberOfLines = 1
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 14, weight: .regular)
        l.textColor     = UIColor(white: 1, alpha: 0.68)
        l.numberOfLines = 3
        return l
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis    = .vertical
        textStack.spacing = 7
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Configure
    func configure(with feature: SubscriptionFeature) {
        iconImageView.image   = UIImage(systemName: feature.iconName)
        titleLabel.text       = feature.title
        descriptionLabel.text = feature.description
    }
}
