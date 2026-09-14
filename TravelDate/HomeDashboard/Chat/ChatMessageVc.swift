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
//  CHANGED (all surgical, same architecture as before):
//   1. Pagination no longer jumps the user's scroll position. Before
//      calling into the older-messages fetch we snapshot contentSize +
//      contentOffset; when ChatViewModel.onOlderPrepended fires (only for
//      the prepend case, not every reload) we reloadData() once and then
//      restore the equivalent offset using the delta in contentSize. See
//      triggerLoadOlderIfNeeded()/bindViewModel().
//   2. `ImagePreviewVC(image: image!)` force-unwrap removed — tapping an
//      image whose UIImage hasn't loaded yet now safely does nothing
//      instead of being a crash waiting to happen.
//   3. Video upload's `Data(contentsOf: localURL)` moved off the main
//      thread — large video files no longer freeze the chat UI while
//      being read into memory for upload.
//

import UIKit
import IQKeyboardManagerSwift
final class ChatMessageVc: BaseClassVc {

    // MARK: - UI
    private let headerView  = ChatHeaderView()
    private let tableView   = UITableView(frame: .zero, style: .plain)
    private let inputBar   = ChatInputView()
    private let refresh     = UIRefreshControl()

    private var inputBottom: NSLayoutConstraint!

    // Bridges UIImagePickerControllerDelegate's callback into
    // vidUpload()'s closure-based style (see extension at bottom of file).
    private var videoPickerCompletion: ((URL?) -> Void)?

    // NEW — pagination scroll-position anchoring (fix #1 above).
    private var isLoadingOlder = false
    private var pendingOldContentSize: CGSize = .zero
    private var pendingOldOffset: CGPoint = .zero

    // MARK: - ViewModel
    private let viewModel: ChatViewModel

    // Optional header info (passed by caller; falls back to defaults)
    var roomTitle: String = "Chat"
    var memberCount: Int = 0
    var roomImageURL: String?

    // MARK: - Init (matches your call site)

    init(
        viewModel: ChatViewModel,
        participants: [UserMembers],
        roomId: String? = nil,
        roomTitle: String,
        type: ChatRoomType
    ) {
        self.viewModel = viewModel
        self.roomTitle = roomTitle
        self.viewModel.roomType = type

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
        if #available(iOS 15.0, *) {
            view.keyboardLayoutGuide.followsUndockedKeyboard = false
        }

        additionalSafeAreaInsets.bottom = 0
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.contentInset.bottom = inputBar.frame.height
        tableView.scrollIndicatorInsets.bottom = inputBar.frame.height
    }

    @objc private func handleIncomingPush(_ notification: Notification) {

        guard let userInfo = notification.userInfo else { return }

        guard let roomId = userInfo["chatRoomId"] as? String else { return }

        // Ignore other rooms
        guard roomId == viewModel.roomId else { return }

        viewModel.loadFirstPage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // FIXED (real bug — this is what was leaving another screen's
        // content frozen and visible behind the chat): hiding the nav bar
        // with animated:true at the exact same time the push transition
        // itself is animating is a well-known way to leave a stray
        // transition snapshot of the PREVIOUS view controller stuck in
        // the hierarchy — it doesn't get cleaned up because two
        // animations are racing over the same view. It has nothing to do
        // with cell/row sizing; it's a navigation-transition issue.
        // Always doing this transition-less (animated: false) removes
        // that race entirely — the bar still ends up hidden, just without
        // fighting the push/pop animation for it.
        navigationController?.setNavigationBarHidden(true, animated: false)
        tripsTabBarController?.hideTabBar()
        ChatState.shared.isChatOpen = true
        ChatState.shared.activeRoomId = viewModel.roomId
        
       
            IQKeyboardManager.shared.isEnabled = false
    }
    
    
    private func scrollToBottom(animated: Bool) {
        guard !viewModel.sections.isEmpty else { return }

        // `scrollToRow(at:.bottom)` right after `reloadData()` was the cause
        // of the visible "jump"/gap after sending a message: self-sizing
        // cells (automaticDimension) haven't resolved their REAL height yet
        // on the very first layout pass, only `estimatedRowHeight`, so
        // scrollToRow lands at a position based on guessed heights and the
        // screen has to visibly snap once the real heights come in.
        //
        // Forcing layout first makes UIKit resolve every visible/needed
        // cell's true height before we compute where "bottom" actually is,
        // so we scroll to the right place in one go instead of jumping.
        // NOTE: this is now cheap and correct with the new ChatMessageCell
        // — attachment rows size themselves synchronously in configure(),
        // so this layout pass isn't waiting on any network call either.
        tableView.layoutIfNeeded()

        let bottomInset = tableView.adjustedContentInset.bottom
        let maxOffsetY = max(
            -tableView.adjustedContentInset.top,
            tableView.contentSize.height - tableView.bounds.height + bottomInset
        )

        tableView.setContentOffset(
            CGPoint(x: 0, y: maxOffsetY),
            animated: animated
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatState.shared.isChatOpen = false
        ChatState.shared.activeRoomId = nil
        // Same reasoning as viewWillAppear — animated:false so this never
        // races the pop transition's own animation.
        navigationController?.setNavigationBarHidden(false, animated: false)
        IQKeyboardManager.shared.isEnabled = true
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
            title: roomTitle,
            subtitle: memberCount > 0 ? "\(memberCount) members" : nil,
            imageURL: roomImageURL,
            showMore: true
        )

        headerView.onBack    = { [weak self] in self?.backTapped() }
        headerView.onProfile = { [weak self] in self?.handleProfileTapped() }
        headerView.onMore    = { [weak self] in self?.handleMoreTapped() }
    }

    private func setupTable() {
        // Defense-in-depth against the nav-transition ghost-snapshot bug
        // fixed in viewWillAppear/viewWillDisappear: an OPAQUE background
        // matching the screen's own color means even if some other stray
        // view ever ended up behind the table again, it couldn't show
        // through. (.clear here relied entirely on nothing ever being
        // behind it, which turned out not to be a safe assumption.)
        tableView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
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

        inputBottom = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

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
            self?.viewModel.send(text,1)
        }
        inputBar.onAttach = { [weak self] in
            self?.view.endEditing(true)
            self?.presentAttachmentChoice()
        }
    }

    private func presentAttachmentChoice() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Photo", style: .default) { [weak self] _ in
            self?.imgUpload()
        })
        sheet.addAction(UIAlertAction(title: "Video", style: .default) { [weak self] _ in
            self?.vidUpload()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    func imgUpload() {
        imagePicker.showImagePicker(allowCamera: true) { [weak self] img in
            guard let self else { return }

            // 1. Show optimistic cell immediately
            let tempItem = ChatItem.temporaryImage(localImage: img, senderId: self.viewModel.currentUserId)
            self.viewModel.appendOptimistic(item: tempItem)

            guard let data = img.jpegData(compressionQuality: 0.7) else {
                self.viewModel.markFailed(id: tempItem.id)
                return
            }

            self.uploadImg(true,data) { [weak self] imageName in
                guard let self else { return }
                guard let imageName else {
                    self.viewModel.markFailed(id: tempItem.id)
                    return
                }
                // 2. Confirm with real URL
                self.viewModel.confirmImageSent(id: tempItem.id, imageURL: imageName)
            }
        }
    }

    // Same optimistic pattern as imgUpload above, for video. Uses a plain
    // UIImagePickerController (see the delegate extension at the bottom of
    // this file).
    //
    // FIXED: reading the picked video's file data used to happen with
    // `Data(contentsOf:)` directly on the main thread — for a large video
    // that blocks the entire UI (including the optimistic bubble that was
    // supposed to appear instantly) until the read finishes. The read now
    // happens on a background queue; only the resulting upload call hops
    // back to main.
    func vidUpload() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        videoPickerCompletion = { [weak self] localURL in
            guard let self, let localURL else { return }

            // 1. Generate a thumbnail + duration and show the cell instantly.
            let thumbnail = ChatVideoThumbnailLoader.generateThumbnailSync(for: localURL)
            let duration  = ChatVideoThumbnailLoader.duration(for: localURL)
            let tempItem = ChatItem.temporaryVideo(
                localVideoURL: localURL,
                thumbnail: thumbnail,
                duration: duration,
                senderId: self.viewModel.currentUserId
            )
            self.viewModel.appendOptimistic(item: tempItem)

            // 2. Read the file data off the main thread — this can be a
            // large file and must never block the UI.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let data = try? Data(contentsOf: localURL)

                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let data else {
                        self.viewModel.markFailed(id: tempItem.id)
                        return
                    }

                    self.uploadImg(false, data) { [weak self] videoName in
                        guard let self else { return }
                        guard let videoName else {
                            self.viewModel.markFailed(id: tempItem.id)
                            return
                        }
                        // 3. Confirm with real URL
                        self.viewModel.confirmVideoSent(id: tempItem.id, videoURL: videoName)
                    }
                }
            }
        }
        present(picker, animated: true)
    }
    
    

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onReload = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            // reloadData() only SCHEDULES layout for the new cells, it
            // doesn't force it to finish before the next screen paint.
            // Forcing it here means we never hand a half-laid-out table
            // back to the screen.
            self.tableView.layoutIfNeeded()
        }
        viewModel.onAppend = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        }
        // NEW — pagination anchoring (fix #1). Fires only when older
        // messages were prepended at the top; we reload once and then
        // restore the user's visual position using the resulting
        // contentSize delta, instead of letting the table jump to
        // whatever the new top happens to be.
        viewModel.onOlderPrepended = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()

            let newContentSize = self.tableView.contentSize
            let delta = newContentSize.height - self.pendingOldContentSize.height
            let newOffsetY = self.pendingOldOffset.y + delta

            self.tableView.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: false)
            self.isLoadingOlder = false
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
        view.endEditing(true)
    }

    private func handleMoreTapped() {
        view.endEditing(true)
        
        if self.viewModel.roomType == .group {
            didTapManageGroup(.owner)
        } else {
            didTapManageGroup(.match)
        }
    }
    
    
    
    func didTapManageGroup(_ type:GroupManageType) {
        var groupId = ""
        
        let rawMembers = viewModel.participants.toJSON()
        let groupMembers: [GroupMember] = rawMembers.map { memberDict in
            
            let userId = memberDict["userId"] as? String ?? ""
            groupId = memberDict["groupId"] as? String ?? ""
            let name = memberDict["name"] as? String ?? "Unknown"
            let photoURL = memberDict["profile_image"] as? String
            
            let backendRole = memberDict["role"] as? String ?? ""
            let isAdmin = backendRole == "ADMIN"
            
            let isCurrentUser = userId == User.curentUser?.id
            let displayName = isCurrentUser ? "You" : name
            
            let initials = name
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first.map(String.init) }
                .joined()
                .uppercased()

            return GroupMember(
                id: userId,
                name: displayName,
                role: isAdmin ? "Group Creator" : "Member",
                isAdmin: isAdmin,
                isCurrentUser: isCurrentUser,
                avatarColor: isCurrentUser
                ? UIColor(hex: "#FF6B00").withAlphaComponent(0.4)
                : UIColor(hex: "#555555"),
                initials: initials.isEmpty ? "?" : initials,
                profileImage: "\(APiConstant.base)\(photoURL ?? "")",currentGroupId:groupId
            )
        }
        
        if type == .owner {
            ManageGroupViewController.present(
                from: self, groupType:.owner,
                groupName: roomTitle,
                groupSubtitle: "\(groupMembers.count) travelers",
                members: groupMembers,
                onDelete: { [weak self] in
                    self?.request.deleteGroupAPi(groupId) { err, code in
                        DispatchQueue.main.async {
                            guard let self else { return }
                            
                            if code == 200 {
                                self.navigationController?.popViewController(animated: true)
                                NotificationCenter.default.post(
                                    name: .valueUpdated,
                                    object: nil,
                                    userInfo: [:]
                                )
                            }
                        }
                    }
                }
            )
        } else {
            
            ManageGroupViewController.present(
                from: self, groupType:.match,
                groupName: roomTitle,
                groupSubtitle: "\(groupMembers.count) travelers",
                members: groupMembers,onLeave: { [weak self] in
                    self?.request.type = "MATCH"
                    self?.request.leaveGroupAPi(self?.viewModel.roomId) { err, code in
                        if code == 200 {
                            DispatchQueue.main.async {
                                self?.navigationController?.popViewController(animated: true)
                                NotificationCenter.default.post(
                                    name: .valueUpdated,
                                    object: nil,
                                    userInfo: [:]
                                )
                            }
                        }
                    }
                }
            )
        }
    }

    // NEW — wraps viewModel.loadOlderIfNeeded() so we only snapshot
    // scroll state when a fetch is actually about to happen (fix #1).
    private func triggerLoadOlderIfNeeded() {
        guard !isLoadingOlder else { return }
        pendingOldContentSize = tableView.contentSize
        pendingOldOffset = tableView.contentOffset
        isLoadingOlder = viewModel.loadOlderIfNeeded()
    }
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
       
        cell.onImageTapped = { [weak self] image in
            // FIXED: was `ImagePreviewVC(image: image!)` — a force-unwrap
            // crash waiting to happen if the image hadn't loaded (or
            // failed to load) yet. Now a no-op in that case.
            guard let self, let image else { return }
            let preview = ImagePreviewVC(image: image)
            self.present(preview, animated: true)
        }
        cell.onRetryTapped = { [weak self] in
            self?.viewModel.retry(itemId: item.id)
        }
        cell.onVideoTapped = { [weak self] remoteURL, localURL in
            guard let self else { return }
            if let remoteURL {
                ChatVideoPlayerPresenter.present(remoteURLString: remoteURL, from: self)
            } else if let localURL {
                ChatVideoPlayerPresenter.present(localURL: localURL, from: self)
            }
        }
        
        cell.onImageLongPressed = { [weak self] image in
            guard let self = self, let image = image else { return }

            let alert = UIAlertController(
                title: nil,
                message: "Save this image to your photos?",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Save Image", style: .default) { [weak self] _ in
                guard let self else { return }
                UIImageWriteToSavedPhotosAlbum(
                    image,
                    self,
                    #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
                    nil
                )
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
        cell.onAttachmentSizeResolved = { [weak self, weak tableView, weak cell] in
            // FIXED (crash): this used to hop through an extra
            // DispatchQueue.main.async before re-deriving the index path.
            // Both Kingfisher's completion and ChatVideoThumbnailLoader's
            // completion already land on the main thread, so that hop
            // bought nothing but a window for viewModel.sections to
            // change shape (e.g. a send/reload landing in between) while
            // the captured index path went stale — UIKit then rejected
            // reloadRows(at:) with "insert row N into section M, but
            // there are only fewer sections after the update".
            //
            // Now we resolve the index path and validate it against the
            // CURRENT data source synchronously, in the same tick as the
            // callback firing — no window for drift — and simply skip
            // the (rare, cosmetic-only) correction if it's gone stale;
            // the cell already shows the correct size either way, only
            // the table's cached row height would be briefly behind,
            // and that self-heals on the next reload.
            guard let self, let tableView, let cell else { return }
            guard let currentIndexPath = tableView.indexPath(for: cell) else { return }
            guard currentIndexPath.section < self.viewModel.sections.count,
                  currentIndexPath.row < self.viewModel.sections[currentIndexPath.section].items.count
            else { return }

            UIView.performWithoutAnimation {
                tableView.reloadRows(at: [currentIndexPath], with: .none)
            }
        }
        // Pass the tableView's own width explicitly — see the long
        // comment on ChatMessageCell.availableContentWidth for why this,
        // and not something read inside the cell itself, is what actually
        // fixed the narrow/character-wrapped text bubble bug.
        cell.configure(with: item, availableWidth: tableView.bounds.width)
        return cell
    }
    
    @objc
    private func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer?
    ) {

        if let error = error {
            showAlert(error.localizedDescription)
        } else {
            showAlert("Image saved successfully")
        }
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
            triggerLoadOlderIfNeeded()
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

    @objc private func keyboardWillChange(_ notification: Notification) {

        guard
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboard = view.convert(keyboardFrame, from: nil)

        let keyboardHeight = max(
            0,
            view.bounds.maxY - keyboard.minY - view.safeAreaInsets.bottom
        )

        inputBottom.constant = -keyboardHeight

        let bottomInset = keyboardHeight + inputBar.frame.height

        tableView.contentInset.bottom = bottomInset
        tableView.scrollIndicatorInsets.bottom = bottomInset

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: false)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {

        inputBottom.constant = 0

        tableView.contentInset.bottom = inputBar.frame.height
        tableView.scrollIndicatorInsets.bottom = inputBar.frame.height

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            self.view.layoutIfNeeded()
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

// MARK: - Video picker
//
// Self-contained UIImagePickerController delegate for vidUpload() above.

extension ChatMessageVc: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let localURL = info[.mediaURL] as? URL
        videoPickerCompletion?(localURL)
        videoPickerCompletion = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        videoPickerCompletion?(nil)
        videoPickerCompletion = nil
    }
}
