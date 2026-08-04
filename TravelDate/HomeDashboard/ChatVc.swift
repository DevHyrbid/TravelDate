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

final class ChatVc: BaseClassVc, UITextFieldDelegate {

    // MARK: - IBOutlets
    @IBOutlet private weak var vwGlass:UIView!

    @IBOutlet private weak var tblVw:       UITableView!
    @IBOutlet private weak var btnLeft:       UIButton!
    @IBOutlet private weak var btnRight:       UIButton!
    @IBOutlet private weak var lblNoData:   UILabel!
    @IBOutlet private weak var lblTitle:    UILabel!
    @IBOutlet private weak var txtSearch:    UITextField!
    // MARK: - Data
    private var groupsData: [ChatData]         = []
    private var chatData:   [ChatData] = []
    private var filteredGroupsData: [ChatData] = []
    private var filteredChatData: [ChatData] = []

    // MARK: - State
    private var selectedSegment: ChatSegment = .groups {
        didSet {
            guard selectedSegment != oldValue else { return }
            refreshTableView()
        }
    }

    // MARK: - Computed
    private var currentData: [ChatData] {
        switch selectedSegment {
        case .groups:
            return txtSearch.text?.isEmpty == false ? filteredGroupsData : groupsData
        case .chats:
            return txtSearch.text?.isEmpty == false ? filteredChatData : chatData
        }
    }

    private var currentRowCount: Int {
        currentData.count
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
        txtSearch.attributedPlaceholder = NSAttributedString(
            string: "Search by group name",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
        )
        txtSearch.font = AppFont.medium(14.0)
        txtSearch.textColor = .white
        txtSearch.delegate = self
        txtSearch.addTarget(self,
                            action: #selector(searchTextChanged(_:)),
                            for: .editingChanged)
//     nvwGlass)
    }
    
    @objc
    private func searchTextChanged(_ textField: UITextField) {
        filterData(with: textField.text ?? "")
    }
    
    private func filterData(with text: String) {

        let keyword = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if keyword.isEmpty {
            filteredGroupsData.removeAll()
            filteredChatData.removeAll()
            refreshTableView()
            return
        }

        switch selectedSegment {

        case .groups:

            filteredGroupsData = groupsData.filter {

                ($0.name ?? "")
                    .localizedCaseInsensitiveContains(keyword)

                ||

                ($0.lastMessage?.content ?? "")
                    .localizedCaseInsensitiveContains(keyword)
            }

        case .chats:

            filteredChatData = chatData.filter {

                ($0.name ?? "")
                    .localizedCaseInsensitiveContains(keyword)

                ||

                ($0.lastMessage?.content ?? "")
                    .localizedCaseInsensitiveContains(keyword)
            }
        }

        refreshTableView()
    }
    
    @objc private func handleIncomingPush(_ notification: Notification) {

//        guard let userInfo = notification.userInfo else { return }
//
//        guard let _ = userInfo["roomId"] as? String else { return }
        
        fetchAllData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.showTabBar()
        fetchAllData()
        // ✅ NO API or socket calls here
    }
    
    func setupBtn(_ sender: UIButton) {

        if sender == btnLeft {

            // My Group Selected
            btnLeft.setImage(UIImage(named: "1-1"), for: .normal)
            btnRight.setImage(UIImage(named: "1-2"), for: .normal)
            

            selectedSegment = .groups

        } else {

            // Match Groups Selected
            btnLeft.setImage(UIImage(named: "2-2"), for: .normal)
            btnRight.setImage(UIImage(named: "2-1"), for: .normal)

            selectedSegment = .chats
        }
        btnRight.imageView?.contentMode = .scaleAspectFill
        btnLeft.imageView?.contentMode = .scaleAspectFill
        self.tblVw.reloadData()
    }
    
    @IBAction func btnSegmentTapped(_ sender: UIButton) {
        setupBtn(sender)
    }

    // MARK: - UI Setup

    private func configureUI() {
        lblTitle.setFont(.medium, size: 18.0)
        addGradient()
//        configureSegmentControl()
        
    }
    
    func registerNibs() {
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
                    
                    self.groupsData = (model?.data ?? []).filter { $0.isDeleted ?? 1 == 0 }
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
        if selectedSegment == .chats {
            let block = UIContextualAction(
                style: .destructive,
                title: "Delete Chat", handler: {_,_,_ in
                    let model = self.chatData[indexPath.row]
                    print("Chat ID:", model.chatId ?? "nil")
                    self.request.type = "MATCH"
                    self.request.leaveGroupAPi(model.chatId ?? "") { err, code in
                        if code == 200 {
                            self.fetchAllData()
                        }
                    }
                }
            )
             
            let report = UIContextualAction(
                style: .destructive,
                title: "Report", handler: {_,_,_ in
                    self.didTapReportOption(indexPath)
                }
            )
            let config = UISwipeActionsConfiguration(actions: [block,report])
            config.performsFirstActionWithFullSwipe = false
            return config
        } else {            
            guard selectedSegment == .groups else { return nil }
            return makeGroupSwipeActions(at: indexPath)
        }
    }
    
    @objc private func didTapBlockOption(_ indx:IndexPath) {
        let model = chatData[indx.row]
        let popup = BlockReportPopupViewController(mode: .block(username: model.name ?? "",id:model.chatId ?? ""), delegate: self)
        
        
        present(popup, animated: false)  // animated: false zaroori hai, popup khud animate karta hai
    }

    @objc private func didTapReportOption(_ indx:IndexPath) {
        let model = chatData[indx.row]
        let popup = BlockReportPopupViewController(mode: .report(username: model.name ?? "",id:model.groupDetails?.id ?? ""), delegate: self)
        present(popup, animated: false)
    }
}
extension ChatVc: BlockReportPopupDelegate {

    func blockReportPopup(_ popup: BlockReportPopupViewController, didConfirmBlockUser username: String) {
        // yahan apna block API call karo
//        BlockService.blockUser(username: username) { success in
//            if success {
//                // UI update, navigate back, etc.
//            }
//        }
    }

    func blockReportPopup(_ popup: BlockReportPopupViewController, didSubmitReportForUser username: String, reason: String, otherText: String?) {
        // yahan apna report API call karo
//        ReportService.reportUser(username: username, reason: reason, details: otherText) { success in
//            if success {
//                self.showToast("Report submitted")
//            }
//        }
    }

    func blockReportPopupDidCancel(_ popup: BlockReportPopupViewController) {
        // optional — cancel hone pe kuch karna ho to
        popup.dismiss(animated: true)
    }
}

// MARK: - Cell Configuration

private extension ChatVc {

    func configureGroupCell(_ cell: ChatTableViewCell, at indexPath: IndexPath) {

        let model = currentData[indexPath.row]
        
        if model.members?.first?.id == User.curentUser?.id{
            if model.members?.first?.role == "ADMIN" {
                
            }
        }
        cell.lblTitle.text = model.name ?? ""
        if model.lastMessage?.content == "" {
            cell.lblDesc.text = "No msg"
        } else {
            cell.lblDesc.text  = "\(model.lastMessage?.content ?? "") • \(changeDate(model.lastMessage?.createdAt ?? ""))"
        }
        cell.lblTime.text  = timeAgo(from: model.lastMessage?.createdAt ?? "")
        loadAvatarImage(into: cell.imgVw, urlString: model.image)
        cell.containerView.isHidden  = true
        cell.imgVw.clipsToBounds = true
        cell.imgVw.contentMode = .scaleToFill
        
    }
    
    
    func changeDate(_ str:String) -> String {
        let isoString = str

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE"   // Mon, Tue, Wed, Thu, Fri, Sat, Sun

            let day = formatter.string(from: date)
            print(day) // Sat
            return day
        }
        return ""
    }
    
    func configureChatCell(_ cell: ChatTableViewCell, at indexPath: IndexPath) {

        let model = currentData[indexPath.row]
        
        if model.type == "MATCH" {
            
            let matchGroup = model
            print(matchGroup.imageArr,"now new msg")
            cell.lblTitle.text = matchGroup.name ?? ""
            cell.lblDesc.text = matchGroup.lastMessage?.content ?? ""
            cell.lblTime.text = timeAgo(from: model.lastMessage?.createdAt ?? "")
            cell.leftImageView.isHidden = false
            
            let imageUrl = matchGroup.imageArr?[0] ??  ""
            loadImage(cell.leftImageView, url: URL(string: imageUrl)!)
            
            cell.rightImageView.isHidden = true
            print(indexPath.row)
            print(matchGroup.imageArr ?? [])
            print(matchGroup.imageArr?[1] ?? "")
            cell.containerView.isHidden = false
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
        let participantIds = group.members?.compactMap { $0.id } ?? []

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
            roomTitle: group.name ?? "",
            type: .group
        )
        vc.roomImageURL =  group.image ?? ""
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

        guard let currentUserId = User.curentUser?.id,
              let currentMember = group.members?.first(where: { $0.userId == currentUserId }) else {
            return UISwipeActionsConfiguration(actions: [])
        }
        print(currentMember,"groupsData",group)
        let title = currentMember.role == "ADMIN" ? "Delete" : "Leave"
        let style: UIContextualAction.Style = currentMember.role == "ADMIN" ? .destructive : .destructive

        let action = UIContextualAction(style: style, title: title) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            if currentMember.role == "ADMIN" {
                // Delete Group API
                self.request.deleteGroupAPi(group.groupDetails?.id ?? "") { [weak self] _, code in
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

                        completion(code == 200)
                    }
                }
            } else {
                // Leave Group API
                self.request.type = "GROUP"
                self.request.leaveGroupAPi(group.chatId ?? "") { err, code in
                    if code == 200 {
                        self.fetchAllData()
                    }
                }
            }
        }

        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

// MARK: - Date Helper

 extension UIViewController {

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
