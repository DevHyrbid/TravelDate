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
    @IBOutlet weak var btnNew:UIButton!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnActive:UIButton!
    
    var selectedTab: MatchTab = .new

    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
       registerNib()
        selectTab(.new) // default selected
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: NewMatchCellTableViewCell = tableView.dequeue(NewMatchCellTableViewCell.self, for: indexPath)

        switch selectedTab {
        case .new:
//            cell.vie
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
            return 750
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

