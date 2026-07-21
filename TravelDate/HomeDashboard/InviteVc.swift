//
//  InviteVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//
import UIKit
import Kingfisher
import Contacts

// MARK: - InviteVc
final class InviteVc: BaseClassVc {

    var inviteLink = ""
    var joinCode   = ""
    private var contactEmails = Set<String>()
    // MARK: - UI
    private let customHeaderView = UIView()
    private let searchContainer  = UIView()
    private let searchField      = UITextField()
    private let tableView        = UITableView()
    private let inviteCard       = UIView()
    private let linkLabel        = UILabel()
    private var suggestedHeader  : UIView!
    private var suggestedCountLabel = UILabel()

    // All users fetched from API (unfiltered)
    private var allUsers: [User] = []
    // Users that matched device contacts — this is what the table shows
    var users: [User]? = nil

    // Normalized set of phone numbers from the device address book
    private var contactNumbers = Set<String>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        inviteLink = "https://travelapp.com/join/" + joinCode
        view.backgroundColor = .appBg
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCustomHeader()
        setupSearch()
        setupInviteCard()
        setupSuggestedHeader()
        setupTableView()
        setupSkipButton()
        loadDataFast()

        let tap = UITapGestureRecognizer(target: self, action: #selector(shareInvite))
        inviteCard.addGestureRecognizer(tap)
        inviteCard.isUserInteractionEnabled = true
    }

    // MARK: - Custom Header
    private func setupCustomHeader() {
        customHeaderView.backgroundColor = .appBg
        customHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customHeaderView)

        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backBtn.tintColor = .white
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        customHeaderView.addSubview(backBtn)
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text      = "Invite Friends"
        titleLabel.textColor = .white
        titleLabel.setFont(.bold, size: 20.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text      = "Build your travel crew"
        subLabel.textColor = .appGrayText
        subLabel.setFont(.regular, size: 13.0)
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        customHeaderView.addSubview(titleLabel)
        customHeaderView.addSubview(subLabel)

        NSLayoutConstraint.activate([
            customHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customHeaderView.heightAnchor.constraint(equalToConstant: 60),

            backBtn.leadingAnchor.constraint(equalTo: customHeaderView.leadingAnchor, constant: 16),
            backBtn.centerYAnchor.constraint(equalTo: customHeaderView.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            backBtn.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: customHeaderView.topAnchor, constant: 10),

            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    // MARK: - Search Bar
    private func setupSearch() {
        // FIX: border color matches Figma subtle border, gap from header = 24
        searchContainer.backgroundColor    = .appCard
        searchContainer.layer.cornerRadius = 14
        searchContainer.layer.borderWidth  = 1
        searchContainer.layer.borderColor  = UIColor.appBorder.cgColor
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchContainer)

        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search friends...",
            attributes: [.foregroundColor: UIColor.appPlaceholder]
        )
        searchField.textColor = .white
        searchField.setFont(.medium, size: 14.0)
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchField)

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor  = .appGrayText
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchIcon)

        NSLayoutConstraint.activate([
            // FIX: 24pt gap from header (was 12)
            searchContainer.topAnchor.constraint(equalTo: customHeaderView.bottomAnchor, constant: 24),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 52),

            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchField.trailingAnchor.constraint(equalTo: searchIcon.leadingAnchor, constant: -8),

            searchIcon.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -16),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Invite Link Card
    private func setupInviteCard() {
        inviteCard.backgroundColor    = .appCard
        inviteCard.layer.cornerRadius = 16
        inviteCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inviteCard)

        // FIX: Share icon — use "square.and.arrow.up" nodes style circle bg with brownish-orange tint
        let iconBg = UIView()
        iconBg.backgroundColor    = UIColor.appOrange.withAlphaComponent(0.18)
        iconBg.layer.cornerRadius = 22
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        inviteCard.addSubview(iconBg)

        let shareIcon = UIImageView(image: UIImage(systemName: "square.and.arrow.up"))
        shareIcon.tintColor    = .appOrange
        shareIcon.contentMode  = .scaleAspectFit
        shareIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(shareIcon)

        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            shareIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            shareIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            shareIcon.widthAnchor.constraint(equalToConstant: 20),
            shareIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        let titleLbl = UILabel()
        titleLbl.text      = "Share Invite Link"
        titleLbl.textColor = .white
        titleLbl.setFont(.semiBold, size: 15.0)

        let subLbl = UILabel()
        subLbl.text          = "Anyone with this link can join your group"
        subLbl.textColor     = .appGrayText
        subLbl.setFont(.regular, size: 12.0)
        subLbl.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis    = .vertical
        textStack.spacing = 3

        let topRow = UIStackView(arrangedSubviews: [iconBg, textStack])
        topRow.axis      = .horizontal
        topRow.spacing   = 12
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false
        inviteCard.addSubview(topRow)

        // Divider
        let divider = UIView()
        divider.backgroundColor = .appBorder
        divider.translatesAutoresizingMaskIntoConstraints = false
        inviteCard.addSubview(divider)

        // FIX: Link row — url sits in its own dark inner container
        let linkContainer = UIView()
        linkContainer.backgroundColor    = UIColor.black.withAlphaComponent(0.25)
        linkContainer.layer.cornerRadius = 10
        linkContainer.layer.borderWidth  = 1
        linkContainer.layer.borderColor  = UIColor.appBorder.cgColor
        linkContainer.translatesAutoresizingMaskIntoConstraints = false
        inviteCard.addSubview(linkContainer)

        linkLabel.text          = inviteLink
        linkLabel.textColor     = .appGrayText
        linkLabel.setFont(.regular, size: 12.0)
        linkLabel.lineBreakMode = .byTruncatingTail
        linkLabel.numberOfLines = 1
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        linkContainer.addSubview(linkLabel)

        // FIX: Copy button — true pill/capsule shape
        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("Copy", for: .normal)
        copyBtn.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyBtn.tintColor          = .white
        copyBtn.backgroundColor    = .appOrange
        copyBtn.layer.cornerRadius = 20   // FIX: capsule — half of height 40
        copyBtn.titleLabel?.setFont(.semiBold, size: 13.0)
        copyBtn.imageEdgeInsets    = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        copyBtn.addTarget(self, action: #selector(copyLink), for: .touchUpInside)
        inviteCard.addSubview(copyBtn)

        NSLayoutConstraint.activate([
            // FIX: gap from search = 20pt (was 16)
            inviteCard.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 20),
            inviteCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inviteCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            topRow.topAnchor.constraint(equalTo: inviteCard.topAnchor, constant: 16),
            topRow.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor, constant: 14),
            topRow.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor, constant: -14),

            divider.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            // Link container + copy button row
            linkContainer.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            linkContainer.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor, constant: 14),
            linkContainer.trailingAnchor.constraint(equalTo: copyBtn.leadingAnchor, constant: -10),
            linkContainer.heightAnchor.constraint(equalToConstant: 40),
            linkContainer.bottomAnchor.constraint(equalTo: inviteCard.bottomAnchor, constant: -14),

            linkLabel.leadingAnchor.constraint(equalTo: linkContainer.leadingAnchor, constant: 10),
            linkLabel.trailingAnchor.constraint(equalTo: linkContainer.trailingAnchor, constant: -10),
            linkLabel.centerYAnchor.constraint(equalTo: linkContainer.centerYAnchor),

            copyBtn.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor, constant: -14),
            copyBtn.centerYAnchor.constraint(equalTo: linkContainer.centerYAnchor),
            copyBtn.widthAnchor.constraint(equalToConstant: 90),
            copyBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Suggested Header
    private func setupSuggestedHeader() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let titleLbl = UILabel()
        titleLbl.text      = "Suggested Friends"
        titleLbl.textColor = .white
        titleLbl.setFont(.semiBold, size: 16.0)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        suggestedCountLabel.text      = "0 friends"
        suggestedCountLabel.textColor = .appGrayText
        suggestedCountLabel.setFont(.regular, size: 14.0)
        suggestedCountLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(titleLbl)
        header.addSubview(suggestedCountLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: inviteCard.bottomAnchor, constant: 24),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            header.heightAnchor.constraint(equalToConstant: 24),

            titleLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            suggestedCountLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            suggestedCountLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        suggestedHeader = header
    }

    // MARK: - TableView
    private func setupTableView() {
        tableView.backgroundColor              = .appBg
        tableView.separatorStyle               = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.id)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: suggestedHeader.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }

    // MARK: - Skip Button
    private func setupSkipButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.setFont(.semiBold, size: 16.0)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions
    @objc private func shareInvite() {
        let message = """
        ✈️ Join my travel group on Trips!

        Use this link to join:
        \(inviteLink)

        Let's plan something awesome 🌍
        """
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityVC, animated: true)
    }

    @objc private func copyLink() {
        UIPasteboard.general.string = inviteLink
        // Optional: show toast
    }

    @objc private func skipTapped() {
        self.pushVC(TripsTabBarController.self, from: .Home) { vc in }
    }

    @objc private func searchChanged() {
        let query = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let base = allUsers.filter { contactNumbers.contains(normalizePhone($0.phone_number ?? "")) }
        users = query.isEmpty ? base : base.filter {
            ($0.name ?? "").lowercased().contains(query.lowercased())
        }
        tableView.reloadData()
        updateCountLabel()
    }

    // MARK: - Fast parallel load: API users + device contacts at the same time
    private func loadDataFast() {
        let group = DispatchGroup()

        group.enter()
        fetchDeviceContactNumbers { [weak self] numbers in
            self?.contactNumbers = numbers
            group.leave()
        }

        group.enter()
        request.getAllUsersAPi { [weak self] res, err, code in
            guard let self = self else { return }
            if code == 200 {
                self.allUsers = res?.data?.users ?? []
            } else {
                self.showAlert(err)
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.applyContactFilter()
        }
    }

    // Filters allUsers down to only those whose phone number is in the user's contact list
    private func applyContactFilter() {
        // NOTE: assumes `User.phone` holds the raw phone number string.
        // Rename below if your model uses a different property name.
        users = allUsers.filter { contactNumbers.contains(normalizePhone($0.phone_number ?? "")) }
        tableView.reloadData()
        updateCountLabel()
    }

    private func updateCountLabel() {
        suggestedCountLabel.text = "\(users?.count ?? 0) friends"
    }

    // MARK: - Contacts fetch (background, fast)
    private func fetchDeviceContactNumbers(completion: @escaping (Set<String>) -> Void) {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            DispatchQueue.global(qos: .userInitiated).async {
                completion(self.readContactNumbers(store))
            }
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] granted, _ in
                guard let self = self else { completion([]); return }
                if granted {
                    DispatchQueue.global(qos: .userInitiated).async {
                        completion(self.readContactNumbers(store))
                    }
                } else {
                    DispatchQueue.main.async { completion([]) }
                }
            }
        default:
            // denied / restricted
            DispatchQueue.main.async {
                self.showContactsPermissionAlert()
                completion([])
            }
        }
    }

    // Runs on a background queue — only fetches phone numbers, nothing else, for speed
    private func readContactNumbers(_ store: CNContactStore) -> Set<String> {
        var numbers = Set<String>()
        let keys = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
        fetchRequest.unifyResults = true

        do {
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                for phone in contact.phoneNumbers {
                    let normalized = self.normalizePhone(phone.value.stringValue)
                    if !normalized.isEmpty {
                        numbers.insert(normalized)
                    }
                }
            }
        } catch {
            print("Contacts fetch failed: \(error)")
        }
        return numbers
    }

    // Strips everything but digits, then compares on the last 10 digits
    // so "+91 98765-43210" and "9876543210" match each other.
    private func normalizePhone(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        guard digits.count >= 10 else { return digits }
        return String(digits.suffix(10))
    }

    private func showContactsPermissionAlert() {
        let alert = UIAlertController(
            title: "Contacts Access Needed",
            message: "Allow contacts access to find friends who are already on Trips.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - API
    func inviteFriend(at index: Int) {
        inviteUser(users?[index].id ?? "")
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    func inviteUser(_ id: String) {
        request.userId  = id
        request.groupId = joinCode
        request.inviteGroupAPi { err, code in }
    }
}

// MARK: - UITableViewDataSource
extension InviteVc: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.id, for: indexPath) as! FriendCell
        cell.configure(with: users![indexPath.row]) { [weak self] in
            self?.inviteFriend(at: indexPath.row)
        }
        return cell
    }
}

// MARK: - FriendCell
final class FriendCell: UITableViewCell {
    static let id = "FriendCell"

    private let avatarView    = UIImageView()
    private let nameLabel     = UILabel()
    private let usernameLabel = UILabel()
    private let inviteButton  = UIButton(type: .system)
    private var onInvite: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .appBg
        selectionStyle  = .none
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        let card = UIView()
        card.backgroundColor    = .appCard
        // FIX: corner radius 14 matches Figma card rounding
        card.layer.cornerRadius = 14
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.heightAnchor.constraint(equalToConstant: 72)
        ])

        // Avatar — circle
        avatarView.contentMode        = .scaleAspectFill
        avatarView.clipsToBounds      = true
        avatarView.layer.cornerRadius = 24
        avatarView.backgroundColor    = .appBorder
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(avatarView)

        // Name
        nameLabel.textColor = .white
        nameLabel.setFont(.semiBold, size: 15.0)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Username
        usernameLabel.textColor = .appGrayText
        usernameLabel.setFont(.regular, size: 12.0)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        textStack.axis    = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textStack)

        // FIX: Invite button — true pill shape, cornerRadius = half of height (38/2 = 19)
        inviteButton.layer.cornerRadius = 19
        inviteButton.layer.borderWidth  = 1.5
        inviteButton.titleLabel?.setFont(.medium, size: 13.0)
        inviteButton.imageEdgeInsets    = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.addTarget(self, action: #selector(inviteTapped), for: .touchUpInside)
        card.addSubview(inviteButton)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            avatarView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: inviteButton.leadingAnchor, constant: -8),

            inviteButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            inviteButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            inviteButton.widthAnchor.constraint(equalToConstant: 92),
            inviteButton.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    func configure(with friend: User, onInvite: @escaping () -> Void) {
        self.onInvite      = onInvite
        nameLabel.text     = friend.name
        usernameLabel.text = "@\(friend.userName?.lowercased().replacingOccurrences(of: " ", with: "") ?? "")\(friend.phone_number ?? "")"

        let url = URL(string: "\(APiConstant.base)\(friend.profile_image ?? "")")
        avatarView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            options: [.transition(.fade(0.3)), .cacheOriginalImage]
        )

        if friend.isInvited ?? false {
            inviteButton.setTitle("Invited", for: .normal)
            inviteButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            inviteButton.tintColor         = .appGrayText
            inviteButton.layer.borderColor = UIColor.appGrayText.cgColor
            inviteButton.backgroundColor   = .clear
        } else {
            inviteButton.setTitle("Invite", for: .normal)
            inviteButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
            inviteButton.tintColor         = .appOrange
            inviteButton.layer.borderColor = UIColor.appOrange.cgColor
            inviteButton.backgroundColor   = .clear
        }
    }

    @objc private func inviteTapped() { onInvite?() }
}
