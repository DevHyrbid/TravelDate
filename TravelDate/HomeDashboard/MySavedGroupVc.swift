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
    var chatData: [ChatData] = []
    
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
        if data?.members?.count == 1 {
            lblCount.text = "\(data?.members?.count ?? 0) Traveler"
        } else {
            lblCount.text = "\(data?.members?.count ?? 0) Travelers"
        }
        
        lblName.text = data?.title ?? ""
        
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
        let model = self.data?.members?[indexPath.row]
        if User.curentUser?.name ?? "" == model?.name {
            cell.lblName.text = "You"
            cell.btnEdit.setTitle("Edit Your Profile", for: .normal)
            cell.btnEdit.backgroundColor = .clear
            cell.btnEdit.addTarget(self, action: #selector(editUser(_:)), for: .touchUpInside)
            cell.btnEdit.tag = indexPath.row
        } else {
            cell.lblName.text = model?.name ?? ""
            cell.btnEdit.tag = indexPath.row
            cell.btnEdit.setTitle("Message", for: .normal)
            cell.btnEdit.backgroundColor = .themeOrange
            cell.btnEdit.addTarget(self, action: #selector(openChat(_:)), for: .touchUpInside)
        }
        cell.styles = model?.travelStyle ?? []
        print(model?.travelStyle ?? [],"iuoiooppppppp",model)
        cell.lblLocation.text = model?.locationString ?? ""
        cell.lblDescription.text = model?.shortBio ?? ""
        
        if let url = URL(string: model?.profile_image ?? "") {
            self.loadImage(cell.imgUser, url: url)
        } else {
            cell.imgUser.image = UIImage(named: "User")
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
        guard let selectedUser = self.data?.members?[sender.tag] else { return }
        
        request.targetUserId  = selectedUser.id  ?? ""
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
        return 400
    }
    
    
}


extension MySavedGroupVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnChat(_ sender:UIButton) {
        print(data?._id,data?.toJSON(),"herere")
        fetchChats { [weak self] in
            guard let self else { return }

            let targetGroupId = self.data?._id ?? ""

            let item = chatData.first {
                let responseGroupId = $0.groupDetails?.group2Id ?? ""

                print("Comparing '\(responseGroupId)' == '\(targetGroupId)'")

                return responseGroupId == targetGroupId
            }

            print(item == nil ? "NOT FOUND" : "FOUND")

            guard let item else {
                return
            }

            let viewModel = ChatViewModel(
                currentUserId: User.curentUser?.id ?? ""
            )

            let vc = ChatMessageVc(
                viewModel: viewModel,
                participants: item.members ?? [],
                roomId: item.chatId,
                roomTitle: item.name ?? "",
                type: .group
            )

            vc.roomImageURL = data?.coverImage ?? ""

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
        

        
        
        
        private func fetchChats(completion: (() -> Void)? = nil) {
            request.getChatsInbox(1) { [weak self] model, msg, code in
                guard let self else { return }

                DispatchQueue.main.async {
                    if code == 200 {
                        self.chatData = model?.data ?? []
                        completion?()
                    }
                }
            }
        }

    
}

