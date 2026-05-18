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
    
    func loadData() {
        if let res = self.res {
            
            self.setupCountdown(startDateString: res.startDate ?? "")
            
            self.lblDate.text = self.formatDateRange(
                start: res.startDate ?? "",
                end: res.endDate ?? ""
            )
            
            lblGroupCount.text = "\(res.members?.count ?? 0) Travelers"
            self.lblLocation.text = res.destination ?? ""
            self.lblTitle.text = res.groupTitle ?? ""
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
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
           handleScroll(scrollView)
       }
    
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
        if User.curentUser?.name ?? "" == model?.name {
            cell.lblName.text = "You"
            cell.lblLocation.text = UserDefaults.standard.value(forKey: "user_loc") as? String ?? "No Location"
            cell.btnEdit.setTitle("Edit Your Profile", for: .normal)
            cell.btnEdit.backgroundColor = .clear
        } else {
            cell.lblLocation.text = "No Location"
            cell.lblName.text = model?.name ?? ""
            cell.btnEdit.setTitle("Message", for: .normal)
            cell.btnEdit.backgroundColor = .themeOrange
        }
        
        if let url = URL(string: model?.profileImage ?? "") {
            self.loadImage(cell.imgUser, url: url)
        }
        cell.imgUser.layer.cornerRadius = cell.imgUser.frame.height / 2
        cell.imgUser.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    @objc func editUser() {
        
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
