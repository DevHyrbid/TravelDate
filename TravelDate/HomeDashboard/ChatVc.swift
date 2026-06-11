//
//  ChatVc.swift
//  TravelDate
//

import UIKit
import SDWebImage
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
    private var groupsData: [ChatData]         = []
    private var chatData:   [ChatData] = []

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
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleIncomingPush(_:)),
               name: .didReceiveChatMessage,
               object: nil
           )
    }
    
    @objc private func handleIncomingPush(_ notification: Notification) {

        guard let userInfo = notification.userInfo else { return }

        guard let roomId = userInfo["roomId"] as? String else { return }
        
        fetchAllData()
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
        request.getChatsInbox(0) { [weak self] model, msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                if code == 200 {
                    self.groupsData = model?.data ?? []
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
        request.getChatsInbox(1) { [weak self] model, msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                if code == 200 {
                    self.chatData = model?.data ?? []
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
        cell.lblTitle.text = model.name ?? ""
        cell.lblDesc.text  = "\(model.name ?? "")"
        cell.lblTime.text  = timeAgo(from: model.lastMessage?.createdAt ?? "")
        loadAvatarImage(into: cell.imgVw, urlString: model.image)
        cell.containerView.isHidden  = true
        cell.imgVw.clipsToBounds = true
        cell.imgVw.contentMode = .scaleToFill
        
    }

    func configureChatCell(_ cell: ChatTableViewCell, at indexPath: IndexPath) {

        let model = chatData[indexPath.row]
    
        if model.type == "MATCH" {

            let matchGroup = model

            cell.lblTitle.text = matchGroup.name ?? ""
            cell.lblDesc.text = matchGroup.lastMessage?.content ?? ""
            cell.lblTime.text = timeAgo(from: model.lastMessage?.createdAt ?? "")
            print(matchGroup.imageArr,"FGHJKL")
            if let images = matchGroup.imageArr,
               images.count >= 2 {

                cell.containerView.isHidden = false
                loadImage(cell.leftImageView, url: URL(string: images[0])!)
                loadImage(cell.rightImageView, url: URL(string: images[1])!)
                

            } else {

                let imageUrl = matchGroup.imageArr?.first ?? matchGroup.image ?? ""
                loadImage(cell.leftImageView, url: URL(string: imageUrl)!)
                

                cell.rightImageView.image = nil
            }

        } else {
            cell.containerView.isHidden = true

            cell.lblTitle.text = model.name
            cell.lblDesc.text = model.lastMessage?.content ?? ""
            cell.lblTime.text = timeAgo(from: model.createdAt ?? "")
            loadAvatarImage(
                into: cell.imgVw,
                urlString: model.image
            )
        }
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
    
    
   

    func loadMergedImage(into imageView: UIImageView, imageUrls: [String]) {

        guard !imageUrls.isEmpty else {
            imageView.image = nil
            return
        }

        // Single image
        if imageUrls.count == 1 {
            imageView.sd_setImage(with: URL(string: imageUrls[0]))
            return
        }

        let group = DispatchGroup()

        var leftImage: UIImage?
        var rightImage: UIImage?

        group.enter()
        SDWebImageManager.shared.loadImage(
            with: URL(string: imageUrls[0]),
            options: [],
            progress: nil
        ) { image, _, _, _, _, _ in
            leftImage = image
            group.leave()
        }

        group.enter()
        SDWebImageManager.shared.loadImage(
            with: URL(string: imageUrls[1]),
            options: [],
            progress: nil
        ) { image, _, _, _, _, _ in
            rightImage = image
            group.leave()
        }

        group.notify(queue: .main) {

            guard
                let left = leftImage,
                let right = rightImage
            else {
                return
            }

            let canvasSize = CGSize(width: 400, height: 400)

            UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)

            left.draw(in: CGRect(
                x: 0,
                y: 0,
                width: canvasSize.width / 2,
                height: canvasSize.height
            ))

            right.draw(in: CGRect(
                x: canvasSize.width / 2,
                y: 0,
                width: canvasSize.width / 2,
                height: canvasSize.height
            ))

            let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            imageView.image = mergedImage
        }
    }
}

// MARK: - Navigation

private extension ChatVc {

    func openGroupChat(at indexPath: IndexPath) {

        let group = groupsData[indexPath.row]

        let currentUserId = User.curentUser?.id ?? ""

        // Get all member ids
        var participantIds = group.members?.compactMap { $0.id } ?? []

        // Ensure current user exists
//        if !participantIds.contains(currentUserId) {
//            participantIds.append(currentUserId)
//        }
//
//        // Remove duplicates
//        participantIds = Array(Set(participantIds))

        let viewModel = ChatViewModel(
            currentUserId: currentUserId
        )

        // Open existing room directly if available
        let vc = ChatMessageVc(
            viewModel: viewModel,
            participants: group.members ?? [],
            roomId: group.chatId,
            roomTitle: "Group Chat",
            type: .group
        )

        vc.memberCount = participantIds.count

        navigationController?.pushViewController(vc, animated: true)
    }

    func openDirectChat(at indexPath: IndexPath) {

        let item = chatData[indexPath.row]

        if item.type == "MATCH" {

            let viewModel = ChatViewModel(
                currentUserId: User.curentUser?.id ?? ""
            )
            let vc = ChatMessageVc(
                viewModel: viewModel,
                participants: item.members ?? [],
                roomId: item.chatId,
                roomTitle: item.name ?? "",
                type: .group
            )

            navigationController?.pushViewController(vc, animated: true)
            return
        } else {
            
//            2B8392
            let viewModel = ChatViewModel(
                currentUserId: User.curentUser?.id ?? ""
            )
            let vc = ChatMessageVc(
                viewModel: viewModel,
                participants: item.members ?? [],
                roomId: item.chatId,
                roomTitle: item.name ?? "",
                type: .individual
            )

            navigationController?.pushViewController(vc, animated: true)
            return
        }

        // existing direct chat logic here
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

            self.request.deleteGroupAPi(group.chatId ?? "") { [weak self] _, code in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if code == 200 {
                        self.groupsData.remove(at: indexPath.row)
                        self.tblVw.deleteRows(at: [indexPath], with: .automatic)
                        self.lblNoData.isHidden = self.currentRowCount > 0
                        NotificationCenter.default.post(
                            name: .valueUpdated,
                            object: nil,
                            userInfo: ["value": "New Value"]
                        )
                        
                        
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


extension Notification.Name {
    static let valueUpdated = Notification.Name("valueUpdated")
}
