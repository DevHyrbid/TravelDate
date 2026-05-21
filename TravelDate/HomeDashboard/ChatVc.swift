//
//  ChatVc.swift
//  TravelDate
//

import UIKit

// MARK: - Segment Enum

enum ChatSegment: Int, CaseIterable {
    case groups = 0
    case chats  = 1

    var title: String {
        switch self {
        case .groups: return "Groups"
        case .chats:  return "Chats"
        }
    }
}

// MARK: - ChatVc

final class ChatVc: BaseClassVc {

    // MARK: - IBOutlets
    @IBOutlet private weak var tblVw:       UITableView!
    @IBOutlet private weak var btnSegment:  UISegmentedControl!
    @IBOutlet private weak var lblNoData:   UILabel!
    @IBOutlet private weak var lblTitle:    UILabel!

    // MARK: - Data
    private var groupsData: [Group]         = []
    private var chatData:   [ChatRoomModel] = []

    // MARK: - State
    private var selectedSegment: ChatSegment = .groups {
        didSet {
            guard selectedSegment != oldValue else { return }
            refreshTableView()
        }
    }

    // MARK: - Computed
    private var currentRowCount: Int {
        switch selectedSegment {
        case .groups: return groupsData.count
        case .chats:  return chatData.count
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        registerNibs()
        fetchAllData()        // ← API called ONCE here
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.showTabBar()
        // ✅ NO API or socket calls here
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSegmentUI()
    }

    // MARK: - UI Setup

    private func configureUI() {
        lblTitle.setFont(.medium, size: 18.0)
        addGradient()
        configureSegmentControl()
    }

    private func configureSegmentControl() {
        btnSegment.setTitleTextAttributes([
            .font:            UIFont(name: "Poppins-SemiBold", size: 14)!,
            .foregroundColor: UIColor.gray
        ], for: .normal)

        btnSegment.setTitleTextAttributes([
            .font:            UIFont(name: "Poppins-SemiBold", size: 14)!,
            .foregroundColor: UIColor.white
        ], for: .selected)

        btnSegment.addTarget(self,
                             action: #selector(segmentChanged(_:)),
                             for: .valueChanged)
    }

    private func registerNibs() {
        tblVw.register(ChatTableViewCell.self)
        tblVw.delegate   = self
        tblVw.dataSource = self
    }

    // MARK: - Segment Action

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedSegment = ChatSegment(rawValue: sender.selectedSegmentIndex) ?? .groups
        // ✅ NO socket calls — just reload table
    }

    // MARK: - Data Fetch (ONCE)

    private func fetchAllData() {
        fetchGroups()
        fetchChats()
    }

    private func fetchGroups() {
        request.getGroups(0) { [weak self] model, msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                if code == 200 {
                    self.groupsData = model?.data?.groups ?? []
                    if self.selectedSegment == .groups {
                        self.refreshTableView()
                    }
                } else {
                    self.showAlert(msg)
                }
            }
        }
    }

    private func fetchChats() {
        request.getChatRooms { [weak self] response, msg, errCode in
            guard let self else { return }
            DispatchQueue.main.async {
                if errCode == 200 {
                    self.chatData = response ?? []
                    if self.selectedSegment == .chats {
                        self.refreshTableView()
                    }
                }
            }
        }
    }

    // MARK: - Table Refresh

    private func refreshTableView() {
        tblVw.reloadData()
        lblNoData.isHidden = currentRowCount > 0
    }

    // MARK: - Scroll

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }

    // MARK: - IBActions

    @IBAction private func btnBack(_ sender: UIButton) {
        backTapped()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension ChatVc: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        currentRowCount
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTableViewCell = tableView.dequeue(ChatTableViewCell.self, for: indexPath)
        switch selectedSegment {
        case .groups: configureGroupCell(cell, at: indexPath)
        case .chats:  configureChatCell(cell, at: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 90 }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch selectedSegment {
        case .groups: openGroupChat(at: indexPath)
        case .chats:  openDirectChat(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        guard selectedSegment == .groups else { return nil }
        return makeGroupSwipeActions(at: indexPath)
    }
}

// MARK: - Cell Configuration

private extension ChatVc {

    func configureGroupCell(_ cell: ChatTableViewCell, at indexPath: IndexPath) {
        let model = groupsData[indexPath.row]
        cell.lblTitle.text = model.groupTitle ?? ""
        cell.lblDesc.text  = "\(model.creator?.name ?? "") · Thu"
        cell.lblTime.text  = timeAgo(from: model.createdAt ?? "")
        loadAvatarImage(into: cell.imgVw, urlString: model.coverImage)
    }

    func configureChatCell(_ cell: ChatTableViewCell, at indexPath: IndexPath) {
        let model = chatData[indexPath.row]

        let senderName = model.lastMessage?.sender?.name
            ?? model.participants?.first?.name
            ?? "Unknown"

        cell.lblTitle.text = senderName
        cell.lblDesc.text  = model.lastMessage?.content ?? "No messages yet"
        cell.lblTime.text  = timeAgo(from: model.lastMessage?.createdAt ?? model.createdAt ?? "")
        loadAvatarImage(into: cell.imgVw, urlString: model.participants?.first?.profileImage)
    }

    func loadAvatarImage(into imageView: UIImageView, urlString: String?) {
        imageView.contentMode        = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds      = true

        if let str = urlString, let url = URL(string: str) {
            loadImage(imageView, url: url)
        } else {
            imageView.image = UIImage(named: "User")
        }
    }
}

// MARK: - Navigation

private extension ChatVc {

    func openGroupChat(at indexPath: IndexPath) {
        let group  = groupsData[indexPath.row]
        let chatVc = ChatMessageVc()

        chatVc.roomId       = group.roomId       ?? ""
        chatVc.roomTitle    = group.groupTitle   ?? "Chat"
        chatVc.groupId      = group.id           ?? ""
        chatVc.roomType     = .group
        chatVc.memberCount  = group.maxGroupSize ?? 0
        chatVc.participants = group.members?.compactMap { $0.id } ?? []

        #if DEBUG
        print("🚀 Group Chat → roomId: \(chatVc.roomId) groupId: \(chatVc.groupId)")
        #endif

        navigationController?.pushViewController(chatVc, animated: true)
    }

    func openDirectChat(at indexPath: IndexPath) {
        let chat   = chatData[indexPath.row]
        let chatVc = ChatMessageVc()

        chatVc.roomId    = chat.id ?? ""
        chatVc.roomTitle = chat.lastMessage?.sender?.name
            ?? chat.participants?.first?.name
            ?? "Chat"
        chatVc.roomType     = .individual
        chatVc.participants = chat.participants?.compactMap { $0.id } ?? []

        #if DEBUG
        print("🚀 Direct Chat → roomId: \(chatVc.roomId)")
        #endif

        navigationController?.pushViewController(chatVc, animated: true)
    }
}

// MARK: - Swipe Actions

private extension ChatVc {

    func makeGroupSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let group = groupsData[indexPath.row]

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }

            self.request.deleteGroupAPi(group.id ?? "") { [weak self] _, code in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if code == 200 {
                        self.groupsData.remove(at: indexPath.row)
                        self.tblVw.deleteRows(at: [indexPath], with: .automatic)
                        self.lblNoData.isHidden = self.currentRowCount > 0
                    }
                }
            }
            completion(true)
        }

        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

// MARK: - Segment UI

private extension ChatVc {

    func setupSegmentUI() {
        guard btnSegment.tag == 0 else { return }
        btnSegment.tag = 1

        let inset: CGFloat = 4

        btnSegment.backgroundColor    = UIColor.white.withAlphaComponent(0.06)
        btnSegment.layer.cornerRadius = 25.5
        btnSegment.layer.cornerCurve  = .continuous
        btnSegment.clipsToBounds      = true

        btnSegment.setBackgroundImage(UIImage(), for: .normal,      barMetrics: .default)
        btnSegment.setBackgroundImage(UIImage(), for: .selected,    barMetrics: .default)
        btnSegment.setBackgroundImage(UIImage(), for: .highlighted, barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState:   .normal,
            barMetrics:          .default
        )

        let pillSize = CGSize(
            width:  (btnSegment.frame.width / CGFloat(btnSegment.numberOfSegments)) - (inset * 2),
            height: btnSegment.frame.height - (inset * 2)
        )

        let pillImage = UIGraphicsImageRenderer(size: pillSize).image { _ in
            UIColor.themeOrange.setFill()
            UIBezierPath(
                roundedRect:  CGRect(origin: .zero, size: pillSize),
                cornerRadius: pillSize.height / 2
            ).fill()
        }

        let stretchable = pillImage.resizableImage(
            withCapInsets: UIEdgeInsets(
                top: 0, left: pillSize.height / 2,
                bottom: 0, right: pillSize.height / 2
            ),
            resizingMode: .stretch
        )
        btnSegment.setBackgroundImage(stretchable, for: .selected, barMetrics: .default)

        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font:            UIFont(name: "Poppins-Medium", size: 15.0)!
        ], for: .normal)

        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font:            UIFont(name: "Poppins-SemiBold", size: 15.0)!
        ], for: .selected)

        btnSegment.selectedSegmentIndex = 0

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for subview in self.btnSegment.subviews {
                subview.layer.cornerRadius = (self.btnSegment.frame.height - (inset * 2)) / 2
                subview.layer.cornerCurve  = .continuous
                subview.clipsToBounds      = true
            }
        }
    }
}

// MARK: - Date Helper

private extension ChatVc {

    func timeAgo(from isoString: String) -> String {
        let formatter          = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else { return "—" }

        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case ..<60:     return "just now"
        case ..<3600:   return "\(seconds / 60)m ago"
        case ..<86400:  return "\(seconds / 3600)h ago"
        case ..<604800: return "\(seconds / 86400)d ago"
        default:        return "\(seconds / 604800)w ago"
        }
    }
}
