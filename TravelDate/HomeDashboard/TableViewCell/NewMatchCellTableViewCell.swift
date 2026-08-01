//
//  NewMatchCellTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit

class NewMatchCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nwVw:UIView!
    @IBOutlet weak var savedVw:UIView!
    @IBOutlet weak var matchVw:UIView!
    @IBOutlet weak var matchVwSave:UIView!
    @IBOutlet weak var lblMatched:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var lblTime:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var btnSaveGroup:UIButton!
    @IBOutlet weak var btnStart:UIButton!
    @IBOutlet weak var imgVw:UIImageView!
    @IBOutlet weak var imgVwSave:UIImageView!
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblTimeSave:UILabel!
    @IBOutlet weak var lblLocationSave:UILabel!
    @IBOutlet weak var btnViewGroup:UIButton!
    
    let membersView = MembersProgressView()
    let membersVwSave = MembersProgressView()
    
    var onStartChat: (() -> Void)?
    var onSaveGroup: (() -> Void)?
    var onViewGroup: (() -> Void)?
    var onRemoveBookmark: (() -> Void)?
    func setTimeText(_ text: String)  { lblTime.text  = text  }
    func setTimeTextSave(_ text: String)  { lblTimeSave.text  = text  }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        membersView.translatesAutoresizingMaskIntoConstraints = false
        membersView.progressTrack.isHidden  = true
        membersVwSave.progressTrack.isHidden  = true
        membersView.backgroundColor = .clear
        membersVwSave.backgroundColor = .clear
        matchVw.addSubview(membersView)
        NSLayoutConstraint.activate([
            membersView.leadingAnchor.constraint(equalTo: matchVw.leadingAnchor),
            membersView.trailingAnchor.constraint(equalTo: matchVw.trailingAnchor),
            membersView.topAnchor.constraint(equalTo: matchVw.topAnchor),
            membersView.bottomAnchor.constraint(equalTo: matchVw.bottomAnchor),
        ])
        
        membersVwSave.translatesAutoresizingMaskIntoConstraints = false
        matchVwSave.addSubview(membersVwSave)
        NSLayoutConstraint.activate([
            membersVwSave.leadingAnchor.constraint(equalTo: matchVwSave.leadingAnchor),
            membersVwSave.trailingAnchor.constraint(equalTo: matchVwSave.trailingAnchor),
            membersVwSave.topAnchor.constraint(equalTo: matchVwSave.topAnchor),
            membersVwSave.bottomAnchor.constraint(equalTo: matchVwSave.bottomAnchor),
        ])
        
        // MARK: - Fonts
        lblMatched.font = AppFont.semibold(14)
        lblTitle.font = AppFont.semibold(16)
        lblTime.font = AppFont.regular(13)
        lblLocation.font = AppFont.regular(13)
        
        lblName.font = AppFont.semibold(16)
        lblTimeSave.font = AppFont.regular(13)
        lblLocationSave.font = AppFont.regular(13)
        btnSaveGroup.layer.borderWidth = 1
        btnSaveGroup.layer.borderColor = UIColor.lightGray.cgColor
        
        btnViewGroup.layer.borderWidth = 1
        btnViewGroup.layer.borderColor = UIColor.lightGray.cgColor
        btnStart.addTarget(self, action: #selector(startChatTapped), for: .touchUpInside)
        btnSaveGroup.addTarget(self, action: #selector(saveGroupTapped), for: .touchUpInside)
        btnViewGroup.addTarget(self,
                               action: #selector(viewGroupTapped),
                               for: .touchUpInside)

       
    }
    
    @objc func viewGroupTapped() {
        onViewGroup?()
    }
    
    @objc private func startChatTapped() {
        onStartChat?()
    }
    
    @objc private func saveGroupTapped() {
        onSaveGroup?()
        
    }
    
    func showNewMatch() {
        nwVw.isHidden = false
        savedVw.isHidden = true
    }

    func showSavedGroup() {
        nwVw.isHidden = true
        savedVw.isHidden = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
    
    func configureNewMatch(with model: Group) {

        nwVw.isHidden = false
        savedVw.isHidden = true

        let group = model

        lblTitle.text = group.title
        lblLocation.text = group.destination

//        lblTime.text = formatDateRange(
//            start: group?.startDate ?? "",
//            end: group?.endDate ?? ""
//        )

        

        membersView.configure(
            members: group.members ?? [],
            totalCount: group.maxGroupSize ?? 0,
            completedCount: group.members?.count ?? 0
        )
    }

    
    
    func configureSavedGroup(with model: Group) {
        print("nwVw:", nwVw.isHidden)
        print("savedVw:", savedVw.isHidden)
//        nwVw.isHidden = true
        savedVw.isHidden = false

        lblName.text = model.title
        lblLocationSave.text = model.destination

//        lblTimeSave.text = formatDateRange(
//            start: model.startDate ?? "",
//            end: model.endDate ?? ""
//        )

        membersVwSave.configure(
            members: model.members ?? [],
            totalCount: model.maxGroupSize ?? 0,
            completedCount: model.members?.count ?? 0
        )
    }
    
}
