//
//  ChatVc.swift
//  TravelDate
//
//  Refactored to senior-level MVC architecture
//  - Single API load in viewDidLoad
//  - Enum-based state management
//  - Clean segment switching (no extra reloads)
//  - Proper memory management with [weak self]
//
import UIKit

// MARK: - Segment Enum

enum ChatSegment {
    case groups
    case chats
}

final class ChatVc: BaseClassVc {

    // MARK: - IBOutlets

    @IBOutlet weak var tblVw: UITableView!
    @IBOutlet weak var lblNoData: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var segmentView: ChatSegmentView!

    // MARK: - Variables

    private var groupsData: [Group] = []
    private var chatData: [ChatRoomModel] = []

    private var selectedSegment: ChatSegment = .groups

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        setupSegmentCallbacks()

        fetchAllData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tripsTabBarController?.showTabBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentHeight = tblVw.contentSize.height
        let tableHeight = tblVw.frame.height

        if contentHeight < tableHeight {
            let extraSpace = 100
            tblVw.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(extraSpace), right: 0)
        } else {
            tblVw.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }
}

// MARK: - Setup

private extension ChatVc {

    func setupUI() {

        lblTitle.setFont(.medium, size: 18.0)

        addGradient()
    }

    func setupTableView() {

        tblVw.delegate = self
        tblVw.dataSource = self

        tblVw.register(ChatTableViewCell.self)
    }

    func setupSegmentCallbacks() {

        segmentView.onSegmentChanged = { [weak self] index in

            guard let self else { return }

            self.selectedSegment = index == 0 ? .groups : .chats

            print("Current Segment:", self.selectedSegment)

            self.refreshTableView()
        }
    }
}

// MARK: - API Calls

private extension ChatVc {

    func fetchAllData() {

        fetchGroups()

        fetchChats()
    }

    func fetchGroups() {

        request.getGroups(0) { [weak self] model, msg, code in

            guard let self else { return }

            DispatchQueue.main.async {

                if code == 200 {

                    self.groupsData = model?.data?.groups ?? []

                    print("Groups Count:", self.groupsData.count)

                    if self.selectedSegment == .groups {

                        self.refreshTableView()
                    }

                } else {

                    self.showAlert(msg)
                }
            }
        }
    }

    func fetchChats() {

        request.getChatRooms { [weak self] response, msg, errCode in

            guard let self else { return }

            DispatchQueue.main.async {

                if errCode == 200 {

                    self.chatData = response ?? []

                    print("Chats Count:", self.chatData.count)

                    if self.selectedSegment == .chats {

                        self.refreshTableView()
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension ChatVc {

    func refreshTableView() {

        print("Reloading Table")

        tblVw.reloadData()

        updateNoDataLabel()
    }

    func updateNoDataLabel() {

        let isEmpty: Bool

        switch selectedSegment {

        case .groups:
            isEmpty = groupsData.isEmpty

        case .chats:
            isEmpty = chatData.isEmpty
        }

        lblNoData.isHidden = !isEmpty
    }

    func currentCount() -> Int {

        switch selectedSegment {

        case .groups:
            return groupsData.count

        case .chats:
            return chatData.count
        }
    }
}

// MARK: - Actions

extension ChatVc {

    @IBAction func btnBack(_ sender: UIButton) {

        backTapped()
    }
}

// MARK: - UITableViewDelegate/DataSource

extension ChatVc: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {

        return currentCount()
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 90
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ChatTableViewCell = tableView.dequeue(ChatTableViewCell.self,
                                                        for: indexPath)

        switch selectedSegment {

        case .groups:

            let model = groupsData[indexPath.row]

            cell.lblTitle.text = model.groupTitle ?? ""

            cell.lblDesc.text = model.creator?.name ?? ""

            cell.lblTime.text = timeAgo(from: model.createdAt ?? "")

            loadAvatarImage(into: cell.imgVw,
                            urlString: model.coverImage)

        case .chats:

            let model = chatData[indexPath.row]

            let senderName =
            model.lastMessage?.sender?.name ??
            model.participants?.first?.name ??
            "Unknown"

            cell.lblTitle.text = senderName

            cell.lblDesc.text =
            model.lastMessage?.content ?? "No messages yet"

            cell.lblTime.text =
            timeAgo(from: model.lastMessage?.createdAt ??
                    model.createdAt ?? "")

            let avatar =
            model.participants?.first?.profileImage

            loadAvatarImage(into: cell.imgVw,
                            urlString: avatar)
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        switch selectedSegment {

        case .groups:

            let group = groupsData[indexPath.row]

            let vc = ChatMessageVc()

            vc.roomId = group.roomId ?? ""

            vc.roomTitle = group.groupTitle ?? ""

            vc.groupId = group.id ?? ""

            vc.roomType = "group"

            navigationController?.pushViewController(vc,
                                                     animated: true)

        case .chats:

            let chat = chatData[indexPath.row]

            let vc = ChatMessageVc()

            vc.roomId = chat.id ?? ""

            vc.roomTitle =
            chat.lastMessage?.sender?.name ?? "Chat"

            vc.roomType = "direct"

            navigationController?.pushViewController(vc,
                                                     animated: true)
        }
    }
}

// MARK: - Image Loader

private extension ChatVc {

    func loadAvatarImage(into imageView: UIImageView,
                         urlString: String?) {

        imageView.contentMode = .scaleAspectFill

        imageView.layer.cornerRadius = imageView.frame.height / 2

        imageView.clipsToBounds = true

        if let urlString,
           let url = URL(string: urlString) {

            loadImage(imageView, url: url)

        } else {

            imageView.image = UIImage(named: "User")
        }
    }
}

// MARK: - Time Ago

private extension ChatVc {

    func timeAgo(from isoString: String) -> String {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        guard let date = formatter.date(from: isoString) else {

            return "-"
        }

        let seconds =
        Int(Date().timeIntervalSince(date))

        switch seconds {

        case ..<60:
            return "Just now"

        case ..<3600:
            return "\(seconds / 60)m ago"

        case ..<86400:
            return "\(seconds / 3600)h ago"

        case ..<604800:
            return "\(seconds / 86400)d ago"

        default:
            return "\(seconds / 604800)w ago"
        }
    }
}
import UIKit

class ChatSegmentView: UIView {

    private let containerView = UIView()
    private var selectedIndex = 0

    var onSegmentChanged: ((_ index: Int) -> Void)?
    private let blurView = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemUltraThinMaterialDark)
    )

    private let selectorView = UIView()

    private let myGroupBtn = UIButton(type: .system)
    private let matchBtn = UIButton(type: .system)

    private let glowLayer = CAGradientLayer()

    

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Setup

    private func commonInit() {

        backgroundColor = .clear

        addSubview(containerView)

        containerView.addSubview(blurView)
        containerView.addSubview(selectorView)

        containerView.addSubview(myGroupBtn)
        containerView.addSubview(matchBtn)

        // MARK: Container Glass Effect

        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.03)

        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.35
        containerView.layer.shadowRadius = 20
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)

        // MARK: Blur

        blurView.clipsToBounds = true

        // MARK: Orange Pill

        selectorView.backgroundColor = .appOrange

        selectorView.layer.shadowColor = UIColor.appOrange.cgColor
        selectorView.layer.shadowOpacity = 0.35
        selectorView.layer.shadowRadius = 14
        selectorView.layer.shadowOffset = CGSize(width: 0, height: 6)

        // MARK: Buttons

        myGroupBtn.setTitle("My group", for: .normal)
        matchBtn.setTitle("Match groups", for: .normal)

        myGroupBtn.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16)
        matchBtn.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16)

        myGroupBtn.setTitleColor(.white, for: .normal)
        matchBtn.setTitleColor(.white.withAlphaComponent(0.7), for: .normal)

        myGroupBtn.backgroundColor = .clear
        matchBtn.backgroundColor = .clear

        myGroupBtn.addTarget(
            self,
            action: #selector(selectMyGroup),
            for: .touchUpInside
        )

        matchBtn.addTarget(
            self,
            action: #selector(selectMatch),
            for: .touchUpInside
        )
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let padding: CGFloat = 4

        containerView.frame = bounds

        containerView.layer.cornerRadius = bounds.height / 2
        containerView.layer.cornerCurve = .continuous

        blurView.frame = containerView.bounds
        blurView.layer.cornerRadius = bounds.height / 2

        let segmentWidth = bounds.width / 2

        selectorView.frame = CGRect(
            x: selectedIndex == 0
                ? padding
                : segmentWidth,
            y: padding,
            width: segmentWidth - padding,
            height: bounds.height - (padding * 2)
        )

        selectorView.layer.cornerRadius = selectorView.frame.height / 2
        selectorView.layer.cornerCurve = .continuous

        myGroupBtn.frame = CGRect(
            x: 0,
            y: 0,
            width: segmentWidth,
            height: bounds.height
        )

        matchBtn.frame = CGRect(
            x: segmentWidth,
            y: 0,
            width: segmentWidth,
            height: bounds.height
        )

        // MARK: Premium Top Highlight

        glowLayer.removeFromSuperlayer()

        glowLayer.frame = containerView.bounds

        glowLayer.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor
        ]

        glowLayer.locations = [0, 1]

        glowLayer.startPoint = CGPoint(x: 0.5, y: 0)
        glowLayer.endPoint = CGPoint(x: 0.5, y: 1)

        glowLayer.cornerRadius = containerView.layer.cornerRadius

        containerView.layer.insertSublayer(glowLayer, at: 0)
    }

    // MARK: - Actions

    @objc private func selectMyGroup() {

        selectedIndex = 0

        onSegmentChanged?(0)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5
        ) {
            self.layoutSubviews()
        }

        myGroupBtn.setTitleColor(.white, for: .normal)

        matchBtn.setTitleColor(
            .white.withAlphaComponent(0.7),
            for: .normal
        )
    }

    @objc private func selectMatch() {

        selectedIndex = 1

        onSegmentChanged?(1)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5
        ) {
            self.layoutSubviews()
        }

        myGroupBtn.setTitleColor(
            .white.withAlphaComponent(0.7),
            for: .normal
        )

        matchBtn.setTitleColor(.white, for: .normal)
    }
}
