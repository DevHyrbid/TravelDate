//
//  ChatMessageVc.swift
//  TravelDate
//

import UIKit

// MARK: - MessageModel

struct MessageModel {
    var id:          String?
    var roomId:      String?
    var senderId:    String?
    var senderName:  String?
    var senderImage: String?
    var content:     String?
    var contentType: String?
    var imageUrl:    String?
    var createdAt:   String?
    var isSeen:      Bool?

    init(dict: [String: Any]) {
        id          = dict["id"]          as? String
        roomId      = dict["roomId"]      as? String
        senderId    = dict["senderId"]    as? String
        content     = dict["content"]     as? String
        contentType = dict["contentType"] as? String
        imageUrl    = dict["imageUrl"]    as? String
        createdAt   = dict["createdAt"]   as? String
        isSeen      = dict["isSeen"]      as? Bool

        if let sender = dict["sender"] as? [String: Any] {
            senderName  = sender["name"]          as? String
            senderImage = sender["profile_image"] as? String
        } else {
            senderName = dict["senderName"] as? String
        }
    }
}

// MARK: - ChatMessageVc

final class ChatMessageVc: BaseClassVc {

    // MARK: - UI Components

    private let navBar          = UIView()
    private let backButton      = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let titleLabel      = UILabel()
    private let subtitleLabel   = UILabel()
    private let moreButton      = UIButton(type: .system)
    private let onlineDot       = UIView()
    private let tableView       = UITableView()
    private let typingLabel     = UILabel()
    private let inputContainer  = UIView()
    private let textField       = UITextField()
    private let emojiButton     = UIButton(type: .system)
    private let attachButton    = UIButton(type: .system)
    private let sendButton      = UIButton(type: .system)

    // MARK: - Input from ChatVc

    var roomId:       String       = ""
    var roomTitle:    String       = "Chat"
    var groupId:      String       = ""
    var roomType:     ChatRoomType = .group
    var memberCount:  Int          = 0
    var participants: [String]     = []

    // MARK: - Private State

    private var messages:      [MessageModel] = []
    private let currentUserId: String         = User.curentUser?.id ?? ""
    private var typingTimer:   Timer?
    private let socket = SocketIOManager.shared

    // MARK: - Keyboard

    private var inputContainerBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.07, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupNavBar()
        setupTableView()
        setupTypingLabel()
        setupInputBar()
        setupKeyboardObservers()

        setupSocket()   // ← single entry point
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // ✅ Clean exit — leave room + remove delegate
        socket.leaveCurrentRoom()
        socket.removeDelegate(self)
        typingTimer?.invalidate()
        typingTimer = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Socket Setup

    private func setupSocket() {
        socket.addDelegate(self)      // ✅ multi-delegate safe
        socket.setupListeners()       // ✅ guarded — runs once globally
        socket.connect()              // ✅ joinRoom fires inside socketConnected()
    }

    private func joinCurrentRoom() {
        socket.joinRoom(
            roomId:       roomId,
            type:         roomType,
            groupId:      groupId,
            participants: participants
        )
    }
}

// MARK: - ChatSocketDelegate

extension ChatMessageVc: ChatSocketDelegate {

    func socketConnected() {
        print("✅ Socket connected — joining room")
        joinCurrentRoom()
    }

    func didJoinRoom(roomId: String) {
        print("🏠 Joined room: \(roomId)")
        // Update roomId if server assigned one (individual chat flow)
        if self.roomId.isEmpty { self.roomId = roomId }
        socket.getMessages(roomId: roomId)
    }

    func didReceiveMessages(_ messages: [MessageModel]) {
        // ✅ Already filtered by roomId in SocketIOManager
        self.messages = messages.sorted { ($0.createdAt ?? "") < ($1.createdAt ?? "") }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.scrollToBottom(animated: false)
        }
    }

    func didReceiveNewMessage(_ message: MessageModel) {
        // ✅ Already filtered — safe direct append
        messages.append(message)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [indexPath], with: .none)
            })
            self.scrollToBottom()
        }
    }

    func didReceiveTyping(senderId: String, isTyping: Bool) {
        guard senderId != currentUserId else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.typingLabel.isHidden = !isTyping
            if isTyping { self.scrollToBottom() }
        }
    }

    func didReceiveMessagesRead(roomId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func didReceiveUserOnline(userId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onlineDot.isHidden = false
            self.subtitleLabel.text      = "Online"
            self.subtitleLabel.textColor = UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
        }
    }

    func didReceiveUserOffline(userId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onlineDot.isHidden = true
            self.subtitleLabel.text      = self.memberCount > 0
                ? "📍 \(self.memberCount) travelers"
                : "Offline"
            self.subtitleLabel.textColor = .lightGray
        }
    }

    func didReceiveChatDeleted(roomId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(
                title:          "Chat Deleted",
                message:        "This chat has been deleted.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true)
        }
    }

    func didReceiveMessagesDeleted(messageIds: [String]) {
        messages.removeAll { messageIds.contains($0.id ?? "") }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func didLeaveGroupChat(roomId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - NavBar

extension ChatMessageVc {

    func setupNavBar() {
        navBar.backgroundColor = UIColor(white: 0.10, alpha: 1)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds      = true
        avatarImageView.backgroundColor    = UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)
        avatarImageView.contentMode        = .scaleAspectFill
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        onlineDot.backgroundColor    = UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
        onlineDot.layer.cornerRadius = 6
        onlineDot.isHidden           = true
        onlineDot.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text      = roomTitle
        titleLabel.setFont(.bold, size: 16.0)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text      = memberCount > 0 ? "📍 \(memberCount) travelers" : ""
        subtitleLabel.setFont(.regular, size: 12.0)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .white
        moreButton.translatesAutoresizingMaskIntoConstraints = false

        [backButton, avatarImageView, onlineDot,
         titleLabel, subtitleLabel, moreButton].forEach { navBar.addSubview($0) }

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 60),

            backButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),

            avatarImageView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            avatarImageView.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            onlineDot.widthAnchor.constraint(equalToConstant: 12),
            onlineDot.heightAnchor.constraint(equalToConstant: 12),
            onlineDot.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            onlineDot.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 2),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            moreButton.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -16),
            moreButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
        ])
    }
}

// MARK: - TableView

extension ChatMessageVc: UITableViewDelegate, UITableViewDataSource {

    func setupTableView() {
        tableView.backgroundColor    = UIColor(white: 0.07, alpha: 1)
        tableView.separatorStyle     = .none
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight           = UITableView.automaticDimension
        tableView.estimatedRowHeight  = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        tableView.delegate   = self
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ChatBubbleCell", for: indexPath
        ) as! ChatBubbleCell
        cell.configure(msg: messages[indexPath.row], currentUserId: currentUserId)
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    private func scrollToBottom(animated: Bool = true) {
        guard messages.count > 0 else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            guard self.tableView.numberOfRows(inSection: 0) > indexPath.row else { return }
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}

// MARK: - Typing Label

extension ChatMessageVc {

    func setupTypingLabel() {
        typingLabel.text      = "typing..."
        typingLabel.font      = .italicSystemFont(ofSize: 12)
        typingLabel.textColor = .lightGray
        typingLabel.isHidden  = true
        typingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typingLabel)

        NSLayoutConstraint.activate([
            typingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            typingLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}

// MARK: - Input Bar

extension ChatMessageVc: UITextFieldDelegate {

    func setupInputBar() {
        inputContainer.backgroundColor = UIColor(white: 0.10, alpha: 1)
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)

        inputContainerBottomConstraint = inputContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            inputContainer.heightAnchor.constraint(equalToConstant: 64),

            typingLabel.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -4),
            tableView.bottomAnchor.constraint(equalTo: typingLabel.topAnchor, constant: -4),
        ])

        let fieldBg = UIView()
        fieldBg.backgroundColor    = UIColor(white: 0.18, alpha: 1)
        fieldBg.layer.cornerRadius = 22
        fieldBg.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder   = "Type a message..."
        textField.textColor     = .white
        textField.setFont(.regular, size: 15.0)
        textField.backgroundColor = .clear
        textField.delegate        = self
        textField.returnKeyType   = .send
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        emojiButton.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        emojiButton.tintColor = UIColor(white: 0.6, alpha: 1)
        emojiButton.translatesAutoresizingMaskIntoConstraints = false

        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachButton.tintColor = UIColor(white: 0.6, alpha: 1)
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)

        sendButton.backgroundColor    = UIColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1)
        sendButton.layer.cornerRadius = 22
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        fieldBg.addSubview(emojiButton)
        fieldBg.addSubview(textField)
        fieldBg.addSubview(attachButton)
        inputContainer.addSubview(fieldBg)
        inputContainer.addSubview(sendButton)

        NSLayoutConstraint.activate([
            fieldBg.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            fieldBg.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            fieldBg.heightAnchor.constraint(equalToConstant: 44),
            fieldBg.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),

            emojiButton.leadingAnchor.constraint(equalTo: fieldBg.leadingAnchor, constant: 10),
            emojiButton.centerYAnchor.constraint(equalTo: fieldBg.centerYAnchor),
            emojiButton.widthAnchor.constraint(equalToConstant: 28),

            textField.leadingAnchor.constraint(equalTo: emojiButton.trailingAnchor, constant: 6),
            textField.trailingAnchor.constraint(equalTo: attachButton.leadingAnchor, constant: -6),
            textField.topAnchor.constraint(equalTo: fieldBg.topAnchor),
            textField.bottomAnchor.constraint(equalTo: fieldBg.bottomAnchor),

            attachButton.trailingAnchor.constraint(equalTo: fieldBg.trailingAnchor, constant: -10),
            attachButton.centerYAnchor.constraint(equalTo: fieldBg.centerYAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 28),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func sendTapped() {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        let activeRoomId = self.roomId
        
        print(activeRoomId,"room")
        guard !activeRoomId.isEmpty else {
            print("❌ sendTapped — roomId is empty")
            return
        }

        socket.sendTextMessage(roomId: activeRoomId, content: text)
        textField.text = nil
        socket.sendTyping(roomId: activeRoomId, isTyping: false)
        typingTimer?.invalidate()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }

    @objc private func textFieldDidChange() {
        let activeRoomId = socket.activeRoom?.roomId ?? roomId
        guard !activeRoomId.isEmpty else { return }

        socket.sendTyping(roomId: activeRoomId, isTyping: true)

        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.socket.sendTyping(roomId: activeRoomId, isTyping: false)
            self.typingTimer = nil
        }
    }

    @objc private func attachTapped() {
        let picker         = UIImagePickerController()
        picker.delegate    = self
        picker.sourceType  = .photoLibrary
        present(picker, animated: true)
    }
}

// MARK: - Image Picker

extension ChatMessageVc: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        uploadImage(image)
    }

    private func uploadImage(_ image: UIImage) {
        // TODO: Upload to server then:
        // socket.sendImageMessage(roomId: socket.activeRoom?.roomId ?? roomId, imageUrl: uploadedUrl)
        print("📸 Upload image here then emit sendMessage with imageUrl")
    }
}

// MARK: - Keyboard Handling

extension ChatMessageVc {

    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info   = notification.userInfo,
              let kFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let dur    = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        inputContainerBottomConstraint.constant = -(kFrame.height - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: dur) { self.view.layoutIfNeeded() }
        scrollToBottom()
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let dur = notification.userInfo?[
            UIResponder.keyboardAnimationDurationUserInfoKey
        ] as? Double else { return }

        inputContainerBottomConstraint.constant = 0
        UIView.animate(withDuration: dur) { self.view.layoutIfNeeded() }
    }
}
