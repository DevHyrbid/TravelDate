//
//  HomeViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone
//

import UIKit
import CoreLocation
// MARK: - Past Trip Model
import SwiftUI
struct PastTrip {
    let image: String
    let destination: String
    let dateRange: String
    let year: String
}

// MARK: - HomeViewController

class HomeViewController: BaseClassVc, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollVw:UIScrollView!
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblGreating:UILabel!
    @IBOutlet weak var lblDay:UILabel!
    @IBOutlet weak var lblMin:UILabel!
    @IBOutlet weak var lblSec:UILabel!
    @IBOutlet weak var lblHours:UILabel!
    @IBOutlet weak var lblDate:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var imgTrips:UIImageView!
    @IBOutlet weak var imgProfile:UIImageView!
    @IBOutlet weak var lblPast:UILabel!
    @IBOutlet weak var lblDatePast:UILabel!
    @IBOutlet weak var height:NSLayoutConstraint!
    @IBOutlet weak var pastTblheight:NSLayoutConstraint!
    @IBOutlet weak var pastLbl:UILabel!
    @IBOutlet weak var pastLblYear:UILabel!
    @IBOutlet weak var hideVw:UIView!
    @IBOutlet weak var lblLeft:UILabel!
    @IBOutlet weak var vwMembers:UIView!
    @IBOutlet weak var btnList:UIButton!
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var lblActive:UILabel!
    @IBOutlet weak var lblNew:UILabel!
    @IBOutlet weak var lblSaved:UILabel!
    @IBOutlet weak var btnEdit:UIButton!
    @IBOutlet weak var imgVerify:UIImageView!
    @IBOutlet weak var btnCreateGroup:UIButton!
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: - Properties
    var timer: Timer?
    var targetDate: Date?
    var data: GroupsData? = nil
    var dataArray: [Group]? = nil
    var pastData: [Group]? = nil
    var selected : Group? = nil
    let membersView = MembersProgressView()
    private var tabBarHideTimer: Timer?
    private let tabBarAutoHideDuration: TimeInterval = 3 // seconds
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
        
        setupPullToRefresh()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(percentageViewTapped))
        
        
        imgVerify.isUserInteractionEnabled = true
        imgVerify.addGestureRecognizer(tapGesture)
    }
    
    @objc private func percentageViewTapped() {
        // Open your screen here
        let vc = GetVerifiedVc()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupPullToRefresh() {
        refreshControl.tintColor = .white
        refreshControl.addTarget(
            self,
            action: #selector(handlePullToRefresh),
            for: .valueChanged
        )

        scrollVw.refreshControl = refreshControl
    }
    
    @objc private func handlePullToRefresh() {
        getGroups()
        getPastGroups()
        getDashboard()
    }
    
    private func showTabBarTemporarily() {
        tripsTabBarController?.showTabBar()
        resetTabBarTimer()
    }

    private func resetTabBarTimer() {
        tabBarHideTimer?.invalidate()

        tabBarHideTimer = Timer.scheduledTimer(withTimeInterval: tabBarAutoHideDuration, repeats: false) { [weak self] _ in
            self?.tripsTabBarController?.hideTabBar()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        showTabBarTemporarily()
    }
    
    
    @objc private func handleValueUpdated(_ notification: Notification) {
        getGroups()
        getPastGroups()
    }
    
    
    func makeTripMenu(trips: [Group]) -> UIMenu {
        let actions = trips.map { trip in
            UIAction(
                title: trip.title ?? "",
                image: UIImage(systemName:"arrow.right")
            ) { _ in
                
                self.didSelectTrip(trip)
            }
        }

        return UIMenu(title: "Trips", children: actions)
    }
    
    
    func didSelectTrip(_ res: Group) {
        
        self.selected  = res
        AppData.shared.latitude = res.latitude
        AppData.shared.longitude = res.longitude

        self.setupCountdown(startDateString: res.startDate ?? "")
        UserDefaults.standard.set(res.id, forKey: "selectedGroupId")

        self.lblDate.text = self.formatDateRange(
            start: res.startDate ?? "",
            end: res.endDate ?? ""
        )
        self.lblLocation.text = res.destination ?? ""
        self.lblTitle.text = res.title ?? ""
        if let url = URL(string: res.coverImage ?? "") {
            self.loadImage(self.imgTrips, url: url)
        }
        
        membersView.configure(members: res.members ?? [], totalCount: (res.maxGroupSize ?? 0), completedCount: res.members?.count ?? 0)
        print((res.members?.count ?? 0),"hjkljkl")
        membersView.onAvatarStackTapped = {
            print("Avatar stack tapped — show members list")
        }
        membersView.onProgressTapped = {
            print("Progress bar tapped — show progress details")
        }
        membersView.onContainerTapped = {
            print("Container tapped — open group detail")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            getDashboard()
            return
        }

        Task {
               await appDelegate.subscriptionPresenter?.refreshSubscriptionStatus()

               await MainActor.run {
                   self.getDashboard()
               }
           }
        
        print(hasPaidSubscription)
        lblName.text = User.curentUser?.name ?? ""
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        
        
        setupUi()
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let tabBar = tripsTabBarController else {
            return
        }
        
        
        // Force tab bar visible + stop auto-hide while onboarding runs
        tabBar.showTabBar()
        tabBarHideTimer?.invalidate()
        
        let steps: [OnboardingStep] = [
            
            // 1. Create Your Trip
            OnboardingStep(
                style: .spotlight(target: { [weak self] in
                    self?.btnCreateGroup
                }),
                illustration: UIImage(named: "onboard_create_trip"),
                title: "Create or join your group",
                description: "Start your group in just one tap. Add your destination, dates, and travel preferences to get started.",
                tooltipPosition: .above,    scrollView: self.scrollVw
            ),
            OnboardingStep(
                style: .spotlight(target: { [weak self] in
                    self?.btnList
                }),
                illustration: UIImage(named: "imgGroup"),
                title: "See all your groups",
                description: "Tap here to view and switch between all your groups.",
                tooltipPosition: .above,
                tabIndex: 1
            ),
            
            
            // 2. New Matches & Saved Groups
            OnboardingStep(
                style: .spotlight(target: { [weak tabBar] in
                    tabBar?.groupsTabButton
                }),
                illustration: UIImage(named: "imgGroup"),
                title: "New matches & saved groups",
                description: "See your new matches and saved groups here.",
                tooltipPosition: .above,
                tabIndex: 1
            ),
            
            // 3. Match With People
            OnboardingStep(
                style: .spotlight(target: { [weak tabBar] in
                    tabBar?.discoverTabButton
                    
                }),
                illustration: UIImage(named: "imgMatch"),
                title: "Match with people who travel like you",
                description: "Discover travelers and groups that match your travel style and interests.",
                tooltipPosition: .above,
                tabIndex: 2
            ),

            
            // 4. Chat
            OnboardingStep(
                style: .spotlight(target: { [weak tabBar] in
                    tabBar?.chatTabButton
                    
                }),
                illustration: UIImage(named: "imgChat2"),
                title: "Chat with people & groups",
                description: "Message your matches  or chat into a group chat with fellow travelers.",
                tooltipPosition: .above,
                tabIndex: 3
            ),
            
            // 5. Profile
            OnboardingStep(
                style: .spotlight(target: { [weak tabBar] in
                    tabBar?.profileTabButton
                }),
                illustration: UIImage(named: "imgprofile"),
                title: "Update your profile",
                description: "Update your profile, travel style, interests and preferences here.",
                tooltipPosition: .above,
                action: .done,
                tabIndex: 4
            )
        ]
        
        
        OnboardingCoachMarkManager.shared.start(
            flowID: "home_v2",
            steps: steps,
            in: self.view.window ?? self.view
        )
    }
    
    deinit {
        tabBarHideTimer?.invalidate()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
    }
    
    
    func shareInvite(_ code:String) {
        
        let message = """
        ✈️ Join my travel group!
        
        Use this link to join:
        \(code)
        
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
   
   
    func setupUi(){
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
        lblGreating.text = getGreeting()
        lblName.setFont(.semiBold, size: 19.0)
        lblDate.setFont(.regular, size: 12.0)
        lblLocation.setFont(.regular, size: 12.0)
        lblHours.setFont(.bold, size: 16.0)
        lblMin.setFont(.bold, size: 16.0)
        lblSec.setFont(.bold, size: 16.0)
        lblDay.setFont(.bold, size: 16.0)
        lblGreating.setFont(.regular, size: 12.0)
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        imgProfile.contentMode = .scaleAspectFill
        getGroups()
        AppLoader.show(text: "")
        membersView.translatesAutoresizingMaskIntoConstraints = false
        vwMembers.addSubview(membersView)
        if User.curentUser?.isVerified == 1 {
            imgVerify.isHidden = false
        } else {
            imgVerify.isHidden = true
        }
        
        NSLayoutConstraint.activate([
            membersView.leadingAnchor.constraint(equalTo: vwMembers.leadingAnchor),
            membersView.trailingAnchor.constraint(equalTo: vwMembers.trailingAnchor),
            membersView.topAnchor.constraint(equalTo: vwMembers.topAnchor),
            membersView.bottomAnchor.constraint(equalTo: vwMembers.bottomAnchor),
        ])

        
        tblVw.register(PastTableViewCell.self)
        getGroups()
        getPastGroups()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleValueUpdated(_:)),
            name: .valueUpdated,
            object: nil
        )
    }
    
    func setupCountdown(startDateString: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: startDateString) {
            self.targetDate = date
            startTimer()
        }
    }
    
    
    func startTimer() {
        timer?.invalidate() // avoid multiple timers

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    func updateCountdown() {
        guard let targetDate = targetDate else { return }

        let calendar = Calendar.current
        let now = Date()

        // Start of the target day (00:00)
        let targetDayStart = calendar.startOfDay(for: targetDate)

        // If we've reached the target date, show zero
        if now >= targetDayStart {
            timer?.invalidate()

            lblDay.text = "00"
            lblHours.text = "00"
            lblMin.text = "00"
            lblSec.text = "00"
            return
        }

        let components = calendar.dateComponents(
            [.day, .hour, .minute, .second],
            from: now,
            to: targetDayStart
        )

        lblDay.text = String(format: "%02d", components.day ?? 0)
        lblHours.text = String(format: "%02d", components.hour ?? 0)
        lblMin.text = String(format: "%02d", components.minute ?? 0)
        lblSec.text = String(format: "%02d", components.second ?? 0)
    }
    
    
    func getPastGroups() {
        request.getGroups(3) { model,msg, code in
            if code == 200 {
                DispatchQueue.main.async { [self] in
                        self.pastData = model?.dataGroup ?? []
                        self.tblVw.reloadData()
                    if pastData?.count == 0 {
                        self.pastTblheight.constant = 0
                        self.pastLbl.isHidden = true
                        self.pastLblYear.isHidden = true
                    } else {
                        self.pastLbl.isHidden = false
                        self.pastLblYear.isHidden = false
                        self.pastTblheight.constant = CGFloat(125) * CGFloat(pastData?.count ?? 0)
                    }
                }
            }
        }
    }
    
    func getGroups() {
        
        request.getGroups(0) { model,msg, code in
            if code == 200 {
                DispatchQueue.main.async { [self] in
                    self.dataArray = model?.dataGroup ?? []
                    
                    if let groups = model?.dataGroup, !groups.isEmpty {
                        self.btnEdit.isHidden = false
                        self.btnList.menu = makeTripMenu(trips: groups)
                        self.btnList.showsMenuAsPrimaryAction = true
                        
                        let savedId = UserDefaults.standard.string(forKey: "selectedGroupId")
                        
                        // Find previously selected group
                        let selectedGroup = groups.first {
                            $0.id == savedId
                        } ?? groups.first!
                        
                        self.didSelectTrip(selectedGroup)
                        
                        self.hideVw.isHidden = true
                        self.height.constant = 670
                        self.btnList.isHidden = false
                        
                    } else {
                        self.btnEdit.isHidden = true
                        self.btnList.isHidden = true
                        self.hideVw.isHidden = false
                        self.height.constant = 100
                    }
                    
                }
            } else {
                self.btnEdit.isHidden = true
                DispatchQueue.main.async {
                    self.btnList.isHidden = true
                    self.showAlert(msg)
                }
                
            }
        }
        
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
//        resetTabBarTimer()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        showTabBarTemporarily()
    }

//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        resetTabBarTimer()
//    }
    
    
    @objc private func createGroupTapped() {
        print(":tag105")
        
        self.pushVC(WelcomeViewController.self, from: .Home,hideTabBar: true)
    }
    
    
    func getDashboard() {
        
        getPastGroups()
        request.getProfile { loginUser, errMsg, errCode in
        }
        
        request.getDashBoardAPi { model, errMsg, errCode in
            
            if errCode == 200 {
                DispatchQueue.main.async {
                    if let first = model?.data?.counts {
                        self.lblSaved.text =  "\(first.savedGroups ?? 0)"
                        self.lblActive.text = "\(first.activeChats ?? 0)"
                        self.lblNew.text =    "\(first.newMatches ?? 0)"
                    }
                }
            }
        }
    }
}



extension HomeViewController {
    
    @IBAction func btnActions(_ sender:UIButton) {
        print(sender.tag , "CLODIDID")
        switch sender.tag {
        case 101:
            selectedGlobal = 0
             
            self.tripsTabBarController?.switchTo(index: 1)
            break
        case 102:
            self.tripsTabBarController?.switchTo(index:3)
            break
        case 103:
            selectedGlobal = 1
            self.tripsTabBarController?.switchTo(index: 1)
            break
        case 104:
            self.btnOpenGroupChat()
            break
        case 105:
            self.createGroupTapped()
            break
        default:
            break
        }
    }
    
    @IBAction func btnOpenGroup(_ sender:UIButton) {
        
        self.pushVC(MyGroupViewController.self, from: .Home,hideTabBar: true) { vc in
            vc.res = self.selected
            
        }
    }
    
    @IBAction func editGroupTapped(_ sender:UIButton) {
        if selected == nil {
            return 
        }
        self.editGroupTappedfunc(self.selected!.toJSON())
    }
    
    @objc private func editGroupTappedfunc(_ group: [String: Any]) {
        guard let model = GroupModel.from(group) else { return }

        let vc = EditGroupViewController()
        vc.groupModel = model
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    func btnOpenGroupChat() {
        
        let group = self.selected
        

        let currentUserId = User.curentUser?.id ?? ""

        // Get all member ids
        var participantIds = group?.members?.compactMap { $0.id } ?? []

        let viewModel = ChatViewModel(
            currentUserId: currentUserId
        )

        // Open existing room directly if available
        let vc = ChatMessageVc(
            viewModel: viewModel,
            participants: group?.membersUser ?? [],
            roomId: "group.chatId",
            roomTitle: group?.title ?? "",
            type: .group
        )
        vc.roomImageURL =  group?.coverImage ?? ""
        vc.memberCount = participantIds.count

        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnNotification(_ sender:UIButton) {
        self.pushVC(NotificationVc.self, from: .Home,hideTabBar: true)
    }
    
    
    @IBAction func btnCreateGroup(_ sender:UIButton) {
        
        if !hasPaidSubscription && (self.dataArray?.count ?? 0) >= 1 {
            showMaterialConfirm(title: "", message: "Upgrade to a subscription to create more than one group.") {
                self.upgradeButtonTapped()
            }
            
            return
        }
        self.pushVC(WelcomeViewController.self, from: .Home,hideTabBar: true)
    }
    
    // MARK: - App Tutorial

    
    
}


extension HomeViewController : UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  pastData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : PastTableViewCell = tblVw.dequeue(PastTableViewCell.self, for: indexPath)
        let model = pastData?[indexPath.row]
        cell.lblDate.text = self.formatDateRange(
            start: model?.startDate ?? "",
            end: model?.endDate ?? ""
        )
        cell.lblTitle.text = model?.title ?? ""
        loadImage(cell.imgVw, url: URL(string: model?.coverImage ?? "")!)
        cell.imgVw.layer.cornerRadius =  10
        cell.imgVw.contentMode = .scaleAspectFill
        cell.imgVw.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
    
}


extension HomeViewController {
    
    @IBAction func btnShare(_ sender:UIButton) {
        print("SHARE TAPPED ,","\(self.selected?.joinCode ?? "")")
        self.shareInvite(self.selected?.joinCode ?? "")
    }
}

import UIKit

extension UIButton {

    func applyGlassEffect() {

        // Avoid duplicate blur views
        subviews.forEach {
            if $0 is UIVisualEffectView {
                $0.removeFromSuperview()
            }
        }

        let blurView = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemUltraThinMaterialDark)
        )

        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false

        insertSubview(blurView, at: 0)

        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        clipsToBounds = true

        backgroundColor = UIColor.white.withAlphaComponent(0.05)

        setTitleColor(.white, for: .normal)
    }
}

final class AppData {

    static let shared = AppData()

    private init() {}

    var latitude: Double?
    var longitude: Double?
}
