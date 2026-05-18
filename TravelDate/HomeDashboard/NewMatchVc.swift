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

class NewMatchVc: BaseClassVc {
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var lblNewMatch:UILabel!
    @IBOutlet weak var lblMatchCount:UILabel!
    @IBOutlet weak var btnNew:UIButton!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnActive:UIButton!
    
    @IBOutlet weak var lblNoData:UILabel!
    var selectedTab: MatchTab = .new
    var data: [Group]? = nil
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        lblNoData.setFont(.medium, size: 20.0)
        lblNewMatch.setFont(.medium, size: 18.0)
        lblMatchCount.setFont(.regular, size: 16.0)
        btnSave.setFont(.medium, size: 15.0)
        btnNew.setFont(.medium, size: 15.0)
        btnNew.layer.cornerRadius = 20
        btnSave.layer.cornerRadius = 20
        registerNib()
        selectTab(.new) // default selected
        getGroups()
    }
    
    func getGroups() {
        request.getGroups(2) { [weak self] res, errMsg, errCode in
            guard let self = self else { return }

            if errCode == 200 {
                DispatchQueue.main.async {
                    if let res = res?.data?.groups {
                        self.data = res
                        self.tblVw.reloadData()
                    }
                }
            }
        }
    }
    
    
    
    
    // MARK: - Methods
    func registerNib(){
        tblVw.register(NewMatchCellTableViewCell.self)
        
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
        case .saved:
            (btnSave as? GlassButton)?.setSelectedStyle()
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

        let cell: NewMatchCellTableViewCell = tableView.dequeue(NewMatchCellTableViewCell.self, for: indexPath)

        switch selectedTab {
        case .new:
            let model = data?[indexPath.row]
            cell.lblTitle.text = model?.groupTitle ?? ""
            cell.lblLocation.text = model?.destination ?? ""
            if let url = URL(string: model?.coverImage ?? "" ){
                self.loadImage(cell.imgVw, url: url)
            }
            cell.lblTime.text = self.formatDateRange(start: model?.startDate ?? "", end: model?.endDate ?? "")
            cell.membersView.configure(members: model?.members ?? [], totalCount: (model?.maxGroupSize ?? 0), completedCount: model?.members?.count ?? 0)

            cell.membersView.onAvatarStackTapped = {
                print("Avatar stack tapped — show members list")
            }
            cell.membersView.onProgressTapped = {
                print("Progress bar tapped — show progress details")
            }
            cell.membersView.onContainerTapped = {
                print("Container tapped — open group detail")
            }

            cell.savedVw.isHidden = true
        case .saved:
//            cell.configureForSaved()
            cell.savedVw.isHidden = false
        case .active:
//            cell.configureForActive()
            cell.savedVw.isHidden = true
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch selectedTab {
        case .new:
           break
        case .saved:
            self.pushVC(MySavedGroupVc.self, from: .Home)
            break
        case .active:
            break
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch selectedTab {
        case .new:
            return 550
        case .saved:
            return 600
        case .active:
            return 750
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

