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
    @IBOutlet weak var lblMatched:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var lblTime:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var btnSaveGroup:UIButton!
    @IBOutlet weak var btnStart:UIButton!
    @IBOutlet weak var imgVw:UIImageView!
    
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblTimeSave:UILabel!
    @IBOutlet weak var lblLocationSave:UILabel!
    @IBOutlet weak var btnViewGroup:UIButton!
    
    let membersView = MembersProgressView()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        membersView.translatesAutoresizingMaskIntoConstraints = false
        matchVw.addSubview(membersView)
        NSLayoutConstraint.activate([
            membersView.leadingAnchor.constraint(equalTo: matchVw.leadingAnchor),
            membersView.trailingAnchor.constraint(equalTo: matchVw.trailingAnchor),
            membersView.topAnchor.constraint(equalTo: matchVw.topAnchor),
            membersView.bottomAnchor.constraint(equalTo: matchVw.bottomAnchor),
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
