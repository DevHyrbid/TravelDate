////
////
////  PrivacyViewController.swift
////
//
//import UIKit
//
//final class PrivacyViewController: UIViewController {
//
//    // MARK: - Views
//
//    private let scrollView: UIScrollView = {
//        let view = UIScrollView()
//        view.showsVerticalScrollIndicator = false
//        view.alwaysBounceVertical = true
//        view.backgroundColor = UIColor(hex: "#121212")
//        return view
//    }()
//
//    private let contentView = UIView()
//
//    private let stackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.spacing = 24
//        stack.alignment = .fill
//        stack.distribution = .fill
//        return stack
//    }()
//
//    // MARK: Hero
//
//    private let heroView = UIView()
//
//    // MARK: Life Cycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setupNavigation()
//        setupViews()
//        setupConstraints()
//
//        buildScreen()
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func setupNavigation() {
//
//        title = "Privacy & Security"
//
//        view.backgroundColor = UIColor(hex: "#121212")
//
//        navigationController?.navigationBar.prefersLargeTitles = false
//
//        navigationController?.navigationBar.tintColor = .white
//
//        navigationController?.navigationBar.titleTextAttributes = [
//
//            .foregroundColor: UIColor.white,
//            .font: UIFont.systemFont(ofSize: 22,
//                                     weight: .bold)
//
//        ]
//
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func setupViews() {
//
//        view.addSubview(scrollView)
//
//        scrollView.addSubview(contentView)
//
//        contentView.addSubview(stackView)
//
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func setupConstraints() {
//
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//
//        ])
//
//        NSLayoutConstraint.activate([
//
//            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//
//            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//
//            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//
//            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//
//            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
//
//        ])
//
//        NSLayoutConstraint.activate([
//
//            stackView.topAnchor.constraint(equalTo: contentView.topAnchor,
//                                           constant: 20),
//
//            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
//                                               constant: 20),
//
//            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
//                                                constant: -20),
//
//            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
//                                              constant: -30)
//
//        ])
//
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func buildScreen() {
//
//        setupHeroCard()
//
//        stackView.addArrangedSubview(heroView)
//
//        stackView.addArrangedSubview(sectionTitle("Account Privacy"))
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "profile",
//                title: "Profile Visibility",
//                subtitle: "Visible to all users",
//                type: .toggle
//            )
//        )
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "eye",
//                title: "Show Last Seen",
//                subtitle: "Let others see when you're active",
//                type: .toggle
//            )
//        )
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "verified",
//                title: "Verified Badge",
//                subtitle: "Get verified to build trust",
//                type: .arrow
//            )
//        )
//
//        stackView.addArrangedSubview(sectionTitle("Location Settings"))
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "location",
//                title: "Enable Group Matching",
//                subtitle: "Turn on to discover nearby travel groups.",
//                type: .toggle
//            )
//        )
//
//        stackView.addArrangedSubview(sectionTitle("Messaging"))
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "message",
//                title: "Who Can Message Me",
//                subtitle: "Everyone",
//                type: .radio
//            )
//        )
//
//        stackView.addArrangedSubview(makeInfoCard())
//
//        stackView.addArrangedSubview(sectionTitle("Account"))
//
//        stackView.addArrangedSubview(
//            makeRow(
//                icon: "trash",
//                title: "Delete Account",
//                subtitle: "Permanently delete your account",
//                type: .delete
//            )
//        )
//
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func sectionTitle(_ title: String) -> UILabel {
//
//        let label = UILabel()
//
//        label.text = title
//
//        label.font = .systemFont(ofSize: 22,
//                                 weight: .bold)
//
//        label.textColor = .white
//
//        return label
//
//    }
//
//}
//
//private extension PrivacyViewController {
//
//    func setupHeroCard() {
//
//        heroView.backgroundColor = UIColor(hex: "#1B1B1B")
//        heroView.layer.cornerRadius = 24
//        heroView.layer.borderWidth = 1
//        heroView.layer.borderColor = UIColor(hex: "#2B2B2B").cgColor
//
//        let iconBG = UIView()
//        iconBG.backgroundColor = UIColor(hex: "#3A2816")
//        iconBG.layer.cornerRadius = 28
//
//        let icon = UIImageView()
//        icon.image = UIImage(named: "location") // your orange icon
//        icon.tintColor = UIColor(hex: "#FF6B00")
//        icon.contentMode = .scaleAspectFit
//
//        let titleLabel = UILabel()
//        titleLabel.text = "Connect with Nearby Travelers"
//        titleLabel.textColor = .white
//        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
//        titleLabel.numberOfLines = 0
//
//        let descriptionLabel = UILabel()
//        descriptionLabel.text = "Enable location to discover nearby travel groups and let others see you're in the area."
//        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.75)
//        descriptionLabel.font = .systemFont(ofSize: 16, weight: .regular)
//        descriptionLabel.numberOfLines = 0
//
//        let infoView = UIView()
//        infoView.backgroundColor = UIColor(hex: "#322111")
//        infoView.layer.cornerRadius = 16
//
//        let infoIcon = UIImageView()
//        infoIcon.image = UIImage(systemName: "info.circle.fill")
//        infoIcon.tintColor = UIColor(hex: "#FF6B00")
//
//        let infoLabel = UILabel()
//        infoLabel.text = "Your exact location is never shown—only your approximate area."
//        infoLabel.textColor = UIColor.white.withAlphaComponent(0.9)
//        infoLabel.font = .systemFont(ofSize: 14)
//        infoLabel.numberOfLines = 0
//
//        heroView.addSubview(iconBG)
//        heroView.addSubview(titleLabel)
//        heroView.addSubview(descriptionLabel)
//        heroView.addSubview(infoView)
//
//        iconBG.addSubview(icon)
//        infoView.addSubview(infoIcon)
//        infoView.addSubview(infoLabel)
//
//        [iconBG,
//         icon,
//         titleLabel,
//         descriptionLabel,
//         infoView,
//         infoIcon,
//         infoLabel].forEach {
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        NSLayoutConstraint.activate([
//
//            iconBG.topAnchor.constraint(equalTo: heroView.topAnchor, constant: 28),
//            iconBG.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
//            iconBG.widthAnchor.constraint(equalToConstant: 56),
//            iconBG.heightAnchor.constraint(equalToConstant: 56),
//
//            icon.centerXAnchor.constraint(equalTo: iconBG.centerXAnchor),
//            icon.centerYAnchor.constraint(equalTo: iconBG.centerYAnchor),
//            icon.widthAnchor.constraint(equalToConstant: 28),
//            icon.heightAnchor.constraint(equalToConstant: 28),
//
//            titleLabel.topAnchor.constraint(equalTo: iconBG.bottomAnchor, constant: 20),
//            titleLabel.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
//            titleLabel.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -24),
//
//            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
//            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
//
//            infoView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
//            infoView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            infoView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
//            infoView.bottomAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -24),
//
//            infoIcon.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
//            infoIcon.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
//            infoIcon.widthAnchor.constraint(equalToConstant: 18),
//            infoIcon.heightAnchor.constraint(equalToConstant: 18),
//
//            infoLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
//            infoLabel.leadingAnchor.constraint(equalTo: infoIcon.trailingAnchor, constant: 12),
//            infoLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
//            infoLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16)
//
//        ])
//    }
//
//}
