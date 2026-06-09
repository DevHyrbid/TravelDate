//
//  MySavedGroupVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit

class MySavedGroupVc: BaseClassVc {
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgGroup: UIImageView!
    @IBOutlet weak var lblCount: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var tblVwHeight:NSLayoutConstraint!
    
    // MARK: - Properties
    var data: Group? = nil
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
       registerNib()
        setupData()
    }
    
    func registerNib(){
        tblVw.register(GroupTableViewCell.self)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
    }
    
    
    func setupData() {
        lblLocation.text = data?.destination ?? ""
        lblDate.text = self.formatDateRange(
            start: data?.startDate ?? "",
            end: data?.endDate ?? ""
        )
        lblTitle.text = data?.title ?? ""
        loadImage(imgGroup, url: URL(string: data?.coverImage ?? "")!)
        lblCount.text = "\(data?.members?.count ?? 0)"
        lblName.text = data?.creator?.name ?? ""
        tblVwHeight.constant = CGFloat((data?.members?.count ?? 0) * 400)
    }
}

// MARK: - TableViewDelegate
extension MySavedGroupVc : UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.members?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : GroupTableViewCell = tableView.dequeue(GroupTableViewCell.self, for: indexPath)
        let model = data?.members?[indexPath.row]
        cell.lblName.text =  model?.name ?? ""
        cell.imgUser.layer.cornerRadius =  cell.imgUser.frame.height / 2
        loadImage(cell.imgUser, url: URL(string: model?.userMembers?.profile_image ?? "")!)
        cell.lblLocation.layer.cornerRadius = 15
        cell.btnEdit.backgroundColor = UIColor.themeOrange
        cell.btnEdit.setTitleColor(.white, for: .normal)
        cell.btnEdit.setTitle("Message", for: .normal)
        cell.btnEdit.layer.borderWidth = 0
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
        
       
        cell.imgUser.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
    }
    
    
}


extension MySavedGroupVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnChat(_ sender:UIButton) {
        super.backTapped()
    }
}

