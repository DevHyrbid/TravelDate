//
//  WelcomeViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone
//
import UIKit
import SwiftUI
// MARK: - Theme

struct Theme {
    static let orange = UIColor(named: "ThemeOrange") ?? .orange
    static let bg = UIColor.black
    static let card = UIColor.white.withAlphaComponent(0.04)
}

import UIKit

class WelcomeViewController: UIViewController {

    // MARK: - UI

    private let logoView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        return v
    }()

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "Trips"
        l.textColor = UIColor.orange
        l.setFont(.semiBold, size: 22)
        //= UIFont.systemFont(ofSize: 22, weight: .semibold)
        return l
    }()

    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome"
        l.textColor = .white
        l.setFont(.semiBold, size: 26)
        //font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        v.layer.cornerRadius = 22
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        return v
    }()

    // Section 1
    private let createTitle = WelcomeViewController.sectionTitle("Create Group")
    private let createDesc = WelcomeViewController.sectionDesc("Create group from scratch and invite friends to join later !")

    private let createButton: UIButton = {
        let b = UIButton()
        b.setTitle("+ Create", for: .normal)
        b.setTitleColor(.orange, for: .normal)
        b.layer.cornerRadius = 22
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.orange.cgColor
        b.titleLabel?.setFont(.semiBold, size: 16)
        b.addTarget(self, action: #selector(openCreateGroup), for: .touchUpInside)
        //font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    // Section 2
    private let joinTitle = WelcomeViewController.sectionTitle("Join Group")
    private let joinDesc = WelcomeViewController.sectionDesc("Paste the link & join your friends existing travel group !")

    private let linkContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        v.layer.cornerRadius = 14
        return v
    }()

    private let linkField: UITextField = {
        let tf = UITextField()
        tf.textColor = .white
        tf.setFont(.regular, size: 14)
        //= UIFont.systemFont(ofSize: 14)
        tf.attributedPlaceholder = NSAttributedString(
            string: "https://tripsapp.com/join/...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        return tf
    }()

    private let pasteButton: UIButton = {
        let b = UIButton()
        b.setTitle("Paste", for: .normal)
        b.setTitleColor(.orange, for: .normal)
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.orange.cgColor
        b.titleLabel?.setFont(.semiBold, size: 14.0)
        //font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return b
    }()

    private let joinButton: UIButton = {
        let b = UIButton()
        b.setTitle("Join Existing Group", for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 26
        b.titleLabel?.setFont(.semiBold, size: 16)
        //font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        layout()
    }

    
    @objc func openCreateGroup() {
        let vc = UIHostingController(rootView: InviteFriendsView())
        navigationController?.pushViewController(vc, animated: true)
        //navigationController?.pushViewController(CreateGroupViewController(), animated: true)
    }
    private func setupUI() {
        view.addSubview(logoView)
        logoView.addSubview(logoLabel)

        view.addSubview(welcomeLabel)
        view.addSubview(cardView)

        [createTitle, createDesc, createButton, joinTitle, joinDesc, linkContainer].forEach {
            cardView.addSubview($0)
        }

        linkContainer.addSubview(linkField)
        linkContainer.addSubview(pasteButton)

        view.addSubview(joinButton)
    }

    private func layout() {
        [logoView, logoLabel, welcomeLabel, cardView,
         createTitle, createDesc, createButton,
         joinTitle, joinDesc, linkContainer,
         linkField, pasteButton, joinButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 100),
            logoView.heightAnchor.constraint(equalToConstant: 100),

            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),

            welcomeLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 18),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardView.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 26),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            createTitle.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            createTitle.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            createDesc.topAnchor.constraint(equalTo: createTitle.bottomAnchor, constant: 4),
            createDesc.leadingAnchor.constraint(equalTo: createTitle.leadingAnchor),
            createDesc.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            createButton.topAnchor.constraint(equalTo: createDesc.bottomAnchor, constant: 14),
            createButton.leadingAnchor.constraint(equalTo: createTitle.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 44),

            joinTitle.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 22),
            joinTitle.leadingAnchor.constraint(equalTo: createTitle.leadingAnchor),

            joinDesc.topAnchor.constraint(equalTo: joinTitle.bottomAnchor, constant: 4),
            joinDesc.leadingAnchor.constraint(equalTo: createTitle.leadingAnchor),
            joinDesc.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            linkContainer.topAnchor.constraint(equalTo: joinDesc.bottomAnchor, constant: 12),
            linkContainer.leadingAnchor.constraint(equalTo: createTitle.leadingAnchor),
            linkContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            linkContainer.heightAnchor.constraint(equalToConstant: 50),
            linkContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),

            linkField.leadingAnchor.constraint(equalTo: linkContainer.leadingAnchor, constant: 12),
            linkField.centerYAnchor.constraint(equalTo: linkContainer.centerYAnchor),
            linkField.trailingAnchor.constraint(equalTo: pasteButton.leadingAnchor, constant: -8),

            pasteButton.trailingAnchor.constraint(equalTo: linkContainer.trailingAnchor, constant: -10),
            pasteButton.centerYAnchor.constraint(equalTo: linkContainer.centerYAnchor),
            pasteButton.widthAnchor.constraint(equalToConstant: 72),
            pasteButton.heightAnchor.constraint(equalToConstant: 34),

            joinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            joinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            joinButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            joinButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private static func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = .white
        l.setFont(.semiBold, size: 16)
        //font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return l
    }

    private static func sectionDesc(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        l.setFont(.regular, size: 13)
        //font = UIFont.systemFont(ofSize: 13)
        l.numberOfLines = 0
        return l
    }
}
