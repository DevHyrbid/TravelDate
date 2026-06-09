//
//  NotificationVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 08/04/26.
//

import UIKit

class NotificationVc: BaseClassVc {
   
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var lblTitle:UILabel!
    
    var notifications: [NotificationItem]?
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
       registerNib()
        lblTitle.setFont(.medium, size: 18.0)
        getNotification()
    }
    
    func registerNib(){
        tblVw.register(NotificationCell.self)
        
    }
    
    func getNotification() {
        request.getNotifications { [self] model, errMsg, errCode in
            DispatchQueue.main.async {
                if errCode == 200 {
                    notifications = model?.data?.notifications ?? []
                    self.tblVw.reloadData()
                    
                } else {
                    self.showAlert(errMsg)
                }
            }
        }
    }
}

// MARK: - TableViewDelegate
extension NotificationVc : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : NotificationCell = tableView.dequeue(NotificationCell.self, for: indexPath)
        if  let model = self.notifications?[indexPath.row] {
            cell.lblDesc.text = model.message ?? ""
            cell.lblTitle.text = model.title ?? ""
            
            if let profileImage = model.sender?.profileImage,
               let url = URL(string: profileImage) {
                self.loadImage(cell.imgVw, url: url)
            }
            cell.imgVw.layer.cornerRadius = 12
        }
        return cell
            
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
}


extension NotificationVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
}

