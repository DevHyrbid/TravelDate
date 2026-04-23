//
//  NotificationVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 08/04/26.
//

import UIKit

class NotificationVc: BaseClassVc {
   
    @IBOutlet weak var tblVw:UITableView!

    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
       registerNib()
    }
    
    func registerNib(){
        tblVw.register(NotificationCell.self)
        
    }
}

// MARK: - TableViewDelegate
extension NotificationVc : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : NotificationCell = tableView.dequeue(NotificationCell.self, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
}


extension NotificationVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
}

