//
//  InviteVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//
import UIKit
import Kingfisher

// MARK: - InviteFriendsViewController
final class InviteVc: BaseClassVc {

  
  
    var  inviteLink = ""

    // MARK: - UI
    private let customHeaderView = UIView()
    private let searchContainer  = UIView()
    private let searchField      = UITextField()
    private let tableView        = UITableView()
    var joinCode = "ihxlca2e"
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
        getAllUsers()
        let tap = UITapGestureRecognizer(target: self, action: #selector(shareInvite))
        inviteCard.addGestureRecognizer(tap)
        inviteCard.isUserInteractionEnabled = true
    }

    // MARK: - Custom Header
    private func setupCustomHeader() {
        customHeaderView.backgroundColor = .appBg
        customHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customHeaderView)

        // Back button
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backBtn.tintColor = .white
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.widthAnchor.constraint(equalToConstant: 32).isActive  = true
        backBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customHeaderView.addSubview(backBtn)

        // Title label
        let titleLabel = UILabel()
        titleLabel.text      = "Invite Friends"
        titleLabel.textColor = .white
        titleLabel.font      = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle label
        let subLabel = UILabel()
        subLabel.text      = "Build your travel crew"
        subLabel.textColor = .appGrayText
        subLabel.font      = .systemFont(ofSize: 13)
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        customHeaderView.addSubview(titleLabel)
        customHeaderView.addSubview(subLabel)

        NSLayoutConstraint.activate([
            customHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customHeaderView.heightAnchor.constraint(equalToConstant: 56),

            backBtn.leadingAnchor.constraint(equalTo: customHeaderView.leadingAnchor, constant: 16),
            backBtn.centerYAnchor.constraint(equalTo: customHeaderView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: customHeaderView.topAnchor, constant: 10),

            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }
    
    @objc private func shareInvite() {
        
        let message = """
        ✈️ Join my travel group on TravelDate!
        
        Use this link to join:
        \(inviteLink)
        
        Let’s plan something awesome 🌍
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }

    // MARK: - Search Bar
    private func setupSearch() {
        searchContainer.backgroundColor   = .appCard
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
        searchField.font      = .systemFont(ofSize: 14)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchField)

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor  = .appGrayText
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.widthAnchor.constraint(equalToConstant: 18).isActive  = true
        searchIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        searchContainer.addSubview(searchIcon)

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: customHeaderView.bottomAnchor, constant: 12),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 52),

            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchField.trailingAnchor.constraint(equalTo: searchIcon.leadingAnchor, constant: -8),

            searchIcon.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -16),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
        ])
    }

    // MARK: - Invite Link Card
    private let inviteCard   = UIView()
    private let linkLabel    = UILabel()
    
    var users: [User]? = nil
    
    private func setupInviteCard() {
        inviteCard.backgroundColor    = .appCard
        inviteCard.layer.cornerRadius = 16
        inviteCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inviteCard)

        // Share icon circle
        let iconBg = UIView()
        iconBg.backgroundColor    = UIColor.appOrange.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 20
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 40).isActive  = true
        iconBg.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let shareIcon = UIImageView(image: UIImage(systemName: "arrowshape.turn.up.right"))
        shareIcon.tintColor      = .appOrange
        shareIcon.contentMode    = .scaleAspectFit
        shareIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(shareIcon)
        NSLayoutConstraint.activate([
            shareIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            shareIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            shareIcon.widthAnchor.constraint(equalToConstant: 18),
            shareIcon.heightAnchor.constraint(equalToConstant: 18)
        ])

        // Text stack
        let titleLbl = UILabel()
        titleLbl.text      = "Share Invite Link"
        titleLbl.textColor = .white
        titleLbl.font      = .systemFont(ofSize: 15, weight: .semibold)

        let subLbl = UILabel()
        subLbl.text      = "Anyone with this link can join your group"
        subLbl.textColor = .appGrayText
        subLbl.font      = .systemFont(ofSize: 12)

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

        // Link row
        linkLabel.text      = inviteLink
        linkLabel.textColor = .appGrayText
        linkLabel.font      = .systemFont(ofSize: 12)
        linkLabel.translatesAutoresizingMaskIntoConstraints = false

        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("Copy", for: .normal)
        copyBtn.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyBtn.tintColor        = .white
        copyBtn.backgroundColor  = .appOrange
        copyBtn.layer.cornerRadius = 10
        copyBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        copyBtn.widthAnchor.constraint(equalToConstant: 84).isActive  = true
        copyBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        // icon left padding
        copyBtn.imageEdgeInsets  = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        copyBtn.addTarget(self, action: #selector(copyLink), for: .touchUpInside)

        let linkRow = UIStackView(arrangedSubviews: [linkLabel, copyBtn])
        linkRow.axis         = .horizontal
        linkRow.alignment    = .center
        linkRow.spacing      = 8
        linkRow.translatesAutoresizingMaskIntoConstraints = false
        inviteCard.addSubview(linkRow)

        NSLayoutConstraint.activate([
            inviteCard.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 16),
            inviteCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inviteCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            topRow.topAnchor.constraint(equalTo: inviteCard.topAnchor, constant: 14),
            topRow.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor, constant: 14),
            topRow.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor, constant: -14),

            divider.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            linkRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            linkRow.leadingAnchor.constraint(equalTo: inviteCard.leadingAnchor, constant: 14),
            linkRow.trailingAnchor.constraint(equalTo: inviteCard.trailingAnchor, constant: -14),
            linkRow.bottomAnchor.constraint(equalTo: inviteCard.bottomAnchor, constant: -14)
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
        titleLbl.font      = .systemFont(ofSize: 16, weight: .semibold)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let countLbl = UILabel()
        countLbl.text      = "\(users?.count) friends"
        countLbl.textColor = .appGrayText
        countLbl.font      = .systemFont(ofSize: 13)
        countLbl.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(titleLbl)
        header.addSubview(countLbl)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: inviteCard.bottomAnchor, constant: 20),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            header.heightAnchor.constraint(equalToConstant: 24),

            titleLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            countLbl.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            countLbl.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        // store reference for tableView top anchor
        suggestedHeader = header
    }

    private var suggestedHeader: UIView!

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
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

   
    @objc private func copyLink() {
        UIPasteboard.general.string = inviteLink
        // Optional: show toast
    }

    @objc private func skipTapped() {
        
        self.pushVC(TripsTabBarController.self, from: .Home) { vc in
            
        }
    }

    func inviteFriend(at index: Int) {
//        users[index].isInvited.toggle()
        inviteUser(users?[index].id ?? "")
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        
    }
    
    
    func getAllUsers() {
        request.getAllUsersAPi { res, err, code in
            if code == 200 {
                
                DispatchQueue.main.async {
                    if res?.data?.users?.count != 0 {
                        self.users = res?.data?.users ?? []
                        self.tableView.reloadData()
                        
                        
                      
                    }
                }
                
            } else {
                self.showAlert(err)
            }
        }
    }
    
    func inviteUser(_ id:String){
        request.userId = id
        request.groupId = joinCode
        request.inviteGroupAPi { err, code in
            
        }
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

    private let avatarView   = UIImageView()
    private let nameLabel    = UILabel()
    private let usernameLabel = UILabel()
    private let inviteButton  = UIButton(type: .system)
    private var onInvite: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor      = .appBg
        selectionStyle       = .none
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        // Container card
        let card = UIView()
        card.backgroundColor    = .appCard
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])

        // Avatar
        avatarView.contentMode       = .scaleAspectFill
        avatarView.clipsToBounds     = true
        avatarView.layer.cornerRadius = 24
        avatarView.backgroundColor   = .appBorder
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(avatarView)

        // Name
        nameLabel.textColor = .white
        nameLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Username
        usernameLabel.textColor = .appGrayText
        usernameLabel.font      = .systemFont(ofSize: 13)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        textStack.axis    = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textStack)

        // Invite button
        inviteButton.setTitle("Invite", for: .normal)
        inviteButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        inviteButton.tintColor         = .appOrange
        inviteButton.layer.borderWidth  = 1.5
        inviteButton.layer.borderColor  = UIColor.appOrange.cgColor
        inviteButton.layer.cornerRadius = 20
        inviteButton.titleLabel?.font   = .systemFont(ofSize: 13, weight: .semibold)
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
            inviteButton.widthAnchor.constraint(equalToConstant: 88),
            inviteButton.heightAnchor.constraint(equalToConstant: 38),

            card.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    func configure(with friend: User, onInvite: @escaping () -> Void) {
        self.onInvite       = onInvite
        nameLabel.text      = friend.name
        usernameLabel.text  = friend.name
        let url = URL(string: friend.profile_image ?? "")
        avatarView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"), // optional
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]
        )

        if friend.isInvited ?? false {
            inviteButton.setTitle("Invited", for: .normal)
            inviteButton.tintColor        = .appGrayText
            inviteButton.layer.borderColor = UIColor.appGrayText.cgColor
            inviteButton.backgroundColor  = .clear
            inviteButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        } else {
            inviteButton.setTitle("Invite", for: .normal)
            inviteButton.tintColor        = .appOrange
            inviteButton.layer.borderColor = UIColor.appOrange.cgColor
            inviteButton.backgroundColor  = .clear
            inviteButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        }
    }

    @objc private func inviteTapped() {
        onInvite?()
    }
    
    
   
}
