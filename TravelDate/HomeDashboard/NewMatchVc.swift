//
//  NewMatchVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit
enum MatchTab {
    case new
    case saved
    case active
}
var selectedGlobal = 0
class NewMatchVc: BaseClassVc {
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var lblNewMatch:UILabel!
    @IBOutlet weak var lblMatchCount:UILabel!
    @IBOutlet weak var btnNew:UIButton!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnActive:UIButton!
    
    @IBOutlet weak var lblNoData:UILabel!
    var selectedTab: MatchTab = .new
    var data: [DataMatch]? = nil
    var dataGroup: [Group]?

    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    func setupUi(){
        lblNoData.setFont(.medium, size: 20.0)
        lblNewMatch.setFont(.medium, size: 18.0)
        lblMatchCount.setFont(.regular, size: 16.0)
        btnSave.setFont(.medium, size: 15.0)
        btnNew.setFont(.medium, size: 15.0)
        btnNew.layer.cornerRadius = 20
        btnSave.layer.cornerRadius = 20
        registerNib()
        if selectedGlobal == 0 {
            selectTab(.new) // default selected
            getGroups(1)
        }
        if selectedGlobal == 1 {
            selectTab(.saved) // default selected
            getGroups(2)
        }
        
        tblVw.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tblVw.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tblVw.alwaysBounceVertical = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tripsTabBarController?.showTabBar()
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
    
    
    
    
    func getNewMatches() {
        request.newMatches { [self] res, errMsg, errCode in
            if errCode == 200 {
                DispatchQueue.main.async {
                    self.data = res?.dataMatch ?? nil
                    self.tblVw.reloadData()
                    if self.data?.count == 0 {
                        self.lblNoData.isHidden = false
                    } else {
                        self.lblNoData.isHidden = true
                    }
                }
            }
        }
    }
    
    
    func getGroups(_ req:Int) {
        var reqType = req

        switch req {
        case 1:
            getNewMatches()
            return

        case 2:
            reqType = 4

        default:
            break
        }

        request.getGroups(reqType) { [weak self] res, errMsg, errCode in
            guard errCode == 200 else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                guard let groups = res?.dataGroup else { return }

                self.dataGroup = groups
                self.lblNoData.isHidden = !groups.isEmpty
                self.tblVw.reloadData()
            }
        }
    }
    
    
    func registerNib() {
        tblVw.register(NewMatchCell.self, forCellReuseIdentifier: "NewMatchCell")
        tblVw.register(SavedGroupCell.self, forCellReuseIdentifier: "SavedGroupCell")
    }
    
    func setupButtons() {
        [btnNew, btnSave, btnActive].forEach {
            ($0 as? GlassButton)?.setUnselectedStyle()
        }
    }

    func selectTab(_ tab: MatchTab) {
        selectedTab = tab
        let buttons = [
            btnNew as? GlassButton,
            btnSave as? GlassButton,
            btnActive as? GlassButton
        ]
        
        // Reset → glass
        buttons.forEach { $0?.setUnselectedStyle() }
        
        // Select one
        switch tab {
        case .new:
            (btnNew as? GlassButton)?.setSelectedStyle()
            getGroups(1)
        case .saved:
            (btnSave as? GlassButton)?.setSelectedStyle()
            getGroups(2)
        case .active:
            (btnActive as? GlassButton)?.setSelectedStyle()
        }
        
        tblVw.reloadData()
    }
}

// MARK: - TableViewDelegate
extension NewMatchVc : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       

        switch selectedTab {
        case .new:
            let model = data?[indexPath.row].otherGroup ?? nil
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewMatchCell", for: indexPath) as! NewMatchCell
            if let model { cell.configure(with: model) }
            if let url = URL(string: model?.coverImage ?? "") {
                loadImage(cell.imageView_, url: url)
            }
            cell.timeLabel.text = formatDateRange(start: model?.startDate ?? "", end: model?.endDate ?? "")
            cell.onStartChat = { /* push chat VC */ }
            cell.onSaveGroup = { [weak self] in
                guard let self = self else { return }
                guard let groupId = model?._id else { return }

                request.saveGroupAPi(groupId) { errMsg, errCode in
                    
                    DispatchQueue.main.async {

                        if errCode == 200 {

                            self.showAlert(message: "Group saved successfully")

                        } else {

                            self.showAlert(message: errMsg)
                        }
                    }
                }
            }
            return cell

        case .saved:
            let model = dataGroup?[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "SavedGroupCell", for: indexPath) as! SavedGroupCell
            if let model { cell.configure(with: model) }
            if let url = URL(string: model?.coverImage ?? "") {
                loadImage(cell.heroImage, url: url)
            }
            cell.setTimeText(formatDateRange(start: model?.startDate ?? "", end: model?.endDate ?? ""))
            cell.onViewGroup = { [weak self] in self?.pushVC(MySavedGroupVc.self, from: .Home) { vc in
                vc.data = model 
            } }
            cell.onBookmark = { [weak self] in
                guard let self = self else { return }
                guard let groupId = model?._id else { return }

                request.saveGroupAPi(groupId) { errMsg, errCode in
                    
                    DispatchQueue.main.async {

                        if errCode == 200 {

                            self.showAlert(message: "Group Removed successfully")
                            self.getGroups(2)
                        } else {

                            self.showAlert(message: errMsg)
                        }
                    }
                }
            }
            return cell

        case .active:
            // Return your ActiveCell here when ready
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch selectedTab {
        case .new:    return 600
        case .saved:  return 560
        case .active: return 750
        }
    }
    
}


extension NewMatchVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    
    @IBAction func btnAction(_ sender: UIButton) {
        
        if sender == btnNew {
            selectTab(.new)
            
        } else if sender == btnSave {
            selectTab(.saved)
        } else if sender == btnActive {
            selectTab(.active)
        }
    }
}

