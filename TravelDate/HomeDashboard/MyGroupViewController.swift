import UIKit


// MARK: - DESIGN TOKENS
struct DS {
    static let bg = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
    static let card = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)
    static let stroke = UIColor.white.withAlphaComponent(0.05)
    static let secondary = UIColor.white.withAlphaComponent(0.6)
    static let muted = UIColor.white.withAlphaComponent(0.4)
    static let orange = UIColor(red: 1.0, green: 0.47, blue: 0.0, alpha: 1)
}

// MARK: - CONTROLLER
class MyGroupViewController: BaseClassVc {

    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var tblVwHeight:NSLayoutConstraint!
    
    @IBOutlet weak var lblGroupCount:UILabel!
    @IBOutlet weak var lblDay:UILabel!
    @IBOutlet weak var lblMin:UILabel!
    @IBOutlet weak var lblSec:UILabel!
    @IBOutlet weak var lblHours:UILabel!
    @IBOutlet weak var lblDate:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var imgTrips:UIImageView!
    
    // MARK: - Properties
    var res : Group? = nil
    var timer: Timer?
    var targetDate: Date?
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        lblDate.setFont(.regular, size: 12.0)
        lblLocation.setFont(.regular, size: 12.0)
        lblHours.setFont(.bold, size: 16.0)
        lblMin.setFont(.bold, size: 16.0)
        lblSec.setFont(.bold, size: 16.0)
        lblDay.setFont(.bold, size: 16.0)
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
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
    
    
    
    
    func loadData() {
        if let res = self.res {
            
            self.setupCountdown(startDateString: res.startDate ?? "")
            
            self.lblDate.text = self.formatDateRange(
                start: res.startDate ?? "",
                end: res.endDate ?? ""
            )
            
            lblGroupCount.text = "\(res.members?.count ?? 0) Travelers"
            self.lblLocation.text = res.destination ?? ""
            self.lblTitle.text = res.title ?? ""
            if let url = URL(string: res.coverImage ?? "") {
                loadImage(self.imgTrips, url: url)
            }
        }
        registerNib()
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

        let now = Date()

        if targetDate <= now {
            timer?.invalidate()
            
            lblDay.text = "0"
            lblHours.text = "0"
            lblMin.text = "0"
            lblSec.text = "0"
            return
        }

        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: targetDate)

        lblDay.text = String(format: "%02d", components.day ?? 0)
        lblHours.text = String(format: "%02d", components.hour ?? 0)
        lblMin.text = String(format: "%02d", components.minute ?? 0)
        lblSec.text = String(format: "%02d", components.second ?? 0)
    }
    
    
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//           handleScroll(scrollView)
//       }
    
    func registerNib(){
        tblVw.register(GroupTableViewCell.self)
        tblVwHeight.constant = 100 + (CGFloat(self.res?.members?.count ?? 0) * 400)
    }
}

// MARK: - TableViewDelegate 
extension MyGroupViewController : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.res?.members?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : GroupTableViewCell = tableView.dequeue(GroupTableViewCell.self, for: indexPath)
        let model = self.res?.members?[indexPath.row]
        if User.curentUser?.name ?? "" == model?.userMembers?.name {
            cell.lblName.text = "You"
            cell.btnEdit.setTitle("Edit Your Profile", for: .normal)
            cell.btnEdit.backgroundColor = .clear
            cell.btnEdit.addTarget(self, action: #selector(editUser(_:)), for: .touchUpInside)
            cell.btnEdit.tag = indexPath.row
        } else {
            cell.lblName.text = model?.userMembers?.name ?? ""
            cell.btnEdit.tag = indexPath.row
            cell.btnEdit.setTitle("Message", for: .normal)
            cell.btnEdit.backgroundColor = .themeOrange
            cell.btnEdit.addTarget(self, action: #selector(openChat(_:)), for: .touchUpInside)
        }
        
        let styles = model?.userMembers?.travelStyles ?? []

        cell.lbl1.text = styles.indices.contains(0) ? " \(styles[0]) " : nil
        cell.lbl2.text = styles.indices.contains(1) ? " \(styles[1]) " : nil
        cell.lbl3.text = styles.indices.contains(2) ? " \(styles[2]) " : nil
        cell.lbl4.text = styles.indices.contains(3) ? " \(styles[3]) " : nil
        cell.lbl1.isHidden = !styles.indices.contains(0)
        cell.lbl2.isHidden = !styles.indices.contains(1)
        cell.lbl3.isHidden = !styles.indices.contains(2)
        cell.lbl4.isHidden = !styles.indices.contains(3)
        
        
        cell.lblLocation.text = model?.userMembers?.locationstring ?? ""
        cell.lblDescription.text = model?.userMembers?.shortbio ?? ""
        
        if let url = URL(string: model?.userMembers?.profile_image ?? "") {
            self.loadImage(cell.imgUser, url: url)
        }
        cell.imgUser.layer.cornerRadius = cell.imgUser.frame.height / 2
        cell.imgUser.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    @objc func editUser(_ sender:UIButton) {
        self.pushVC(EditProfileVc.self, from: .Settings)
    }
    
    
    @objc func openChat(_ sender:UIButton) {
        guard let selectedUser = self.res?.members?[sender.tag] else { return }
        
        request.targetUserId  = selectedUser.userMembers?.id  ?? ""
        request.directChat { model,errMsg, errCode in
            if errCode == 200 {
                
                
                
                let currentUserId = User.curentUser?.id ?? ""
                let otherParticipantId = selectedUser.userMembers?.id  ?? ""
                
                // Prevent self chat
                guard otherParticipantId != currentUserId else { return }
                
                let viewModel = ChatViewModel(
                    currentUserId: currentUserId
                )
                
                let vc = ChatMessageVc(
                    viewModel: viewModel,
                    participants: model?.participantsUser ?? [],
                    roomId: model?.id ?? "", //. ID HERE
                    roomTitle: selectedUser.name ?? "Chat",
                    type: .individual
                )
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 430
    }
    
    
}


extension MyGroupViewController {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnChat(_ sender:UIButton) {
        super.backTapped()
    }
}
