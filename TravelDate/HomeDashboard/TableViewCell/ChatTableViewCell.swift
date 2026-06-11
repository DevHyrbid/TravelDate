//
//  ChatTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 14/04/26.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var imgVw:UIImageView!
    @IBOutlet weak var lblDesc:UILabel!
    @IBOutlet weak var lblOnline:UILabel!
    @IBOutlet weak var lblTime:UILabel!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblTitle.font = AppFont.regular(18)
        lblDesc.font = AppFont.regular(13)
        lblOnline.layer.cornerRadius = 5
        lblOnline.clipsToBounds = true
        lblTime.font = AppFont.regular(11)
        
        
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = containerView.frame.height / 2
        
        leftImageView.contentMode = .scaleAspectFill
        rightImageView.contentMode = .scaleAspectFill
        
        leftImageView.clipsToBounds = true
        rightImageView.clipsToBounds = true
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
