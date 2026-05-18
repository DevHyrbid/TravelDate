//
//  ChatVc.swift
//  TravelDate
//

import UIKit

class ChatVc: BaseClassVc {
    
    @IBOutlet weak var tblVw: UITableView!
    @IBOutlet weak var btnSegment: UISegmentedControl!
    @IBOutlet weak var lblNoData: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTitleActive: UILabel!
    private var segmentSetupDone = false
    var data: GroupsData? = nil
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib()
        addGradient()
        lblTitle.setFont(.medium, size: 18.0)
        // Normal state font
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Poppins-SemiBold", size: 14)!,
            .foregroundColor: UIColor.gray
        ]
        
        // Selected state font
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Poppins-SemiBold", size: 14)!,
            .foregroundColor: UIColor.white
        ]
        
        btnSegment.setTitleTextAttributes(normalAttributes, for: .normal)
        btnSegment.setTitleTextAttributes(selectedAttributes, for: .selected)
        
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
        request.getGroups(0) { model,msg, code in
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

        let inset: CGFloat = 4

        // Outer container
        btnSegment.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        btnSegment.layer.cornerRadius = 25.5
        btnSegment.layer.cornerCurve = .continuous
        btnSegment.clipsToBounds = true

        // Remove default UI
        btnSegment.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        btnSegment.setBackgroundImage(UIImage(), for: .selected, barMetrics: .default)
        btnSegment.setBackgroundImage(UIImage(), for: .highlighted, barMetrics: .default)

        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .normal,
            barMetrics: .default
        )

        // Selected pill image
        let selectedSize = CGSize(
            width: (btnSegment.frame.width / CGFloat(btnSegment.numberOfSegments)) - (inset * 2),
            height: btnSegment.frame.height - (inset * 2)
        )

        let renderer = UIGraphicsImageRenderer(size: selectedSize)

        let selectedImage = renderer.image { context in

            let rect = CGRect(origin: .zero, size: selectedSize)

            let path = UIBezierPath(
                roundedRect: rect,
                cornerRadius: selectedSize.height / 2
            )

            UIColor.themeOrange.setFill()
            path.fill()
        }

        let stretchable = selectedImage.resizableImage(
            withCapInsets: UIEdgeInsets(
                top: 0,
                left: selectedSize.height / 2,
                bottom: 0,
                right: selectedSize.height / 2
            ),
            resizingMode: .stretch
        )

        btnSegment.setBackgroundImage(
            stretchable,
            for: .selected,
            barMetrics: .default
        )

        // Text styles
        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont(name: "Poppins-Medium", size: 15.0)
        ], for: .normal)

        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Poppins-SemiBold", size: 15.0)
        ], for: .selected)

        btnSegment.selectedSegmentIndex = 0

        // IMPORTANT FIX
        DispatchQueue.main.async {

            for view in self.btnSegment.subviews {

                view.layer.cornerRadius = (self.btnSegment.frame.height - (inset * 2)) / 2
                view.layer.cornerCurve = .continuous
                view.clipsToBounds = true
            }
        }
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
        cell.lblDesc.text = "\(model?.creator?.name ?? "") · Thu"
        if let url = URL(string: model?.coverImage ?? "") {
            loadImage(cell.imgVw, url: url)
        } else {
            cell.imgVw.image = UIImage(named: "User")
        }
        
        cell.imgVw.contentMode = .scaleAspectFill
        cell.imgVw.layer.cornerRadius = cell.imgVw.frame.height / 2
        cell.imgVw.clipsToBounds = true
        cell.lblTime.text = timeAgo(from: model?.createdAt ?? "")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
       90
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
    
    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let group = self.data?.groups?[indexPath.row]

        // DELETE ACTION
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Delete") { _, _, completion in

            print("Delete tapped for group id: \(group?.id ?? "")")

            // API Call Here
            
            self.request.deleteGroupAPi(group?.id ?? "") { msg, code in
                DispatchQueue.main.async {
                    if code == 200 {
                        self.data?.groups?.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
               
            }
            

            completion(true)
        }

        deleteAction.backgroundColor = .systemRed

        // REPORT ACTION
        let reportAction = UIContextualAction(style: .normal,
                                              title: "Report") { _, _, completion in

            print("Report tapped for group id: \(group?.id ?? "")")

            // API Call Here
            /*
            request.reportGroup(groupId: group?.id ?? "") { msg, code in
                self.showAlert("Reported Successfully")
            }
            */

            completion(true)
        }

        reportAction.backgroundColor = .systemOrange

        let configuration = UISwipeActionsConfiguration(actions: [
            deleteAction
//            reportAction
        ])

        configuration.performsFirstActionWithFullSwipe = false

        return configuration
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

import UIKit

class ChatSegmentView: UIView {

    private let containerView = UIView()

    private let blurView = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemUltraThinMaterialDark)
    )

    private let selectorView = UIView()

    private let myGroupBtn = UIButton(type: .system)
    private let matchBtn = UIButton(type: .system)

    private let glowLayer = CAGradientLayer()

    private var selectedIndex = 0

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
