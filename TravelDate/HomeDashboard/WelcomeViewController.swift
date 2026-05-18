//
//  WelcomeViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone

struct Theme {
    static let orange = UIColor(named: "ThemeOrange") ?? .orange
    static let bg = UIColor.black
    static let card = UIColor.white.withAlphaComponent(0.04)
}
import UIKit

class WelcomeViewController: BaseClassVc {

    // MARK: - Logo Box
    private let logoView: UIView = {
        let v = UIView()
        v.backgroundColor   = UIColor.white.withAlphaComponent(0.04)
        v.layer.cornerRadius = 20
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.15).cgColor
        return v
    }()
    
    
    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text      = "Trips"
        l.textColor = .themeOrange
        l.setFont(.semiBold, size: 22)
        return l
    }()

    // MARK: - Welcome
    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text      = "Welcome"
        l.textColor = .white
        l.setFont(.semiBold, size: 26)
        return l
    }()

    // MARK: - Card
    private let cardView: UIView = {
        let v = UIView()
        // #151718
        v.backgroundColor    = UIColor(red:0.082, green:0.090, blue:0.094, alpha:1)
        v.layer.cornerRadius = 22
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor(red:0.110, green:0.118, blue:0.133, alpha:1).cgColor
        return v
    }()

    // MARK: - Create Group row
    private let createBarView  = WelcomeViewController.accentBar()
    private let createTitleLbl = WelcomeViewController.sectionTitle("Create Group")
    private let createDescLbl  = WelcomeViewController.sectionDesc(
        "Create group from scratch and invite friends to join later !")

    private let createButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Create", for: .normal)
        b.setTitleColor(.themeOrange, for: .normal)
        b.layer.cornerRadius = 12
        b.layer.borderWidth  = 1.5
        b.layer.borderColor  = UIColor.themeOrange.cgColor
        b.titleLabel?.setFont(.semiBold, size: 16)
        b.addTarget(self, action: #selector(openCreateGroup), for: .touchUpInside)
        return b
    }()

    // MARK: - Join Group row
    private let joinBarView  = WelcomeViewController.accentBar()
    private let joinTitleLbl = WelcomeViewController.sectionTitle("Join Group")
    private let joinDescLbl  = WelcomeViewController.sectionDesc(
        "Paste the link & join your friends existing travel group !")

  
   

    // MARK: - Join Group - Link section
    private let linkContainer: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "111211")
        v.layer.cornerRadius = 14
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.12).cgColor
        return v
    }()

    private let groupLinkLabel: UILabel = {
        let l = UILabel()
        l.text      = "Group Link"
        l.textColor = .white
        l.setFont(.semiBold, size: 14)
        return l
    }()

    // The inner box around the text field
    private let linkFieldBox: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor.white.withAlphaComponent(0.05)
        v.layer.cornerRadius = 10
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.12).cgColor
        return v
    }()

    private let linkField: UITextField = {
        let tf = UITextField()
        tf.textColor = .white
        tf.setFont(.regular, size: 14)
        tf.attributedPlaceholder = NSAttributedString(
            string: "https://tripsapp.com/join/...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.35)]
        )
        return tf
    }()

    private let pasteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.themeOrange, for: .normal)
        b.layer.cornerRadius = 10
        b.layer.borderWidth  = 1.5
        b.layer.borderColor  = UIColor.themeOrange.cgColor
        b.titleLabel?.setFont(.semiBold, size: 16)
        b.tintColor = .themeOrange

        let icon = UIImage(systemName: "doc.on.clipboard")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        b.setImage(icon, for: .normal)
        b.setTitle("  Paste", for: .normal)
        b.semanticContentAttribute = .forceLeftToRight

        b.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Bottom CTA
    private let joinButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Join Existing Group", for: .normal)
        b.backgroundColor    = UIColor(white: 0.267, alpha: 1) // #444444
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 14
        b.titleLabel?.setFont(.semiBold, size: 16)
        b.addTarget(self, action: #selector(btnJoin), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red:0.067, green:0.071, blue:0.067, alpha:1) // #111211
        setupUI()
        layout()
        setupBackButton()
        addGradient()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Add blobs after bounds are known
//        if view.subviews.filter({ $0.tag == 999 }).isEmpty {
//            setupAmbientBlobs()
//        }
    }

    // MARK: - Helpers
    private static func accentBar() -> UIView {
        let v = UIView()
        v.backgroundColor    = UIColor(red:1.0, green:0.161, blue:0.302, alpha:1) // #FE294D
        v.layer.cornerRadius = 2
        return v
    }

    private static func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.textColor = .white
        l.setFont(.semiBold, size: 16)
        return l
    }

    private static func sectionDesc(_ text: String) -> UILabel {
        let l = UILabel()
        l.text          = text
        l.textColor     = UIColor.white.withAlphaComponent(0.6)
        l.setFont(.regular, size: 13)
        l.numberOfLines = 0
        return l
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(logoView)
        logoView.addSubview(logoLabel)
        view.addSubview(welcomeLabel)
        view.addSubview(cardView)

        cardView.addSubview(createBarView)
        cardView.addSubview(createTitleLbl)
        cardView.addSubview(createDescLbl)
        cardView.addSubview(createButton)
        cardView.addSubview(joinBarView)
        cardView.addSubview(joinTitleLbl)
        cardView.addSubview(joinDescLbl)
        cardView.addSubview(linkContainer)

        // linkContainer children
        linkContainer.addSubview(groupLinkLabel)
        linkContainer.addSubview(linkFieldBox)
        linkContainer.addSubview(pasteButton)
        linkFieldBox.addSubview(linkField)

        view.addSubview(joinButton)
    }

    private func layout() {
        let all: [UIView] = [
            logoView, logoLabel, welcomeLabel, cardView,
            createBarView, createTitleLbl, createDescLbl, createButton,
            joinBarView, joinTitleLbl, joinDescLbl,
            linkContainer, groupLinkLabel, linkFieldBox, linkField, pasteButton,
            joinButton
        ]
        all.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let cardInner: CGFloat = 16
        let cardEdge:  CGFloat = 16

        NSLayoutConstraint.activate([

            // ── Logo box ──
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 113),
            logoView.heightAnchor.constraint(equalToConstant: 109),
            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),

            // ── Welcome ──
            welcomeLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 18),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ── Card ──
            cardView.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 26),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: cardEdge),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -cardEdge),

            // ── Create Bar ──
            createBarView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            createBarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            createBarView.widthAnchor.constraint(equalToConstant: 4),
            createBarView.heightAnchor.constraint(equalToConstant: 20),

            // ── Create Title ──
            createTitleLbl.centerYAnchor.constraint(equalTo: createBarView.centerYAnchor),
            createTitleLbl.leadingAnchor.constraint(equalTo: createBarView.trailingAnchor, constant: 8),

            // ── Create Desc ──
            createDescLbl.topAnchor.constraint(equalTo: createBarView.bottomAnchor, constant: 6),
            createDescLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            createDescLbl.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardInner),

            // ── Create Button ──
            createButton.topAnchor.constraint(equalTo: createDescLbl.bottomAnchor, constant: 14),
            createButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            createButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -(cardInner + 10)),
            createButton.heightAnchor.constraint(equalToConstant: 44),

            // ── Join Bar ──
            joinBarView.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 22),
            joinBarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            joinBarView.widthAnchor.constraint(equalToConstant: 4),
            joinBarView.heightAnchor.constraint(equalToConstant: 20),

            // ── Join Title ──
            joinTitleLbl.centerYAnchor.constraint(equalTo: joinBarView.centerYAnchor),
            joinTitleLbl.leadingAnchor.constraint(equalTo: joinBarView.trailingAnchor, constant: 8),

            // ── Join Desc ──
            joinDescLbl.topAnchor.constraint(equalTo: joinBarView.bottomAnchor, constant: 6),
            joinDescLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            joinDescLbl.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardInner),

            // ── Link Container ──
            linkContainer.topAnchor.constraint(equalTo: joinDescLbl.bottomAnchor, constant: 12),
            linkContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardInner + 10),
            linkContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -(cardInner + 10)),
            linkContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),

            // ── Group Link Label (inside container) ──
            groupLinkLabel.topAnchor.constraint(equalTo: linkContainer.topAnchor, constant: 14),
            groupLinkLabel.leadingAnchor.constraint(equalTo: linkContainer.leadingAnchor, constant: 14),

            // ── Link Field Box (inside container, below label) ──
            linkFieldBox.topAnchor.constraint(equalTo: groupLinkLabel.bottomAnchor, constant: 10),
            linkFieldBox.leadingAnchor.constraint(equalTo: linkContainer.leadingAnchor, constant: 10),
            linkFieldBox.trailingAnchor.constraint(equalTo: pasteButton.leadingAnchor, constant: -10),
            linkFieldBox.heightAnchor.constraint(equalToConstant: 52),
            linkFieldBox.bottomAnchor.constraint(equalTo: linkContainer.bottomAnchor, constant: -14),

            // ── Link Field (inside linkFieldBox) ──
            linkField.leadingAnchor.constraint(equalTo: linkFieldBox.leadingAnchor, constant: 12),
            linkField.trailingAnchor.constraint(equalTo: linkFieldBox.trailingAnchor, constant: -12),
            linkField.centerYAnchor.constraint(equalTo: linkFieldBox.centerYAnchor),

            // ── Paste Button (right of linkFieldBox) ──
            pasteButton.trailingAnchor.constraint(equalTo: linkContainer.trailingAnchor, constant: -10),
            pasteButton.centerYAnchor.constraint(equalTo: linkFieldBox.centerYAnchor),
            pasteButton.widthAnchor.constraint(equalToConstant: 110),
            pasteButton.heightAnchor.constraint(equalToConstant: 52),

            // ── Join Button ──
            joinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            joinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            joinButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            joinButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    // MARK: - Back button
    private func setupBackButton() {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor         = .white
        b.backgroundColor   = UIColor.white.withAlphaComponent(0.1)
        b.layer.cornerRadius = 18
        b.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        view.addSubview(b)
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            b.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            b.widthAnchor.constraint(equalToConstant: 36),
            b.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
           
    }

    @objc private func openCreateGroup() {
        pushVC(CreateGroupViewController.self, from: .Home)
    }

    @objc private func pasteTapped() {
        linkField.text = UIPasteboard.general.string ?? ""
    }

    @objc func btnJoin(_ sender: UIButton) {
        guard let code = linkField.text, !code.isEmpty else {
            showAlert(message: "Please add the link"); return
        }
        request.code = code
        request.joinGroupAPi { errMsg, errCode in
            DispatchQueue.main.async {
                if errCode == 200 {
                    self.showAlertAction("Group Joined Successfully") { self.backTapped() }
                } else {
                    self.showAlert(errMsg)
                }
            }
        }
    }
}
