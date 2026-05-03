//
//  ChatVc.swift
//  TravelDate
//

import UIKit

class ChatVc: BaseClassVc {
    
    @IBOutlet weak var tblVw: UITableView!
    @IBOutlet weak var btnSegment: UISegmentedControl!
    @IBOutlet weak var lblNoData: UILabel!
    private var segmentSetupDone = false
    var data: GroupsData? = nil
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib()
       
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSegmentUI()
    }
    
    func registerNib() {
        tblVw.register(ChatTableViewCell.self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.showTabBar()
        getGroups()
    }
    
    func getGroups() {
        request.getGroups { model,msg, code in
            if code == 200 {
                DispatchQueue.main.async { [self] in
                    self.data = model?.data ?? nil
                    self.tblVw.reloadData()
                    if self.data?.groups?.count == 0 {
                        self.lblNoData.isHidden = false
                    } else {
                        self.lblNoData.isHidden = true
                    }
                }
            } else {
                DispatchQueue.main.async { [self] in
                    showAlert(msg)
                }
            }
        }
    }
    
    func setupSegmentUI() {
        guard !segmentSetupDone else { return }
        segmentSetupDone = true

        let height      = btnSegment.bounds.height
        let width       = btnSegment.bounds.width
        let inset: CGFloat = 4
        let pillH       = height - (inset * 2)
        let pillW       = (width / CGFloat(btnSegment.numberOfSegments)) - (inset * 2)

        // ── Outer container ──────────────────────────────────────
        btnSegment.backgroundColor  = UIColor.white.withAlphaComponent(0.08)
        btnSegment.layer.cornerRadius  = height / 2          // perfect pill
        btnSegment.layer.masksToBounds = true

        // Remove ALL Apple default chrome
        btnSegment.setBackgroundImage(
            UIImage(), for: .normal,   barMetrics: .default)
        btnSegment.setBackgroundImage(
            UIImage(), for: .selected, barMetrics: .default)
        btnSegment.setBackgroundImage(
            UIImage(), for: .highlighted, barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .normal,
            barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .selected,
            rightSegmentState: .normal,
            barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .selected,
            barMetrics: .default)

        // ── Orange pill (selected) ────────────────────────────────
        // Draw pill with EQUAL corner radius on both sides
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pillW, height: pillH))
        let pillImage = renderer.image { ctx in
            let path = UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: pillW, height: pillH),
                cornerRadius: pillH / 2          // ← full round both ends
            )
            UIColor.themeOrange.setFill()
            path.fill()
        }

        // Make it stretchable — preserve both rounded caps
        let cap = pillH / 2
        let stretchable = pillImage.resizableImage(
            withCapInsets: UIEdgeInsets(top: cap, left: cap, bottom: cap, right: cap),
            resizingMode: .stretch
        )

        btnSegment.setBackgroundImage(stretchable, for: .selected, barMetrics: .default)

        // ── Segment content insets (keeps pill away from container edge) ──
        for i in 0..<btnSegment.numberOfSegments {
            btnSegment.setWidth(width / CGFloat(btnSegment.numberOfSegments), forSegmentAt: i)
        }

        // ── Typography ───────────────────────────────────────────
        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ], for: .normal)

        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ], for: .selected)

        // ── Default selection ─────────────────────────────────────
        btnSegment.selectedSegmentIndex = 0   // "My group" selected
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
}

// MARK: - TableViewDelegate
extension ChatVc: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        self.data?.groups?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTableViewCell = tableView.dequeue(
            ChatTableViewCell.self, for: indexPath)
        let model = self.data?.groups?[indexPath.row]
        cell.lblTitle.text =  model?.groupTitle ?? ""
        cell.lblDesc.text = model?.creator?.name ?? ""
        if let url = URL(string: model?.creator?.profileImage ?? "") {
            loadImage(cell.imgVw, url: url)
        } else {
            cell.imgVw.image = UIImage(named: "User")
        }
        cell.imgVw.layer.cornerRadius = cell.imgVw.frame.height / 2
        cell.imgVw.clipsToBounds = true
        cell.lblTime.text = timeAgo(from: model?.createdAt ?? "")
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = self.data?.groups?[indexPath.row]

        let chatVc = ChatMessageVc()
        chatVc.roomId      = selectedUser?.roomId ?? ""
        chatVc.roomTitle   = selectedUser?.groupTitle ?? "Chat"
        chatVc.groupId     = selectedUser?.id ?? ""
        chatVc.roomType    = "group"
        chatVc.memberCount = selectedUser?.maxGroupSize ?? 0

        // ✅ Correct way - compactMap use karo
        chatVc.participants = selectedUser?.members?.compactMap { $0.id } ?? []
        // ✅ Full log before push
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🚀 Opening ChatMessageVc")
        print("📌 roomId      : \(chatVc.roomId)")
        print("📌 roomTitle   : \(chatVc.roomTitle)")
        print("📌 groupId     : \(chatVc.groupId)")
        print("📌 roomType    : \(chatVc.roomType)")
        print("📌 memberCount : \(chatVc.memberCount)")
        print("📌 participants: \(chatVc.participants)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        navigationController?.pushViewController(chatVc, animated: true)
    }
}

extension ChatVc {
    @IBAction func btnBack(_ sender: UIButton) {
        super.backTapped()
    }
}

extension ChatVc {
   

    func timeAgo(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else {
            return "Invalid date"
        }

        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            return "\(seconds / 60) min ago"
        } else if seconds < 86400 {
            return "\(seconds / 3600) hr ago"
        } else if seconds < 604800 {
            return "\(seconds / 86400) day ago"
        } else {
            let weeks = seconds / 604800
            return "\(weeks) week ago"
        }
    }
}
