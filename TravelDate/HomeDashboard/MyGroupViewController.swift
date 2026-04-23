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

// MARK: - MODEL
struct Member: Hashable {
    let id = UUID()
    let name: String
    let age: Int
    let city: String
    let bio: String
    let tags: [String]
    let isYou: Bool
}

// MARK: - CONTROLLER
class MyGroupViewController: BaseClassVc {

    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var tblVwHeight:NSLayoutConstraint!

    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
       registerNib()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tripsTabBarController?.showTabBar()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
           handleScroll(scrollView)
       }
    
    func registerNib(){
        tblVw.register(GroupTableViewCell.self)
        tblVwHeight.constant = 1600
    }
}

// MARK: - TableViewDelegate 
extension MyGroupViewController : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : GroupTableViewCell = tableView.dequeue(GroupTableViewCell.self, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
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
