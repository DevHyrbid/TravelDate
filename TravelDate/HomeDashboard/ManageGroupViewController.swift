//
//  ManageGroupViewController.swift
//  TravelDate
//
//  Premium dark-themed group management screen (UIKit, programmatic).
//

import UIKit

// MARK: - Models

struct GroupMember {
    let id: String
    var name: String
    var role: String
    var isAdmin: Bool
    var isCurrentUser: Bool
    var avatarColor: UIColor
    var initials: String
    var profileImage: String?   // ← add this
}

// MARK: - Design Tokens



// MARK: - ManageGroupViewController

final class ManageGroupViewController: UIViewController {

    // MARK: Config
    var groupName: String = "Bali Adventure Crew"
    var groupSubtitle: String = "Bali Adventure Crew"
    var tripDates: String = "Static"
    var onDeleteGroup: (() -> Void)?

    private var members: [GroupMember] = [
        GroupMember(id: "you",   name: "You",           role: "Group Creator", isAdmin: true,  isCurrentUser: true,  avatarColor: UIColor(hex: "#555555"), initials: ""),
        GroupMember(id: "sarah", name: "Sarah Johnson", role: "Member",        isAdmin: false, isCurrentUser: false, avatarColor: UIColor(hex: "#7B3F3F"), initials: "SJ"),
        GroupMember(id: "mike",  name: "Mike Chen",     role: "Member",        isAdmin: false, isCurrentUser: false, avatarColor: UIColor(hex: "#3F5A7B"), initials: "MC"),
        GroupMember(id: "emma",  name: "Emma Davis",    role: "Member",        isAdmin: false, isCurrentUser: false, avatarColor: UIColor(hex: "#4F7B5A"), initials: "ED"),
    ]

    private var isMembersExpanded = true
    private var isMuted = true

    // MARK: Views
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()
    private let membersListStack = UIStackView()

    private lazy var titleLabel    = makeLabel("Manage Group", size: 22, weight: .bold, color: Theme.textPrimary)
    private lazy var subtitleLabel = makeLabel(groupSubtitle, size: 14, weight: .regular, color: Theme.textSecond)

    private lazy var membersChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.down",
                                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        iv.tintColor = Theme.textSecond
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private lazy var muteToggle: UISwitch = {
        let s = UISwitch()
        s.isOn = isMuted
        s.onTintColor = Theme.accent
        s.addTarget(self, action: #selector(muteSwitchChanged(_:)), for: .valueChanged)
        return s
    }()

    private let feedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bg
        setupSheet()
        buildUI()
    }

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
    }

    // MARK: Build UI

    private func buildUI() {
        // ---- Header (fixed at top) ----
        let header = buildHeader()

        // ---- Scrollable content ----
        let membersCard = buildMembersCard()
        let muteCard    = buildIconRow(iconName: "bell.fill",
                                       iconTint: Theme.accent,
                                       title: "Mute Notifications",
                                       trailing: muteToggle)
        let tripCard    = buildTripDatesRow()
        let deleteCard  = buildDeleteRow()

        [membersCard, muteCard, tripCard, deleteCard].forEach { styleAsCard($0) }

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 4, left: 18, bottom: 32, right: 18)
        [membersCard, muteCard, tripCard, deleteCard].forEach { contentStack.addArrangedSubview($0) }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        header.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    // MARK: Header

    private func buildHeader() -> UIView {
        let avatar = UIView()
        avatar.backgroundColor = UIColor(hex: "#333333")
        avatar.layer.cornerRadius = 26
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 52),
            avatar.heightAnchor.constraint(equalToConstant: 52),
        ])
        let avatarIcon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        avatarIcon.tintColor = UIColor(hex: "#777777")
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)
        NSLayoutConstraint.activate([
            avatarIcon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 24),
            avatarIcon.heightAnchor.constraint(equalToConstant: 24),
        ])

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)), for: .normal)
        closeButton.tintColor = UIColor(hex: "#AAAAAA")
        closeButton.backgroundColor = Theme.floatBtnBg
        closeButton.layer.cornerRadius = 16
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
        ])
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [avatar, textStack, closeButton])
        row.alignment = .center
        row.spacing = 14
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        return row
    }

    // MARK: Members Card

    private func buildMembersCard() -> UIView {
        let container = UIView()

        let iconView = makeIconView(systemName: "person.2.fill")
        let label = makeLabel("View Members", size: 16, weight: .semibold, color: Theme.textPrimary)

        let headerRow = UIStackView(arrangedSubviews: [iconView, label, UIView(), membersChevron])
        headerRow.alignment = .center
        headerRow.spacing = 12
        headerRow.isLayoutMarginsRelativeArrangement = true
        headerRow.layoutMargins = Theme.rowInset
        headerRow.isUserInteractionEnabled = true
        headerRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleMembers)))

        membersListStack.axis = .vertical
        membersListStack.spacing = 0
        rebuildMemberRows()

        let stack = UIStackView(arrangedSubviews: [headerRow, membersListStack])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        stack.pinEdges(to: container)
        return container
    }

    private func rebuildMemberRows() {
        membersListStack.arrangedSubviews.forEach {
            membersListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard isMembersExpanded else { return }
        for (i, member) in members.enumerated() {
            membersListStack.addArrangedSubview(makeSeparator(inset: 16))
            membersListStack.addArrangedSubview(buildMemberRow(member: member, index: i))
        }
    }

    private func buildMemberRow(member: GroupMember, index: Int) -> UIView {
        let container = UIView()
        container.tag = index

        let avatarView = makeAvatar(for: member)

        let nameLabel = makeLabel(member.name, size: 15.5, weight: .semibold, color: Theme.textPrimary)
        let roleLabel = makeLabel(member.role, size: 13, weight: .regular, color: Theme.textSecond)

        var nameRow: UIView = nameLabel
        if member.isAdmin {
            let ns = UIStackView(arrangedSubviews: [nameLabel, makeAdminBadge(), UIView()])
            ns.alignment = .center
            ns.spacing = 7
            nameRow = ns
        }

        let infoStack = UIStackView(arrangedSubviews: [nameRow, roleLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let trailingView: UIView
        if member.id == "mike" {
            trailingView = makeRemoveButton(memberId: member.id)
        } else if !member.isCurrentUser {
            trailingView = makeMoreButton(memberId: member.id)
        } else {
            trailingView = UIView()
        }

        let row = UIStackView(arrangedSubviews: [avatarView, infoStack, UIView(), trailingView])
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        row.pinEdges(to: container)
        return container
    }

    private func makeAvatar(for member: GroupMember) -> UIView {
        let avatarView = UIView()
        avatarView.backgroundColor = member.avatarColor
        avatarView.layer.cornerRadius = 22
        avatarView.clipsToBounds = false
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),
        ])

        let circle = UIView()
        circle.backgroundColor = member.avatarColor
        circle.layer.cornerRadius = 22
        circle.clipsToBounds = true
        circle.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(circle)
        circle.pinEdges(to: avatarView)

        // Remote profile image — loads async, sits on top of color fallback
        if let urlString = member.profileImage,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            let iv = UIImageView()
            iv.contentMode   = .scaleAspectFill
            iv.clipsToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: circle.topAnchor),
                iv.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: circle.trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            ])
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { iv.image = img }
            }.resume()

        } else if member.isCurrentUser {
            // Fallback: person icon for current user
            let icon = UIImageView(image: UIImage(systemName: "person.fill"))
            icon.tintColor   = .white
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(icon)
            NSLayoutConstraint.activate([
                icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 22),
                icon.heightAnchor.constraint(equalToConstant: 22),
            ])
        } else {
            // Fallback: initials
            let lbl = UILabel()
            lbl.text      = member.initials
            lbl.font      = .systemFont(ofSize: 15, weight: .semibold)
            lbl.textColor = .white
            lbl.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            ])
        }

        // Crown badge — always shown for admin regardless of avatar type
        if member.isAdmin {
            let crown = UILabel()
            crown.text                = "👑"
            crown.font                = .systemFont(ofSize: 9)
            crown.backgroundColor     = Theme.accent
            crown.textAlignment       = .center
            crown.layer.cornerRadius  = 9
            crown.layer.borderWidth   = 2
            crown.layer.borderColor   = Theme.card.cgColor
            crown.clipsToBounds       = true
            crown.translatesAutoresizingMaskIntoConstraints = false
            avatarView.addSubview(crown)
            NSLayoutConstraint.activate([
                crown.widthAnchor.constraint(equalToConstant: 18),
                crown.heightAnchor.constraint(equalToConstant: 18),
                crown.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 2),
                crown.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: -2),
            ])
        }

        return avatarView
    }

    // MARK: Icon Rows (Mute)

    private func buildIconRow(iconName: String, iconTint: UIColor, title: String, trailing: UIView?) -> UIView {
        let iconView = makeIconView(systemName: iconName)
        let label = makeLabel(title, size: 16, weight: .medium, color: Theme.textPrimary)
        var arranged: [UIView] = [iconView, label, UIView()]
        if let t = trailing { arranged.append(t) }
        let row = UIStackView(arrangedSubviews: arranged)
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = Theme.rowInset
        let wrap = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(row)
        row.pinEdges(to: wrap)
        return wrap
    }

    // MARK: Trip Dates Row (styled label with accent date)

    private func buildTripDatesRow() -> UIView {
        let iconView = makeIconView(systemName: "calendar")

        let label = UILabel()
        label.numberOfLines = 0
        let attr = NSMutableAttributedString(
            string: "Trip Dates — ",
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium),
                         .foregroundColor: Theme.textPrimary])
        attr.append(NSAttributedString(
            string: tripDates,
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium),
                         .foregroundColor: Theme.textSecond]))
        label.attributedText = attr

        let row = UIStackView(arrangedSubviews: [iconView, label, UIView()])
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = Theme.rowInset
        let wrap = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(row)
        row.pinEdges(to: wrap)
        return wrap
    }

    // MARK: Delete Row

    private func buildDeleteRow() -> UIView {
        let iconView = makeIconView(systemName: "rectangle.portrait.and.arrow.right",
                                    bg: UIColor(hex: "#3A1212"), tint: Theme.danger)
        let label = makeLabel("Delete Group", size: 16, weight: .medium, color: Theme.danger)
        let row = UIStackView(arrangedSubviews: [iconView, label, UIView()])
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = Theme.rowInset
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(deleteGroupTapped(_:))))
        let wrap = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(row)
        row.pinEdges(to: wrap)
        return wrap
    }

    // MARK: Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func toggleMembers() {
        feedback.impactOccurred()
        isMembersExpanded.toggle()

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4, options: [.curveEaseInOut]) {
            self.membersChevron.transform = self.isMembersExpanded ? .identity
                                            : CGAffineTransform(rotationAngle: -.pi + 0.0001)
        }

        rebuildMemberRows()
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.membersListStack.alpha = self.isMembersExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func muteSwitchChanged(_ sender: UISwitch) {
        isMuted = sender.isOn
        feedback.impactOccurred()
    }

    @objc private func deleteGroupTapped(_ gesture: UITapGestureRecognizer) {
        if let row = gesture.view { animateTap(row) }
        presentDeleteConfirmation()
    }

    @objc private func removeMemberTapped(_ sender: UIButton) {
        guard let memberId = sender.accessibilityIdentifier else { return }
        let alert = UIAlertController(title: "Remove Member",
                                      message: "Remove this member from the group?",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.members.removeAll { $0.id == memberId }
            self?.animateMembersReload()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func moreOptionsTapped(_ sender: UIButton) {
        guard let memberId = sender.accessibilityIdentifier,
              let idx = members.firstIndex(where: { $0.id == memberId }) else { return }
        let member = members[idx]
        let sheet = UIAlertController(title: member.name, message: nil, preferredStyle: .actionSheet)
        let adminTitle = member.isAdmin ? "Remove Admin" : "Make Admin"
        sheet.addAction(UIAlertAction(title: adminTitle, style: .default) { [weak self] _ in
            self?.members[idx].isAdmin.toggle()
            self?.animateMembersReload()
        })
        sheet.addAction(UIAlertAction(title: "Remove from Group", style: .destructive) { [weak self] _ in
            self?.members.removeAll { $0.id == memberId }
            self?.animateMembersReload()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func animateMembersReload() {
        rebuildMemberRows()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: Delete Confirmation Modal

    private func presentDeleteConfirmation() {
        let popup = DeleteConfirmationViewController()
        popup.onConfirm = { [weak self] in
            self?.dismiss(animated: true) { self?.onDeleteGroup?() }
        }
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        present(popup, animated: false)
    }

    // MARK: Tap Animation

    private func animateTap(_ view: UIView) {
        UIView.animate(withDuration: 0.08, animations: {
            view.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            view.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.5) {
                view.transform = .identity
                view.alpha = 1
            }
        }
    }

    // MARK: Reusable Builders

    private func styleAsCard(_ view: UIView) {
        view.backgroundColor = Theme.card
        view.layer.cornerRadius = Theme.cardRadius
        view.clipsToBounds = true
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.numberOfLines = 0
        return l
    }

    private func makeIconView(systemName: String,
                              bg: UIColor = UIColor(hex: "#3A2A0A"),
                              tint: UIColor = Theme.accent) -> UIView {
        let container = UIView()
        container.backgroundColor = bg
        container.layer.cornerRadius = 11
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 38),
            container.heightAnchor.constraint(equalToConstant: 38),
        ])
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 19),
            icon.heightAnchor.constraint(equalToConstant: 19),
        ])
        return container
    }

    private func makeAdminBadge() -> UIView {
        let l = PaddingLabel()
        l.text = "ADMIN"
        l.font = .systemFont(ofSize: 10.5, weight: .bold)
        l.textColor = Theme.accent
        l.backgroundColor = Theme.accent.withAlphaComponent(0.14)
        l.layer.cornerRadius = 5
        l.clipsToBounds = true
        l.textAlignment = .center
        l.insets = UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }

    private func makeRemoveButton(memberId: String) -> UIView {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Remove"
        config.image = UIImage(systemName: "person.fill.badge.minus")
        config.imagePadding = 5
        config.baseForegroundColor = Theme.danger
        config.background.backgroundColor = Theme.danger.withAlphaComponent(0.13)
        config.background.cornerRadius = 9
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 12)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 14, weight: .semibold)
            return out
        }
        btn.configuration = config
        btn.accessibilityIdentifier = memberId
        btn.addTarget(self, action: #selector(removeMemberTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func makeMoreButton(memberId: String) -> UIView {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "ellipsis.vertical"), for: .normal)
        btn.tintColor = Theme.textSecond
        btn.backgroundColor = UIColor(hex: "#242424")
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 32),
            btn.heightAnchor.constraint(equalToConstant: 32),
        ])
        btn.accessibilityIdentifier = memberId
        btn.addTarget(self, action: #selector(moreOptionsTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func makeSeparator(inset: CGFloat) -> UIView {
        let wrap = UIView()
        let line = UIView()
        line.backgroundColor = Theme.separator
        line.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(line)
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 0.5),
            line.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: inset),
            line.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -inset),
            line.topAnchor.constraint(equalTo: wrap.topAnchor),
            line.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
        ])
        return wrap
    }
}

// MARK: - Present Helper

extension ManageGroupViewController {
    static func present(from vc: UIViewController,
                        groupName: String = "Bali Adventure Crew",
                        groupSubtitle: String = "Bali Adventure Crew",
                        tripDates: String = "Apr 15 – Apr 25, 2026",
                        members: [GroupMember]? = nil,
                        onDelete: (() -> Void)? = nil) {
        let sheet = ManageGroupViewController()
        sheet.groupName = groupName
        sheet.groupSubtitle = groupSubtitle
        sheet.tripDates = tripDates
        if let members = members { sheet.members = members }
        sheet.onDeleteGroup = onDelete
        sheet.modalPresentationStyle = .pageSheet
        vc.present(sheet, animated: true)
    }
}

// MARK: - DeleteConfirmationViewController (Custom Centered Modal)

final class DeleteConfirmationViewController: UIViewController {
    
    var onConfirm: (() -> Void)?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let popupView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    private func buildUI() {
        // Blur + dim backdrop
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0
        view.addSubview(blurView)
        
        dimView.frame = view.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.alpha = 0
        view.addSubview(dimView)
        
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dimView.addGestureRecognizer(dismissTap)
        
        // Popup card
        popupView.backgroundColor = UIColor(hex: "#1C1C1E")
        popupView.layer.cornerRadius = 24
        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.alpha = 0
        popupView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        view.addSubview(popupView)
        
        let title = UILabel()
        title.text = "Delete Group?"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white
        title.textAlignment = .center
        
        let subtitle = UILabel()
        subtitle.text = "Are you sure you want to permanently delete your group?"
        subtitle.font = .systemFont(ofSize: 15, weight: .regular)
        subtitle.textColor = UIColor(hex: "#9A9A9E")
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        
        let cancelBtn = makeButton(title: "Cancel",
                                   textColor: .white,
                                   bg: UIColor(hex: "#2C2C2E"),
                                   borderColor: UIColor(hex: "#48484A"))
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        let deleteBtn = makeButton(title: "Delete",
                                   textColor: .white,
                                   bg: UIColor(hex: "#FF3B30"),
                                   borderColor: nil)
        deleteBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        let buttonRow = UIStackView(arrangedSubviews: [cancelBtn, deleteBtn])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 12
        
        let stack = UIStackView(arrangedSubviews: [title, subtitle, buttonRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(24, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            stack.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 26),
            stack.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -22),
        ])
    }
    
    private func makeButton(title: String, textColor: UIColor, bg: UIColor, borderColor: UIColor?) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(textColor, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = bg
        b.layer.cornerRadius = 22
        if let border = borderColor {
            b.layer.borderWidth = 1
            b.layer.borderColor = border.cgColor
        }
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return b
    }
    
    private func animateIn() {
        UIView.animate(withDuration: 0.25) {
            self.blurView.alpha = 1
            self.dimView.alpha = 1
        }
        UIView.animate(withDuration: 0.4, delay: 0.05, usingSpringWithDamping: 0.72,
                       initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            self.popupView.alpha = 1
            self.popupView.transform = .identity
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.22, animations: {
            self.blurView.alpha = 0
            self.dimView.alpha = 0
            self.popupView.alpha = 0
            self.popupView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in completion() }
    }
    
    @objc private func cancelTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        animateOut { self.dismiss(animated: false) }
    }
    
    @objc private func confirmTapped() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        animateOut {
            self.dismiss(animated: false) { self.onConfirm?() }
        }
    }
}
