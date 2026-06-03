//
//  ChatMessageVc.swift
//  TravelDate
//
//  The chat screen. Table of message bubbles + bottom input bar.
//  Pure API-driven (no sockets). Binds to ChatViewModel.
//
//  Init matches your existing call site in ChatVc:
//      ChatMessageVc(viewModel:participants:type:)
//

import UIKit

final class ChatMessageVc: BaseClassVc {

    // MARK: - UI
    private let headerView  = ChatHeaderView()
    private let tableView   = UITableView(frame: .zero, style: .plain)
    private let inputBar   = ChatInputView()
    private let refresh     = UIRefreshControl()

    private var inputBottom: NSLayoutConstraint!

    // MARK: - ViewModel
    private let viewModel: ChatViewModel

    // Optional header info (passed by caller; falls back to defaults)
    var roomTitle: String = "Chat"
    var memberCount: Int = 0
    var roomImageURL: String?

    // MARK: - Init (matches your call site)

    init(
        viewModel: ChatViewModel,
        participants: [String],
        roomId: String? = nil,
        roomTitle: String,
        type: ChatRoomType
    ) {
        self.viewModel = viewModel
        self.roomTitle = roomTitle

        super.init(nibName: nil, bundle: nil)

        self.viewModel.configure(
            participants: participants,
            type: type,
            roomId: roomId
        )
    }

   
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
        setupHeader()
        setupTable()
        setupInput()
        bindViewModel()
        registerKeyboard()
        viewModel.start()
        
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

        // Ignore other rooms
        guard roomId == viewModel.roomId else { return }

        viewModel.loadFirstPage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tripsTabBarController?.hideTabBar()
        ChatState.shared.isChatOpen = true
        ChatState.shared.activeRoomId = viewModel.roomId
    }
    
    
    private func scrollToBottom(animated: Bool) {
        guard !viewModel.sections.isEmpty else { return }

        let lastSection = viewModel.sections.count - 1
        let lastRow = viewModel.sections[lastSection].items.count - 1

        guard lastRow >= 0 else { return }

        let indexPath = IndexPath(row: lastRow, section: lastSection)

        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(
                at: indexPath,
                at: .bottom,
                animated: animated
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatState.shared.isChatOpen = false
        ChatState.shared.activeRoomId = nil
        // Restore the nav bar for the rest of the app.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        headerView.configure(
            title:    roomTitle,
            subtitle: memberCount > 0 ? "\(memberCount) members" : nil,
            imageURL: roomImageURL,
            showMore: true
        )

        headerView.onBack    = { [weak self] in self?.backTapped() }
        headerView.onProfile = { [weak self] in self?.handleProfileTapped() }
        headerView.onMore    = { [weak self] in self?.handleMoreTapped() }
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        refresh.tintColor = .white
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    private func setupInput() {
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        inputBottom = inputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottom,
        ])

        inputBar.onSend = { [weak self] text in
            self?.viewModel.send(text)
        }
        inputBar.onAttach = { [weak self] in
            // Hook up your existing attachment picker here.
            self?.view.endEditing(true)
        }
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onReload = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom(animated: true)
        }
        viewModel.onAppend = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom(animated: true)
        }
        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
        viewModel.onLoadingChanged = { [weak self] loading in
            if !loading { self?.refresh.endRefreshing() }
        }
    }

    // MARK: - Actions

    @objc private func pullToRefresh() {
        viewModel.refresh()
    }

    private func handleProfileTapped() {
        // Hook up: open profile / group info screen.
        view.endEditing(true)
    }

    private func handleMoreTapped() {
        // Hook up: open the "Chat Options" sheet (mute, trip dates, leave group).
        view.endEditing(true)
        
        if self.viewModel.roomType == .group {
            didTapManageGroup()
        }

    }
    
    
    @objc  func didTapManageGroup() {

        let participants = self.viewModel.participants

        let groupMembers: [GroupMember] = participants.enumerated().map { index, userId in

            let isCurrentUser = userId == User.curentUser?.id
            let isAdmin = index == 0

            return GroupMember(
                id: userId,
                name: isCurrentUser ? "You" : userId,
                role: isAdmin ? "Group Creator" : "Member",
                isAdmin: isAdmin,
                isCurrentUser: isCurrentUser,
                avatarColor: UIColor(hex: "#555555"),
                initials: String(userId.prefix(2)).uppercased()
            )
        }

        ManageGroupViewController.present(
            from: self,
            groupName: roomTitle,
            groupSubtitle: "\(groupMembers.count) travelers",
            members: groupMembers,
            onDelete: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        )
    }
    

    
    
    /*
     @objc private func didTapManageGroup() {
         ManageGroupViewController.present(
             from: self,
             groupName: "Bali Adventure Crew",
             groupSubtitle: "4 travelers",
             tripDates: "Apr 15 – Apr 25, 2026",
             onDelete: { [weak self] in
                 // group was deleted — pop back to the chat list
                 self?.navigationController?.popViewController(animated: true)
             }
         )
     }
     */

    // MARK: - Scroll helper

    
}

// MARK: - Table DataSource / Delegate

extension ChatMessageVc: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMessageCell.reuseId, for: indexPath
        ) as! ChatMessageCell

        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        cell.onRetryTapped = { [weak self] in
            self?.viewModel.retry(itemId: item.id)
        }
        return cell
    }

    // Date section header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = viewModel.sections[section].title
        label.textAlignment = .center
        label.font = UIFont(name: "Poppins-Medium", size: 12) ?? .systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        return label
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        28
    }

    // Load older when reaching the top
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 60 {
            viewModel.loadOlderIfNeeded()
        }
    }
}

// MARK: - Keyboard

private extension ChatMessageVc {

    func registerKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc func keyboardWillChange(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let overlap = view.bounds.height - frame.origin.y
        inputBottom.constant = overlap > 0 ? -(overlap - view.safeAreaInsets.bottom) : 0

        UIView.animate(withDuration: duration) { [weak self] in
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.scrollToBottom(animated: true)
        }
    }

    @objc func keyboardWillHide() {
        inputBottom.constant = 0
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
}

extension UIView {
    func pinEdges(to parent: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}
