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
    @IBOutlet weak var lblNoData:UILabel!
    
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
                    self.notifications = model?.data?.notifications ?? []
                    if self.notifications?.count ?? 0 == 0 {
                        self.lblNoData.isHidden = false
                    } else {
                        self.lblNoData.isHidden = true
                    }
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
            cell.lblTime.text = timeAgo(from: model.createdAt ?? "")
            if let profileImage = model.sender?.profileImage,
               let url = URL(string: "\(profileImage)") {
                if url.absoluteString.contains("https://lh3.googleuserconten") {
                    self.loadImage(cell.imgVw, url: url)
                } //\(APiConstant.base)
                else {
                    if profileImage != "" {
                        self.loadImage(cell.imgVw, url: URL(string: "\(profileImage)")!)
                    }
                    
                }
                 
            } else {
                cell.imgVw.image = UIImage(named: "User")
            }
            
        }
        cell.imgVw.layer.cornerRadius = 12
        return cell
            
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration {

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in

            guard let self = self,
                  let id = self.notifications?[indexPath.row].id else {
                completion(false)
                return
            }

            self.deleteNotifications(ids: [id])
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
    

    
    func deleteNotifications(ids: [String]) {
//.joined(separator: ",")
        request.deleteNotifications(ids: ids) { [weak self] errMsg, errCode in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if errCode == 200 {
                    self.getNotification()
                } else {
                    self.showAlert(errMsg)
                }
            }
        }
    }
}


extension NotificationVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnDeleteAll(_ sender: UIButton) {
        guard let ids = notifications?.compactMap({ $0.id }), !ids.isEmpty else {
            return
        }

        deleteNotifications(ids: ids)
    }
}

